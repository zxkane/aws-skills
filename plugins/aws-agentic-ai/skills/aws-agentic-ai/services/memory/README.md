# AgentCore Memory Service

> **Status**: ✅ Available

## Overview

Amazon Bedrock AgentCore Memory is a fully managed service that gives AI agents the ability to remember past interactions, enabling more intelligent, context-aware, and personalized conversations. It addresses a fundamental challenge in agentic AI: statelessness. Without memory capabilities, AI agents treat each interaction as a new instance with no knowledge of previous conversations.

## Memory Types

AgentCore Memory offers two types of memory that work together:

### Short-Term Memory
Captures turn-by-turn interactions within a single session, allowing agents to maintain immediate context without requiring users to repeat information.

**Example**: When a user asks "What's the weather like in Seattle?" and follows up with "What about tomorrow?", the agent relies on recent conversation history to understand that "tomorrow" refers to Seattle weather.

### Long-Term Memory
Automatically extracts and stores key insights from conversations across multiple sessions, including user preferences, important facts, and session summaries for persistent knowledge retention.

**Example**: If a customer mentions they prefer window seats during flight booking, the agent stores this preference and proactively offers window seats in future interactions.

## Core Capabilities

### Memory Resource Management
- **Logical Containers**: Encapsulate both raw events and processed long-term memories
- **Retention Policies**: Define how long data is retained
- **Security Configuration**: Control access and encryption
- **Data Transformation**: Transform raw interactions into meaningful insights

### Short-Term Memory Features
- **Event Storage**: Store conversations, system events, and state changes as immutable events
- **Session Organization**: Organize by actor and session
- **Context Preservation**: Maintain immediate context within sessions
- **Structured Storage**: Support structured storage of interaction data

### Long-Term Memory Features
- **Insight Extraction**: Automatically extract insights, preferences, and knowledge
- **Asynchronous Processing**: Extract memories asynchronously using memory strategies
- **Cross-Session Persistence**: Retain information across multiple sessions
- **Semantic Search**: Search memories by meaning and context

### Memory Strategies
Define the intelligence layer that transforms raw events into meaningful memories:

| Strategy | Description |
|----------|-------------|
| **Semantic** | Extract meaningful facts and information |
| **Summary** | Generate conversation summaries |
| **User Preference** | Extract and store user preferences |
| **Custom** | Define custom extraction logic |

### Advanced Features
- **Branching**: Create alternative conversation paths from specific points
- **Checkpointing**: Save and mark specific states for later reference
- **Memory Consolidation**: Merge related memories without duplicates
- **Audit Trail**: Immutable audit trail for all memory operations

## Use Cases

### Conversational Agents
Enable chatbots to:
- Remember previous issues and preferences
- Provide relevant assistance based on history
- Create personalized customer experiences
- Maintain context across session breaks

### Task-Oriented Agents
Support workflows like:
- Track multi-step business process status
- Maintain workflow progress across sessions
- Remember task context for resumption
- Store intermediate results

### Multi-Agent Systems
Allow agent teams to:
- Share memory for synchronized operations
- Coordinate inventory levels and logistics
- Maintain shared context
- Optimize collaborative workflows

### Autonomous Agents
Enable agents to:
- Plan routes based on past experiences
- Learn from previous interactions
- Improve decision-making over time
- Build persistent knowledge bases

## Quick Start

### Create Memory Resource

```bash
aws bedrock-agentcore-control create-memory \
  --memory-name my-agent-memory \
  --memory-strategies '[{"strategyName": "SEMANTIC", "configuration": {}}]' \
  --region us-west-2
```

### Using Memory with SDK

```python
from bedrock_agentcore.memory import MemoryClient

# Initialize memory client
memory = MemoryClient(memory_id="my-agent-memory")

# Add short-term memory event
memory.add_event(
    session_id="session-123",
    actor_id="user-456",
    event_type="message",
    content={"role": "user", "message": "Book a flight to Seattle"}
)

# Retrieve conversation history
history = memory.get_session_events(session_id="session-123")

# Search long-term memories
memories = memory.search_memories(
    query="user flight preferences",
    limit=5
)
```

### Store and Retrieve Memories

```python
# Store long-term memory
memory.store_memory(
    memory_type="user_preference",
    content={"preference": "window_seat", "context": "flights"}
)

# Retrieve relevant memories
relevant = memory.search_memories(
    query="seating preferences for flights",
    actor_id="user-456"
)
```

## Common Operations

### List Memories

```bash
aws bedrock-agentcore-control list-memories \
  --region us-west-2
```

### Get Memory Details

```bash
aws bedrock-agentcore-control get-memory \
  --memory-id <MEMORY_ID> \
  --region us-west-2
```

### Update Memory Configuration

```bash
aws bedrock-agentcore-control update-memory \
  --memory-id <MEMORY_ID> \
  --memory-strategies '[{"strategyName": "SEMANTIC"}, {"strategyName": "USER_PREFERENCE"}]' \
  --region us-west-2
```

### Delete Memory

```bash
aws bedrock-agentcore-control delete-memory \
  --memory-id <MEMORY_ID> \
  --region us-west-2
```

## Memory Strategies Configuration

### Built-in Strategies

```bash
# Use semantic strategy
aws bedrock-agentcore-control create-memory \
  --memory-name semantic-memory \
  --memory-strategies '[{
    "strategyName": "SEMANTIC",
    "configuration": {}
  }]'
```

### Custom Strategies

```bash
# Create custom strategy with specific model
aws bedrock-agentcore-control create-memory \
  --memory-name custom-memory \
  --memory-strategies '[{
    "strategyName": "CUSTOM",
    "configuration": {
      "modelId": "anthropic.claude-3-sonnet",
      "extractionPrompt": "Extract key user preferences from this conversation"
    }
  }]'
```

## Best Practices

### Memory Architecture
- Design memory architecture intentionally
- Choose appropriate strategies for use case
- Implement proper retention policies
- Consider memory costs and storage

### Performance
- Use appropriate time-to-live settings
- Extract only relevant information
- Implement rhythm of memory operations
- Monitor memory search latency

### Security
- Implement proper access controls
- Encrypt sensitive memories
- Audit memory access
- Follow data privacy regulations (GDPR, HIPAA)

### Operations
- Monitor memory usage and costs
- Set up alerts for memory failures
- Implement backup strategies
- Test memory operations regularly

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Memory not found | Incorrect memory ID | Verify memory ID with list command |
| Search returns empty | No matching memories | Check query and memory content |
| Slow memory retrieval | Large memory size | Implement pagination and filters |
| Strategy extraction fails | Invalid configuration | Check strategy configuration |

## Related Services

- **[Gateway Service](../gateway/README.md)**: Expose APIs as tools for agents
- **[Runtime Service](../runtime/README.md)**: Execute agents that generate conversation data
- **[Identity Service](../identity/README.md)**: Secure access to conversation data
- **[Observability Service](../observability/README.md)**: Monitor memory operations

## References

- [AWS Memory Documentation](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/memory.html)
- [Memory Types](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/memory-types.html)
- [Memory Strategies](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/memory-strategies.html)
- [Building Context-Aware Agents Blog](https://aws.amazon.com/blogs/machine-learning/amazon-bedrock-agentcore-memory-building-context-aware-agents/)
- [Long-Term Memory Deep Dive](https://aws.amazon.com/blogs/machine-learning/building-smarter-ai-agents-agentcore-long-term-memory-deep-dive/)
