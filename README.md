# self-hosted-minimax-github-agent
Combining MiniMax M2.7 (via OpenCode) into a Self-Hosted GitHub Action Runner

## About this

This repository is a template for running [MiniMax M2.7](https://www.minimax.io/models/text/m27) as an autonomous coding agent triggered by GitHub issue and PR comments. It uses OpenCode with MiniMax's Anthropic-compatible API endpoint, so you get the full agentic tool-use experience (file reads/writes, git operations, GitHub PR management) powered by MiniMax's model.

No GitHub Actions credits or GitHub Copilot credits are consumed. The runner runs on your own infrastructure.

## How to deploy

### All Options

   1.
      Install the OpenCode GitHub Opencode Application on your repository.
      https://github.com/apps/opencode-agent
   
   2. Enable "Allow GitHub Actions to create and approve pull requests" for your github repository. Go to **Settings → Actions →General → Workflow permissions** and check the box. 


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

4. Copy `.github/workflows/minimax.yml` from this repository into your target repository, then commit and push.

5. Optional: add `CLAUDE.md` with project-specific instructions for the agent.

---

### Option B — Bare metal

1. Deploy and connect a GitHub self-hosted runner to your repository. Go to **Settings → Actions → Runners → New self-hosted runner** and follow the instructions.

2. Add your MiniMax API key as a GitHub secret (`MINIMAX_API_KEY`) as described in step 1 of Option A.

3. Copy `.github/workflows/minimax.yml` into your target repository and commit and push.

4. Optional: Add `CLAUDE.md` with project-specific information for the agent.

## How it works

The workflow uses the [OpenCode GitHub Action](https://github.com/anomalyco/opencode) configured to use MiniMax's Anthropic-compatible API endpoint:

| Setting | Value |
|---|---|
| API endpoint | `https://api.minimax.io/anthropic` |
| Model | `minimax/MiniMax-M2.7` |
| Auth | `MINIMAX_API_KEY` secret |

## Usage

Trigger OpenCode by mentioning `/oc` or `/opencode` in a GitHub issue or PR comment:

- **Explain an issue:** `/opencode explain this issue`
- **Fix an issue:** `/opencode fix this` — OpenCode will create a branch and open a PR
- **Review PR code:** Leave a comment with `/oc` on specific lines in the Files tab
- **Implement PR changes:** `/oc add error handling here`

## Supported Events

- `issue_comment` — Comment on an issue or PR
- `pull_request_review_comment` — Comment on specific code lines in a PR
- `pull_request` — PR opened or updated

## Timeout

Each workflow run has a **120-minute hard timeout**. For very large or complex tasks the agent may not finish in a single run.
