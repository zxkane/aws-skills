# AgentCore Gateway Deployment Strategies

## Overview

This reference guide covers different deployment strategies for AWS Bedrock AgentCore Gateway targets, including credential management approaches, multi-environment patterns, and rollback procedures.

## Credential Provider Strategies

### Strategy 1: Shared Provider (Recommended for Most Cases)

**Concept**: Create ONE credential provider and share across all gateway targets

**Setup**:
```bash
# Create shared provider with API key (run once)
aws bedrock-agentcore-control create-api-key-credential-provider \
  --name SharedAPICredentialProvider \
  --api-key "YOUR_API_KEY" \
  --profile default --region us-west-2
```

**Environment Configuration**:
```bash
# .env.gateway-a
GATEWAY_IDENTIFIER=gateway-a-abc123xyz
CREDENTIAL_PROVIDER_NAME=SharedAPICredentialProvider  # Same for all

# .env.gateway-b
GATEWAY_IDENTIFIER=gateway-b-def456uvw
CREDENTIAL_PROVIDER_NAME=SharedAPICredentialProvider  # Same for all
```

**Benefits**:
- ✅ Simplified key management - single key to rotate
- ✅ Reduced operational overhead
- ✅ Consistent authentication across all gateways
- ✅ Easier compliance and auditing

**Use Cases**:
- Same API, multiple gateway deployments
- Development/Testing/Production gateways
- Regional deployments (us-west-2, eu-west-1)

**Trade-offs**:
- Less isolation between gateways (all or nothing key rotation)

### Strategy 2: Isolated Provider (Per-Gateway)

**Concept**: Create UNIQUE credential provider for each gateway

**Setup**:
```bash
# Create provider for Gateway A
aws bedrock-agentcore-control create-api-key-credential-provider \
  --name GatewayAAPICredentialProvider \
  --api-key "API_KEY_A" \
  --profile default --region us-west-2

# Create provider for Gateway B
aws bedrock-agentcore-control create-api-key-credential-provider \
  --name GatewayBAPICredentialProvider \
  --api-key "API_KEY_B" \
  --profile default --region us-west-2
```

**Environment Configuration**:
```bash
# .env.gateway-a
GATEWAY_IDENTIFIER=gateway-a-abc123xyz
CREDENTIAL_PROVIDER_NAME=GatewayAAPICredentialProvider  # Unique

# .env.gateway-b
GATEWAY_IDENTIFIER=gateway-b-def456uvw
CREDENTIAL_PROVIDER_NAME=GatewayBAPICredentialProvider  # Unique
```

**Benefits**:
- ✅ Complete isolation between gateways
- ✅ Independent key rotation per environment
- ✅ Different API keys for different use cases
- ✅ Better security boundaries

**Use Cases**:
- Production vs Development with different API keys
- Different APIs for different gateways
- Compliance requiring environment separation
- Testing new API versions in isolation

**Trade-offs**:
- More complex key management
- Multiple keys to rotate and maintain

### Strategy 3: Tiered (Shared + Isolated)

**Concept**: Hybrid approach with shared provider for non-prod, isolated for production

**Setup**:
```bash
# Shared provider for dev/test
aws bedrock-agentcore-control create-api-key-credential-provider \
  --name DevTestAPICredentialProvider \
  --api-key "DEV_TEST_API_KEY" \
  --profile default --region us-west-2

# Isolated provider for production
aws bedrock-agentcore-control create-api-key-credential-provider \
  --name ProdAPICredentialProvider \
  --api-key "PROD_API_KEY" \
  --profile default --region us-west-2
```

**Environment Configuration**:
```bash
# .env.development
GATEWAY_IDENTIFIER=dev-gateway-abc123xyz
CREDENTIAL_PROVIDER_NAME=DevTestAPICredentialProvider

# .env.staging
GATEWAY_IDENTIFIER=staging-gateway-def456uvw
CREDENTIAL_PROVIDER_NAME=DevTestAPICredentialProvider

# .env.production
GATEWAY_IDENTIFIER=prod-gateway-ghi789rst
CREDENTIAL_PROVIDER_NAME=ProdAPICredentialProvider
```

