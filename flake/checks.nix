# Evaluation-time checks that guard wiring `nix flake check` cannot see on its
# own, because it only proves each configuration EVALUATES - not that two
# separately-evaluated configurations still agree with each other.
#
# The scufris secret is exactly that case. It is decrypted once, at the NixOS
# level, and consumed by two units that live in different evaluations:
#
#   * services.scufris-hostd (NixOS)         -> a RAW single-value secret file
#   * programs.scufris (home-manager, alex)  -> a rendered KEY=value env file
#
# home-manager here is standalone (flake/home-configurations.nix), so it cannot
# reference the NixOS `config` and has to name the rendered path as a literal
# string. That literal is the seam this check exists to weld: change the path on
# the NixOS side without changing home/alex and the machine still builds, but
# the user service silently starts with no secrets at all. See
# tasks/20260730-190929/DECISION.md (D1) for why that seam is accepted.
{
  inputs,
  lib,
  ...
}: {
  perSystem = {pkgs, ...}: let
    nixos = inputs.self.nixosConfigurations.nixos.config;
    home = inputs.self.homeConfigurations.alex.config;

    envTemplate = nixos.sops.templates."scufris.env";
    hostdSecret = nixos.sops.secrets."SCUFRIS_HOSTD_SECRET";

    # Resolves anchors/aliases and `creation_rules` the way sops itself does,
    # which a grep cannot: the `keys:` list is a shared POOL, and each rule
    # picks a subset of it. Reading it any other way makes a second machine that
    # legitimately does not hold this credential look like a defect.
    python = pkgs.python3.withPackages (ps: [ps.pyyaml]);
  in {
    checks.scufris-secret-wiring =
      pkgs.runCommand "scufris-secret-wiring" {
        # The ENCRYPTED file: the check reads the variable NAMES straight from
        # the ciphertext (sops leaves top-level keys in the clear), so adding a
        # variable to the secret without adding it to the template fails here
        # rather than at runtime. Nothing is decrypted.
        sopsFile = hostdSecret.sopsFile;
        # The recipient POLICY, plus this secret's path RELATIVE to the flake
        # root - the path `creation_rules` match against. Derived by stripping
        # the store prefix rather than written out again, so it cannot drift
        # from the sopsFile above.
        sopsPolicy = "${inputs.self}/.sops.yaml";
        sopsRelPath = lib.removePrefix "${inputs.self}/" hostdSecret.sopsFile;
        nativeBuildInputs = [python];
        templateContent = envTemplate.content;
        templatePath = envTemplate.path;
        hostdSecretPath = hostdSecret.path;
        hostdExecStart = nixos.systemd.services.scufris-hostd.serviceConfig.ExecStart;
        homeEnvironmentFile = home.programs.scufris.environmentFile;
        # Reaching the socket is a precondition for the secret to matter at all,
        # and unlike a wrong path it fails SILENTLY - so it is asserted here too.
        socketGroup = nixos.services.scufris-hostd.group;
        userGroups = nixos.users.users.alex.extraGroups;
        declaredGroups = builtins.attrNames nixos.users.groups;
        policyCheck = ''
          import re, sys, yaml

          policy_path, rel_path, cipher_path = sys.argv[1:4]
          policy = yaml.safe_load(open(policy_path))
          cipher = yaml.safe_load(open(cipher_path))

          # sops applies the FIRST creation rule whose path_regex matches, and a
          # rule with no path_regex matches everything.
          rule = next(
              (r for r in policy.get("creation_rules", [])
               if re.search(r.get("path_regex", ""), rel_path)),
              None,
          )
          if rule is None:
              sys.exit(f"no creation_rule in {policy_path} matches {rel_path}: "
                       "sops would refuse to encrypt it")

          def recipients(age):
              # sops accepts `age:` as either a list or a COMMA-SEPARATED STRING
              # (config/config.go declares it `interface{} // string or []string`,
              # and the comma-separated form is the documented one).
              if age is None:
                  return []
              if isinstance(age, str):
                  return [r.strip() for r in age.split(",") if r.strip()]
              return list(age)

          expected = {
              recipient
              for group in rule.get("key_groups", [{"age": rule.get("age")}])
              for recipient in recipients(group.get("age"))
          }

          # The ciphertext mirrors that shape: a single key group is flattened to
          # a top-level `sops.age`, but with more than one sops writes
          # `sops.key_groups` instead and omits `age` entirely
          # (stores/stores.go, `omitempty`).
          meta = cipher.get("sops", {})
          entries = meta.get("age") or [
              entry
              for group in meta.get("key_groups", [])
              for entry in (group.get("age") or [])
          ]
          actual = {entry["recipient"] for entry in entries}

          if not expected:
              sys.exit(f"the creation_rule for {rel_path} names no age recipients")
          missing, extra = expected - actual, actual - expected
          if missing:
              sys.exit(f"{rel_path} is NOT encrypted to {sorted(missing)} - "
                       "run 'sops updatekeys' on it")
          if extra:
              sys.exit(f"{rel_path} is encrypted to {sorted(extra)}, which "
                       f"{policy_path} does not grant it - run 'sops updatekeys'")
        '';
        passAsFile = ["templateContent" "policyCheck"];
      } ''
        fail() { echo "scufris-secret-wiring: $1" >&2; exit 1; }

        # 1. The two evaluations agree on the rendered env file.
        [ "$homeEnvironmentFile" = "$templatePath" ] || fail \
          "home/alex reads '$homeEnvironmentFile' but hosts/nixos renders '$templatePath'"

        # 2. The helper reads the RAW per-key secret, never the env file. Its
        #    --secret-file is read whole and stripped as the secret itself, so
        #    handing it a KEY=value blob would make every frame fail auth.
        case "$hostdExecStart" in
          *"--secret-file $hostdSecretPath"*) ;;
          *) fail "scufris-hostd --secret-file is not '$hostdSecretPath': $hostdExecStart" ;;
        esac
        [ "$hostdSecretPath" != "$templatePath" ] || fail \
          "the helper's secret file and the app's env file are the same path"

        # 3. Every line of the rendered env file is exactly one NAME=value, and
        #    no line repeats its own name. A template that wraps an
        #    already-prefixed value yields 'NAME=NAME=<value>', which is a real
        #    bug this repo has shipped before (LESSONS.md
        #    sops-dotenv-decrypts-whole-file).
        while IFS= read -r line; do
          [ -n "$line" ] || continue
          echo "$line" | grep -qE '^[A-Z][A-Z0-9_]*=' || fail "not a KEY=value line: $line"
          if echo "$line" | grep -qE '^([A-Z][A-Z0-9_]*)=\1='; then
            fail "doubled variable name: $line"
          fi
        done < "$templateContentPath"

        # 4. The template covers the secret file exactly: every encrypted
        #    variable is rendered, and nothing is rendered that is not in the
        #    file. `sops:` is the metadata block and is not a variable.
        grep -oP '^[A-Z][A-Z0-9_]*(?=:)' "$sopsFile" | sort > declared
        grep -oP '^[A-Z][A-Z0-9_]*(?==)' "$templateContentPath" | sort > rendered
        [ -s declared ] || fail "no variables found in $sopsFile - the check would pass vacuously"
        if ! diff -u declared rendered > delta; then
          cat delta >&2
          fail "the rendered env file and $sopsFile do not hold the same variables"
        fi

        # 5. alex can actually REACH the socket. scufris-hostd creates its
        #    runtime dir root:<group> 0750, so without membership the app cannot
        #    traverse to the socket at all - and unlike a wrong path, that fails
        #    silently: both configurations still evaluate, and the failure only
        #    shows up as host actions never working on the real machine.
        case " $userGroups " in
          *" $socketGroup "*) ;;
          *) fail "alex is not in '$socketGroup' (groups: $userGroups) and cannot reach the hostd socket" ;;
        esac
        case " $declaredGroups " in
          *" $socketGroup "*) ;;
          *) fail "group '$socketGroup' is used but never declared in users.groups" ;;
        esac

        # 6. The ciphertext is encrypted to exactly the recipients the policy
        #    assigns to THIS file - no more, no fewer. A secret that lost the
        #    HOST recipient still decrypts fine by hand and then fails at boot on
        #    the machine that needs it, which is the most expensive place to
        #    diagnose it; one that gained an unexpected recipient is readable by
        #    a machine the policy never granted.
        python3 "$policyCheckPath" "$sopsPolicy" "$sopsRelPath" "$sopsFile" || exit 1

        touch $out
      '';
  };
}
