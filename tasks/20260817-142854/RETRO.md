# Retro: Deploy calculated food entry through Home Manager

- TASK: 20260817-142854
- BRANCH: master
- REVIEW ROUNDS: 1

## What went well

- Input following gave Today and the user profile one macros package and one
  database contract.
- An explicit `MACROS_DATABASE` makes the service independent of Neovim's
  default-path implementation while retaining the existing data.
- The running dashboard restored all five Today instances against the new
  package without state migration.

## What went wrong

- Local path inputs required lock refreshes after each owner-repository commit.
  This is expected development wiring but creates avoidable rebuild churn.

## What to improve next time

- Finish owner-repository commits before refreshing downstream local locks.
- Replace both local paths with release tags in one downstream update.

## Action items

- Release macros.nvim and Today, then replace both development path inputs with
  GitHub tags.
