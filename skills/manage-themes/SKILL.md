---
name: Manage Themes
description: >-
  Manage visual design themes for the workspace — extract themes from live
  websites (via Chrome), PowerPoint templates, or presets, then store and apply
  them to all visual outputs (slides, documents, diagrams, reports). Use this
  skill whenever the user mentions themes, brand colors, visual identity,
  extracting styles, or wants consistent look-and-feel across outputs. Even if
  the user just says "make it match our brand", "use our company colors", or
  "grab the style from that site", this skill applies.
version: 0.2.0
---

# Manage Themes

Manage visual design themes for the cogni-works workspace. Themes are compact markdown files containing color palettes, typography, and design principles consumed by all plugins that produce visual output (slides, documents, diagrams, reports).

## Prerequisites

Before any operation, resolve the workspace themes directory:

1. Use `${COGNI_WORKSPACE_ROOT}/themes/` if the env var is set
2. Otherwise fall back to `{workspace}/cogni-workspace/themes/`
3. If the themes directory does not exist, create it (and `_template/` inside it) before proceeding

If Chrome browser automation tools are unavailable, inform the user upfront and suggest PPTX extraction or theme-factory presets as alternatives.

## Theme Storage

All themes live in the resolved themes directory. Each theme gets its own directory:

```
themes/
├── _template/theme.md    # Canonical template (see Theme File Format below)
├── digital-x/theme.md    # Brand theme
├── cogni-work/theme.md   # Brand theme
└── {custom}/theme.md     # User themes
```

When a theme slug already exists, ask the user whether to overwrite or create a versioned alternative (e.g., `acme-v2`).

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
6. Generate theme.md following the template (see Theme File Format below)
7. Save to `{themes-dir}/{theme-slug}/theme.md`

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

Extract theme from a PowerPoint template file. PPTX files embed theme XML in their ZIP structure — the key data lives in `ppt/theme/theme1.xml`.

**Workflow**:

1. Read the PPTX file using the `document-skills:pptx` skill to extract theme XML
2. Parse the OOXML color scheme (`a:clrScheme`) and map to semantic roles:
   - `dk1` → Text color
   - `lt1` → Background color
   - `dk2` → Secondary text
   - `lt2` → Surface/card background
   - `accent1` → Primary brand color
   - `accent2` → Secondary brand color
   - `accent3`–`accent6` → Additional palette colors
3. Parse the font scheme (`a:fontScheme`):
   - `a:majorFont` → Header font family
   - `a:minorFont` → Body font family
4. Generate theme.md following the template (see Theme File Format below)
5. Save to `{themes-dir}/{theme-slug}/theme.md`

### 4. Create Theme from Preset

Delegate to `document-skills:theme-factory` for preset theme creation:

1. Invoke the `theme-factory` skill to show available presets or create custom themes
2. Once user selects/creates a theme, capture the color palette and typography
3. Generate a theme.md following the template (see Theme File Format below)
4. Save to `{themes-dir}/{theme-slug}/theme.md`

This bridges theme-factory's preset system with the workspace's theme storage.

### 5. Apply Theme

When the user asks to apply a theme, read the theme.md and feed its contents into the downstream skill that produces the output.

1. Read the requested theme from `{themes-dir}/{name}/theme.md`
2. If the user hasn't specified which artifact to theme, ask them (e.g., "Apply this to which output — slides, a document, a diagram?")
3. Include the full theme.md content in the prompt/context when invoking the downstream skill. The consuming skill needs the raw color hex codes, font names, and design principles to apply them. For example:
   - **Slides** (`document-skills:pptx`): pass theme colors and fonts so they map to slide master styles
   - **Documents** (`document-skills:docx`): pass palette for heading colors, accent boxes, table styling
   - **Diagrams** (`cogni-workplace:diagram-expert`): pass primary/secondary/accent colors and design principles
   - **Web/HTML outputs**: pass full palette and typography for CSS variable mapping

The theme.md content is the single source of truth — always read it fresh rather than relying on cached or partial values.

## Theme File Format

Follow the template at `{themes-dir}/_template/theme.md`. Key sections:

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

- **`{themes-dir}/_template/theme.md`** — Canonical theme template with all sections. Read this template before generating any new theme to ensure all required sections are present.
