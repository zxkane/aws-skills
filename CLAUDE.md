# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is an AWS skills plugin marketplace for Claude Code. It contains 4 plugins that provide AWS development expertise through skills and MCP server integrations.

## Architecture

```
.claude-plugin/marketplace.json    # Plugin marketplace definition (versions, MCP servers)
plugins/
├── aws-cdk/                       # CDK infrastructure as code
├── aws-cost-ops/                  # Cost optimization & monitoring
├── serverless-eda/                # Serverless & event-driven patterns
└── aws-agentic-ai/                # Bedrock AgentCore for AI agents
```

Each plugin contains:
- `skills/<skill-name>/SKILL.md` - Main skill file with frontmatter config
- `skills/<skill-name>/references/` - Detailed reference documentation
- Optional: `scripts/`, `services/`, `cross-service/` directories

## Testing Skills Locally

Skills are symlinked from `.claude/skills/` for local development:

```bash
# Start Claude Code in this directory - skills auto-load
cd /data/git/agentic/aws-skills
claude

# Verify skills loaded
/skills
/context
```

**Non-interactive testing:**
```bash
claude -p "List all available skills in this project"
claude -p "Read the frontmatter of aws-cdk-development skill"
```

**If symlinks break, recreate them:**
```bash
cd .claude && rm -rf skills && mkdir skills
ln -s ../../plugins/aws-cdk/skills/aws-cdk-development skills/
ln -s ../../plugins/serverless-eda/skills/aws-serverless-eda skills/
ln -s ../../plugins/aws-agentic-ai/skills/aws-agentic-ai skills/
ln -s ../../plugins/aws-cost-ops/skills/aws-cost-operations skills/
```

## Skill Frontmatter (Claude Code 2.1 Features)

Skills use these frontmatter fields for Claude Code 2.1:

```yaml
---
name: skill-name
description: ...
context: fork                    # Run in forked sub-agent context
model: sonnet                    # Specify model for skill execution
skills:
  - other-skill                  # Auto-load sub-skills
allowed-tools:
  - mcp__server__*               # Wildcard MCP tool permissions
  - Bash(aws *)                  # Wildcard bash permissions
hooks:
  PreToolUse:
    - matcher: Bash(cdk deploy*)
      command: aws sts get-caller-identity --query Account --output text
      once: true                 # Run hook only once per session
---
```

## MCP Server Naming

MCP servers use short names due to Bedrock's 64-char tool name limit:
- `cdk` - AWS CDK MCP
- `pricing` - AWS Pricing MCP
- `costexp` - Cost Explorer MCP
- `cw` - CloudWatch MCP

Tool names follow pattern: `mcp__plugin_{plugin}_{server}__{tool}`

## Version Management

Versions are in `.claude-plugin/marketplace.json`:
- `metadata.version` - Overall marketplace version
- `plugins[].version` - Individual plugin versions

Bump minor version when adding features, patch for fixes.

## Key Files to Modify

| Task | Files |
|------|-------|
| Add/update skill content | `plugins/<plugin>/skills/<skill>/SKILL.md` |
| Add reference docs | `plugins/<plugin>/skills/<skill>/references/*.md` |
| Add MCP servers to plugin | `.claude-plugin/marketplace.json` → `plugins[].mcpServers` |
| Change plugin metadata | `.claude-plugin/marketplace.json` |
