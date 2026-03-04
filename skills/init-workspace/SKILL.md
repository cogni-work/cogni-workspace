---
name: Init Workspace
description: >-
  This skill should be used when the user asks to "create a workspace",
  "init workspace", "initialize workspace", "set up workspace here",
  "scaffold workspace", or mentions creating a new cogni-works workplace.
  Provides workspace initialization with plugin discovery, environment
  variable generation, and shared foundation setup.
version: 0.1.0
---

# Init Workspace

Initialize a cogni-works workspace by creating the shared foundation that all marketplace plugins depend on. The workspace provides centralized environment configuration, theme storage, and plugin registration.

## Prerequisites

Before initialization, verify dependencies are available by running:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/check-dependencies.sh
```

Required: `jq`, `python3`, `bash` 3.2+. Optional: `curl`, `git`.

## Initialization Workflow

### Step 1: Determine Target Location

Ask the user where to create the workspace. Default to the current working directory. Confirm the path before proceeding.

If a `.workspace-config.json` already exists at the target, warn the user and suggest using `update-workspace` instead.

### Step 2: Discover Installed Plugins

Run the plugin discovery script to scan for installed cogni-* marketplace plugins:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/discover-plugins.sh
```

This scans `$CLAUDE_PLUGIN_ROOT` (or the marketplace cache) for plugins with `.claude-plugin/plugin.json` markers. Present the discovered plugins to the user and ask for confirmation before registering them.

### Step 3: Ask Configuration Questions

Gather workspace preferences using AskUserQuestion:

1. **Language preference**: EN or DE (affects output-styles and templates)
2. **Confirm plugin list**: Show discovered plugins, let user add/remove
3. **Tool integrations**: Which tools are in use? (Obsidian, VS Code, other) - for delegation to tool-specific plugins

### Step 4: Generate Workspace Foundation

Create the workspace structure:

```
{target}/
├── .workspace-config.json       # Workspace metadata
├── .workspace-env.sh            # Environment for non-Claude contexts
├── .claude/
│   ├── settings.local.json      # Single source of truth for env vars
│   └── output-styles/
│       ├── workspace-en.md      # EN behavioral anchors (if EN selected)
│       └── workspace-de.md      # DE behavioral anchors (if DE selected)
└── cogni-workspace/
    └── themes/                  # Shared theme storage
        └── _template/
            └── theme.md
```

Generate environment variables using the naming convention:
- Known plugins (cogni-research, cogni-narrative, etc.): `COGNI_{NAME}_ROOT`, `COGNI_{NAME}_PLUGIN`
- Other plugins: `PLUGIN_{NAME}_ROOT`, `PLUGIN_{NAME}_PLUGIN`
- Always set: `PROJECT_AGENTS_OPS_ROOT`, `COGNI_WORKSPACE_ROOT`, `COGNI_WORKSPACE_PLUGIN`

Run the settings generator:

```bash
bash ${CLAUDE_PLUGIN_ROOT}/scripts/generate-settings.sh \
  --target "${TARGET_DIR}" \
  --language "${LANGUAGE}" \
  --plugins "${PLUGIN_LIST_JSON}"
```

### Step 5: Copy Output Styles

Copy the language-appropriate output-style files from `${CLAUDE_PLUGIN_ROOT}/assets/output-styles/` to `${TARGET_DIR}/.claude/output-styles/`.

### Step 6: Copy Theme Template

Copy `${CLAUDE_PLUGIN_ROOT}/themes/_template/` to `${TARGET_DIR}/cogni-workspace/themes/_template/`.

### Step 7: Delegate Tool-Specific Setup

If the user indicated they use Obsidian and cogni-obsidian is installed, inform them they can run cogni-obsidian's setup separately. Do NOT call cogni-obsidian scripts directly - respect plugin boundaries.

Similarly for VS Code or other tool integrations.

### Step 8: Present Summary

Show what was created:
- Workspace path
- Registered plugins with their env var names
- Language setting
- Theme storage location
- Next steps (install themes, configure tools)

## Key Files

### .workspace-config.json

```json
{
  "version": "0.1.0",
  "language": "en",
  "created_at": "ISO8601",
  "updated_at": "ISO8601",
  "installed_plugins": ["cogni-research", "cogni-narrative"],
  "tool_integrations": ["obsidian", "vscode"]
}
```

### .claude/settings.local.json

Contains `env` block with all plugin environment variables. This is the single source of truth - Claude Code auto-injects these as environment variables.

### .workspace-env.sh

Mirrors settings.local.json for non-Claude contexts (Obsidian Terminal, VS Code tasks, CI/CD).

## Environment Variable Naming Convention

| Plugin | ROOT var | PLUGIN var |
|--------|----------|------------|
| cogni-research | `COGNI_RESEARCH_ROOT` | `COGNI_RESEARCH_PLUGIN` |
| cogni-narrative | `COGNI_NARRATIVE_ROOT` | `COGNI_NARRATIVE_PLUGIN` |
| cogni-workplace | `COGNI_WORKSPACE_ROOT` | `COGNI_WORKSPACE_PLUGIN` |
| cogni-obsidian | `COGNI_OBSIDIAN_ROOT` | `COGNI_OBSIDIAN_PLUGIN` |
| my-custom-plugin | `PLUGIN_MY_CUSTOM_PLUGIN_ROOT` | `PLUGIN_MY_CUSTOM_PLUGIN_PLUGIN` |

- `*_ROOT` = workspace data directory (where plugin writes output)
- `*_PLUGIN` = plugin installation path (where plugin code lives)

## Additional Resources

### Scripts

- **`${CLAUDE_PLUGIN_ROOT}/scripts/check-dependencies.sh`** - Verify required tools
- **`${CLAUDE_PLUGIN_ROOT}/scripts/discover-plugins.sh`** - Scan for installed plugins
- **`${CLAUDE_PLUGIN_ROOT}/scripts/generate-settings.sh`** - Generate settings.local.json and .workspace-env.sh
