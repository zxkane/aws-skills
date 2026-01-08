#!/bin/bash
# AgentCore Gateway Multi-Environment Deployment Script
# Template for deploying targets to multiple gateways

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

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

# Check if environment file is provided
if [ $# -eq 0 ]; then
    print_error "Environment file not provided!"
    echo "Usage: $0 <environment-file>"
    echo "Example: $0 .env.production"
    exit 1
fi

ENV_FILE=$1

# Check if environment file exists
if [ ! -f "$ENV_FILE" ]; then
    print_error "Environment file not found: $ENV_FILE"
    exit 1
fi

print_info "Loading environment from: $ENV_FILE"

# Load environment variables
export $(cat $ENV_FILE | xargs)

# Validate required environment variables
REQUIRED_VARS=("GATEWAY_IDENTIFIER" "CREDENTIAL_PROVIDER_NAME" "AWS_REGION")
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        print_error "Required environment variable not set: $var"
        exit 1
    fi
done

# Get AWS account ID
print_info "Getting AWS account ID..."
export CDK_DEFAULT_ACCOUNT=$(aws sts get-caller-identity \
  --query Account --output text \
  --profile ${AWS_PROFILE:-default})

if [ -z "$CDK_DEFAULT_ACCOUNT" ]; then
    print_error "Failed to get AWS account ID"
    exit 1
fi

print_info "Account ID: $CDK_DEFAULT_ACCOUNT"
print_info "Gateway: $GATEWAY_IDENTIFIER"
print_info "Credential Provider: $CREDENTIAL_PROVIDER_NAME"
print_info "Region: $AWS_REGION"

# Extract gateway name from identifier if not provided
if [ -z "$GATEWAY_NAME" ]; then
    # Extract prefix before first hyphen
    GATEWAY_NAME=$(echo $GATEWAY_IDENTIFIER | cut -d'-' -f1)
    export GATEWAY_NAME
    print_info "Auto-extracted gateway name: $GATEWAY_NAME"
fi

# Build project
print_info "Building project..."
npm run build

if [ $? -ne 0 ]; then
    print_error "Build failed!"
    exit 1
fi

print_info "Build successful!"

# Deploy to AWS
print_info "Deploying to AWS..."
cdk deploy --profile ${AWS_PROFILE:-default} --require-approval never

if [ $? -eq 0 ]; then
    print_info "Deployment successful!"

    # Display deployment information
    echo ""
    print_info "Deployment Details:"
    echo "  Gateway ID: $GATEWAY_IDENTIFIER"
    echo "  Stack Name: ${GATEWAY_NAME}FootballAPITarget"
    echo "  Region: $AWS_REGION"
    echo "  Credential Provider: $CREDENTIAL_PROVIDER_NAME"
    echo ""

    # Get and display target information
    print_info "Fetching target details..."
    aws bedrock-agentcore-control list-gateway-targets \
      --gateway-identifier $GATEWAY_IDENTIFIER \
      --profile ${AWS_PROFILE:-default} \
      --region $AWS_REGION

else
    print_error "Deployment failed!"
    exit 1
fi
