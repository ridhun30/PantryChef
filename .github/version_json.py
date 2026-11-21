"""Writes version.json for the "latest" release: the version (versionName from pubspec.yaml, the
build number CI passes as versionCode) and what changed, as the merged pull request titles since
the previous build. The app reads it to tell that an update is out and what it brings.
Usage: version_json.py previous.json notes.md BUILD_NUMBER > version.json"""
import json
import re
import subprocess
import sys


def git(*args):
    return subprocess.run(["git", *args], capture_output=True, text=True).stdout


try:
    with open(sys.argv[1]) as f:
        prev = json.load(f)
except Exception:
    prev = {}

pubspec = open("pubspec.yaml").read()
name = re.search(r"^version:\s*([^+\s]+)", pubspec, re.M).group(1)
code = int(sys.argv[3])
head = git("rev-parse", "HEAD").strip()

prev_sha = prev.get("sha", "")
known = prev_sha and subprocess.run(["git", "cat-file", "-e", prev_sha + "^{commit}"], capture_output=True).returncode == 0
span = f"{prev_sha}..HEAD" if known else "HEAD~1..HEAD"

changes = []
for entry in git("log", "--first-parent", "--format=%s%x1f%b%x1e", span).split("\x1e"):
    entry = entry.strip("\n")
    if not entry.strip():
        continue
    subject, _, body = entry.partition("\x1f")
    title = subject.lstrip("\ufeff")
    if subject.startswith("Merge pull request") and body.strip():
        title = body.strip().splitlines()[0]   # a merge's body starts with the pull request's title
    title = re.sub(r"\s*\(v[\d.]+\)\s*$", "", title).strip()
    if title and title not in changes:
        changes.append(title)

history = prev.get("history", [])
same = next((h for h in history if h.get("versionCode") == code), None)
if same:   # the same run built again (re-run): keep what it already listed
    changes = same.get("changes", []) + [c for c in changes if c not in same.get("changes", [])]
history = [{"versionCode": code, "versionName": name, "changes": changes}] + \
          [h for h in history if h.get("versionCode") != code]

json.dump({"versionCode": code, "versionName": name, "sha": head, "changes": changes,
           "history": history[:30]}, sys.stdout, indent=1)

with open(sys.argv[2], "w") as f:
    f.write(f"Pantry Chef {name} (build {code}), built from {head[:7]}. The app offers it by itself "
            "(ⓘ › Download and install); or download PantryChef.apk on the phone and install it.\n\n")
    f.write("\n".join(f"- {c}" for c in changes) + "\n")
