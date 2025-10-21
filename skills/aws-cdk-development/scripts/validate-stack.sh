#!/bin/bash

# AWS CDK Stack Validation Script
#
# This script performs comprehensive validation of CDK stacks before deployment.
# Run this as part of pre-commit checks to ensure infrastructure quality.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

echo "🔍 AWS CDK Stack Validation"
echo "============================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track validation status
VALIDATION_PASSED=true

# Function to print success
success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Function to print error
error() {
    echo -e "${RED}✗${NC} $1"
    VALIDATION_PASSED=false
}

# Function to print warning
warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Function to print info
info() {
    echo "ℹ $1"
}

# Check if cdk is installed
if ! command -v cdk &> /dev/null; then
    error "AWS CDK CLI not found. Install with: npm install -g aws-cdk"
    exit 1
fi

success "AWS CDK CLI found"

# Check for package.json
if [ ! -f "${PROJECT_ROOT}/package.json" ]; then
    error "package.json not found in project root"
    exit 1
fi

success "package.json found"

echo ""
info "Running CDK synthesis..."

# Synthesize stacks
if cdk synth --quiet > /dev/null 2>&1; then
    success "CDK synthesis successful"
else
    error "CDK synthesis failed"
    echo ""
    echo "Run 'cdk synth' for detailed error information"
    exit 1
fi

echo ""
info "Checking for common issues..."

# Check for hardcoded resource names (common anti-pattern)
if grep -r "functionName:" "${PROJECT_ROOT}/lib" 2>/dev/null | grep -v "node_modules" | grep -q "."; then
    warning "Found potential hardcoded Lambda function names (functionName:)"
    warning "Consider letting CDK generate names automatically"
fi

if grep -r "bucketName:" "${PROJECT_ROOT}/lib" 2>/dev/null | grep -v "node_modules" | grep -q "."; then
    warning "Found potential hardcoded S3 bucket names (bucketName:)"
    warning "Consider letting CDK generate names automatically"
fi

if grep -r "tableName:" "${PROJECT_ROOT}/lib" 2>/dev/null | grep -v "node_modules" | grep -q "."; then
    warning "Found potential hardcoded DynamoDB table names (tableName:)"
    warning "Consider letting CDK generate names automatically"
fi

# Check for overly broad IAM permissions
if grep -r "actions: \['\*'\]" "${PROJECT_ROOT}/lib" 2>/dev/null | grep -v "node_modules" | grep -q "."; then
    warning "Found overly broad IAM permissions (actions: ['*'])"
    warning "Use grant methods for least privilege access"
fi

if grep -r "resources: \['\*'\]" "${PROJECT_ROOT}/lib" 2>/dev/null | grep -v "node_modules" | grep -q "."; then
    warning "Found overly broad IAM resources (resources: ['*'])"
    warning "Specify explicit resource ARNs when possible"
fi

# Check for L1 constructs (CfnXxx) which might indicate lower-level usage
L1_COUNT=$(grep -r "new Cfn" "${PROJECT_ROOT}/lib" 2>/dev/null | grep -v "node_modules" | grep -v "CfnOutput" | wc -l || echo 0)
if [ "$L1_COUNT" -gt 0 ]; then
    warning "Found ${L1_COUNT} L1 (Cfn*) construct(s)"
    warning "Consider using higher-level L2/L3 constructs when available"
fi

# Check if Lambda functions use proper constructs
if grep -r "new lambda.Function" "${PROJECT_ROOT}/lib" 2>/dev/null | grep -v "node_modules" | grep -q "."; then
    warning "Found lambda.Function usage"
    warning "Consider using NodejsFunction or PythonFunction for automatic bundling"
fi

success "Common issue checks completed"

echo ""
info "Checking synthesized templates..."

# Get list of synthesized templates
TEMPLATES=$(find "${PROJECT_ROOT}/cdk.out" -name "*.template.json" 2>/dev/null || echo "")

if [ -z "$TEMPLATES" ]; then
    error "No CloudFormation templates found in cdk.out/"
    exit 1
fi

TEMPLATE_COUNT=$(echo "$TEMPLATES" | wc -l)
success "Found ${TEMPLATE_COUNT} CloudFormation template(s)"

# Validate each template
for template in $TEMPLATES; do
    STACK_NAME=$(basename "$template" .template.json)

    # Check template size
    TEMPLATE_SIZE=$(wc -c < "$template")
    MAX_SIZE=51200 # 50KB warning threshold

    if [ "$TEMPLATE_SIZE" -gt "$MAX_SIZE" ]; then
        warning "${STACK_NAME}: Template size (${TEMPLATE_SIZE} bytes) is large"
        warning "Consider using nested stacks to reduce size"
    fi

    # Count resources
    RESOURCE_COUNT=$(jq '.Resources | length' "$template" 2>/dev/null || echo 0)

    if [ "$RESOURCE_COUNT" -gt 200 ]; then
        warning "${STACK_NAME}: High resource count (${RESOURCE_COUNT})"
        warning "Consider splitting into multiple stacks"
    else
        success "${STACK_NAME}: ${RESOURCE_COUNT} resources"
    fi
done

echo ""
echo "============================"

if [ "$VALIDATION_PASSED" = true ]; then
    echo -e "${GREEN}✓ Validation passed${NC}"
    echo ""
    info "Stack is ready for deployment"
    exit 0
else
    echo -e "${RED}✗ Validation failed${NC}"
    echo ""
    error "Please fix the errors above before deploying"
    exit 1
fi
