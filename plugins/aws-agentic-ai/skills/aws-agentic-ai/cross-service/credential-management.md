# Cross-Service Credential Management

**Applies to**: Gateway, Runtime, Memory, Identity

## Overview

Credential management is a cross-cutting concern across all AgentCore services. This guide provides unified patterns for managing API keys, tokens, and authentication credentials across the AgentCore platform.

## Authentication Overview

| Service | Direction | Supported Methods | Use Case |
|---------|-----------|-------------------|----------|
| **Gateway** | Inbound | IAM, JWT, No Auth | Who can invoke MCP tools |
| **Gateway** | Outbound | IAM, OAuth (2LO/3LO), API Key | Accessing external APIs |
| **Runtime** | Inbound | IAM (SigV4), JWT | Who can invoke agents |
| **Runtime** | Outbound | OAuth, API Key | Accessing third-party services |
| **Memory** | - | IAM Role | Data access permissions |
| **Identity** | - | AWS KMS | Secret encryption |

### Inbound Authorization (Who Can Access Your Services)

**Gateway Options** ([docs](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/gateway-inbound-auth.html)):
- **IAM Identity**: Uses AWS IAM credentials for authorization
- **JWT**: Tokens from identity providers (Cognito, Microsoft Entra ID, etc.)
- **No Authorization**: Open access - only for production with proper security controls

**Runtime Options** ([docs](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-oauth.html)):
- **IAM (SigV4)**: Default authentication (works automatically)
- **JWT Bearer Token**: Token-based auth with discovery URL and audience validation

> **Note**: A Runtime can only use one inbound auth type (IAM or JWT), not both simultaneously.

### Outbound Authorization (Accessing External Services)

**Gateway Options** ([docs](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/gateway-outbound-auth.html)):

| Target Type | IAM (Service Role) | OAuth 2LO | OAuth 3LO | API Key |
|-------------|-------------------|-----------|-----------|---------|
| Lambda function | ✅ | ❌ | ❌ | ❌ |
| API Gateway | ✅ | ❌ | ❌ | ✅ |
| OpenAPI schema | ❌ | ✅ | ✅ | ✅ |
| Smithy schema | ✅ | ✅ | ✅ | ❌ |
| MCP server | ❌ | ✅ | ❌ | ❌ |

- **OAuth 2LO**: Client credentials grant (machine-to-machine)
- **OAuth 3LO**: Authorization code grant (user-delegated access)

**Runtime Options**:
- **OAuth**: Tokens on behalf of users via Identity Service
- **API Key**: Key-based authentication via Identity Service

## Best Practices

### ✅ DO's

1. **Use Identity Service**: Always manage credentials through the Identity service
   ```bash
   # ✅ Correct - Use Identity API
   aws bedrock-agentcore-control create-api-key-credential-provider \
     --name MyCredentialProvider \
     --api-key "YOUR_API_KEY_VALUE"
   ```

2. **Separate by Environment**: Use different providers for different environments
   ```bash
   - dev-api-key-provider      # Development
   - staging-api-key-provider  # Staging
   - prod-api-key-provider     # Production
   ```

3. **Rotate Regularly**: Implement quarterly credential rotation
   ```bash
   aws bedrock-agentcore-control update-api-key-credential-provider \
     --name MyCredentialProvider \
     --api-key "NEW_API_KEY"
   ```

4. **Least Privilege**: Grant minimal required permissions to each credential
   ```bash
   # API key should only have necessary API permissions
   # IAM roles should have scoped-down policies
   ```

5. **Monitor Usage**: Track credential usage and set up alerts
   ```json
   {
     "CloudWatch Alarms": {
       "HighErrorRate": "Alert if > 10% failed requests",
       "UnusualActivity": "Alert on usage spikes"
     }
   }
   ```

### ❌ DON'Ts

1. **Never Hardcode**: Don't embed credentials in code or configuration files
   ```bash
   # ❌ Bad - Hardcoded API key
   const apiKey = "sk-1234567890abcdef"

   # ✅ Good - Reference credential provider
   const credentialProvider = "MyCredentialProvider"
   ```

2. **Don't Share Across Environments**: Avoid using production keys in development
   ```bash
   # ❌ Bad - Same key everywhere
   dev:  third-party-api-key: prod-key
   prod: third-party-api-key: prod-key

   # ✅ Good - Separate keys
   dev:  third-party-api-key: dev-key
   prod: third-party-api-key: prod-key
   ```

