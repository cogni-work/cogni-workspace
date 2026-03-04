---
name: Workspace Status
description: >-
  This skill should be used when the user asks to "check workspace",
  "workspace status", "workspace health", "is my workspace ok",
  "diagnose workspace", "verify workspace", or mentions checking
  the state of their cogni-works workplace.
  Provides health checks across environment, plugins, themes, and dependencies.
version: 0.1.0
---

# Workspace Status

Check the health and status of a cogni-works workspace. Verify environment variables, plugin registration, theme availability, and dependency status.

## Locating the Workspace

Find the workspace using this priority:
1. User-provided path
2. `$PROJECT_AGENTS_OPS_ROOT` environment variable
3. Current working directory

If no workspace is found (no `.workspace-config.json`), report this and suggest `init-workspace`.

## Health Check Categories

Run all checks and present a consolidated status report.

### 1. Foundation Check

Verify core workspace files exist:

| File | Required | Purpose |
|------|----------|---------|
| `.workspace-config.json` | Yes | Workspace metadata |
| `.claude/settings.local.json` | Yes | Environment variables |
| `.workplace-env.sh` | No | Non-Claude env vars |
| `.claude/output-styles/` | No | Behavioral anchors |

Read `.workspace-config.json` for workspace metadata (version, language, plugins, last updated).

### 2. Environment Check

Verify environment variables are set and valid:

- `PROJECT_AGENTS_OPS_ROOT` - points to existing directory
- `COGNI_WORKSPACE_ROOT` - points to existing directory
- `COGNI_WORKSPACE_PLUGIN` - points to existing plugin directory
- For each registered plugin: `*_ROOT` and `*_PLUGIN` vars exist and point to valid paths

Report any missing or broken env vars.

### 3. Plugin Registry Check

Compare registered plugins (from `.workspace-config.json`) against actually installed plugins:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/discover-plugins.sh
```

Report:
- **Registered and installed**: OK
- **Registered but not installed**: Warning - plugin removed but still in config
- **Installed but not registered**: Info - new plugin available, suggest `update-workspace`

### 4. Theme Check

Scan `${COGNI_WORKSPACE_ROOT}/themes/` for available themes:

- Count total themes (excluding `_template`)
- Verify each theme.md has required sections (Color Palette, Typography)
- Check template exists

### 5. Dependency Check

Run dependency checker:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-dependencies.sh
```

Report status of required tools (jq, python3) and optional tools (curl, git, bc).

## Status Report Format

Present a concise status summary:

```
Workspace Status: {workspace-path}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Foundation:  OK | 4/4 files present
Environment: OK | 12 vars set, 0 missing
Plugins:     OK | 5 registered, 5 installed
Themes:      OK | 3 themes available
Dependencies: OK | 4/4 required, 2/3 optional

Language: EN | Last updated: 2026-03-04
```

For any category with issues, expand with details:

```
Environment: WARNING | 12 vars set, 2 missing
  Missing: COGNI_NARRATIVE_ROOT (plugin installed but not registered)
  Missing: COGNI_NARRATIVE_PLUGIN (plugin installed but not registered)
  → Run update-workspace to fix
```

## Quick vs Detailed Mode

- **Quick mode** (default): One-line-per-category summary as above
- **Detailed mode** (when user asks for details or diagnosis): Expand all categories with full file listings, env var values, and theme contents
