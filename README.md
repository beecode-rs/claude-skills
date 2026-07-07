# claude-skills

A collection of shared [Claude Code Skills](https://docs.claude.com/en/docs/claude-code/skills) — drop-in packages that teach Claude how to handle specific workflows, from customer-discovery interviews to TypeScript monorepo architecture.

Each skill lives under `skills/<name>/` as a `SKILL.md` (with frontmatter describing when it activates) plus supporting references, templates, and scripts.

## Available skills

| Skill | What it does |
|-------|--------------|
| [mom-test-coach](skills/mom-test-coach/) | Validates product/startup ideas using **The Mom Test** — shapes the idea, finds the riskiest assumptions, crafts interview questions that surface facts (not compliments), debriefs raw notes, and reaches a proceed / pivot / kill verdict. Includes a mock-interview practice mode. |
| [writing-clean-ts](skills/writing-clean-ts/) | TypeScript code patterns for backend and frontend — services, repositories, DALs, entities, controllers, use cases, and React components following a strict layered clean-architecture convention. |
| [mono-repo-typescript](skills/mono-repo-typescript/) | TypeScript monorepo architecture with **pnpm workspaces** — package organization, shared libraries, ES module path aliases, centralized config, and Docker Compose orchestration. |

## Installation

Install a skill with `npx skills add` (no global install needed):

```bash
npx skills add beecode-rs/claude-skills@<skill-name>
```

Replace `<skill-name>` with one of:

```bash
npx skills add beecode-rs/claude-skills@mom-test-coach
npx skills add beecode-rs/claude-skills@writing-clean-ts
npx skills add beecode-rs/claude-skills@mono-repo-typescript
```

Claude auto-discovers skills on startup and activates them based on the `description` in each `SKILL.md` — you don't need to configure anything else.

## License

All skills are licensed under the MIT License. Each skill folder contains its own `LICENSE.txt` (e.g. [`skills/mom-test-coach/LICENSE.txt`](skills/mom-test-coach/LICENSE.txt)) — copy, modify, and use freely, including commercially.
