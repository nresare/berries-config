#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.12"
# dependencies = [
#   "requests>=2.32.0",
# ]
# ///

from __future__ import annotations

import os
import re
import subprocess
import sys

import requests


AUDIENCE = "idcat.noa.re"
OWNER = "nresare"
REPO = "berries-config"
IDCAT_BASE_URL = "https://idcat.noa.re/proxy"
GITHUB_API_VERSION = "2026-03-10"
MAX_COMMENT_BYTES = 60_000


def main() -> int:
    pr_number = os.environ.get("BUILDKITE_PULL_REQUEST")
    if not pr_number or pr_number == "false":
        print("Skipping manifest diff comment because this build was not triggered by a pull request.")
        return 0

    diff_result = subprocess.run(
        ["manifest-builder", "--diff"],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )

    token = request_idcat_token()
    body = build_comment_body(pr_number, diff_result.returncode, diff_result.stdout)
    post_issue_comment(token, pr_number, body)

    return diff_result.returncode


def request_idcat_token() -> str:
    return subprocess.check_output(
        ["buildkite-agent", "oidc", "request-token", "--audience", AUDIENCE],
        text=True,
    ).strip()


def build_comment_body(pr_number: str, returncode: int, output: str) -> str:
    build_url = os.environ.get("BUILDKITE_BUILD_URL")
    commit = os.environ.get("BUILDKITE_COMMIT")

    lines = [
        "### `manifest-builder --diff`",
        "",
        f"Pull request: #{pr_number}",
    ]

    if build_url:
        lines.append(f"Build: {build_url}")
    if commit:
        lines.append(f"Commit: `{commit}`")
    if returncode:
        lines.append(f"Exit code: `{returncode}`")

    diff_output = output.strip() or "No diff output produced."
    fence = markdown_fence(diff_output)
    lines.extend(["", f"{fence}diff", diff_output, fence])

    return truncate_comment("\n".join(lines))


def markdown_fence(text: str) -> str:
    longest_backtick_run = max((len(match.group(0)) for match in re.finditer(r"`+", text)), default=0)
    return "`" * max(3, longest_backtick_run + 1)


def truncate_comment(body: str) -> str:
    encoded = body.encode()
    if len(encoded) <= MAX_COMMENT_BYTES:
        return body

    suffix = "\n\n_Output truncated to fit within the GitHub comment size limit._"
    allowed_bytes = MAX_COMMENT_BYTES - len(suffix.encode())
    truncated = encoded[:allowed_bytes].decode(errors="ignore").rstrip()
    return f"{truncated}{suffix}"


def post_issue_comment(token: str, pr_number: str, body: str) -> None:
    url = f"{IDCAT_BASE_URL}/nresare-buildsystem/repos/{OWNER}/{REPO}/issues/{pr_number}/comments"
    response = requests.post(
        url,
        headers={
            "Authorization": f"Bearer {token}",
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": GITHUB_API_VERSION,
        },
        json={"body": body},
        timeout=30,
    )

    if not response.ok:
        print(response.text, file=sys.stderr)
    response.raise_for_status()


if __name__ == "__main__":
    raise SystemExit(main())
