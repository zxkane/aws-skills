# AgentCore Identity Service

> **Status**: ✅ Available

## Overview

Amazon Bedrock AgentCore Identity is an identity and credential management service designed specifically for AI agents and automated workloads. It provides secure authentication, authorization, and credential management capabilities that enable agents and tools to access AWS resources and third-party services on behalf of users while maintaining strict security controls and audit trails.

## Core Capabilities

### Centralized Agent Identity Management
- **Workload Identities**: Agent identities implemented as workload identities with specialized attributes
- **Unified Directory**: Create, manage, and organize agent identities through unified directory service
- **Hierarchical Organization**: Group-based access controls and hierarchical organization
- **Cross-Environment**: Consistent identity management regardless of deployment location

### Secure Credential Storage
- **Token Vault**: Securely store OAuth 2.0 tokens, client credentials, and API keys
- **Encryption**: Comprehensive encryption at rest and in transit
- **Access Controls**: Strict access controls with independent request validation
- **Defense-in-Depth**: Protects end-user data from malicious or misbehaving agent code

### OAuth 2.0 Flow Support
- **Client Credentials Grant**: Machine-to-machine authentication (2LO)
- **Authorization Code Grant**: User-delegated access (3LO)
- **Built-in Providers**: Pre-configured providers for Google, GitHub, Slack, Salesforce
- **Custom Providers**: Configurable OAuth 2.0 credential providers for custom integrations

### Credential Provider Management
- **API Key Providers**: Securely store and manage API keys
- **OAuth Credential Providers**: Handle OAuth flow and token management
- **Token Lifecycle**: Automatic token refresh and expiration handling
- **Provider Discovery**: Automatically discover available credential providers

### Agent Identity and Access Controls
- **Impersonation Flow**: Agents access resources using provided credentials
- **Audit Trails**: Maintain audit trails for all actions performed on behalf of users
- **Request Verification**: Token signature verification, expiration checks, scope validation
- **Identity-Aware Authorization**: Pass user context to agent code for dynamic decisions

## Use Cases

### Securing AI Agent Access
Enable agents to:
- Authenticate with external services securely
- Access resources on behalf of users
- Maintain proper audit trails
- Implement least-privilege access patterns

### Multi-Provider Authentication
Support scenarios like:
- Different authentication methods for different APIs
- Unified credential management across services
- OAuth flows for user-delegated access
- API key management for service accounts

### Zero-Trust Security Models
Allow implementation of:
- No long-lived credentials in application code
- Centralized, audited credential vault
- Automated rotation to reduce attack window
- Comprehensive access logging

### Compliance and Auditing
Enable teams to:
- Generate reports for compliance audits (SOC2, ISO27001)
- Implement periodic access reviews
- Maintain secrets inventory
- Enforce credential policies

## Quick Start

### Create API Key Credential Provider

```bash
aws bedrock-agentcore-control create-api-key-credential-provider \
  --name MyAPICredentialProvider \
  --api-key "YOUR_API_KEY" \
  --region us-west-2
```

### Create OAuth Credential Provider

```bash
aws bedrock-agentcore-control create-oauth2-credential-provider \
  --name MyOAuthProvider \
  --client-id "YOUR_CLIENT_ID" \
  --client-secret "YOUR_CLIENT_SECRET" \
  --authorization-url "https://provider.com/oauth/authorize" \
  --token-url "https://provider.com/oauth/token" \
  --scopes '["read", "write"]' \
  --region us-west-2
```

### Using Credentials with SDK

```python
from bedrock_agentcore.identity import CredentialProvider

# Get credentials for external API
provider = CredentialProvider("MyAPICredentialProvider")
api_key = provider.get_api_key()

# Get OAuth token
oauth_provider = CredentialProvider("MyOAuthProvider")
token = oauth_provider.get_access_token()
```

## Common Operations

### List Credential Providers

```bash
aws bedrock-agentcore-control list-api-key-credential-providers \
  --region us-west-2
```

### Update Credential Provider

```bash
aws bedrock-agentcore-control update-api-key-credential-provider \
  --name MyAPICredentialProvider \
  --api-key "NEW_API_KEY" \
  --region us-west-2
```

### Delete Credential Provider

```bash
aws bedrock-agentcore-control delete-api-key-credential-provider \
  --name MyAPICredentialProvider \
  --region us-west-2
```

## Built-in OAuth Providers

AgentCore Identity includes built-in providers for popular services:

| Provider | Use Case |
|----------|----------|
| **Google** | Google Workspace, Gmail, Drive |
| **GitHub** | Repository access, Actions |
| **Slack** | Messaging, channel access |
| **Salesforce** | CRM data access |

## Best Practices

### Security
- Use credential providers instead of hardcoded credentials
- Implement least-privilege access for each credential
- Rotate credentials regularly (quarterly minimum)
- Monitor credential usage with CloudWatch

### Development
- Use separate credential providers per environment
- Implement proper error handling for credential access
- Test credential flows in non-production first
- Use SDK annotations for cleaner code

### Operations
- Set up alerts for credential access failures
- Audit credential usage periodically
- Implement automated rotation where possible
- Document credential ownership and purpose

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Credential not found | Provider doesn't exist or name typo | Verify provider name with list command |
| Invalid API key | Key expired or incorrect | Update credential provider with new key |
| OAuth token expired | Token refresh failed | Check OAuth provider configuration |
| Access denied | Insufficient permissions | Verify IAM policy for credential access |

## Related Services

- **[Gateway Service](../gateway/README.md)**: Uses Identity for MCP target authentication
- **[Runtime Service](../runtime/README.md)**: Uses Identity for agent authentication
- **[Memory Service](../memory/README.md)**: May use Identity for data encryption

## References

- [AWS Identity Documentation](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/identity.html)
- [Credential Provider Setup](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/identity-outbound-credential-provider.html)
- [Identity Features](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/key-features-and-benefits.html)
- [Securing AI Agents Blog](https://aws.amazon.com/blogs/security/securing-ai-agents-with-amazon-bedrock-agentcore-identity/)
