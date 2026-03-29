#!/bin/bash
set -euo pipefail

: "${GITHUB_URL:?GITHUB_URL is required (e.g. https://github.com/owner/repo)}"

RUNNER_NAME="${RUNNER_NAME:-claude-runner}"
RUNNER_LABELS="${RUNNER_LABELS:-self-hosted,claude}"

cd /home/runner/actions-runner

# ── Register once ─────────────────────────────────────────────────────────────
# .runner is written by config.sh on successful registration and persists in the
# Docker volume, so we only register on the very first startup.
if [ -f ".runner" ]; then
    echo "Runner already registered, skipping configuration."
else
    echo "First startup — registering runner '${RUNNER_NAME}'..."

    if [ -z "${RUNNER_TOKEN:-}" ]; then
        : "${GITHUB_TOKEN:?Either RUNNER_TOKEN or GITHUB_TOKEN must be provided on first startup}"

        REPO_PATH="${GITHUB_URL#https://github.com/}"
        echo "Fetching runner registration token for ${REPO_PATH}..."
        RUNNER_TOKEN=$(curl -fsSL -X POST \
            -H "Authorization: token ${GITHUB_TOKEN}" \
            -H "Accept: application/vnd.github.v3+json" \
            "https://api.github.com/repos/${REPO_PATH}/actions/runners/registration-token" \
            | jq -r '.token')

        if [ -z "$RUNNER_TOKEN" ] || [ "$RUNNER_TOKEN" = "null" ]; then
            echo "ERROR: Failed to obtain runner registration token." >&2
            echo "       Check that GITHUB_TOKEN has the 'repo' scope." >&2
            exit 1
        fi
    fi

    ./config.sh \
        --url        "$GITHUB_URL" \
        --token      "$RUNNER_TOKEN" \
        --name       "$RUNNER_NAME" \
        --labels     "$RUNNER_LABELS" \
        --unattended \
        --replace
fi

# ── Start ──────────────────────────────────────────────────────────────────────
echo "Starting GitHub Actions runner..."
./run.sh
