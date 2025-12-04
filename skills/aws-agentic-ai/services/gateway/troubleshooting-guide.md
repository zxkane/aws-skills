# AgentCore Gateway Troubleshooting Guide

## Quick Diagnosis

### Symptom: Target Creation Fails

**Error Message**: `"Gateway target creation failed"`

**Diagnosis Steps**:
1. Verify gateway exists
   ```bash
   aws bedrock-agentcore-control get-gateway \
     --gateway-identifier <GATEWAY_ID> \
     --profile default --region us-west-2
   ```

2. Check credential provider exists (if using API key auth)
   ```bash
   aws bedrock-agentcore-control get-api-key-credential-provider \
     --name <PROVIDER_NAME> \
     --profile default --region us-west-2
   ```

3. List existing targets
   ```bash
   aws bedrock-agentcore-control list-gateway-targets \
     --gateway-identifier <GATEWAY_ID> \
     --profile default --region us-west-2
   ```

**Common Causes**:
- Gateway ID incorrect or gateway doesn't exist
- Credential provider name misspelled (for API key auth)
- OpenAPI schema syntax error
- S3 bucket permissions issue for schema

---

## Permission Errors

### Error: "User is not authorized to perform: bedrock-agentcore:GetResourceApiKey"

**Full Error**:
```
User: arn:aws:sts::<ACCOUNT_ID>:assumed-role/GatewayServiceRole is not
authorized to perform: bedrock-agentcore:GetResourceApiKey on resource: *
```

**Root Cause**: Gateway service role missing credential provider access permissions

**Diagnosis**:
```bash
# Get gateway role ARN
GATEWAY_ROLE=$(aws bedrock-agentcore-control get-gateway \
  --gateway-identifier <GATEWAY_ID> \
  --query 'roleArn' --output text \
  --profile default --region us-west-2)

echo $GATEWAY_ROLE

# Extract role name
ROLE_NAME=$(echo $GATEWAY_ROLE | cut -d'/' -f2)

# Check attached policies
aws iam list-attached-role-policies \
  --role-name $ROLE_NAME \
  --profile default --region us-west-2
```

**Solution**: Add required permissions to gateway role:
```bash
cat > /tmp/gateway-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GetResourceApiKey",
      "Effect": "Allow",
      "Action": ["bedrock-agentcore:GetResourceApiKey"],
      "Resource": "*"
    },
    {
      "Sid": "GetWorkloadAccessToken",
      "Effect": "Allow",
      "Action": ["bedrock-agentcore:GetWorkloadAccessToken"],
      "Resource": "*"
    },
    {
      "Sid": "GetCredentials",
      "Effect": "Allow",
      "Action": ["secretsmanager:GetSecretValue"],
      "Resource": ["arn:aws:secretsmanager:us-west-2:<ACCOUNT_ID>:secret:bedrock-agentcore-identity!*"]
    }
  ]
}
EOF

# Get policy ARN from role
POLICY_ARN=$(aws iam list-attached-role-policies \
  --role-name $ROLE_NAME \
  --query 'AttachedPolicies[0].PolicyArn' \
  --output text \
  --profile default --region us-west-2)

# Create new policy version
aws iam create-policy-version \
  --policy-arn $POLICY_ARN \
  --policy-document file:///tmp/gateway-policy.json \
  --set-as-default \
  --profile default --region us-west-2
```

---

### Error: "AccessDeniedException: Secrets Manager"

**Full Error**:
```
AccessDeniedException: User: arn:aws:sts::<ACCOUNT_ID>:assumed-role/GatewayServiceRole
is not authorized to perform: secretsmanager:GetSecretValue on resource: ...
```

**Root Cause**: Gateway cannot access Secrets Manager for credential provider

**Solution**: Add `secretsmanager:GetSecretValue` permission to gateway role (see above)

---

## Credential Provider Issues

### Error: "Credential provider not found"

**Diagnosis**:
```bash
# Check if provider exists
aws bedrock-agentcore-control get-api-key-credential-provider \
  --name <PROVIDER_NAME> \
  --profile default --region us-west-2

# List all providers
aws bedrock-agentcore-control list-api-key-credential-providers \
  --profile default --region us-west-2
```

**Solution**:
```bash
# Create provider if missing
aws bedrock-agentcore-control create-api-key-credential-provider \
  --name <PROVIDER_NAME> \
  --api-key "YOUR_API_KEY" \
  --profile default --region us-west-2
```

---

### Error: "Invalid API key"

**Symptom**: API calls return 403 or authentication errors

**Diagnosis**:
```bash
# Check API key format in secret
SECRET=$(aws secretsmanager get-secret-value \
  --secret-id "arn:aws:secretsmanager:us-west-2:<ACCOUNT_ID>:secret:bedrock-agentcore-identity/default/apikeycredentialprovider/<PROVIDER_NAME>-AbCdEf" \
  --query 'SecretString' --output text \
  --profile default --region us-west-2)

echo $SECRET | jq '.'
# Should be: {"apiKey": "your-key-here"}
```

**Solution**:
```bash
# Use the correct update command (not secretsmanager put-secret-value)
aws bedrock-agentcore-control update-api-key-credential-provider \
  --name <PROVIDER_NAME> \
  --api-key "YOUR_VALID_API_KEY" \
  --profile default --region us-west-2
```

**Common Mistake**: Using `secretsmanager put-secret-value` directly bypasses credential provider validation

---

## OpenAPI Schema Issues

### Error: "Invalid OpenAPI schema"

