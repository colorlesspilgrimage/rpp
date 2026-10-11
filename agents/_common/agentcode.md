## Agent-readable code
Agents, not humans, read this code next. Optimize code and code structure for agent reading:
- Give every file, function, and variable a name that says what it does. A search for the name must find it.
- Keep one concept in one place. Use one name for one concept. Do not use aliases.
- Make code explicit. Prefer plain, flat control flow, explicit types, and explicit imports. Avoid magic, hidden state, and clever shortcuts.
- Keep each file self-contained enough to read alone. Put the contract (inputs, outputs, errors, side effects) at the top of a module or function.
- Prefer many small, focused files over a few large ones. Keep related code together.
- Do not trade clarity for brevity or for human polish (for example, decorative formatting, long prose comments, or abbreviations).
- A comment states a fact the code cannot show: the reason, an invariant, or a constraint. Do not restate the code.
This rule changes how you write code and structure. It does not override the repo's own rules (see "Code structure").
