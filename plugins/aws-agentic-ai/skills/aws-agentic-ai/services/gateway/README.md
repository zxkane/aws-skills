# Gateway Service

The Gateway service converts REST APIs into MCP tools that AI agents can use. It handles authentication, schema validation, and request routing.

## Quick Start

### Prerequisites
- AWS CLI configured with appropriate permissions
- An existing Gateway (created via AWS Console or CLI)
- OpenAPI schema for your target API

### Deploy a Gateway Target

**Step 1: Upload OpenAPI schema to S3**
```bash
aws s3 cp my-api-openapi.yaml s3://<BUCKET_NAME>/schemas/
```

**Step 2: Create credential provider (API Key auth only)**
```bash
aws bedrock-agentcore-control create-api-key-credential-provider \
  --name MyAPICredentialProvider \
  --api-key "YOUR_API_KEY" \
  --region us-west-2
```

**Step 3: Create gateway target**
```bash
aws bedrock-agentcore-control create-gateway-target \
  --gateway-identifier <GATEWAY_ID> \
  --name MyAPITarget \
  --endpoint-configuration '{"openApiSchema": {"s3": {"uri": "s3://<BUCKET_NAME>/schemas/my-api-openapi.yaml"}}}' \
  --credential-provider-configurations '[{"credentialProviderType": "GATEWAY_API_KEY_CREDENTIAL_PROVIDER", "apiKeyCredentialProvider": {"providerArn": "arn:aws:bedrock-agentcore:us-west-2:<ACCOUNT_ID>:api-key-credential-provider/MyAPICredentialProvider"}}]' \
  --region us-west-2
```

**Step 4: Verify deployment**
```bash
aws bedrock-agentcore-control get-gateway-target \
  --gateway-identifier <GATEWAY_ID> \
  --target-identifier <TARGET_ID> \
  --region us-west-2
```

## Authentication Options

### Outbound (Accessing External APIs)

| Target Type | IAM | OAuth 2LO | OAuth 3LO | API Key |
|-------------|-----|-----------|-----------|---------|
| Lambda function | Yes | No | No | No |
| API Gateway | Yes | No | No | Yes |
| OpenAPI schema | No | Yes | Yes | Yes |
| Smithy schema | Yes | Yes | Yes | No |
| MCP server | No | Yes | No | No |

### Inbound (Who Can Invoke Tools)
- **IAM**: AWS IAM credentials
- **JWT**: Tokens from identity providers (Cognito, Entra ID)
- **No Auth**: Open access (use with caution)

## Documentation

| Document | Description |
|----------|-------------|
| [Deployment Strategies](deployment-strategies.md) | Credential provider patterns, multi-environment setup, key rotation |
| [Troubleshooting Guide](troubleshooting-guide.md) | Common errors, diagnosis steps, solutions |
| [Deploy Template Script](deploy-template.sh) | Automated deployment script |
| [Validate Deployment Script](validate-deployment.sh) | Post-deployment verification |

## Common Operations

### List Gateway Targets
```bash
aws bedrock-agentcore-control list-gateway-targets \
  --gateway-identifier <GATEWAY_ID> \
  --region us-west-2
```

### Update Credential Provider
```bash
aws bedrock-agentcore-control update-api-key-credential-provider \
  --name MyAPICredentialProvider \
  --api-key "NEW_API_KEY" \
  --region us-west-2
```

### Delete Gateway Target
```bash
aws bedrock-agentcore-control delete-gateway-target \
  --gateway-identifier <GATEWAY_ID> \
  --target-identifier <TARGET_ID> \
  --region us-west-2
```

## Related Resources

- [Cross-Service Credential Management](../../cross-service/credential-management.md)
- [AWS Gateway Documentation](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/gateway.html)
- [Bedrock AgentCore CLI Reference](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/bedrock-agentcore-control/index.html)
