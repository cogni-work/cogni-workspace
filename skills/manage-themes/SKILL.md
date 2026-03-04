---
name: Manage Themes
description: >-
  This skill should be used when the user asks to "grab a theme",
  "extract theme from website", "list themes", "show themes",
  "apply theme", "create theme", "manage themes", "add theme",
  "extract theme from pptx", or mentions theme management in the workspace.
  Provides theme extraction from websites and PPTX files, wraps
  document-skills:theme-factory for preset themes, and organizes
  themes in the workspace.
version: 0.1.0
---

# Manage Themes

Manage visual design themes for the cogni-works workspace. Themes are compact markdown files containing color palettes, typography, and design principles consumed by all plugins that produce visual output (slides, documents, diagrams, reports).

## Theme Storage

All themes live in `${COGNI_WORKSPACE_ROOT}/themes/` (or `{workspace}/cogni-workspace/themes/` if env var not set). Each theme gets its own directory:

```
themes/
├── _template/theme.md    # Canonical template
├── digital-x/theme.md    # Brand theme
├── cogni-work/theme.md   # Brand theme
└── {custom}/theme.md     # User themes
```

## Operations

### 1. List Themes

When the user asks to list or show available themes, scan the themes directory:

Use the Glob tool to find all themes:
```
pattern: "*/theme.md"
path: "${COGNI_WORKSPACE_ROOT}/themes"
```

Present each theme with its name (directory name) and first line description from the theme.md file.

### 2. Grab Theme from Website

Extract a visual theme from a live website using Chrome browser automation. This produces a brand-accurate theme.md from real CSS and visual inspection.

**Requirements**: Chrome browser automation tools (`mcp__claude-in-chrome__*`). Before attempting website extraction, verify Chrome tools are available by checking if `mcp__claude-in-chrome__tabs_context_mcp` is callable. If unavailable, inform the user that Chrome browser automation is required and suggest using theme-factory presets or PPTX extraction instead.

**Workflow**:

1. Navigate to the target URL using Chrome
2. Take a screenshot for visual reference
3. Extract CSS design tokens using JavaScript execution:
   - Primary/secondary/accent colors from computed styles
   - Font families and sizes
   - Background colors
   - Border radius, spacing patterns
4. Calculate WCAG contrast ratios for extracted color pairs
5. Research the brand via WebSearch for design philosophy context
6. Generate theme.md following the template at `${CLAUDE_PLUGIN_ROOT}/themes/_template/theme.md`
7. Save to `${COGNI_WORKSPACE_ROOT}/themes/{theme-slug}/theme.md`

**CSS Extraction Script** (execute via JavaScript tool):
```javascript
const cs = getComputedStyle(document.documentElement);
const body = getComputedStyle(document.body);
JSON.stringify({
  colors: {
    primary: cs.getPropertyValue('--primary-color') || cs.color,
    background: body.backgroundColor,
    text: body.color,
    links: getComputedStyle(document.querySelector('a') || document.body).color
  },
  typography: {
    heading: getComputedStyle(document.querySelector('h1,h2,h3') || document.body).fontFamily,
    body: body.fontFamily,
    headingSize: getComputedStyle(document.querySelector('h1') || document.body).fontSize
  }
});
```

Augment extracted values with visual inspection of the screenshot. Infer design principles from the overall visual language.

### 3. Grab Theme from PPTX

Extract theme from a PowerPoint template file.

**Workflow**:

1. Read the PPTX file using the `document-skills:pptx` skill to extract theme XML
2. Map OOXML theme colors to semantic roles (dk1→text, lt1→background, accent1-6)
3. Extract font scheme (major→headers, minor→body)
4. Generate theme.md following the template
5. Save to `${COGNI_WORKSPACE_ROOT}/themes/{theme-slug}/theme.md`

### 4. Create Theme from Preset

Delegate to `document-skills:theme-factory` for preset theme creation:

1. Invoke the `theme-factory` skill to show available presets or create custom themes
2. Once user selects/creates a theme, capture the color palette and typography
3. Generate a theme.md following the workspace template format
4. Save to `${COGNI_WORKSPACE_ROOT}/themes/{theme-slug}/theme.md`

This bridges theme-factory's preset system with the workspace's theme storage.

### 5. Apply Theme

When the user asks to apply a theme, read the theme.md and make its values available for the current session:

1. Read the requested theme from `${COGNI_WORKSPACE_ROOT}/themes/{name}/theme.md`
2. Parse color palette, typography, and design principles
3. Confirm with the user which artifact to apply it to
4. Pass theme values to the appropriate skill (pptx, docx, diagram-expert, etc.)

Themes are consumed by downstream skills - this skill provides the theme data, the consuming skill handles application.

## Theme File Format

Follow the template at `${CLAUDE_PLUGIN_ROOT}/themes/_template/theme.md`. Key sections:

- **Color Palette**: 6-12 colors with hex codes and usage descriptions
- **Status Colors**: Success, Warning, Danger, Info (standardized)
- **Typography**: Header, Body, Mono fonts with fallbacks
- **Design Principles**: 3-8 rules for visual consistency
- **Best Used For**: Target contexts
- **Source**: Origin (URL, PPTX file, preset name) and extraction date

## Naming Convention

Theme directories use kebab-case slugs derived from the brand/source name:
- `digital-x` (from DIGITAL X brand)
- `cogni-work` (from cogni-work.ai)
- `ocean-depths` (from theme-factory preset)
- `client-acme` (from client website)

## Additional Resources

### Template

- **`${CLAUDE_PLUGIN_ROOT}/themes/_template/theme.md`** - Canonical theme template with all sections