3. **Don't Commit to Git**: Exclude credential files from version control
   ```bash
   # .gitignore
   *.env
   *.secret
   credential-*.json
   ```

4. **Don't Use Long-Lived Tokens**: Implement token refresh for OAuth
   ```bash
   # OAuth tokens should auto-refresh
   # Don't use tokens with > 30 day expiration
   ```

## Multi-Service Credential Patterns

### Pattern 1: Centralized Identity, Distributed Usage

```
┌─────────────────────────────────────┐
│  Identity Service                   │
│  - Stores ALL credentials           │
│  - Manages rotation                 │
│  - Provides audit logs              │
└──────────┬──────────────────────────┘
           │
           ├────────────┬────────────┬────────────┐
           ▼            ▼            ▼            ▼
    ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
    │ Gateway  │ │ Runtime  │ │  Memory  │ │  Other   │
    │  Uses    │ │  Uses    │ │  Uses    │ │  Uses    │
    └──────────┘ └──────────┘ └──────────┘ └──────────┘
```

**Benefits**:
- Single source of truth for all credentials
- Unified rotation and audit
- Consistent access patterns

**Setup**:
```bash
# 1. Create master credential in Identity
aws bedrock-agentcore-control create-api-key-credential-provider \
  --name MasterAPICredentials \
  --api-key "YOUR_MASTER_API_KEY"

# 2. Grant access to each service
# - Gateway: can read MasterAPICredentials
# - Runtime: can read MasterAPICredentials
# - Memory: can read MasterAPICredentials
```

### Pattern 2: Service-Specific Credentials

```
┌─────────────────────────────────────┐
│  Identity Service                   │
│  - Stores credentials per service   │
└──────────┬──────────────────────────┘
           │
    ┌──────┴──────┬────────┬─────────┐
    ▼             ▼        ▼         ▼
┌─────────┐ ┌─────────┐ ┌──────┐ ┌─────┐
│ Gateway │ │ Runtime │ │Memory││Other│
│  Cred   │ │  Cred   │ │ Cred ││Cred │
└─────────┘ └─────────┘ └──────┘ └─────┘
```

**Benefits**:
- Isolation between services
- Independent rotation per service
- Service-specific permissions

**Setup**:
```bash
# Create separate providers
aws bedrock-agentcore-control create-api-key-credential-provider \
  --name GatewayAPICredentials \
  --api-key "YOUR_GATEWAY_API_KEY"

aws bedrock-agentcore-control create-api-key-credential-provider \
  --name RuntimeCredentials \
  --api-key "YOUR_RUNTIME_API_KEY"
```

### Pattern 3: Tiered (Master + Service)

```
┌─────────────────────────────────────┐
│  Identity Service                   │
│  - Master credential                │
│  - Per-service credentials          │
└──────────┬──────────────────────────┘
           │
    ┌──────┴──────┐
    ▼             ▼
┌─────────┐ ┌─────────────┐
│ Master  │ │   Services  │
│  Cred   │ │   - Gateway │ │
└────┬────┘ │   - Runtime │
     │      │   - Memory  │
     └──────┤   (each has │
            │ own creds)  │
            └─────────────┘
```

**Use Cases**:
- Production: Master credential for critical APIs
- Development: Service-specific credentials for testing
- Emergency: Master credential as backup

## Security Best Practices

### Encryption

```bash
# Use KMS for secret encryption
aws secretsmanager create-secret \
  --name MySecret \
  --kms-key-id arn:aws:kms:us-west-2:123456789012:key/12345678-abcd-ef12-3456-7890abcdef12 \
  --secret-string "my-secret-value"
```

### Access Control

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock-agentcore:GetResourceApiKey"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:PrincipalTag/Service": "gateway"
        }
      }
    }
  ]
}
```

### Audit Logging

```bash
# Enable CloudTrail for Bedrock AgentCore
aws cloudtrail create-trail \
  --name agentcore-audit \
  --s3-bucket-name agentcore-audit-logs \
  --include-global-service-events true
