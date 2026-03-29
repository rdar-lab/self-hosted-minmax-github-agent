# self-hosted-minmax-github-agent
Combining MiniMax M2.7 (via Claude Code CLI) into a Self-Hosted GitHub Action Runner

## About this

This repository is a template for running [MiniMax M2.7](https://www.minimax.io/models/text/m27) as an autonomous coding agent triggered by GitHub issue and PR comments. It uses the Claude Code CLI pointed at MiniMax's Anthropic-compatible API endpoint, so you get the full agentic tool-use experience (file reads/writes, git operations, GitHub PR management) powered by MiniMax's model.

No GitHub Actions credits or GitHub Copilot credits are consumed. The runner runs on your own infrastructure.

## How to deploy

### Option A — Docker (recommended)

**Prerequisites:** Docker and Docker Compose installed on the host machine.

1. **Get your MiniMax API key** from the [MiniMax Developer Platform](https://platform.minimax.io/user-center/basic-information/interface-key). Save it as a GitHub secret:
   Repository **Settings → Secrets and variables → Actions → New repository secret**, name it `MINIMAX_API_KEY`.

2. **Configure the runner:**
    ```bash
    cp .env.example .env
    # Edit .env — set GITHUB_URL and RUNNER_TOKEN at minimum
    ```
    Get `RUNNER_TOKEN` from your repository: **Settings → Actions → Runners → New self-hosted runner**. Scroll to the Configure section and copy the token value from the `./config.sh --token <VALUE>` command. The token is only needed on the very first startup — after that the registration is persisted in a Docker volume.

3. **Build and start:**
    ```bash
    docker compose build
    docker compose up -d
    ```
    The runner appears under repository **Settings → Actions → Runners** once it is online.

4. Copy `.github/workflows/minmax.yml` and `CLAUDE.md` from this repository into your target repository, then commit and push.

5. Optional: add `AGENTS.md` with project-specific conventions for the agent.

> **Note on `RUNNER_VERSION`:** The Dockerfile pins a specific runner version via the `RUNNER_VERSION` build arg (default `2.333.0`). If the build fails to download the runner binary, check the [latest release](https://github.com/actions/runner/releases) and override: `docker compose build --build-arg RUNNER_VERSION=X.Y.Z`.

---

### Option B — Bare metal

1. Deploy and connect a GitHub self-hosted runner to your repository. Go to **Settings → Actions → Runners → New self-hosted runner** and follow the instructions.

2. Install Node.js and the Claude Code CLI on the runner machine:
    ```bash
    curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
    sudo apt-get install -y nodejs
    sudo npm install -g @anthropic-ai/claude-code
    ```

3. Add your MiniMax API key as a GitHub secret (`MINIMAX_API_KEY`) as described in step 1 of Option A.

4. Copy `.github/workflows/minmax.yml` and `CLAUDE.md` into your target repository and commit and push.

5. Optional: Add `AGENTS.md` with project-specific information for the agent.

6. Working on any issue requires 2 steps:
    - Comment on the issue with `@minmax` in the body. This triggers the workflow and creates a draft PR with an implementation plan (`IMPLEMENTATION_PLAN.md`). Example: `"@minmax please create an implementation plan for this issue and create a branch for it."`
    - Open the draft PR and add an `@minmax` comment or ensure `@minmax` is in the PR body. This triggers the implementation. Example: `"@minmax please implement the plan in IMPLEMENTATION_PLAN.md and commit frequently."`
    - Once implementation is done, review the code. Leave inline comments on any lines you want addressed, then submit the review with a comment containing `@minmax please see comments`.

## How it works

The workflow configures the Claude Code CLI to use MiniMax's Anthropic-compatible API endpoint:

| Setting | Value |
|---|---|
| API endpoint | `https://api.minimax.io/anthropic` |
| Model | `MiniMax-M2.7` |
| Auth | `MINIMAX_API_KEY` secret |

On each trigger, the workflow:
1. Builds a prompt from the GitHub event context (issue/PR/comment content)
2. Writes `~/.claude/settings.json` with the MiniMax endpoint and API key
3. Runs `claude -p "<prompt>"` in non-interactive mode with restricted tools

## What the agent can and cannot do

The workflow restricts the agent to a specific set of tools for safety:

- **Allowed:** reading, writing, and editing files (`Read`, `Write`, `Edit`, `Glob`, `Grep`, `LS`)
- **Allowed:** git commands (`git *`) and `find`
- **Allowed:** creating and reading GitHub pull requests via the GitHub MCP tool
- **Not allowed:** arbitrary shell commands, running tests, installing packages, or any other system operations

If your project requires the agent to run tests or build commands, extend the `--allowedTools` list in `minmax.yml`.

## Timeout

Each workflow run has a **120-minute hard timeout** and a **200-turn limit**. For very large or complex tasks the agent may not finish in a single run. `CLAUDE.md` instructs it to commit and push whatever it has completed before hitting the limit, and the workflow has a safety-net step that commits and pushes any remaining uncommitted changes after every run regardless of how it ended.

## What CLAUDE.md does

The `CLAUDE.md` file is automatically read by the Claude Code CLI at the start of every session. It governs two key behaviors:

- **Git discipline:** In CI, the agent commits after every individual file change and pushes every 3 commits, ensuring progress is saved continuously.
- **Phase separation:** When triggered from an issue comment, the agent only creates a plan and opens a draft PR — it does not implement anything yet. Implementation only begins when triggered from the PR opened event (when `@minmax` is in the PR body).
