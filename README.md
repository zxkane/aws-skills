# AWS Skills for Claude Code

Claude Code plugins for AWS development with specialized knowledge and MCP server integrations.

## Plugins

### 1. AWS CDK Plugin

AWS CDK development skill with integrated MCP servers for infrastructure as code.

**Features**:
- AWS CDK best practices and patterns
- Pre-deployment validation script
- Comprehensive CDK patterns reference

**Integrated MCP Servers**:
- AWS Documentation MCP (HTTP)
- AWS CDK MCP (stdio)

### 2. AWS Cost & Operations Plugin

Cost optimization, monitoring, and operational excellence with 8 integrated MCP servers.

**Features**:
- Cost estimation and optimization
- Monitoring and observability patterns
- Security assessment and auditing
- Operational best practices

**Integrated MCP Servers**:
- AWS Billing and Cost Management
- AWS Pricing
- AWS Cost Explorer
- Amazon CloudWatch
- CloudWatch Application Signals
- AWS Managed Prometheus
- AWS CloudTrail
- Well-Architected Security Assessment Tool

## Installation

Add the marketplace to Claude Code:

```bash
/plugin marketplace add zxkane/aws-skills
```

Install plugins individually:

```bash
/plugin install aws-cdk@aws-skills
/plugin install aws-cost-operations@aws-skills
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

## Usage Examples

### CDK Development

Ask Claude to help with CDK:

```
Create a CDK stack with a Lambda function that processes S3 events
```

Claude will:
- Follow CDK best practices
- Use NodejsFunction for automatic bundling
- Avoid explicit resource naming
- Grant proper IAM permissions
- Use MCP servers for latest AWS information

### Cost Optimization

Estimate costs before deployment:

```
Estimate the monthly cost of running 10 Lambda functions with 1M invocations each
```

Analyze current spending:

```
Show me my AWS costs for the last 30 days broken down by service
```

### Monitoring and Observability

Set up monitoring:

```
Create CloudWatch alarms for my Lambda functions to alert on errors and high duration
```

Investigate issues:

```
Show me CloudWatch logs for my API Gateway errors in the last hour
```

### Security and Audit

Audit activity:

```
Show me all IAM changes made in the last 7 days
```

Assess security:

```
Run a Well-Architected security assessment on my infrastructure
```

## Structure

```
.
├── .claude-plugin/
│   └── marketplace.json              # Plugin marketplace configuration
├── skills/
│   ├── aws-cdk-development/          # CDK development skill
│   │   ├── SKILL.md
│   │   ├── references/
│   │   │   └── cdk-patterns.md
│   │   └── scripts/
│   │       └── validate-stack.sh
│   └── aws-cost-operations/          # Cost & operations skill
│       ├── SKILL.md
│       └── references/
│           ├── operations-patterns.md
│           └── cloudwatch-alarms.md
└── README.md
```

## Resources

- [Claude Agent Skills](https://docs.claude.com/en/docs/claude-code/skills)
- [AWS MCP Servers](https://awslabs.github.io/mcp/)
- [AWS CDK](https://aws.amazon.com/cdk/)
- [MCP Protocol](https://modelcontextprotocol.io/)

## License

MIT License - see [LICENSE](LICENSE)

## Author

Kane Zhu ([@zxkane](https://github.com/zxkane))
