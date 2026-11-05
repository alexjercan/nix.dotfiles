# Neovim bridge

Pi runs in tmux window 2 of the same session as Neovim. Its pane advertises a
private Unix socket through `@pi_nvim_socket`. The chat `/btw` command does not
need tmux or Neovim.

## Comments

- `<leader>n` queues a comment on the current line or visual line range.
- `<leader>q` opens the editable project queue.
- Inside the queue, `<leader>n` submits the batch and `q` closes the window.

Drafts persist under Neovim's state directory in `pi-queues/`. The project key
is the Git root of the current working directory, or the working directory
outside Git. A submitted draft clears only after Pi accepts it. An edited
submitted draft is kept. Acceptance does not mean the work succeeded.

## BTW questions

In Pi chat, use `/btw <question>`. The command returns immediately while the
side session answers in the background. The question and answer appear in an
expandable BTW card in the transcript, outside model context. A footer status
shows how many chat questions are running. No Neovim popup opens for chat
questions.

`<leader>b` opens a side-question prompt for the current line or visual range.
The answer opens in a scrollable, read-only Neovim popup. Use `q` or Escape to
close it.

Both comment and question keys work in local netrw thin listings. Visual ranges
target all files and folders on the selected rows. Other listing styles and
remote netrw paths are not supported.

BTW uses the selected Pi model in a separate in-memory SDK session. It gets a
text snapshot of the active conversation, including compaction and context
edits. An in-progress response may not yet be present. Its only tools are
`read`, `grep`, `find`, and `ls`. It loads no extensions, skills, prompt templates,
or context files. It cannot edit files or run shell commands, and it does not
send, steer, or queue messages in the main conversation.

The question and answer are also saved as a custom Pi session entry. Pi renders
this as an expandable BTW card, but does not send it to the main model. Failed
model requests also produce a card. These cards survive session resume; they
are not a separate conversation thread. BTW makes additional model requests
and uses the normal stored provider credentials.

Each entry point permits up to three concurrent BTW questions. A request times
out after two minutes. Changing the Pi session or reloading the extension
cancels side work. Closing Neovim's connection also cancels that request. Cancelled requests do not write into a replacement Pi
session.

## Checks

From the repository root:

```fish
node --experimental-strip-types --test home/modules/agents/pi/extensions/nvim-bridge/*_test.ts
nix build .#homeConfigurations.alex.activationPackage --no-link
```
