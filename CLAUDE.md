## Git Workflow — MANDATORY IN CI
When running in GitHub Actions (CI=true) you MUST follow these rules without exception:
- After EVERY file you create or modify: immediately run `git add <file> && git commit -m "<message>"`. No exceptions.
- ONE file = ONE commit. Never batch multiple files into a single commit.
- After every 3 commits: run `git push`.
- If you are about to run out of turns: stop implementing, commit and push everything completed so far (even if incomplete), then stop.

IMPORTANT: Skipping a commit after a file change is a critical failure. The safety net at the end of the workflow will catch leftovers, but do not rely on it — always commit immediately after each file.
- When running locally: do not commit or push anything unless explicitly asked.

## GitHub Issues Workflow
- When triggered on an issue in GitHub Actions (CI=true): analyze the issue, create a branch, push IMPLEMENTATION_PLAN.md, then use mcp__github__create_pull_request to open a draft PR with the implementation plan in the description and @claude in the PR body. Do not implement anything yet.

## GitHub PR Workflow
- When triggered on a PR opened event where @claude appears in the PR body: implement the plan, committing frequently.
- When triggered on a PR comment containing @claude: follow the instructions in that comment only.

## Agent Memory
@AGENTS.md
- If the above import was not auto-loaded, explicitly read `AGENTS.md` at the start of every session. It contains project-specific conventions and feedback that must be followed.
