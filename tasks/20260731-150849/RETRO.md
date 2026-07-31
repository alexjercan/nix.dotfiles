# Retro: State YAGNI and KISS in the global rules, plan scope gate, and review dimensions

- TASK: 20260731-150849
- BRANCH: feature/yagni-kiss-rules
- REVIEW ROUNDS: 2

## What went well

Sabotage at plan time carried the whole task. Every proof was run red on
master and then individually falsified in a scratch copy of
`home/modules/agents` before a branch existed, so the work phase had no
diagnosis in it: each proof's failure mode was already known, and the
implementation was three edits against known-good anchors.

Locating the rule before writing it. Planning started from the contradiction
in the global file ("More code ... valid costs") rather than from the
request's wording, which is why the change landed as one principle stated
once plus two operational forms, instead of a slogan repeated in every skill
the gate would then flag as a duplicated paragraph.

The out-of-context reviewer earned its round again, and the in-session pass
earned its re-derivation: the reviewer surfaced the lifecycle-marker
divergence, and re-deriving it (diffing the main checkout's working tree, not
just the branch record) is what showed the finding was worth MAJOR rather than
the MINOR it was filed as. The reviewer accepted the escalation and named its
own blind spot.

## What went wrong

The lifecycle transitions ran in the wrong checkout. After `sprout new`, three
`tatr flow` calls were made from `/home/alex/personal/nix.dotfiles` instead of
the worktree, so master accumulated an uncommitted `FLOW STEP: REVIEWING`
while the branch record still said `PLANNED` under a finished close-out.

Why it seemed sound at the time: `tatr` was invoked exactly as the flow route
table spells it (`tatr flow <id> --to WORKING`), from the shell that had just
run `sprout new`. The command was right; only its working directory was wrong,
and nothing in the invocation shows which `tasks/` tree it edits. The work
skill's standing rule names "every edit/git call" - `tatr` is neither word, so
the rule read as satisfied.

The R1.2 rewrap left an orphan 8-char line (`decision`) mid-paragraph. The
edit fixed the one over-long line it was asked about and did not reflow the
paragraph around it - the exact half of `line-breaks-are-load-bearing` that
had already been recorded twice.

## What to improve next time

Run `tatr` with `-r <worktree>` for the whole life of a task once a worktree
exists, the same way `git -C` is already used. The habit is cheaper than the
rule: `-r` is explicit at the call site, so a reader can see which tree is
being written.

After any prose edit that changes a line's length, reflow the paragraph and
re-check it, not just the line named in the finding. A column check over the
skill markdown would catch this without a reviewer.

## Action items

- Ledger: bumped `edit-the-worktree-not-the-cwd` to x4 - the promoted
  work-skill prose says "edit/git" and does not cover `tatr` record commands.
- Ledger: bumped `line-breaks-are-load-bearing` to x3 and moved it to Pending
  promotions with a tool proposal (an 80-column check in
  `home/modules/agents/skills/check.sh`). `lessons` owns the user gate.
- Follow-up task 20260731-152453 covers the work-skill prose gap.
- R2.1 (NIT, open at APPROVE) was applied here as a recorded cleanup: the
  Design paragraph in `review/dimensions.md` is reflowed, no line over 80.
