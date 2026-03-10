# Issue Templates

Templates for the four issue types. Fill placeholders before presenting to the user.

## Bug Report

```markdown
## Bug Report: {plugin_name}

**Plugin:** {plugin_name} v{version}
**Marketplace:** {marketplace}
**Environment:** {os} / Claude Code

### What happened
{description}

### Expected behavior
{expected}

### Steps to reproduce
1. {step1}
2. {step2}
3. {step3}

### Error output / logs
```
{logs}
```

### Additional context
{context}
```

## Feature Request

```markdown
## Feature Request: {plugin_name}

**Plugin:** {plugin_name} v{version}
**Marketplace:** {marketplace}

### Use case
{use_case}

### Proposed solution
{proposed_solution}

### Alternatives considered
{alternatives}

### Additional context
{context}
```

## Change Request

```markdown
## Change Request: {plugin_name}

**Plugin:** {plugin_name} v{version}
**Marketplace:** {marketplace}

### Current behavior
{current_behavior}

### Desired behavior
{desired_behavior}

### Motivation
{motivation}

### Impact assessment
{impact}

### Additional context
{context}
```

## Question

```markdown
## Question: {plugin_name}

**Plugin:** {plugin_name} v{version}
**Marketplace:** {marketplace}

### Context
{context}

### Question
{question}

### What I've tried
{tried}
```

## Label Mapping

| Issue type | GitHub label |
|------------|-------------|
| bug | `bug` |
| feature | `enhancement` |
| change-request | `change-request` |
| question | `question` |
