---
marp: true
theme: gaia
paginate: true
size: 16:9
math: katex
style: |
  :root {
    --color-background: rgb(55, 114, 153);
    --color-foreground: #333;
    --color-highlight: #f96;
    --color-dimmed: #888;
  }
  section {
    background-color: #0f172a;
    color: #f1f5f9;
  }
  h1, h2, h3 {
    color: #38bdf8;
  }
  h2 {
    font-size: 1em;
  }
  pre, code {
    background-color: #1e293b;
    padding: 20px 6px;
    border-radius: 3px;
    font-size: 25px;
  }
  table {
    font-size: 0.78em;
  }
  .columns {
    display: grid;
    grid-template-columns: 1fr 2fr;
    gap: 30px;
  }
  ul {
    font-size: 0.7em;
  }
---

# 🛡️ Azure Zone Resiliency

### Two zones or three?

**Author:** Sylvain Riquen, Cloud Technical Architect  
**Date:** September 2026  
**Audience:** Development teams learning Azure design and implementation

---

<style scoped>
  blockquote {
    margin-bottom: 50px;
    font-size: 26px;
  }
</style>

# 📦 The problem

> A production zone is unavailable. Does the workload keep serving users, protecting data, and recovering cleanly?

## The common answer

- “Use all three availability zones.”
- “Add more replicas.”
- “The platform handles it.”

## The engineering answer

- Define the failure we must absorb.
- Evaluate every critical component.
- Prove the post-failure operating state.

---

# 📚 What we will learn

1. What availability zones protect against
2. Zonal versus zone-redundant resources
3. A component-level decision framework
4. When two zones are enough
5. When three zones earn their keep
6. Capacity planning after a zone loss
7. How developers implement and test the design
8. A hands-on architecture challenge

---

<style scoped>
  h2 {
    font-size: 26px;
    margin-top: 25px;
  }
  ul {
    font-size: 20px;
  }
  pre, code {
    font-size: 14px;
    padding: 5px;
  }
</style>

# 🌐 What zones protect against

```
Azure region
├── Availability Zone 1
│   ├── independent power
│   ├── independent cooling
│   └── independent networking
├── Availability Zone 2
└── Availability Zone 3
```

## Availability zones help with

- A failure isolated to one zone
- Planned maintenance impact
- Localized power, cooling, or network faults

## Availability zones do not provide

- Protection from a full regional outage
- Automatic application failover for every resource
- A substitute for backup, recovery, or multi-region DR

---

<style scoped>
  pre, code {
    font-size: 16px;
    padding: 10px;
  }
</style>

# 🔀 Two deployment models

## Zonal resource

<div class="columns">
<div>

```text
Your app
   ↓
Zone 2 resource
```

</div>
<div>

- Pinned to one zone
- You deploy instances in other zones
- You own routing, health, replication, and recovery

</div>
</div>

## Zone-redundant resource
<div class="columns">
<div>

```text
Your app
   ↓
Azure-managed resource
   ├── Zone 1
   ├── Zone 2
   └── Zone 3
```

</div>
<div>

- Azure manages placement or replication
- Failover behavior is service-specific
- Prefer it when it meets your requirements

</div>
</div>

---

<style scoped>
  h1 {
    font-size: 51px;
  }
  h2 {
    font-size: 26px;
    margin-top: 25px;
  }
  ul {
    font-size: 20px;
  }
  blockquote {
    font-size: 24px;
    padding: 5px;
  }
</style>

# 🎯 Do not choose one number for the workload

A workload is a set of components with different failure behavior.

```text
Critical flow: Checkout

Client → Front Door → API → Queue → Order database
                         ↘ Cache
```

## Ask these questions per component

- Can the remaining capacity serve the required operating state?
- Does correctness depend on a third failure domain?
- Can Azure manage zone redundancy for us?
- How will the component be detected, failed over, recovered, and tested?

> Zone resiliency is a set of component-level decisions, not a workload-wide switch.

---

# 🧭 The decision framework

```text
For each critical component:

1. Is zone redundancy service-managed?
   └─ Yes: validate it meets RTO, RPO, capacity, and durability needs.

2. If customer-managed, can two zones meet the objective?
   └─ Validate routing, capacity, latency, failover, and operations.

3. If not, what specifically requires three zones?
   └─ Capacity, durability, quorum, consensus, or leader election.

4. Document the decision and test the failure behavior.
```

---