**Benefits**:
- ✅ Balance of simplicity and security
- ✅ Production isolation with dev/test convenience
- ✅ Easier testing in non-prod environments
- ✅ Production key remains protected

**Use Cases**:
- Most common enterprise pattern
- Clear separation between environments
- Controlled production access

## Multi-Account Deployment

When deploying across multiple AWS accounts:

### Setup

1. **Credential Provider per Account**:
   ```bash
   # Account 1 (Dev)
   aws bedrock-agentcore-control create-api-key-credential-provider \
     --name APICredentialProvider \
     --api-key "DEV_API_KEY" \
     --profile dev-account

   # Account 2 (Prod)
   aws bedrock-agentcore-control create-api-key-credential-provider \
     --name APICredentialProvider \
     --api-key "PROD_API_KEY" \
     --profile prod-account
   ```

2. **Centralized Configuration**:
   ```bash
   # .env.dev
   ACCOUNT_ID=123456789012
   GATEWAY_IDENTIFIER=dev-gateway-abc123xyz
   AWS_PROFILE=dev-account

   # .env.prod
   ACCOUNT_ID=987654321098
   GATEWAY_IDENTIFIER=prod-gateway-abc123xyz
   AWS_PROFILE=prod-account
   ```

3. **Cross-Account Deployment Script**:
   ```bash
   #!/bin/bash
   ENV_FILE=$1

   # Load environment
   export $(cat $ENV_FILE | xargs)

   # Get AWS account ID
   export CDK_DEFAULT_ACCOUNT=$(aws sts get-caller-identity \
     --profile $AWS_PROFILE \
     --query Account --output text)

   # Deploy
   npm run build && cdk deploy --profile $AWS_PROFILE --require-approval never
   ```

## Key Rotation Procedures

### Shared Provider Strategy

**Manual Rotation**:
```bash
# 1. Update key in provider
aws bedrock-agentcore-control update-api-key-credential-provider \
  --name SharedAPICredentialProvider \
  --api-key "NEW_API_KEY" \
  --profile default --region us-west-2

# 2. Restart gateway targets (if needed) to pick up new key
```

**Automated Rotation**:
- Use AWS Secrets Manager rotation (if supported by credential provider)
- Triggered by CloudWatch Events schedule
- Lambda function handles key generation/update

### Isolated Provider Strategy

**Per-Gateway Rotation**:
```bash
# Rotate dev environment only
aws bedrock-agentcore-control update-api-key-credential-provider \
  --name DevAPICredentialProvider \
  --api-key "NEW_DEV_KEY"

# Production remains unchanged
aws bedrock-agentcore-control update-api-key-credential-provider \
  --name ProdAPICredentialProvider \
  --api-key "EXISTING_PROD_KEY"
```

## Rollback Procedures

### Rollback Failed Deployment

```bash
# List CloudFormation stacks
aws cloudformation list-stacks --stack-status-filter UPDATE_ROLLBACK_FAILED

# Get previous stack configuration
aws cloudformation describe-stack-resources --stack-name StackName

# Rollback to previous version
aws cloudformation continue-update-rollback --stack-name StackName
```

### Rollback Credential Changes

```bash
# If new API key is causing issues, restore previous key
aws bedrock-agentcore-control update-api-key-credential-provider \
  --name APICredentialProvider \
  --api-key "PREVIOUS_WORKING_KEY"
```

## Monitoring and Alerting

### CloudWatch Metrics to Monitor

- **Gateway Target Status**: Monitor target health
- **API Request Count**: Track usage per gateway
- **Error Rates**: 4xx and 5xx errors
- **Latency**: P95, P99 response times
- **Credential Provider Errors**: Secret access failures

### CloudWatch Alarms

```typescript
// CDK Example: Create alarm for high error rate
new cloudwatch.Alarm(this, 'HighErrorRate', {
  metric: new cloudwatch.Metric({
    namespace: 'AWS/BedrockAgentCore',
    metricName: 'TargetErrorRate',
    dimensionsMap: {
      GatewayId: gatewayId,
      TargetId: targetId,
    },
    statistic: 'avg',
    period: Duration.minutes(5),
  }),
  threshold: 10,
  evaluationPeriods: 2,
  datapointsToAlarm: 2,
  comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
  alarmDescription: 'Error rate exceeds 10%',
  actionsEnabled: true,
});
```

