# self-hosted-claude-github-agent
Combining Claude Code into Self-Hosted GitHub Action Runner

## About this

First let's address why it is needed, after all we have GitHub Cloud Action Runners, and GitHub Copilot integration to Claude.
But, they both requires GitHub credits, and a lot of them.
At some point, when I run out of them, I decided I want to run Code Agent workflows but be independent from the GitHub Actions or GitHub Copilot credits allocations.

So whats wrong with Claude CLI? Nothing, but I want to have a more seamless experience, The CLI keeps asking you for information and permissions. I want to be able to assign a task, and provide code review when it is done.

## How to deploy

The core requires the following:

1. You need to deploy and connect a GitHub self-hosted runner to your repository. This is the machine that will run the agent. To do so you will need to go to the project settings in GitHub, choose the option Actions->Runners, press "New..." and follow the instructions to deploy. Now remember, this runner runs on the machine, so I suggest to use a VM / sandboxed system for the runner.
2. The same runner machine needs to have claude installed and configured:
    - Install the claude CLI tool on the machine:
    ```bash
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
    sudo npm install -g @anthropic-ai/claude-code
    ```
    - Run `claude auth login` to connect it to your account.
    - Run `claude /install-github-app` to connect the claude app with the repository.
    - Run `claude setup-token`, grab the token that is generated, and save it as your `CLAUDE_CODE_OAUTH_TOKEN` secret in GitHub.
3. Now you will need to copy to your repository (commit and push) the workflow file (see `.github/workflows/claude.yml` in this repository) in your repository. This file will trigger the agent when it is called upon via any @claude comment in issue or PR
4. Also add to your repository the provided `CLAUDE.md` file
5. Optional: Add `AGENTS.md` with all project specific information for the agent. You can use the agent in CLI to generate the file
6. Now working on any issue requires 2 steps:
    - First, you need to comment on the issue with @claude in it. This will trigger the workflow and create a draft PR with the implementation plan. Make sure to include in the comment the sentence to create `IMPLEMENTATION_PLAN.md` and create a branch for it. The comment exact text should be something like: "@claude please create an implementation plan for this issue, and create a branch for it. The implementation plan should be in a file called IMPLEMENTATION_PLAN.md"
    - Then, you need to open the draft PR, and add @claude comment to the PR. This will trigger the workflow again and start the implementation process. The comment should be something like "@claude please implement the plan in the IMPLEMENTATION_PLAN.md file, and commit frequently"
    - Once implementation is done, you can review the code changes in the PR. Leave inline comments on any lines you want Claude to address, and when you're done submit the review with a comment containing `@claude please see comments`. This will trigger the workflow and Claude will address your review feedback.

## Triggering Claude on PR comments

Beyond the two-phase issue workflow, you can also mention `@claude` in any PR review comment or PR review submission to give Claude follow-up instructions — for example asking it to fix review feedback or explain a decision. The workflow listens to `pull_request_review_comment` and `pull_request_review` events in addition to issue comments.

## What Claude can and cannot do

The workflow restricts Claude to a specific set of tools for safety:

- **Allowed:** reading, writing, and editing files (`Read`, `Write`, `Edit`, `Glob`, `Grep`, `LS`)
- **Allowed:** git commands (`git *`) and `find`
- **Allowed:** creating GitHub pull requests via the GitHub MCP tool
- **Not allowed:** arbitrary shell commands, running tests, installing packages, or any other system operations

If your project requires Claude to run tests or build commands, you will need to extend the `--allowedTools` list in `claude.yml`.

## Timeout

Each workflow run has a **60-minute hard timeout**. For large or complex tasks Claude may not finish in a single run. The `CLAUDE.md` instructs Claude to commit and push whatever it has completed before the timeout is reached, so work is never fully lost.

## What CLAUDE.md does

The `CLAUDE.md` file is automatically read by Claude at the start of every session. It governs two key behaviors:

- **Git discipline:** In CI, Claude commits after every individual file change and pushes every 3 commits, ensuring progress is saved continuously.
- **Phase separation:** When triggered from an issue comment, Claude only creates a plan and opens a draft PR — it does not implement anything yet. Implementation only begins when triggered from the PR opened event.