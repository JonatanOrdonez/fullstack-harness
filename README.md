# fullstack-harness

A Claude Code harness for `client/` + `server/` monorepos: Next.js/React on the client (components, hooks, contexts) and a layered Express/TypeScript API with PostgreSQL, realtime and file uploads.

It follows a plan → implement → test → review loop, enforced by agents, rules and hooks.

## Layout

| Path | Purpose |
|------|---------|
| `CLAUDE.md` | Entry point; points to `.claude/` |
| `.claude/skills/` | Slash-command workflows (`/add-feature`, `/add-server-feature`, ...) |
| `.claude/agents/` | Planner, server/client writers, test writer, reviewer |
| `.claude/rules/` | Path-scoped conventions loaded automatically |
| `.claude/settings.json` | Permissions and hooks |
| `.claude/docs/` | On-demand reference: patterns and code templates (see `.claude/docs/README.md`) |
| `.claude/scripts/` | `harness.sh` (headless flow) and the hook scripts |

## Use it

1. Copy `CLAUDE.md` and `.claude/` to the root of a project with `client/` and `server/`.
2. Make hook scripts executable: `chmod +x .claude/scripts/harness.sh .claude/scripts/hooks/*.sh`.
3. Run `/add-feature <description>` in Claude Code, or `./.claude/scripts/harness.sh "<description>"` headless.

The hooks do nothing until a workspace has a `package.json` and `node_modules`, so the harness is safe to drop into an empty project.