## Cost Optimization

### Cost Considerations

1. **AgentCore Gateway**: Pay per tool invocation
   - Optimize schema to reduce unnecessary API calls
   - Cache frequently accessed data in schema descriptions
   - Use batch operations where available

2. **S3 Asset Storage**: Negligible (<$0.01/month)
   - Schema files are small
   - CDK automatically cleans up old versions

3. **Lambda (GatewayRoleUpdater)**: ~$0.01 per deployment
   - Covered by AWS Lambda free tier (1M requests/month)
   - Only runs during deployment/update

4. **Secrets Manager**: ~$0.40/month per secret
   - Use shared provider to minimize secret count
   - Rotate secrets on schedule to maintain security

5. **API Calls (RapidAPI Example)**:
   - Free tier: 100 requests/day
   - Paid tiers: From $10/month
   - Optimize by embedding IDs in schema

### Optimization Strategies

**Schema Optimization**:
```yaml
# Embed common IDs to reduce API calls by 50%
info:
  description: |
    COMMON LEAGUE IDs:
    - Premier League: 39
    - Champions League: 2
    - World Cup: 1
```

**Credential Provider Sharing**:
- Single provider for all gateways = 1 secret = $0.40/month
- Separate providers = N secrets = $0.40N/month

## Security Best Practices

### Credential Management
- Never commit API keys to source control
- Use AWS Secrets Manager via credential providers
- Rotate keys regularly (quarterly minimum)
- Use different keys for different environments

### IAM Permissions
- Custom Resource Lambda has scoped permissions
- Only allows access to Gateway service roles
- Follows principle of least privilege
- Audit policy versions regularly

### Network Security
- Ensure Gateway is in VPC if required
- Use AWS PrivateLink for on-premises integrations
- Enable encryption in transit (TLS 1.2+)
- Verify API endpoints use HTTPS

## Common Patterns

### Pattern 1: Development Pipeline

```bash
# Branch-based deployment
if [ "$BRANCH" = "main" ]; then
  ./deploy.sh .env.production
elif [ "$BRANCH" = "develop" ]; then
  ./deploy.sh .env.staging
else
  ./deploy.sh .env.development
fi
```

### Pattern 2: Regional Deployment

```bash
# Deploy to multiple regions
for region in us-west-2 eu-west-1 ap-southeast-1; do
  export AWS_REGION=$region
  export GATEWAY_IDENTIFIER="my-gateway-${region}"
  npm run build && cdk deploy --require-approval never
done
```

### Pattern 3: Blue-Green Deployment

```bash
# Deploy to blue environment
./deploy.sh .env.blue

# Test blue environment
./test-target.sh blue

# Switch to green if blue is healthy
./deploy.sh .env.green
```

## Migration Strategies

### Migrating from Manual to CDK Management

1. **Discovery Phase**:
   ```bash
   # Document existing targets
   aws bedrock-agentcore-control list-gateway-targets \
     --gateway-identifier existing-gateway \
     --profile default --region us-west-2
   ```

2. **Schema Extraction**:
   - Export existing OpenAPI schemas
   - Audit and optimize schema descriptions
   - Embed common IDs for performance

3. **CDK Implementation**:
   - Create stack with existing target configuration
   - Import existing credential provider
   - Add GatewayRoleUpdater for IAM automation

4. **Cutover**:
   - Deploy to new gateway first (test)
   - Update AI agents to use new target
   - Decommission old target after verification

## Additional References

- **Main Skill Documentation**: [`../../SKILL.md`](../../SKILL.md)
- **Troubleshooting Guide**: [`./troubleshooting-guide.md`](./troubleshooting-guide.md)
- **Deployment Template Script**: [`./deploy-template.sh`](./deploy-template.sh)
- **Credential Management**: [`../../cross-service/credential-management.md`](../../cross-service/credential-management.md)
