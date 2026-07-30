# Review: Share one sops secret between the scufris user service and the root scufris-hostd unit

- TASK: 20260730-190929
- BRANCH: fix/scufris-sops-single-source

## Round 1

- VERDICT: APPROVE
- REVIEWER: out-of-context

- [ ] R1.1 (MINOR) hosts/nixos/default.nix:15 - The comment claims "sops-nix
  validates each name against the encrypted file at eval time, so a typo fails
  the build rather than silently rendering an empty value". That is false.
  `sops.validateSopsFiles` only does `builtins.hashFile` on the sops file
  (sops-nix `modules/sops/default.nix:52`); it never inspects keys. Adding
  `"SCUFRIS_TYPO_VAR"` to `scufrisEnvVars` and evaluating the toplevel
  succeeds. What actually catches it is `flake/checks.nix` and, failing that,
  `sops-install-secrets` at activation. Suggested change: reword to say the
  typo is caught by flake/checks.nix (and by sops-install-secrets at
  activation), not by the NixOS evaluation, which accepts any name.
  - Response: fixed in the round-1 follow-up commit "fix(checks): assert the group seam and recipient coverage". Confirmed the claim independently before
    adopting it: adding a bogus name to `scufrisEnvVars` evaluates the toplevel
    cleanly. Comment reworded to name flake/checks.nix as what actually catches
    it.
- [ ] R1.2 (MINOR) flake/checks.nix:25 - The check welds the secret seam but
  not the group seam, which the same branch introduces and which fails
  SILENTLY at runtime rather than loudly. Dropping `"scufris"` from
  `users.users.alex.extraGroups`, or changing `services.scufris-hostd.group`,
  leaves every assertion green: both configs evaluate, the paths still agree,
  and the app simply cannot traverse the 0750 `/run/scufris-hostd` to reach the
  socket - the exact failure the branch added the group to prevent. Suggested
  change: assert that `services.scufris-hostd.group` is an element of
  `users.users.alex.extraGroups` (both are in the same evaluation the check
  already reads).
  - Response: fixed in the round-1 follow-up commit "fix(checks): assert the group seam and recipient coverage". Added assertion 5, in two parts: alex is in the
    socket group, AND the group is declared in `users.groups`. Both sabotages
    (dropping the group from extraGroups; deleting the group declaration) now
    fail with the specific message.
- [ ] R1.3 (NIT) flake/checks.nix:25 - D2 hangs on `secrets/scufris.yaml`
  carrying the host age recipient, and nothing in the repo asserts it; a future
  `sops updatekeys` run from a stale `.sops.yaml`, or a new secret file created
  before the anchor is added, drops it. It fails loudly at activation rather
  than silently, so this is optional, but the recipient list is cleartext in
  the ciphertext and a grep would move the failure to `nix flake check`.
  - Response: fixed in the round-1 follow-up commit "fix(checks): assert the group seam and recipient coverage". Added assertion 6: every age recipient named in
    .sops.yaml must appear in the ciphertext. Sabotage (pointing the anchor at
    a recipient the file lacks) fails with a re-run-updatekeys message. Taken
    despite being a NIT because the failure it prevents lands at BOOT on the
    machine that needs it.

### Verification notes (round 1, out-of-context reviewer)

DoD `cmd:` proofs executed by the reviewer: both `nix eval` proofs evaluate;
`nix flake check` exits 0; `sprout-test.sh` passes 14/14;
`nix build .#checks.x86_64-linux.scufris-secret-wiring` builds and reproduces
under `--rebuild`; the absence-proving grep exits 0. `tatr check` fails with
`closed-missing-review`/`closed-missing-retro`, the normal transient state of a
CLOSED-but-under-review task; not treated as a defect.

Falsifiability: the reviewer independently reproduced all three sabotages
TASK.md records, against a throwaway copy, and each produced the specific
intended failure; and confirmed that a bare `nix flake check` (unlike
`--no-build`) actually fails on a sabotaged path. Breakages constructed that
the check does NOT catch: flipping the template `owner` from `alex` to `root`,
widening secret `mode` to `0444`, and the group drift of R1.2. The first two
fail loudly at service start; only the third is silent, which is why only it
became a finding.

