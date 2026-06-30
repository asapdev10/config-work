---
name: arch-review
description: Audit a codebase's architecture along structural axes — type-vs-operation grouping (inheritance vs composition), modularity level (monolith → modular monolith → microservices), horizontal-vs-vertical organization and its depth (shared repository vs module-owned tables), the purity of module separation, and data-oriented design (hot paths, data layouts, system-over-entity / ECS opportunities). Cross-references the code layout with git history to surface temporal coupling (modules frequently changed together). Reports findings inline in the session. Use when the user wants an architecture review, a modularity/coupling/performance-layout audit, or a recommendation on how to (re)organize a codebase.
---

<what-to-do>

Run a structured architecture audit of the target codebase and report the findings **inline in the session** (do not write a file unless the user explicitly asks for one). Work in passes; do not skip passes. Each pass produces evidence (file paths, counts, git output) before any verdict — never classify without showing what you saw.

If the user names a path, audit that. Otherwise audit the current working directory. Confirm the repo root and language(s) first.

</what-to-do>

<passes>

Run these in order. Read `RUBRIC.md` for the classification taxonomies and `GIT-SIGNALS.md` for the exact git commands. Gather evidence first across all passes (mostly read-only exploration + git queries), then synthesize the report once.

## Pass 0 — Orient
- Confirm repo root, primary language(s), build system, and whether it's a git repo (some passes need history; note if absent).
- Map the top-level directory structure (2–3 levels deep). This is the spine of every later judgment.
- Identify the unit of deployment(s): one process? many services? a single binary with plugins?

## Pass 1 — Type-vs-operation grouping (inheritance vs composition)
- Decide whether the top-level packaging groups code **by type/layer** (all controllers together, all models together, all repositories together) or **by operation/capability** (each folder holds the controller+model+service for one behavior).
- Within the code, sample the dominant reuse mechanism: deep **inheritance** hierarchies (abstract base classes, `extends` chains, template-method patterns) vs **composition** (injected collaborators, interfaces/traits, has-a over is-a).
- Report both the package-level grouping AND the in-the-small reuse style; they can disagree. Cite concrete files.

## Pass 2 — Modularity level
- Place the system on the spectrum: **monolith → monolith with shared repository → modular monolith → microservices** (see RUBRIC). 
- Evidence: number of deployable units, presence/absence of enforced module boundaries (build modules, package visibility, separate manifests), and whether modules talk in-process or over the network.

## Pass 3 — Horizontal vs vertical organization
- Determine if the codebase is sliced **horizontally (by domain entity / technical layer)** or **vertically (by feature / use case)**.
- A repo can be horizontal at the top and vertical inside (or vice versa) — describe the actual shape, don't force one label.

## Pass 4 — Depth of vertical organization (data ownership)
- Only meaningful where some vertical/module structure exists. Ask: how *deep* does the slice go?
  - Shallow: modules share one repository/data-access layer and one schema.
  - Medium: modules own their service/repository code but share a database.
  - Deep: each module owns its own tables (schema-per-module) or its own datastore.
- Find the data layer: ORM models, migrations, schema files, connection setup. Map tables → owning module. Flag tables written by more than one module.

## Pass 5 — Module-separation purity audit
- For the module boundaries identified above, measure how clean they are:
  - **Cross-module imports** that reach past a module's public surface into internals.
  - **Circular dependencies** between modules.
  - **Shared mutable state** / god objects / shared "common" or "utils" dumping grounds.
  - **Leaky data ownership** (a module reading/writing another's tables — from Pass 4).
- Produce a dependency sketch (who imports whom) and rate each boundary: clean / leaky / nonexistent.

## Pass 6 — Git temporal coupling (smells over time)
- Use `GIT-SIGNALS.md` queries to find files/modules that **change together** more often than their structural separation implies, plus churn hotspots and god-files.
- High co-change across supposedly separate modules is the strongest evidence that the *intended* boundary doesn't match the *real* one. This is the cross-check on Passes 2–5: structure says one thing, history says another.
- If not a git repo or history is shallow, say so and skip — don't fabricate.

## Pass 7 — Data-oriented design & hot paths
- Identify the **hot paths**: code that runs over large collections or at high frequency — loops over entity arrays, per-frame/per-tick updates (game loops, simulations), per-request fan-out, batch jobs, anything in a profiler's top-N or obviously O(n·m). Look for the volume, not just the call.
- For each hot path, evaluate the **data layout** it touches against DOD principles (see RUBRIC Axis 6):
  - Array-of-structs vs struct-of-arrays: are we hauling whole fat objects through cache to touch one field?
  - Pointer-chasing / linked traversals / heavy OOP graphs where a flat contiguous array would do.
  - Mixing hot fields (touched every iteration) with cold fields (rarely read) in the same record.
  - Polymorphic virtual dispatch inside tight loops (vtable indirection + branch misprediction).
- Assess whether the design separates **data from the systems that operate on it**. Where many entities share behavior processed in bulk, note whether an **entity-component-system (ECS)** or a data-table/SoA approach would fit — and be honest about when it would *not* (low entity counts, no measured hot path, heavy per-entity branching → ECS is overkill).
- Ground claims in evidence: cite the loop/file, the data structure, and why the layout hurts. Do not assert a perf win without a mechanism (cache misses, allocation churn, dispatch). Recommend measuring (profiler/benchmark) before any rewrite — never prescribe an ECS rewrite as a reflex.

</passes>

<synthesis>

Report findings **inline in the session** using this skeleton. Lead each section with the verdict,
then the evidence, then the recommendation. Only write a file (`docs/architecture-audit.md`) if the
user asks for one.

```
# Architecture Audit — <repo> (<date>)

## Summary
- Grouping: <by type | by operation | mixed> · Reuse: <inheritance | composition | mixed>
- Modularity: <monolith | shared-repo monolith | modular monolith | microservices>
- Organization: <horizontal | vertical | hybrid>, depth: <shallow | medium | deep>
- Boundary health: <clean | leaky | none> · Top temporal-coupling risk: <…>
- Hot-path / data-layout flags: <none | …>

## 1. Grouping & reuse style        (evidence + verdict)
## 2. Modularity level
## 3. Horizontal vs vertical
## 4. Data ownership / vertical depth
## 5. Module-separation purity      (dependency sketch + per-boundary rating)
## 6. Git temporal coupling         (co-change table + churn hotspots)
## 7. Data-oriented design          (hot paths, layout findings, ECS/SoA fit-or-not)

## Tensions
Where structure and git history disagree, or where two axes conflict.

## Recommendations
Ranked, each tied to a finding above. Note effort and blast radius. Do NOT recommend a rewrite,
a microservices split, or an ECS migration as a reflex — justify any such change with evidence
(and, for performance, recommend measuring first).
```

Rules:
- Every verdict cites at least one path, count, or git result. No unsupported adjectives.
- Stay descriptive before prescriptive. Name the architecture as it is before saying what it should be.
- Respect the user's batch-size preference: if recommendations imply code changes, propose them; don't start editing.
- If the report is long, lead with the Summary block so the headline verdicts land first.

</synthesis>

<supporting-info>
- `RUBRIC.md` — the classification taxonomies and decision tests for each axis (1–6, incl. data-oriented design).
- `GIT-SIGNALS.md` — copy-pasteable git/rg commands for churn, co-change, ownership, and hot-path discovery.
</supporting-info>