<style scoped>
  h2 {
    font-size: 30px;
    margin-top: 25px;
  }
  p {
    font-size: 26px;
  }
  blockquote {
    font-size: 20px;
    margin-top: 50px;
  }
</style>

# ⚖️ The three dimensions

## 1. Resource availability

Can the remaining zone or zones support the required state after one zone fails?

## 2. Data consistency and durability

Does correctness require a third failure domain, a witness, or three replicas?

## 3. Cost and capacity

What total capacity and operational effort are needed to meet the objective?

> Define the resiliency objective first. Optimize cost second.

---

# ✅ When two zones are enough

Two zones can meet a single-zone failure objective when:

- The component is stateless or easily replaced.
- Traffic can route to the surviving zone.
- A tested active-active or active-passive pair is sufficient.
- The remaining zone can support the approved degraded state.
- Synchronous latency stays within the application budget.
- Monitoring, failover, recovery, and failback are automated and tested.

```text
Zone 1: API instance ─┐
                      ├─ Load balancer → users
Zone 2: API instance ─┘

Zone 1 fails → route 100% to Zone 2
```

---

<style scoped>
  ul, p {
    font-size: 24px;
  }
  pre, code {
    font-size: 18px;
    padding: 5px;
  }
  blockquote {
    font-size: 20px;
    margin-top: 50px;
    margin-bottom: 50px;
  }
</style>

# 🧱 When three zones are required

Three zones are justified when two zones cannot meet the component requirement:

- A two-zone design cannot carry the required post-failure capacity.
- Durability depends on placement across three failure domains.
- Quorum, consensus, or leader election requires a third domain.
- A witness or tie-breaker is needed to prevent split-brain.
- The service's supported replication model requires three zones.

> Three replicas are not the same as three failure domains.

```text
3 replicas across 2 zones ≠ 3 independent failure domains

Zone 1: Replica A + Replica B  ← majority can disappear
Zone 2: Replica C
```

---

<style scoped>
  h1 {
    font-size: 55px;
  }
  h2 {
    font-size: 34px;
  }
  ul, p {
    font-size: 24px;
  }
</style>

# 💾 Stateful systems need sharper questions

For a database, queue, or cluster, validate:

- Replica count and physical placement
- Synchronous versus asynchronous replication
- Quorum and majority behavior
- Leader election and split-brain prevention
- Recovery and failback behavior
- RTO, RPO, consistency, and durability
- Whether the managed service owns these mechanisms

## Developer takeaway

Do not infer resilience from a replica count alone. Read the service guidance for the selected region, SKU, tier, and configuration.

---

<style scoped>
  h2 {
    font-size: 34px;
    margin-top: 25px;
  }
  p, table {
    font-size: 24px;
  }
  pre, code {
    font-size: 14px;
    padding: 5px;
  }
</style>

# 📐 Capacity after one zone fails

For active-active capacity:

$$
\text{Total capacity} = \frac{\text{Target remaining capacity} \times Z}{Z - 1}
$$

Example: the application must retain **80 units** after one zone fails.

| Pattern | Total provisioned | Per zone | Remaining after failure |
|---|---:|---:|---:|
| Two zones | 160 units | 80 | 80 |
| Three zones | 120 units | 40 | 80 |

## Important

Define whether the target means full baseline, approved degradation, throttling, or prioritized traffic.

---

# 🧮 Turn the model into implementation

```bash
# Example: zone-pinned VM instances in two zones
az vm create \\
  --resource-group rg-checkout \\
  --name checkout-api-z1 \\
  --location eastus2 \\
  --zone 1 \\
  --image Ubuntu2204 \\
  --size Standard_D2s_v5

az vm create \\
  --resource-group rg-checkout \\
  --name checkout-api-z2 \\
  --location eastus2 \\
  --zone 2 \\
  --image Ubuntu2204 \\
  --size Standard_D2s_v5
```

## The commands are not the design

You still need:

- A health-aware load balancer
- Idempotent deployment and configuration
- Autoscale and quota validation per zone
- Telemetry for zone and dependency failures
- A repeatable failure test

---

<style scoped>
  table {
    font-size: 22px;
  }
  blockquote {
    font-size: 26px;
  }
</style>

# 🧩 A practical component matrix

