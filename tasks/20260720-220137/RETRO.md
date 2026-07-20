# Retro: mark pre-flow tasks historical

## What went well

- Unblocked by building its dependency (tatr 20260720-220046) first, then this
  was a clean mechanical pass: tag the 10 flagging tasks `historical`, preserve
  existing tags, no fabricated retros. The reviewer's reverse audit confirmed no
  hidden gaps (no tagged task actually had a RETRO; no recent task was tagged to
  dodge a real retro).
- The tatr exemption also auto-cleared the two `goal` umbrellas from `-S`, so
  only the genuine pre-flow tasks needed tagging.

## What went wrong

- The DoD proof (`tatr check -S` clean) only holds with the freshly-built tatr
  binary; the home-manager-installed `tatr` on PATH still predates the exemption
  until the profile is rebuilt. Had to run the proof (and tell the reviewer to
  run it) via the explicit /home/alex/personal/tatr/tatr path.

## What to improve next time

- When a task's proof depends on a just-landed change to a tool that is deployed
  via home-manager, the tool is not live on PATH until a rebuild. File a
  deploy/rebuild follow-up (or note it) rather than assuming the installed CLI
  reflects the landed code.

## Action items

- [x] 10 pre-flow tasks tagged historical; `tatr check -S` clean with the new binary.
- Follow-up: a home-manager rebuild is needed for the installed `tatr` to carry
  the exemption (so plain `tatr check -S` is clean without the explicit path).
