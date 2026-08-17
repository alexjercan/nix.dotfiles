# Retro: Run dashboardd with Today through Home Manager

- TASK: 20260817-134626
- BRANCH: master
- REVIEW ROUNDS: 1

## What went well

- The external package contract reduced integration to two package roots and
  one environment variable. No source copying or overlay was needed.
- Building the complete Home Manager activation package exercised dashboardd,
  its built-in widgets, Today's widget package, and the generated systemd unit.
- Runtime verification used the health endpoint, journal discovery count, and
  public widget catalog rather than relying only on successful evaluation.

## What went wrong

- The first direct Home Manager evaluation could not see the new module because
  the flake source excludes untracked files. Staging the intended files before
  evaluation fixed it.
- The first catalog probe used `/api/widgets` instead of the versioned
  `/api/v1/widgets` endpoint.

## What to improve next time

- Stage new flake-referenced paths before the first Nix evaluation.
- Read the router or OpenAPI document before scripting an endpoint probe.
- Replace the local Today path with a tagged source immediately after release.

## Action items

- Release the Today widget package, then replace the local path input with its
  GitHub tag.
