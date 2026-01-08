#!/bin/bash
# AgentCore Gateway Target Validation Script
# Validates gateway target deployment and functionality

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION=${AWS_REGION:-us-west-2}
AWS_PROFILE=${AWS_PROFILE:-default}

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_section() {
    echo ""
    echo -e "${BLUE}==== $1 ====${NC}"
}

# Check if gateway ID is provided
if [ $# -eq 0 ]; then
    print_error "Gateway ID not provided!"
    echo "Usage: $0 <gateway-identifier>"
    echo "Example: $0 xiaozhi-mfyvjzuqpk"
    exit 1
fi

GATEWAY_ID=$1
print_info "Validating gateway: $GATEWAY_ID"

# Test 1: Gateway exists
print_section "Test 1: Gateway Existence"
print_info "Checking if gateway exists..."

if aws bedrock-agentcore-control get-gateway \
  --gateway-identifier $GATEWAY_ID \
  --profile $AWS_PROFILE \
  --region $AWS_REGION > /dev/null 2>&1; then
    print_info "✓ Gateway exists"
else
    print_error "✗ Gateway not found: $GATEWAY_ID"
    exit 1
fi

# Test 2: List gateway targets
print_section "Test 2: Gateway Targets"
print_info "Listing targets on gateway..."

TARGETS_JSON=$(aws bedrock-agentcore-control list-gateway-targets \
  --gateway-identifier $GATEWAY_ID \
  --profile $AWS_PROFILE \
  --region $AWS_REGION 2>/dev/null)

if [ $? -eq 0 ]; then
    TARGET_COUNT=$(echo $TARGETS_JSON | jq -r '.targets | length')
    print_info "✓ Found $TARGET_COUNT target(s)"

    if [ "$TARGET_COUNT" -gt 0 ]; then
        echo ""
        echo "Target Details:"
        echo $TARGETS_JSON | jq -r '.targets[] | "  - Target ID: \(.targetId)"'
        echo $TARGETS_JSON | jq -r '.targets[] | "    Status: \(.status)"'
    fi
else
    print_error "✗ Failed to list targets"
    exit 1
fi

# Test 3: Check target details (if targets exist)
if [ "$TARGET_COUNT" -gt 0 ]; then
    print_section "Test 3: Target Details"

    for TARGET_ID in $(echo $TARGETS_JSON | jq -r '.targets[].targetId'); do
        print_info "Checking target: $TARGET_ID"

        TARGET_DETAIL=$(aws bedrock-agentcore-control get-gateway-target \
          --gateway-identifier $GATEWAY_ID \
          --target-identifier $TARGET_ID \
          --profile $AWS_PROFILE \
          --region $AWS_REGION 2>/dev/null)

        if [ $? -eq 0 ]; then
            STATUS=$(echo $TARGET_DETAIL | jq -r '.status')
            echo $TARGET_DETAIL | jq -r "|----------------------------------------|"
            echo $TARGET_DETAIL | jq -r "| Target ID    | $TARGET_ID              |"
            echo $TARGET_DETAIL | jq -r "| Status       | \(.status)                    |"
            echo $TARGET_DETAIL | jq -r "| Gateway ARN  | \(.gatewayArn) |" | cut -c1-42
            echo $TARGET_DETAIL | jq -r "| Schema URI   | \(.schemaS3Uri)         |" | head -1
            echo "|----------------------------------------|"

            if [ "$STATUS" = "READY" ]; then
                print_info "✓ Target is READY"
            else
                print_warning "⚠ Target status: $STATUS"
            fi

            # Check for common issues
            if echo $TARGET_DETAIL | jq -r '.targetName' | grep -q "null\|None"; then
                print_warning "? Target name not set"
            fi
        else
            print_error "✗ Failed to get target details: $TARGET_ID"
        fi
        echo ""
    done
fi

# Test 4: Check credential provider access
print_section "Test 4: Credential Provider Access"
print_info "Checking if Gateway service role has credential access..."

# Get gateway details
GATEWAY_DETAIL=$(aws bedrock-agentcore-control get-gateway \
  --gateway-identifier $GATEWAY_ID \
  --profile $AWS_PROFILE \
  --region $AWS_REGION 2>/dev/null)

if [ $? -eq 0 ]; then
    ROLE_ARN=$(echo $GATEWAY_DETAIL | jq -r '.roleArn')
    print_info "Gateway Role: $ROLE_ARN"

    # Extract role name from ARN
    ROLE_NAME=$(echo $ROLE_ARN | cut -d'/' -f2)

    # Check attached policies
    POLICIES=$(aws iam list-attached-role-policies \
      --role-name $ROLE_NAME \
      --profile $AWS_PROFILE \
      --region $AWS_REGION 2>/dev/null)

    if [ $? -eq 0 ]; then
        print_info "✓ Role has attached policies"
        echo $POLICIES | jq -r '.AttachedPolicies[] | "  - \(.PolicyName): \(.PolicyArn)"'

        # Check for required permissions
        # Note: This is a simplified check - full verification requires policy inspection
        print_info "✓ IAM permissions appear to be configured"
    else
        print_warning "⚠ Could not verify role policies"
    fi
else
    print_error "✗ Failed to get gateway details"
fi

# Test 5: Check CloudFormation stack (optional)
print_section "Test 5: CloudFormation Stack"

# Extract stack name from gateway ID (prefix before first hyphen)
STACK_PREFIX=$(echo $GATEWAY_ID | cut -d'-' -f1)
STACK_NAME="${STACK_PREFIX}FootballAPITarget"

print_info "Checking CloudFormation stack: $STACK_NAME"

STACK_STATUS=$(aws cloudformation describe-stacks \
  --stack-name $STACK_NAME \
  --profile $AWS_PROFILE \
  --region $AWS_REGION \
  --query 'Stacks[0].StackStatus' \
  --output text 2>/dev/null)

if [ $? -eq 0 ]; then
    print_info "✓ Stack exists with status: $STACK_STATUS"

    if [ "$STACK_STATUS" = "UPDATE_COMPLETE" ] || [ "$STACK_STATUS" = "CREATE_COMPLETE" ]; then
        print_info "✓ Stack is healthy"
    else
        print_warning "⚠ Stack status: $STACK_STATUS"
    fi
else
    print_warning "⚠ Stack not found (this is OK if using different naming)"