```

## Rotation Strategy

### Automated Rotation

```bash
# Enable automatic rotation (when supported)
aws secretsmanager rotate-secret \
  --secret-id MySecret \
  --lambda-arn arn:aws:lambda:us-west-2:123456789012:function:MyRotationFunction

# Rotation schedule (every 30 days)
aws secretsmanager rotate-secret \
  --secret-id MySecret \
  --rotation-rules AutomaticAfterDays=30
```

### Manual Rotation Process

```bash
#!/bin/bash
# rotate-credentials.sh

echo "Step 1: Generate new credential"
NEW_KEY=$(generate-new-api-key)

echo "Step 2: Update in Identity service"
aws bedrock-agentcore-control update-api-key-credential-provider \
  --name MyCredentialProvider \
  --api-key "$NEW_KEY"

echo "Step 3: Verify all services work"
./test-all-services.sh

echo "Step 4: Delete old credential"
# Old credential is automatically deprecated
```

## Common Patterns

### Pattern: Credential Fallback

```typescript
// Try primary credential, fallback to backup
async function callWithFallback(provider: string) {
  try {
    return await callAPI(provider);
  } catch (error) {
    if (error.code === 'InvalidAPICredentials') {
      // Fallback to backup provider
      return await callAPI(`${provider}-backup`);
    }
    throw error;
  }
}
```

### Pattern: Rate Limiting with Credential Pool

```typescript
// Rotate through multiple credentials to avoid rate limits
const credentialPool = [
  'cred-1',
  'cred-2',
  'cred-3'
];

let currentIndex = 0;

function getNextCredential(): string {
  const credential = credentialPool[currentIndex];
  currentIndex = (currentIndex + 1) % credentialPool.length;
  return credential;
}
```

## Troubleshooting Credential Issues

### Issue: "Credential not found"

**Diagnosis**:
```bash
# Check if provider exists
aws bedrock-agentcore-control get-api-key-credential-provider \
  --name MyCredentialProvider

# Check IAM permissions
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:role/MyRole \
  --action-names bedrock-agentcore:GetResourceApiKey \
  --resource-arns arn:aws:bedrock-agentcore:us-west-2:123456789012:*
```

**Solution**: Create provider or grant IAM permissions

---

### Issue: "Invalid credentials" after rotation

**Diagnosis**:
```bash
# Check secret value format
aws secretsmanager get-secret-value \
  --secret-id arn:aws:secretsmanager:us-west-2:123456789012:secret:MySecret

# Should be: {"apiKey": "valid-key"}
```

**Solution**: Use correct update API
```bash
aws bedrock-agentcore-control update-api-key-credential-provider \
  --name MyCredentialProvider \
  --api-key "VALID_KEY"
```

---

### Issue: Cross-service access denied

**Diagnosis**:
```bash
# Check which services can access the credential
aws bedrock-agentcore-control get-api-key-credential-provider \
  --name MyCredentialProvider

# Review service IAM policies
```

**Solution**: Add cross-service access policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "bedrock-agentcore:GetResourceApiKey",
      "Resource": "*",
      "Condition": {
        "ArnLike": {
          "aws:PrincipalArn": [
            "arn:aws:iam::*:role/*gateway*",
            "arn:aws:iam::*:role/*runtime*"
          ]
        }
      }
    }
  ]
}
```

## Cost Considerations

### Secrets Manager Costs

- **Per secret**: ~$0.40/month
- **Per 10,000 API calls**: ~$0.05
- **Cross-region replication**: Additional costs

**Optimization**:
- Share credentials across services when possible
- Use regional replication only when necessary
- Cache credential retrieval (respect security requirements)

### Identity Service Costs

- **Credential provider storage**: Included in Secrets Manager
- **API calls**: Same as Secrets Manager pricing
- **Cross-account access**: No additional cost

## References

- **[Identity Service](../services/identity/README.md)**: Credential provider management
- **[Gateway Service](../services/gateway/README.md)**: Uses credentials for API authentication
- **AWS Secrets Manager**: [Pricing](https://aws.amazon.com/secrets-manager/pricing/)
- **AWS Documentation**: [Managing AWS Secrets Manager secrets](https://docs.aws.amazon.com/secretsmanager/latest/userguide/manage_create-basic-secret.html)

---

**Related Guides**:
- [Observability Service](../services/observability/README.md)
- [AWS AgentCore Identity Documentation](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/identity.html)