| Component | State | Candidate pattern | Decision evidence |
|---|---|---|---|
| Front Door / gateway | Stateless | Service-managed | Validate health probes and failover |
| API compute | Stateless | Two zones | Surviving capacity and routing |
| Queue | Stateful | Managed redundancy | Confirm replication and delivery semantics |
| Cache | Replaceable state | Two zones or managed | Rebuild time and degraded behavior |
| Order database | Durable state | Service-specific | RPO, RTO, quorum, durability |
| Secrets and identity | Platform dependency | Managed | Regional and service guarantees |

> The matrix is a design record, not a support matrix. Validate every service choice.

---

<style scoped>
  h2 {
    font-size: 26px;
    margin-top: 25px;
  }
  ul {
    font-size: 20px;
  }
  pre, code {
    font-size: 14px;
    padding: 5px;
  }
</style>

# 🧪 Failure is a test case

## The zone-loss scenario

```text
Given: checkout is serving normal traffic
When: one availability zone becomes unavailable
Then:
  - requests route to healthy instances
  - writes preserve consistency and durability
  - queues do not silently lose orders
  - alerts identify the degraded state
  - operators can recover and fail back safely
```

## Test evidence to capture

- Error rate, latency, throughput, and saturation
- Remaining capacity and autoscale behavior
- Data consistency and duplicate handling
- Recovery time and operator actions
- Logs, traces, metrics, and alert quality

---

# 👩‍💻 Developer design checklist

Before calling the workload zone-resilient:

- [ ] Break each critical flow into components.
- [ ] Classify every component as managed, two-zone, or three-zone.
- [ ] Write the required post-failure operating state.
- [ ] Validate region, SKU, tier, and configuration support.
- [ ] Test routing, replication, failover, recovery, and failback.
- [ ] Preserve identity, security, monitoring, and data protection.
- [ ] Assign an owner for each operational action.
- [ ] Record why a third zone is required when it is required.

---

<style scoped>
  h2 {
    font-size: 26px;
    margin-top: 25px;
  }
  ul, ol, p {
    font-size: 18px;
  }
  pre, code {
    font-size: 14px;
    padding: 5px;
  }
</style>

# 🛠️ Architecture challenge

## Scenario: ticket checkout API

The service must tolerate the loss of one availability zone in a region.

- 400 requests/second at normal load
- 320 requests/second is the approved degraded state
- Orders must not be lost or duplicated
- p95 synchronous API latency must remain below 250 ms
- Recovery should be automated; operators approve failback

## Your task

Choose a zone pattern for:

1. API compute
2. Message queue
3. Order database
4. Cache

For each choice, state the requirement that drives it.

---

# 🧠 Discuss and defend

Use this format for each component:

```text
Component: order database
Pattern: service-managed / two zones / three zones
Failure objective: survive one zone loss
Post-failure state: no lost orders, RPO = 0
Evidence: replication + failover behavior + tested RTO
Operational owner: platform team
Open risk: verify selected SKU in target region
```

## The quality bar

A good design explains the failure behavior.  
A great design also proves it with telemetry and a repeatable test.

---

# 📌 Key takeaways

- Zones protect against a single-zone failure, not a regional outage.
- Service-managed zone redundancy is the default when it meets requirements.
- Two zones can be the right answer for stateless and replaceable components.
- Three zones earn their keep for capacity, durability, quorum, or operations.
- Replica count does not prove failure-domain separation.
- Cost comes after the resiliency objective and capacity model.
- The design is incomplete until the failure behavior is tested.

> The answer is not “two” or “three.” The answer is a decision you can defend, component by component.

---

# 📖 References

- [Two zones or three? A design framework for zone-resilient Azure workloads](https://azure.microsoft.com/en-us/blog/two-zones-or-three-a-design-framework-for-zone-resilient-azure-workloads/)
- [Choosing two-zone and three-zone patterns for zone-resilient Azure workloads](https://techcommunity.microsoft.com/blog/reliability-and-resiliency-in-azure/choosing-two-zone-and-three-zone-patterns-for-zone-resilient-azure-workloads/4554527)
- [Azure services that support availability zones](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-service-support)
- [Enable zone resiliency for Azure workloads](https://learn.microsoft.com/en-us/azure/reliability/availability-zones-enable-zone-resiliency)
- [Architecture strategies for availability zones and regions](https://learn.microsoft.com/en-us/azure/well-architected/design-guides/regions-availability-zones)

**Source note:** Azure zone behavior varies by service, SKU, tier, region, and configuration. Always validate the selected design against current service reliability guidance and test the workload's actual failure behavior.

---

# 🙏 Q&A

## Design for the failure you can explain.

**What component in your workload has the least defensible failure behavior today?**
