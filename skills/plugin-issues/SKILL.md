---
name: plugin-issues
description: |
  File and track GitHub issues (bugs, feature requests, change requests, questions) against
  cogni-works ecosystem plugins. Resolves the target plugin's repository automatically,
  drafts issues from templates, creates them via `gh` CLI, and tracks them locally.
  Use this skill whenever the user wants to report a bug, request a feature, file a change
  request, ask a question about a plugin, list filed issues, or check issue status.
  Also trigger when the user says things like "this plugin is broken", "I found a problem
  with {plugin}", "can we get X added to {plugin}", "{plugin} doesn't work", "open an issue",
  "something is wrong with {plugin}", or any complaint/suggestion about a specific plugin —
  even if they don't use the word "issue".
---

# Plugin Issues

Manage the lifecycle of GitHub issues for cogni-works ecosystem plugins: resolve which
repository a plugin belongs to, draft issues from templates, create them via `gh`, and
track them locally.

## Environment

The skill scripts live at `${COGNI_WORKSPACE_PLUGIN}/skills/plugin-issues/scripts/`.
If `COGNI_WORKSPACE_PLUGIN` is not set, fall back to the workspace root's plugin path
(typically the directory containing `.claude-plugin/plugin.json`). If you still can't
find the scripts, tell the user — don't guess paths.

## Modes

Pick the mode from the user's intent:

| Mode | Triggers | Action |
|------|----------|--------|
| **create** | reporting bugs, requesting features, filing change requests, asking plugin questions | Resolve plugin, draft from template, confirm with user, create on GitHub, log locally |
| **list** | "my issues", "show issues", "what have I filed" | Read local state, display grouped by plugin |
| **status** | "check issue #N", "any updates on my issue" | Fetch from GitHub, update local record |
| **browse** | "open issue", "show in browser" | Open via `gh issue view --web` |

Default to **list** when intent is unclear.

## Prerequisites

Before any `gh` operation, verify auth:

```bash
gh auth status 2>&1
```

If this fails, guide the user to install (`brew install gh`) and authenticate (`gh auth login`).
Do not attempt issue creation without valid auth — fail fast.

## Workspace init

Run once before any operation (idempotent):

```bash
bash "${SKILL_DIR}/scripts/issue-store.sh" init "${working_dir}"
```

`working_dir` defaults to the current working directory. State lives in `{working_dir}/cogni-issues/`.

## Create mode

### 1. Resolve the plugin

```bash
bash "${SKILL_DIR}/scripts/resolve-plugin.sh" "<plugin_name>"
```

The script returns JSON. Handle these cases:
- `"ambiguous": true` — present matches, ask which marketplace
- `"error"` — plugin not found; list what's available and ask the user to clarify
- Success — extract `owner_repo`, `version`, `marketplace` for later steps

### 2. Determine the issue type

Infer the type from context:

| Type | Signals |
|------|---------|
| `bug` | "broken", "error", "crash", "doesn't work", "fails", "wrong" |
| `feature` | "add", "new", "would be nice", "request", "support for" |
| `change-request` | "change", "modify", "adjust", "different behavior" |
| `question` | "how to", "why does", "confused", "wondering" |

If it's genuinely ambiguous, ask. But most user messages make the type obvious — trust your judgment.

### 3. Draft the issue

Read the template for the determined type from `references/issue-templates.md`.

Fill in what you can from the conversation and the resolver output. For fields you
don't have enough information for, either ask the user or omit the section entirely —
a shorter issue with real content is better than one padded with "N/A" placeholders.
Detect the OS via `uname -s`.

### 4. Confirm with the user

Show the complete draft (title + body) and ask for approval. Never create without
explicit confirmation.

### 5. Create on GitHub

```bash
gh issue create --repo "<owner_repo>" --title "<title>" --body "<body>" --label "<label>"
```

Label mapping is in `references/issue-templates.md`. If the label doesn't exist on
the repo, retry without `--label` and mention this to the user.

If creation fails for other reasons (auth, permissions, network), show the error and
suggest next steps rather than retrying blindly.

### 6. Log locally

```bash
ID_JSON=$(bash "${SKILL_DIR}/scripts/issue-store.sh" gen-id)
```

Then pipe the issue record as JSON via stdin:

```bash
echo '<json_record>' | bash "${SKILL_DIR}/scripts/issue-store.sh" add "${working_dir}"
```

The record includes: `id`, `plugin`, `marketplace`, `repository`, `github_number`,
`github_url`, `type`, `title`, `status` ("open"), `created_at`, `updated_at`.

Parse `github_number` and `github_url` from `gh issue create` output.

### 7. Confirm

Return the GitHub issue URL and local issue ID.

## List mode

```bash
bash "${SKILL_DIR}/scripts/issue-store.sh" read "${working_dir}"
```

Display issues grouped by plugin: title, type badge, GitHub number + URL, status, date.
If empty, suggest the create flow.

## Status mode

1. Look up the issue in local state to get `owner_repo` and `github_number`
2. Fetch from GitHub:
   ```bash
   gh issue view <number> --repo "<owner_repo>" --json state,title,labels,comments,updatedAt
   ```
3. Update local record via `update-status`
4. Show: state, latest comments summary, labels, last update

## Browse mode

```bash
gh issue view <number> --repo "<owner_repo>" --web
```

## Scripts

- **`scripts/resolve-plugin.sh`** — Resolves a plugin name to its GitHub repo by scanning marketplace.json files
- **`scripts/issue-store.sh`** — Local JSON state management (init, gen-id, add, read, update-status). The `add` command reads JSON from stdin for safety.

## References

- **`references/issue-templates.md`** — Templates for the four issue types with auto-fill placeholders and label mapping
