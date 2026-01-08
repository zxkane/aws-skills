# AgentCore Observability Service

> **Status**: ✅ Available

## Overview

Amazon Bedrock AgentCore Observability helps developers trace, debug, and monitor agent performance in production through unified operational dashboards and OpenTelemetry-compatible telemetry.

## Core Capabilities

### Distributed Tracing
- **End-to-End Tracing**: Complete request tracing across all AgentCore services
- **Workflow Visualization**: Detailed step-by-step workflow execution views
- **Service Dependencies**: Automatic mapping of service interactions
- **Bottleneck Detection**: Identify performance bottlenecks in agent workflows
- **Error Attribution**: Pinpoint exact failure points in complex workflows

### Metrics and Monitoring
- **Real-Time Metrics**: Live operational metrics for all agent activities
- **Token Tracking**: Monitor token consumption and costs
- **Latency Measurements**: Track P50, P95, P99 response times
- **Session Monitoring**: Track session duration and status
- **Error Rates**: Monitor error rates by service and operation
- **Throughput**: Measure requests per second and operation counts

### Logging
- **Centralized Aggregation**: All service logs in one place
- **Structured Logging**: Consistent log format with correlation IDs
- **Search and Filter**: Query logs by service, operation, or time
- **Real-Time Streaming**: Live log tailing for debugging
- **Log Retention**: Configurable retention policies

### Dashboards and Alerting
- **Unified Dashboards**: Pre-built operational dashboards
- **Custom Metrics**: Define and visualize custom metrics
- **CloudWatch Integration**: Native AWS CloudWatch support
- **Configurable Alerts**: Set up alerts for critical conditions
- **Multi-Service Views**: Consolidated view across all services

### OpenTelemetry Support
- **Industry Standard**: Compatible with OpenTelemetry specification
- **Tool Integration**: Works with existing observability tools
- **Custom Instrumentation**: Add custom traces and metrics
- **External Export**: Export telemetry to external systems

## Use Cases

### Production Debugging
Enable teams to:
- Debug agent execution issues in real-time
- Identify root causes of failures quickly
- Trace request flows across services
- Analyze error patterns and trends

### Performance Monitoring
Support scenarios like:
- Monitor agent response times
- Track token usage and costs
- Identify slow operations
- Optimize agent workflows

### Behavior Analysis
Allow teams to:
- Analyze agent behavior patterns
- Understand user interaction flows
- Identify usage trends
- Detect anomalies

### Quality Assurance
Enable teams to:
- Ensure SLA compliance
- Monitor service reliability
- Track quality metrics
- Validate performance standards

### Capacity Planning
Support activities like:
- Forecast resource needs
- Identify scaling requirements
- Optimize resource allocation
- Plan for growth

## Architecture

### Observability Data Flow

```
┌─────────────────────────────────────────┐
│  AgentCore Services                     │
│  - Gateway, Runtime, Memory, etc.       │
│  - Emit traces, logs, metrics           │
└─────────────────────────────────────────┘
           ↓
┌─────────────────────────────────────────┐
│  OpenTelemetry Collector                │
│  - Receive telemetry data               │
│  - Process and enrich                   │
│  - Route to destinations                │
└─────────────────────────────────────────┘
           ↓
    ┌──────┴──────┐
    ↓             ↓
┌─────────┐  ┌─────────────┐
│CloudWatch│  │  X-Ray      │
│ Logs    │  │  Traces     │
│ Metrics │  │  Service Map│
└─────────┘  └─────────────┘
    ↓             ↓
┌─────────────────────────────────────────┐
│  Unified Dashboards                     │
│  - Service health                       │
│  - Performance metrics                  │
│  - Error analysis                       │
│  - Cost tracking                        │
└─────────────────────────────────────────┘
```

### Data Collection Model

1. **Automatic Instrumentation**: Built-in instrumentation for all services
2. **Context Propagation**: Correlation IDs passed across service boundaries
3. **Sampling**: Intelligent sampling for high-volume operations
4. **Buffering**: Local buffering for reliability
5. **Batch Export**: Efficient batch transmission to backends

## Configuration

### Enable Observability

```bash
# Enable observability for agent
aws bedrock-agentcore-control update-observability-config \
  --agent-id <AGENT_ID> \
  --config '{
    "tracing": {
      "enabled": true,
      "samplingRate": 1.0
    },
    "metrics": {
      "enabled": true,
      "interval": 60
    },
    "logging": {
      "enabled": true,
      "level": "INFO"
    }
  }' \
  --region <REGION>
```

