# KotobaLab Documentation

This directory is the durable product, engineering, and execution memory for
KotobaLab. It should let a contributor without conversation history understand
the product, the current system, the active objective, the next action, and the
evidence required for completion.

## Reading Order

Start a development task with:

1. [Product Contract](product/product_contract.md)
2. [Product Roadmap](roadmap/product_roadmap.md)
3. [Current Work](development/current_work.md)
4. The active phase linked from Current Work
5. Relevant architecture or dictionary contracts
6. The actual source code and tests

Completed phase records are historical evidence and do not need to be read for
every task.

## Documentation Roles

- `product/`: product identity, users, principles, v1 contract, and content
  boundaries.
- `roadmap/`: long-lived capability directions, without task or status tracking.
- `development/`: the current handoff and stable engineering workflow.
- `architecture/`: the architecture that is true in the current implementation.
- `dictionary/`: dictionary source, data, runtime asset, and pipeline contracts.
- `phases/`: executable plans and frozen completion records.
- `_local/`: gitignored drafts and temporary analysis; never a formal contract.

## Sources of Truth

| Information | Owner |
| --- | --- |
| Agent constraints | [`AGENTS.md`](../AGENTS.md) |
| Product and v1 contract | [`product_contract.md`](product/product_contract.md) |
| Long-term direction | [`product_roadmap.md`](roadmap/product_roadmap.md) |
| Current objective and next action | [`current_work.md`](development/current_work.md) |
| Engineering and Git workflow | [`engineering_workflow.md`](development/engineering_workflow.md) |
| Current code architecture | [`overview.md`](architecture/overview.md) |
| Dictionary principles | [`strategy.md`](dictionary/strategy.md) |
| Current build pipeline | [`pipeline.md`](dictionary/pipeline.md) |
| Phase scope and evidence | The relevant record under [`phases/`](phases/README.md) |
| Actual implementation | Source code and tests |
| Concrete delivery history | Commits and pull requests |

Other documents link to these owners instead of copying their state.

## Update Policy

- Update Current Work when the active objective or next action changes.
- Update the active phase when its plan, progress, decisions, or evidence change.
- Update architecture or dictionary contracts when the implementation changes
  them.
- Update the Product Contract only for material product-scope changes.
- Update the Roadmap only when long-term capability direction changes.
- Never update `AGENTS.md` merely because work progressed.

## Documentation Rules

- Formal documentation is written in English.
- Current facts and target direction are labeled distinctly.
- Plans and roadmaps are not implementation evidence.
- Time-sensitive measurements identify their artifact, commit, date, and
  environment.
- Completed phase records preserve what was true at completion.
- Current and planned phases are working hypotheses and may change when better
  evidence or implementation methods appear.
- Replace obsolete rules instead of growing documents through append-only edits.
- Create a document only when it has an independent responsibility.
