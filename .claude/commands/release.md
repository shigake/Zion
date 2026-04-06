---
name: release
description: Create a GitHub Release with tag, changelog. Usage: /release v4.0.0
argument-hint: "<version, e.g., v4.0.0>"
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob
---

Create a full GitHub Release for the Zion project.

## Input

The user provides a version string as argument, e.g., v4.0.0.
If no argument is provided, read game/VERSION, increment minor, and prefix with v.

## Steps

### 1. Validate and Prepare

Run git pull first.

- Parse the version from the argument (strip leading v if present for the VERSION file)
- Validate format: must match X.Y.Z (semver)
- Check that no tag with this version already exists
- If tag exists, STOP and tell the user

### 2. Update VERSION file

- Write the version (without v prefix) to game/VERSION
- Example: if user says v4.0.0, write 4.0.0 to game/VERSION

### 3. Generate Changelog

- Get the previous release tag
- If no previous tag, use recent commits (last 50)
- Otherwise get commits since previous tag
- Group commits into categories:
  - Novas features: commits with feat, add, new, implement
  - Correcoes: commits with fix, bug, corrig, resolve
  - Melhorias: commits with improve, update, polish, enhance, refactor
  - Outros: everything else
- Format as markdown sections. Skip empty categories.
- Max 30 entries if there are too many

### 4. Commit and Tag

Stage game/VERSION, commit with message "release: vX.Y.Z", create annotated tag vX.Y.Z, push with --follow-tags.

### 5. Create GitHub Release

Use gh release create with the generated changelog as notes. Set --latest flag. Title: "Zion vX.Y.Z".

### 6. Notify Discord

Post to http://localhost:3123/notify with channel zion, the release URL, and status done.

### 7. Report

Show the user: version released, link to GitHub release, number of commits, summary of changes.

## Error Handling

- If gh is not installed, tell the user to install GitHub CLI
- If not authenticated, tell the user to run gh auth login
- If tag already exists, STOP and warn
- If push fails, STOP and show error

## Rules

- ALWAYS git pull first
- NEVER force push
- Tag MUST have v prefix (v4.0.0)
- VERSION file MUST NOT have v prefix (4.0.0)
