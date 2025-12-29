#!/usr/bin/env python3

import argparse
import os
import re
import shutil
import subprocess


def _run_capture(cmd: list[str]) -> bytes:
    return subprocess.check_output(cmd, stderr=subprocess.STDOUT)


def _get_unexpired_codesign_identity_hashes() -> set[str]:
    # Output format (example):
    #  1) ABCDEF... "Developer ID Application: ..." (CSSMERR_TP_NOT_TRUSTED)
    #  2) 123456... "Developer ID Application: ..."
    out = _run_capture(["security", "find-identity", "-p", "codesigning", "-v"])
    hashes = re.findall(rb"^\s*\d+\)\s*([0-9A-F]{40})\s+\"", out, flags=re.MULTILINE)
    return {h.decode("utf-8").lower() for h in hashes}


def _get_identity_hash(identity_name: str) -> str:
    # Match the Chromium signing code behavior:
    # - Get the set of valid identities from `security find-identity`.
    # - Get the SHA-1 hashes for certificates matching the name.
    # - Pick the first hash that is also in the valid identity list.
    unexpired = _get_unexpired_codesign_identity_hashes()

    out = _run_capture([
        "security",
        "find-certificate",
        "-a",
        "-c",
        identity_name,
        "-Z",
    ])

    cert_hashes = re.findall(
        rb"^SHA-1 hash: ([0-9A-Fa-f]{40})$", out, flags=re.MULTILINE
    )
    if not cert_hashes:
        raise RuntimeError(
            "No certificate hashes found for identity name. Output:\n" + out.decode("utf-8", "replace")
        )

    for h in cert_hashes:
        hs = h.decode("utf-8").lower()
        if hs in unexpired:
            return hs

    raise RuntimeError(
        "No matching unexpired identity hash found. "
        "Certificate hashes: {}\nUnexpired identity hashes: {}\n".format(
            [h.decode("utf-8").lower() for h in cert_hashes], sorted(unexpired)
        )
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--src", required=True)
    parser.add_argument("--dst-dir", required=True)
    parser.add_argument("--basename", required=True)
    parser.add_argument("--identity", required=True)
    parser.add_argument("--stamp", required=True)
    args = parser.parse_args()

    identity_hash = _get_identity_hash(args.identity)

    os.makedirs(args.dst_dir, exist_ok=True)

    dst = os.path.join(args.dst_dir, f"{args.basename}.{identity_hash}.provisionprofile")
    shutil.copyfile(args.src, dst)

    os.makedirs(os.path.dirname(args.stamp) or ".", exist_ok=True)
    with open(args.stamp, "w", encoding="utf-8") as f:
        f.write(dst + "\n")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
