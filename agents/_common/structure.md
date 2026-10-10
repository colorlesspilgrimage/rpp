## Code structure
Follow this order. The first source that speaks wins:
1. The repo's own rules: `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING`, and the lint and format config.
2. The patterns that the repo already uses.
3. The RPP default below.

RPP default:
- Layout: use the standard layout of the ecosystem. Python: `src/` and `pyproject.toml`. Node and TypeScript:
  `src/` and `tsconfig`. Go: `cmd/` and `internal/`. Rust: the cargo layout. Do not invent a layout.
- Shape: "functional core, imperative shell". Put pure logic in its own modules. Keep I/O at the edges
  (files, network, subprocesses, CLI parsing). Pass I/O in as arguments. Use one module per feature.
- Tests: the test tree mirrors the source tree.
- Size: a function has 50 lines or fewer. A file has 400 lines or fewer. Split a unit that grows past this.
- Toolchain: the repo's formatter, linter, and type checker must pass on the files you change.