### Configure Sampling

```bash
# Set trace sampling rate
aws bedrock-agentcore-control update-tracing-config \
  --agent-id <AGENT_ID> \
  --sampling-rate 0.1 \
  --region <REGION>
```

### Custom Metrics

```bash
# Define custom metric
aws bedrock-agentcore-control create-custom-metric \
  --agent-id <AGENT_ID> \
  --metric-name "CustomOperationCount" \
  --metric-type "Counter" \
  --description "Count of custom operations" \
  --region <REGION>
```

## Traces

### View Traces

```bash
# Query recent traces
aws xray get-trace-summaries \
  --start-time <START_TIMESTAMP> \
  --end-time <END_TIMESTAMP> \
  --filter-expression 'service(id(name: "AgentCore", type: "AWS::Service"))'
```

### Trace Details

```bash
# Get specific trace
aws xray batch-get-traces \
  --trace-ids <TRACE_ID_1> <TRACE_ID_2>
```

### Service Map

```bash
# Get service map
aws xray get-service-graph \
  --start-time <START_TIMESTAMP> \
  --end-time <END_TIMESTAMP>
```

## Metrics

### Common Metrics

**Gateway Metrics**:
- `TargetInvocations`: Number of target invocations
- `TargetErrors`: Number of target errors
- `TargetLatency`: Target response latency

**Runtime Metrics**:
- `AgentExecutions`: Number of agent executions
- `ExecutionDuration`: Agent execution duration
- `ExecutionErrors`: Number of execution failures

**Memory Metrics**:
- `MemoryReads`: Number of memory read operations
- `MemoryWrites`: Number of memory write operations
- `MemorySize`: Total memory storage size

**Token Metrics**:
- `TokensConsumed`: Total tokens used
- `TokenCost`: Estimated cost in dollars

### Query Metrics

```bash
# Get metric statistics
aws cloudwatch get-metric-statistics \
  --namespace AWS/BedrockAgentCore \
  --metric-name TargetInvocations \
  --dimensions Name=AgentId,Value=<AGENT_ID> \
  --start-time <START> \
  --end-time <END> \
  --period 300 \
  --statistics Sum Average
```

### Custom Metrics

```bash
# Put custom metric data
aws cloudwatch put-metric-data \
  --namespace AgentCore/Custom \
  --metric-name CustomMetric \
  --value 1.0 \
  --dimensions AgentId=<AGENT_ID>
```

## Logs

### Query Logs

```bash
# Tail agent logs
aws logs tail /aws/bedrock-agentcore/<AGENT_ID> \
  --follow \
  --format short

# Query logs with filter
aws logs filter-log-events \
  --log-group-name /aws/bedrock-agentcore/<AGENT_ID> \
  --filter-pattern "ERROR" \
  --start-time <TIMESTAMP>
```

### Log Insights

```bash
# Run Insights query
aws logs start-query \
  --log-group-name /aws/bedrock-agentcore/<AGENT_ID> \
  --start-time <START_TIMESTAMP> \
  --end-time <END_TIMESTAMP> \
  --query-string 'fields @timestamp, @message
    | filter @message like /ERROR/
    | sort @timestamp desc
    | limit 20'
```

## Dashboards

### Create Dashboard

```bash
# Create CloudWatch dashboard
aws cloudwatch put-dashboard \
  --dashboard-name AgentCore-<AGENT_ID> \
  --dashboard-body file://dashboard-definition.json
```

### Dashboard Definition Example

```json
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/BedrockAgentCore", "TargetInvocations", {"stat": "Sum"}]
        ],
        "period": 300,
        "stat": "Sum",
        "region": "us-west-2",
        "title": "Target Invocations"
      }
    },
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/BedrockAgentCore", "TargetErrors", {"stat": "Sum"}]
        ],
        "period": 300,
        "stat": "Sum",
        "region": "us-west-2",
        "title": "Target Errors"
      }
    }
  ]
}
```

## Alerting

### Create Alarm

```bash
# Create CloudWatch alarm
aws cloudwatch put-metric-alarm \
  --alarm-name high-error-rate-<AGENT_ID> \
  --alarm-description "Alert when error rate exceeds threshold" \
  --metric-name TargetErrors \
  --namespace AWS/BedrockAgentCore \
  --statistic Sum \
  --period 300 \
  --evaluation-periods 2 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=AgentId,Value=<AGENT_ID> \
  --alarm-actions <SNS_TOPIC_ARN>
```

