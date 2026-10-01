# Add Pi grilling mode with autonomous default decisions

- STATUS: CLOSED
- PRIORITY: 100
- TAGS: pi, extension

Add a session-local `/grill` toggle. Default to autonomous decisions, block `ask_user` outside grilling, and let the agent record decisions for `/decisions` review. In grilling mode, plan and allow questions. The user chose strict no-pause behavior even for high-risk decisions.

Checks: extension unit tests, TypeScript typecheck, Home Manager activation package build.

