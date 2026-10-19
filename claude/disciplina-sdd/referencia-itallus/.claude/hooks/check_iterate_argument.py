#!/usr/bin/env python3
"""Block an /iterate agent call whose argument lacks the sections AGENTS.md requires."""

import json
import sys

REQUIRED_SECTIONS = ("Mudança:", "Fato provado:", "Hipótese:")
TARGET_AGENT = "agentspec:workflow:iterate-agent"


def main() -> int:
    tool_input = json.load(sys.stdin).get("tool_input") or {}
    if tool_input.get("subagent_type") != TARGET_AGENT:
        return 0
    prompt = tool_input.get("prompt") or ""
    missing = [section for section in REQUIRED_SECTIONS if section not in prompt]
    if not missing:
        return 0
    print(
        "BLOCKED: the /iterate argument does not follow AGENTS.md (Fluxo AgentSpec).\n"
        f"Missing sections: {', '.join(missing)}\n"
        'Every mechanism claim goes under "Fato provado:" with its proof '
        "(execution or file:line); anything unproven goes under "
        '"Hipótese:" ("nenhuma" when there is none).',
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    sys.exit(main())