### Alarm Templates

**High Error Rate**:
```bash
# Alert on >5% error rate
aws cloudwatch put-metric-alarm \
  --alarm-name error-rate-high \
  --metric-name ErrorRate \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold
```

**High Latency**:
```bash
# Alert on P95 latency >2s
aws cloudwatch put-metric-alarm \
  --alarm-name latency-high \
  --metric-name TargetLatency \
  --statistic p95 \
  --threshold 2000 \
  --comparison-operator GreaterThanThreshold
```

**High Token Usage**:
```bash
# Alert on excessive token usage
aws cloudwatch put-metric-alarm \
  --alarm-name tokens-high \
  --metric-name TokensConsumed \
  --statistic Sum \
  --threshold 1000000 \
  --comparison-operator GreaterThanThreshold
```

## Best Practices

### Instrumentation
- Enable observability for all production agents
- Use appropriate sampling rates (1.0 for dev, 0.1 for prod)
- Add custom metrics for business-critical operations
- Include context in log messages
- Use structured logging formats

### Performance
- Use appropriate metric aggregation periods
- Implement metric sampling for high-volume operations
- Set reasonable log retention periods
- Use log filtering to reduce noise
- Archive old traces and logs

### Cost Optimization
- Adjust sampling rates based on traffic
- Use metric filters to create custom metrics
- Set appropriate log retention (7-30 days)
- Archive infrequently accessed data to S3
- Use CloudWatch Insights for complex queries

### Alerting
- Define clear SLOs and SLIs
- Set meaningful alert thresholds
- Avoid alert fatigue with proper tuning
- Use composite alarms for complex conditions
- Implement escalation policies

### Security
- Encrypt logs and metrics at rest
- Use IAM for access control
- Implement least privilege access
- Audit observability data access
- Protect sensitive data in logs

## Integration Patterns

### With All Services

Observability is automatically integrated with all AgentCore services:

```
Gateway ──→ Observability
Runtime ──→ Observability
Memory ──→ Observability
Identity ──→ Observability
Code Interpreter ──→ Observability
Browser ──→ Observability
```

### With External Tools

Export telemetry to external observability platforms:

```
AgentCore Observability
    ↓
OpenTelemetry Collector
    ↓
┌────────┬────────┬────────┐
│Datadog │New Relic│Grafana│
└────────┴────────┴────────┘
```

## Troubleshooting

### No Traces Appearing

**Diagnosis**:
```bash
# Check if tracing is enabled
aws bedrock-agentcore-control get-observability-config \
  --agent-id <AGENT_ID>
```

**Solution**: Enable tracing in observability configuration

### High Cardinality Metrics

**Symptom**: Too many unique metric combinations
**Solution**: Reduce dimension cardinality, use metric filters

### Missing Logs

**Diagnosis**:
```bash
# Check log group exists
aws logs describe-log-groups \
  --log-group-name-prefix /aws/bedrock-agentcore
```

**Solution**: Verify IAM permissions for CloudWatch Logs

### High Costs

**Symptom**: Excessive CloudWatch costs
**Solution**: Adjust sampling rates, reduce log retention, archive old data

## Performance Monitoring

### Key Performance Indicators

**Availability**:
- Service uptime percentage
- Error rate by service
- Failed request percentage

**Performance**:
- P50, P95, P99 latency
- Request throughput
- Operation duration

**Efficiency**:
- Token consumption rate
- Cost per operation
- Resource utilization

**Quality**:
- Agent success rate
- User satisfaction metrics
- Workflow completion rate

## Additional Resources

- **AWS Documentation**: [Bedrock AgentCore Observability](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/observability.html)
- **CloudWatch Guide**: [CloudWatch User Guide](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/)
- **X-Ray Guide**: [AWS X-Ray Developer Guide](https://docs.aws.amazon.com/xray/latest/devguide/)
- **OpenTelemetry**: [OpenTelemetry Documentation](https://opentelemetry.io/docs/)
- **Best Practices**: [Observability Best Practices](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/observability-best-practices.html)

---

**Related Services**:
- [Gateway Service](../gateway/README.md) - Gateway monitoring
- [Runtime Service](../runtime/README.md) - Runtime tracing
- [Memory Service](../memory/README.md) - Memory metrics
- [Credential Management](../../cross-service/credential-management.md) - Cross-service credential patterns