**Diagnosis**:
```bash
# Validate OpenAPI schema locally
npm install -g @apidevtools/swagger-cli
swagger-cli validate schemas/my-api-openapi.yaml

# Check for unsupported constructs
grep -n "oneOf\|anyOf\|allOf" schemas/my-api-openapi.yaml
# These constructs are not supported in Gateway
```

**Common Issues**:
1. **oneOf/anyOf/allOf**: Not supported, use simple types
2. **Missing operationId**: All operations must have operationId
3. **Invalid $ref references**: Must point to valid components
4. **YAML syntax errors**: Use online YAML validator

**Solution**: Use OpenAPI 3.0 simple types only:
```yaml
# ❌ Bad - unsupported
schema:
  oneOf:
    - type: string
    - type: number

# ✅ Good - simple type
schema:
  type: string
```

---

### Error: "Schema size exceeds limit"

**Root Cause**: OpenAPI schema too large for Gateway

**Solutions**:
1. Remove unused endpoints from schema
2. Simplify descriptions (keep essential info only)
3. Remove redundant component definitions
4. Split into multiple targets if necessary

---

## API Call Issues

### Error: "Rate limit exceeded"

**Symptom**: API calls return 429 Too Many Requests

**Root Cause**: Gateway or upstream API rate limits

**Diagnosis**:
```bash
# Check gateway target status
aws bedrock-agentcore-control get-gateway-target \
  --gateway-identifier <GATEWAY_ID> \
  --target-identifier <TARGET_ID> \
  --profile default --region us-west-2
```

**Solutions**:
1. **Check Gateway limits**: Verify gateway quota in AWS Console
2. **Upstream API limits**: Check your API provider dashboard for limits
3. **Optimize calls**: Use embedded IDs in schema to reduce API queries
4. **Implement caching**: Cache responses when possible
5. **Request limit increase**: Contact AWS support if needed

---

### Error: "Invalid API host header"

**Root Cause**: API endpoint or host header configuration mismatch

**Diagnosis**:
```bash
# Check schema for correct server URL
grep -A5 "servers:" schemas/my-api-openapi.yaml

# Verify host header in security scheme
grep -A10 "securitySchemes:" schemas/my-api-openapi.yaml
```

**Solution**: Update OpenAPI schema with correct server URL and host header

---

### Error: "Connection timeout"

**Symptom**: Gateway target calls fail with timeout errors

**Root Cause**: Upstream API not responding within timeout limit

**Solutions**:
1. Verify upstream API is accessible
2. Check network connectivity from Gateway
3. Increase timeout in target configuration (if supported)
4. Check if upstream API requires VPC configuration

---

## Target Status Issues

### Target Status: "FAILED"

**Diagnosis**:
```bash
# Get target details including status reason
aws bedrock-agentcore-control get-gateway-target \
  --gateway-identifier <GATEWAY_ID> \
  --target-identifier <TARGET_ID> \
  --query '{status: status, statusReason: statusReason}' \
  --profile default --region us-west-2
```

**Common Status Reasons**:
- `SCHEMA_VALIDATION_FAILED`: OpenAPI schema has errors
- `CREDENTIAL_PROVIDER_NOT_FOUND`: API key provider doesn't exist
- `PERMISSION_DENIED`: IAM permissions missing

---

### Target Status: "PENDING" for too long

**Root Cause**: Target creation stuck

**Solutions**:
1. Check if all dependencies exist (gateway, credential provider)
2. Delete and recreate target
3. Check AWS service health dashboard

---

## Testing and Verification

### How to Test Target Deployment

```bash
#!/bin/bash
# test-target.sh

GATEWAY_ID=$1
TARGET_ID=$2

# Test 1: List targets
echo "Listing gateway targets..."
aws bedrock-agentcore-control list-gateway-targets \
  --gateway-identifier $GATEWAY_ID \
  --profile default --region us-west-2

# Test 2: Get target details
echo "Getting target details..."
aws bedrock-agentcore-control get-gateway-target \
  --gateway-identifier $GATEWAY_ID \
  --target-identifier $TARGET_ID \
  --profile default --region us-west-2

# Test 3: Get tools from target
echo "Getting tools..."
aws bedrock-agentcore-control get-gateway-target \
  --gateway-identifier $GATEWAY_ID \
  --target-identifier $TARGET_ID \
  --query 'tools' \
  --profile default --region us-west-2
```

---

## Common Error Summary Table

| Error | Likely Cause | Solution |
|-------|-------------|----------|
| "not authorized to perform: bedrock-agentcore:GetResourceApiKey" | Missing IAM permissions | Add permissions to gateway role |
| "Credential provider not found" | Provider doesn't exist or name typo | Create provider with `create-api-key-credential-provider` |
| "Invalid API key" | Key format wrong or key invalid | Use `update-api-key-credential-provider` to update |
| "Invalid OpenAPI schema" | Unsupported constructs (oneOf/anyOf/allOf) | Remove unsupported constructs, use simple types |
| "Invalid API host header" | Host header doesn't match endpoint | Update OpenAPI schema with correct host |
| "Rate limit exceeded" | Too many API calls | Check limits, implement caching |
| "Connection timeout" | Upstream API not responding | Verify API accessibility |
| "Target status FAILED" | Schema or credential issues | Check statusReason in get-gateway-target |

---

## Escalation Path

If issues persist after troubleshooting:

1. **Check AWS Documentation**: https://docs.aws.amazon.com/bedrock-agentcore/
2. **AWS Support**: Open case with Bedrock AgentCore service
3. **Community**: AWS Developer Forums

**Information to gather for AWS Support**:
- Gateway ID and target ID
- Error messages and timestamps
- OpenAPI schema (sanitized)
- IAM role and policy configuration
