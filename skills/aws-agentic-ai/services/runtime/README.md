# Runtime Service

The Runtime service provides a secure, serverless hosting environment for deploying and running AI agents or tools. It handles scaling, session management, security isolation, and infrastructure management.

## Key Features

| Feature | Description |
|---------|-------------|
| **Framework Agnostic** | Works with LangGraph, Strands, CrewAI, or custom agents |
| **Model Flexibility** | Supports any LLM (Bedrock, Claude, Gemini, OpenAI) |
| **Protocol Support** | MCP (Model Context Protocol) and A2A (Agent to Agent) |
| **Session Isolation** | Dedicated microVM per session with isolated CPU, memory, filesystem |
| **Extended Execution** | Up to 8 hours for long-running workloads |
| **100MB Payloads** | Handle multimodal content (text, images, audio, video) |
| **Bidirectional Streaming** | HTTP API and WebSocket for real-time interactions |

## Quick Start

### Prerequisites
- AWS CLI configured with appropriate permissions
- Docker installed for container builds
- Python 3.9+ for SDK usage

### Deploy an Agent

**Step 1: Install AgentCore SDK**
```bash
pip install bedrock-agentcore
```

**Step 2: Create agent code**
```python
from bedrock_agentcore.runtime import BedrockAgentCoreApp

app = BedrockAgentCoreApp()

@app.handler()
async def handle_request(request, context):
    user_input = request.get("input", "")
    # Your agent logic here
    return {"response": f"Processed: {user_input}"}
```

**Step 3: Create AgentCore Runtime**
```bash
aws bedrock-agentcore-control create-agent-runtime \
  --agent-runtime-name my-agent \
  --runtime-artifact '{"containerConfiguration": {"containerUri": "<ACCOUNT_ID>.dkr.ecr.<REGION>.amazonaws.com/my-agent:latest"}}' \
  --role-arn arn:aws:iam::<ACCOUNT_ID>:role/AgentRuntimeExecutionRole \
  --network-configuration '{"networkMode": "PUBLIC"}' \
  --region us-west-2
```

**Step 4: Invoke agent**
```bash
aws bedrock-agentcore-runtime invoke-agent-runtime \
  --agent-runtime-endpoint-arn arn:aws:bedrock-agentcore:us-west-2:<ACCOUNT_ID>:runtime/my-agent/endpoint/DEFAULT \
  --payload '{"input": "Hello, agent!"}' \
  --region us-west-2
```

## Core Components

### AgentCore Runtime
Containerized application hosting your AI agent or tool code. Each runtime:
- Has a unique identity
- Is versioned for controlled deployment and updates
- Can use popular frameworks or custom implementations

### Versions
Immutable snapshots of configuration:
- Version 1 (V1) created automatically with new runtime
- Each update creates a new version
- Enables rollback capabilities

### Endpoints
Addressable access points to runtime versions:
- **DEFAULT**: Automatically created, points to latest version
- Custom endpoints for different environments (dev, test, prod)
- Unique ARN for invocation

Endpoint states: `CREATING` → `READY` (or `CREATE_FAILED`) → `UPDATING` → `READY`

### Sessions
Individual interaction contexts with complete isolation:
- Dedicated microVM per session
- Preserves context across interactions
- Persists up to 8 hours
- Auto-terminates after 15 minutes idle

Session states: `Active` → `Idle` → `Terminated`

## Authentication

### Inbound (Who Can Access Your Agent)

| Method | Description |
|--------|-------------|
| **IAM (SigV4)** | AWS credentials for identity verification |
| **OAuth 2.0** | External identity providers (Cognito, Okta, Entra ID) |

**OAuth Flow**:
1. User authenticates with identity provider
2. Client receives bearer token
3. Token passed in authorization header
4. Runtime validates token
5. Request processed or rejected

### Outbound (Accessing External Services)

| Method | Use Case |
|--------|----------|
| **OAuth** | Services supporting OAuth flows |
| **API Keys** | Key-based authentication |

**Modes**:
- **User-delegated**: Acting on behalf of end user
- **Autonomous**: Acting with service-level credentials

## Common Operations

### List Agent Runtimes
```bash
aws bedrock-agentcore-control list-agent-runtimes \
  --region us-west-2
```

### Get Runtime Details
```bash
aws bedrock-agentcore-control get-agent-runtime \
  --agent-runtime-id <RUNTIME_ID> \
  --region us-west-2
```

### Update Runtime
```bash
aws bedrock-agentcore-control update-agent-runtime \
  --agent-runtime-id <RUNTIME_ID> \
  --runtime-artifact '{"containerConfiguration": {"containerUri": "<NEW_IMAGE_URI>"}}' \
  --region us-west-2
```

### Delete Runtime
```bash
aws bedrock-agentcore-control delete-agent-runtime \
  --agent-runtime-id <RUNTIME_ID> \
  --region us-west-2
```

## Long-Running Agents

For workloads exceeding request/response cycles (up to 8 hours):

```python
from bedrock_agentcore.runtime import BedrockAgentCoreApp

app = BedrockAgentCoreApp()

@app.handler()
async def handle_request(request, context):
    # Add async task
    task_id = context.add_async_task("background-processing")

    # Start background work
    # ... long-running operation ...

    # Complete task when done
    context.complete_async_task(task_id)

    return {"status": "Task started", "task_id": task_id}
```

## Streaming Responses

Enable real-time partial results:

```python
@app.handler()
async def handle_request(request, context):
    async for chunk in generate_response(request):
        yield {"partial": chunk}
    yield {"complete": True}
```

## Supported Frameworks

| Framework | Description |
|-----------|-------------|
| **LangGraph** | Graph-based agent workflows |
| **Strands** | AWS-native agent framework |
| **CrewAI** | Multi-agent collaboration |
| **Custom** | Any Python-based agent |

## Troubleshooting

| Error | Cause | Solution |
|-------|-------|----------|
| 504 Gateway Timeout | Container issues, ARM64 compatibility | Ensure container exposes port 8080, use ARM64 image |
| 403 AccessDeniedException | Missing permissions | Verify IAM role and policies |
| exec format error | Wrong architecture | Build ARM64 containers with buildx |
| Session terminated after 15min | Idle timeout | Implement ping handler with HEALTHY_BUSY status |

## Related Services

- **[Gateway Service](../gateway/README.md)**: Expose APIs as tools for agents
- **[Memory Service](../memory/README.md)**: Store agent conversation history
- **[Identity Service](../identity/README.md)**: Manage agent credentials
- **[Observability Service](../observability/README.md)**: Monitor agent performance

## References

- [AWS Runtime Documentation](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/agents-tools-runtime.html)
- [How Runtime Works](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-how-it-works.html)
- [Runtime Troubleshooting](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/runtime-troubleshooting.html)
- [Runtime API Reference](https://docs.aws.amazon.com/bedrock-agentcore-control/latest/APIReference/)