Correctness: `sops.age.sshKeyPaths` evaluates to
`["/etc/ssh/ssh_host_ed25519_key"]` and `useSystemdActivation` is false, so
decryption happens in the `setupSecrets` activation script in stage-2, before
systemd starts units - `/run/secrets/SCUFRIS_HOSTD_SECRET` therefore exists
before `scufris-hostd.service`, and the boot-order failure the task set out to
fix is genuinely fixed. Per-key secrets are root-owned 0400; the rendered
template is alex-owned 0400. The template `content` in the store holds only
`<SOPS:...:PLACEHOLDER>` tokens, so no plaintext reaches the nix store, and
neither does the check derivation (it reads only the ciphertext's cleartext key
names). The reviewer decrypted the secret (values never printed) and confirmed
it holds exactly the four expected keys, none containing a newline, quote,
backslash or surrounding whitespace; the scrypt hash's `$` is not expanded by
systemd in an `EnvironmentFile`, so the dotenv-to-template move is not a
parsing regression.

Pending `manual:` items, unresolved by this round and left for the user:
(1) `sudo sops decrypt` with the host key - the reviewer verified the host
recipient is present and matches this machine's `ssh-to-age` output, but did
not decrypt as root; (2) `nixos-rebuild switch` bringing `scufris-hostd.service`
active with the socket `root:scufris` 0660 and the env file alex 0400;
(3) after `home-manager switch`, a host-action proposal round-tripping. The
reviewer flags for (3) that alex's new `scufris` group membership does not
apply to already-open login sessions, so a re-login or reboot may be needed
before the socket is reachable.

## Round 2

- VERDICT: APPROVE
- REVIEWER: out-of-context

- [ ] R2.1 (MINOR) flake/checks.nix:105 - Assertion 6 derives the "policy" by
  grepping every `age1...` token in the whole `.sops.yaml`, then demands
  `secrets/scufris.yaml` be encrypted to each one. That is broader than the
  policy actually is: in sops, the `keys:` anchor list is a shared pool and
  `creation_rules` decide which recipients each file gets. Two legitimate future
  configurations therefore fail the check for no defect: (a) an anchor under
  `keys:` deliberately NOT listed in this creation rule - a second machine that
  should not hold the scufris credential; (b) a key mentioned only in a comment,
  which collides with the repo's own "Revoking a machine" runbook. Suggested
  change: scope the recipient set to the `age:` group of the creation rule that
  matches this file.
  - Response: fixed in the round-2 follow-up commit "fix(checks): resolve sops
    creation_rules instead of grepping recipients". Replaced the grep with a
    pyyaml pass that resolves anchors/aliases and picks the FIRST creation_rule
    whose path_regex matches this file's flake-relative path (derived from the
    sopsFile by stripping the store prefix, so it cannot drift), then compares
    that rule's age group against the ciphertext's `sops.age[].recipient` set in
    BOTH directions. Verified by exit code, not by grepping build output: both
    of the reported false positives now pass, while dropping the host recipient
    from the rule fails as "encrypted to [...] which .sops.yaml does not grant",
    pointing the anchor at an absent recipient fails as "is NOT encrypted to
    [...]", and narrowing path_regex so nothing matches fails as "no
    creation_rule ... matches". Checking `extra` as well as `missing` was not
    requested but falls out of comparing sets, and catches a file readable by a
    machine the policy never granted.

### Verification notes (round 2, out-of-context reviewer)

R1.1 confirmed resolved - the reviewer re-checked both halves independently and
also confirmed `sops-install-secrets` does error on a missing key
(`main.go:307,320`).

R1.2 confirmed resolved AND load-bearing: the reviewer first proved that
evaluating `system.build.toplevel.drvPath` does force `config.assertions` (by
injecting a false assertion and watching it throw), then showed that BOTH
dropping `scufris` from `extraGroups` and deleting `users.groups.scufris`
evaluate cleanly - so neither half of assertion 5 is redundant with the NixOS
evaluation. Narrowing noted but not raised as a finding: assertion 5 reads only
`extraGroups`, so making `scufris` alex's PRIMARY group would false-fail.

R1.3 confirmed resolved for the case it was raised about, including that
`[ -s policy ]` prevented a vacuous pass and that `fail` inside the `while read`
loop does terminate the build (the loop reads a file, not a pipe). The
over-broad extraction became R2.1.

