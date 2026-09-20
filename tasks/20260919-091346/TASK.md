# Investigate startup CLD and CDX status

- STATUS: CLOSED
- PRIORITY: 0
- TAGS: investigation

Investigate why i3 bar shows CLD ? and CDX ? after startup. Make no configuration changes.

## Findings

- i3status-rust runs each custom command immediately, then every 600 seconds.
- The runtime cache under `/run/user/1000/ai-usage` is empty after each boot.
- Both initial API requests therefore depend on currently valid CLI credentials.
- The Codex token expired before this boot. The endpoint currently returns HTTP 401 `token_expired`.
- Claude credentials were refreshed at 09:12:09, seven minutes after i3status started. The Claude endpoint now returns HTTP 200, and its cache was populated at 09:12:38.
- Failed initial requests have no cached value to display, so the script emits `CLD ?` or `CDX ?` until a later update succeeds.
