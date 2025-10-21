# AWS Skills for Claude Code

Claude Code plugins for AWS development with specialized knowledge and MCP server integrations.

## AWS CDK Plugin

AWS CDK development skill with integrated MCP servers for enhanced development experience.

**Features**:
- AWS CDK best practices and patterns
- Integrated AWS Documentation MCP server
- Integrated AWS CDK MCP server
- Pre-deployment validation script
- Comprehensive CDK patterns reference

## Installation

Add the marketplace to Claude Code:

```bash
/plugin marketplace add zxkane/aws-skills
```

Install the aws-cdk plugin:

```bash
/plugin install aws-cdk@aws-skills
```

## Core CDK Principles

### Resource Naming

**Do NOT explicitly specify resource names** when they are optional in CDK constructs.

```typescript
// ✅ GOOD - Let CDK generate unique names
new lambda.Function(this, 'MyFunction', {
  // No functionName specified
});

// ❌ BAD - Prevents multiple deployments
new lambda.Function(this, 'MyFunction', {
  functionName: 'my-lambda',
});
```

### Lambda Functions

Use appropriate constructs for automatic bundling:

- **TypeScript/JavaScript**: `NodejsFunction` from `aws-cdk-lib/aws-lambda-nodejs`
- **Python**: `PythonFunction` from `@aws-cdk/aws-lambda-python-alpha`

### Pre-Deployment Validation

Before committing CDK code:

```bash
npm run build
npm test
npm run lint
cdk synth
./scripts/validate-stack.sh
```

## MCP Servers

### AWS Documentation MCP Server
- Access AWS documentation and knowledge base
- Check service regional availability
- Search and read documentation pages

### AWS CDK MCP Server
- CDK construct guidance
- Best practice recommendations
- Pattern suggestions

## Usage

Ask Claude to help with CDK development:

```
Create a CDK stack with a Lambda function that processes S3 events
```

Claude will:
- Follow CDK best practices
- Use NodejsFunction for automatic bundling
- Avoid explicit resource naming
- Grant proper IAM permissions
- Use MCP servers for latest AWS information

## Structure

```
.
├── .claude-plugin/
│   └── marketplace.json          # Plugin configuration
├── skills/
│   └── aws-cdk-development/
│       ├── SKILL.md
│       ├── references/
│       │   └── cdk-patterns.md   # Detailed patterns
│       └── scripts/
│           └── validate-stack.sh
└── README.md
```

## Resources

- [Claude Agent Skills](https://docs.claude.com/en/docs/claude-code/skills)
- [AWS CDK](https://aws.amazon.com/cdk/)
- [MCP Protocol](https://modelcontextprotocol.io/)

## License

MIT License - see [LICENSE](LICENSE)

## Author

Kane Zhu ([@zxkane](https://github.com/zxkane))