Check suite re-run at 92392f9: `nix flake check` exits 0 and reported "running 1
flake checks"; `--rebuild` reproduces; both `nix eval` proofs evaluate;
`sprout-test.sh` 14/14; the absence grep exits 0. `tatr check` now reports only
`closed-missing-retro`, cleared when /compound writes RETRO.md. The three
`manual:` items remain pending for the user, with the re-login caveat for alex's
new group membership.

## Round 3

- VERDICT: APPROVE
- REVIEWER: out-of-context

- [ ] R3.1 (MINOR) flake/checks.nix:78 - The resolver handles this repo's
  `.sops.yaml` shape correctly but mis-parses two other shapes sops itself
  accepts, failing loudly with a misdirecting message in both. (a) `expected`:
  the fallback `rule.get("age", [])` assumes a list, but sops declares
  rule-level `age` as `interface{} // string or []string`
  (`config/config.go:182`) and its documented form is a COMMA-SEPARATED STRING;
  converted to that form the check failed with
  `is NOT encrypted to [',', '0', '1', ... 'z']` - it iterated the string
  character by character. (b) `actual`: `cipher["sops"]["age"]` only exists
  when the policy has a single key group; with more than one, sops serialises
  `sops.key_groups` instead and `age` is `omitempty` (`stores/stores.go:39,45`),
  so `actual` would be empty and every recipient reported missing. Suggested
  change: coerce a str `age` with `.split(",")` and strip, and fall back to
  `sops.key_groups[].age[]` when `sops.age` is absent.
  - Response: fixed in the round-3 follow-up commit "fix(checks): handle both
    sops age shapes on each side of the recipient comparison". Added a
    `recipients()` coercion for the str-or-list `age`, and an `entries` fallback
    reading `sops.key_groups[].age[]` when `sops.age` is absent. Verified (a)
    end to end against a real build, by exit code: the comma-separated form with
    both recipients passes, and the same form MISSING the host key now fails
    with the correct "does not grant it" message instead of a per-character
    diff. Verified (b) as a unit test, since it needs a multi-group ciphertext
    this repo has no way to produce: extracted the script from the derivation
    with `nix derivation show` and ran it against synthetic multi-group
    ciphertexts - complete passes, one-recipient-missing fails with
    "is NOT encrypted to ['age1bbb']" - proving the fallback is live code rather
    than an untested branch. The single-group shape still passes unchanged.

### Verification notes (round 3, out-of-context reviewer)

Both R2.1 false positives confirmed resolved by EXIT CODE captured before any
pipeline (a pooled anchor not granted to this file, and a key named only in a
comment, both build EXIT=0), while all three real breakages still fail EXIT=1
with their specific messages - the fix did not cost the assertion its teeth.

On faithfulness to sops: first-match-wins is correct (`config/config.go:589-599`
breaks on the first match) and an empty `path_regex` matching everything is
reproduced by `re.search("")`, both verified end to end - a rule with
`path_regex` deleted builds EXIT=0, and prepending a narrower rule granting only
`*alex_nixos` correctly fails rather than being masked by the broader rule
below. Go's `regexp.MatchString` and Python's `re.search` are both unanchored,
so the matching semantics agree. Mixed policies naming `pgp` or `kms` alongside
`age` do not false-fail, since both sides are restricted to the age dimension.
On the `extra` direction: no legitimate configuration in this repo's documented
workflow trips it - `sops updatekeys` derives recipients from the same rule - the
one case that would is an ad-hoc `sops --add-age` never recorded in
`.sops.yaml`, which secrets/README.md already directs against, so flagging it is
intended.

On the python3+pyyaml dependency: judged proportionate. R2.1's point was that
anchors, aliases and per-rule scoping cannot be resolved by grep, so a real YAML
parser is the minimum honest implementation; the environment is already realised
in this machine's store and pulled in by the rest of the flake, so the marginal
cost is effectively zero. Passing the script via `passAsFile` rather than
interpolating it into the shell is the right call.

Suite at HEAD: `nix flake check` EXIT=0, `nix build --rebuild` of the check
EXIT=0 (so it really runs and really passes, not merely cached), both `nix eval`
proofs EXIT=0, `sprout-test.sh` EXIT=0. `tatr check` reports only
`closed-missing-retro`, the expected transient until /compound writes RETRO.md.
The three `manual:` items remain pending for the user.
