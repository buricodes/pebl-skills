# pebl skills

Agent skills taken from features of [pebl](https://github.com/buricodes/pebl), the terminal sidebar that runs several Claude Code sessions side by side. Each skill works on its own in Claude Code, Cursor, Copilot or any agent that reads `SKILL.md` folders; pebl is not needed.

| Skill | What it does |
| --- | --- |
| [checkpoint](checkpoint/SKILL.md) | Save and restore snapshots of the working tree as git refs, without committing or touching HEAD |
| [run-checks](run-checks/SKILL.md) | Detect a project's tests, linter and type checker, run them, fix what the change broke |
| [second-opinion-review](second-opinion-review/SKILL.md) | Read only review of a diff, ending in `path:line` findings |

## Install

Claude Code, for every project:

```bash
git clone https://github.com/buricodes/pebl-skills
cp -r pebl-skills/checkpoint pebl-skills/run-checks pebl-skills/second-opinion-review ~/.claude/skills/
```

Or copy a folder into `.claude/skills/` inside one repo. Other agents: put the folders wherever your agent loads skills from.

The scripts need bash and git.

## Want it automatic?

[pebl](https://github.com/buricodes/pebl) does all three without asking: a snapshot after every turn you can scrub back through, checks run each time a session stops, and `R` to start a reviewer next to any session.

MIT licensed.
