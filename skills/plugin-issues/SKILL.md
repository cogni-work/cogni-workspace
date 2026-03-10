---
name: plugin-issues
description: |
  File and track issues (bugs, feature requests, change requests, questions) against cogni-works
  and cogni-works-pro plugins. Resolves the target plugin's GitHub repository automatically,
  drafts issues from templates, creates them via `gh` CLI, and tracks them locally.
  Use this skill when the user wants to report a bug, request a feature, file a change request,
  ask a question about a plugin, list their filed issues, or check issue status.
---

# Plugin Issues Orchestrator

You manage the lifecycle of GitHub issues for cogni-works ecosystem plugins: resolving which repository a plugin belongs to, drafting issues from templates, creating them via `gh` CLI, and tracking them locally.

## Choosing the right mode

Determine the operating mode from the user's intent:

| Mode | What triggers it | What it does |
|------|-----------------|--------------|
| `create` | "file issue", "report bug", "request feature", "change request on {plugin}", "question about {plugin}" | Resolve plugin, draft from template, user reviews, create on GitHub, log locally |
| `list` | "my issues", "show issues", "list issues" | Read local `issues.json`, display grouped by plugin |
| `status` | "check issue", "issue status", "update on issue" | Fetch current state from GitHub, update local record |
| `browse` | "open issue", "show issue in browser" | Open issue in browser via `gh issue view --web` |

When in doubt, `list` is a safe default.

## Prerequisites check

Before any operation that requires `gh`, verify authentication:

```bash
gh auth status 2>&1
```

If this fails, guide the user:
1. Install: `brew install gh`
2. Authenticate: `gh auth login`
3. Ensure the account has access to the target repository

Fail fast — do not attempt issue creation without valid auth.

## Workspace setup

Before any operation, ensure the local state directory exists. Run the init script (idempotent):

```bash
bash "${COGNI_WORKSPACE_PLUGIN}/skills/plugin-issues/scripts/issue-store.sh" init "${working_dir}"
```

The `working_dir` defaults to the current working directory. All issue state lives in `{working_dir}/cogni-issues/`.

## Create mode

### Step 1: Resolve plugin

Run the resolver to find the plugin's repository:

```bash
bash "${COGNI_WORKSPACE_PLUGIN}/skills/plugin-issues/scripts/resolve-plugin.sh" "{plugin_name}"
```

- If the result has `"ambiguous": true`, present the matches and ask the user which marketplace they mean
- If the result has `"error"`, tell the user the plugin wasn't found and list available plugins
- Extract `owner_repo` for the `gh` command

### Step 2: Determine issue type

From the user's description, determine the type:

| Type | Indicators |
|------|-----------|
| `bug` | "bug", "broken", "error", "crash", "doesn't work", "fails" |
| `feature` | "feature", "add", "new capability", "would be nice", "request" |
| `change-request` | "change", "modify", "update behavior", "different", "adjust" |
| `question` | "question", "how to", "why does", "wondering", "confused" |

If unclear, ask the user.

### Step 3: Draft issue from template

Read the template from `references/issue-templates.md` for the determined type. Auto-fill:
- `{plugin_name}` — from resolver result
- `{version}` — from resolver result
- `{marketplace}` — from resolver result
- `{os}` — detect via `uname -s` (Darwin/Linux)

Fill remaining fields from the user's description. Present the draft to the user for review.

### Step 4: User review

Show the complete issue draft (title and body) and ask the user to confirm or edit. Do not create the issue without explicit approval.

### Step 5: Create on GitHub

```bash
gh issue create --repo "{owner_repo}" --title "{title}" --body "{body}" --label "{type}"
```

Where `{type}` maps to the GitHub label per the label mapping in `references/issue-templates.md`.

If label creation fails (label doesn't exist), retry without the `--label` flag and note this in the output.

### Step 6: Log locally

Generate an ID and add the issue to local state:

```bash
bash "${COGNI_WORKSPACE_PLUGIN}/skills/plugin-issues/scripts/issue-store.sh" gen-id
bash "${COGNI_WORKSPACE_PLUGIN}/skills/plugin-issues/scripts/issue-store.sh" add "${working_dir}" '{json}'
```

The JSON record should include: `id`, `plugin`, `marketplace`, `repository`, `github_number`, `github_url`, `type`, `title`, `status` ("open"), `created_at`, `updated_at`.

Parse `github_number` and `github_url` from the `gh issue create` output.

### Step 7: Confirm

Return the GitHub issue URL to the user.

## List mode

Read the local issue store:

```bash
bash "${COGNI_WORKSPACE_PLUGIN}/skills/plugin-issues/scripts/issue-store.sh" read "${working_dir}"
```

Display issues grouped by plugin, showing for each:
- Title and type badge
- GitHub issue number and URL
- Status
- Created date

If no issues exist, tell the user and suggest the create flow.

## Status mode

Given an issue ID or GitHub number:

1. Look up the issue in local `issues.json` to get the `owner_repo` and `github_number`
2. Fetch current status from GitHub:
   ```bash
   gh issue view {github_number} --repo "{owner_repo}" --json state,title,labels,comments,updatedAt
   ```
3. Update the local record's status via `update-status`
4. Display: current state, latest comments summary, labels, last update time

## Browse mode

Open the issue in the user's default browser:

```bash
gh issue view {github_number} --repo "{owner_repo}" --web
```

## Scripts

- **`scripts/resolve-plugin.sh`** — Resolves a plugin name to its GitHub repository by scanning marketplace.json files. Invoke: `bash "${COGNI_WORKSPACE_PLUGIN}/skills/plugin-issues/scripts/resolve-plugin.sh" <plugin-name>`
- **`scripts/issue-store.sh`** — Local JSON state management (init, gen-id, add, read, update-status). Invoke: `bash "${COGNI_WORKSPACE_PLUGIN}/skills/plugin-issues/scripts/issue-store.sh" <command> [args...]`

## References

- **`references/issue-templates.md`** — Templates for the four issue types (bug, feature, change-request, question) with auto-fill placeholders and label mapping.
