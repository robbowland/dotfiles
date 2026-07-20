#!/usr/bin/env python3
"""
Render a template using PALETTE_* from the environment (optionally plus .env).

- Replaces ${PALETTE_*} placeholders
- Lets an explicit env file override the ambient shell palette
- Validates #RRGGBB
"""

import argparse
import os
import pathlib
import re
import sys
from typing import Dict

HEX = re.compile(r"^#[0-9a-fA-F]{6}$")
PH = re.compile(r"\$\{([A-Z0-9_]+)\}")


def main() -> int:
    ap = argparse.ArgumentParser(description="Render template from PALETTE_* env.")
    ap.add_argument("--template", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--env-file")
    args = ap.parse_args()

    tpl = pathlib.Path(os.path.expanduser(args.template))
    out = pathlib.Path(os.path.expanduser(args.out))
    if not tpl.exists():
        print(f"ERROR: template not found: {tpl}", file=sys.stderr)
        return 1

    palette: Dict[str, str] = {
        k: v for k, v in os.environ.items() if k.startswith("PALETTE_")
    }
    if args.env_file:
        envp = pathlib.Path(os.path.expanduser(args.env_file))
        if not envp.exists():
            print(f"ERROR: env-file not found: {envp}", file=sys.stderr)
            return 1
        palette.update(load_dotenv(envp))

    text = tpl.read_text(encoding="utf-8")
    needed = {
        m.group(1) for m in PH.finditer(text) if m.group(1).startswith("PALETTE_")
    }

    miss = [k for k in needed if k not in palette]
    if miss:
        print("ERROR: missing palette keys: " + ", ".join(miss), file=sys.stderr)
        return 1
    bad = [k for k in needed if not HEX.match(palette[k])]
    if bad:
        for k in bad:
            print(f"ERROR: invalid hex for {k}: {palette[k]!r}", file=sys.stderr)
        return 1

    for k in needed:
        text = text.replace("${" + k + "}", palette[k])

    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(text, encoding="utf-8")
    print(f"Wrote {out}")
    return 0


def load_dotenv(path: pathlib.Path) -> Dict[str, str]:
    out: Dict[str, str] = {}
    for line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
        s = line.strip()
        if not s or s.startswith("#") or "=" not in s:
            continue
        k, v = s.split("=", 1)
        k, v = k.strip(), v.strip().strip("'").strip('"')
        if k.startswith("PALETTE_"):
            out[k] = v
    return out


if __name__ == "__main__":
    sys.exit(main())
