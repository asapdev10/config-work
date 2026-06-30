# Classification rubric

Taxonomies and decision tests for each axis. These are heuristics, not laws — a codebase
can sit between rungs. Always report the *closest* rung plus what pulls it toward the next.

---

## Axis 1 — Grouping: by type vs by operation

Look at the **top-level package layout**, then sample the **reuse mechanism** in the small.

**Grouped by type (a.k.a. by layer / by kind):** folders named for what code *is*.
```
controllers/   models/   services/   repositories/   views/
```
- Pro: easy to find "all the X". Con: one feature smears across every folder; high change fan-out.

**Grouped by operation (a.k.a. by feature / by capability):** folders named for what code *does*.
```
checkout/  (controller + model + service together)
inventory/
shipping/
```
- Pro: a change to one capability stays local. Con: cross-cutting concerns can duplicate.

**Reuse style (orthogonal, sample 5–10 representative classes/modules):**
- *Inheritance-leaning:* abstract base classes, `extends`/subclass chains ≥2 deep, template-method,
  shared behavior via overriding. Search for `extends`, `abstract`, `: BaseX`, `super(`.
- *Composition-leaning:* dependencies injected/passed in, behavior assembled from small interfaces
  or traits, has-a over is-a, strategy/decorator. Search for constructor injection, interface params.

Report grouping and reuse separately. A by-type layout with deep inheritance is a different beast
from a by-operation layout with composition, and either pairing can occur.

---

## Axis 2 — Modularity level

Spectrum, least to most decoupled:

| Rung | Deployable units | Boundaries | Data | Tell-tale |
|---|---|---|---|---|
| **Monolith** | 1 | none enforced; free import anywhere | one shared schema | flat or layer-only structure, any file imports any file |
| **Monolith w/ shared repository** | 1 | logical folders, but everything reaches a shared data/access layer | one shared schema, one DAL | "core"/"common"/"shared" module everyone depends on |
| **Modular monolith** | 1 (or few) | explicit modules with public surfaces; cross-module access is intended to go through APIs | usually shared DB, ideally schema-per-module | build modules / packages / enforced visibility; modules named by domain |
| **Microservices** | many | network boundaries; independent deploy & versioning | each service owns its datastore | multiple manifests/Dockerfiles, RPC/HTTP/queue between units, per-service DB |

Decision tests:
- Count deployable units (Dockerfiles, service manifests, `main`/entrypoints, CI deploy targets).
- Are boundaries *enforced* (build system, package-private, module visibility) or merely *suggested* (folders)?
- Do modules call each other **in-process** (imports) or **over a wire** (HTTP/gRPC/queue)?
- "Distributed monolith" warning: many services but they deploy together / share a DB / can't be
  released independently → call it out; it's worse than a clean modular monolith.

---

## Axis 3 — Horizontal vs vertical organization

- **Horizontal:** sliced by domain entity or technical layer. `User`, `Order`, `Product` each own a
  model+repo, OR the whole app split into `web/`, `domain/`, `data/`. Optimizes for "all code about
  entity/layer X in one place."
- **Vertical:** sliced by feature / use case. `place-order/`, `cancel-subscription/` each contain the
  full stack for that flow. Optimizes for "everything for behavior X in one place."

A repo is frequently **hybrid**: vertical feature folders at the top, horizontal layering inside each.
Describe the actual nesting rather than forcing a single label. The question to answer: *"when a typical
change request arrives, does it land in one folder (vertical) or fan out across many (horizontal)?"* —
Pass 6's co-change data is the empirical answer to this.

---

## Axis 4 — Depth of vertical organization (data ownership)

Only meaningful where module/feature structure exists. Measures how far the slice penetrates.

| Depth | Code | Data | Coupling implication |
|---|---|---|---|
| **Shallow** | modules share one data-access layer / repository | one schema, shared models | changing a table risks every module |
| **Medium** | each module owns its service + repository code | shared database, but tables informally "belong" to a module | refactors localize, but DB is a shared coupling point |
| **Deep** | module owns code end-to-end | schema-per-module or datastore-per-module; cross-module data via API/events only | true isolation; the prerequisite for splitting to services |

How to measure: locate migrations/schema/ORM models, build a table→writer map (Pass 4 + GIT-SIGNALS
ownership query). A table written by ≥2 modules = ownership leak; pulls depth toward "shallow."

---

## Axis 5 — Module-separation purity

Rate each boundary **clean / leaky / nonexistent**:

- **Clean:** dependencies flow one direction through a declared public surface; no internals reached;
  no shared mutable state; the module owns its data.
- **Leaky:** mostly separated but with cross-boundary reaches — imports of another module's internal
  files, a fat `common`/`utils` everyone depends on, two modules writing one table, occasional cycle.
- **Nonexistent:** the "module" is a folder only; code imports freely across it.

Smell checklist:
- Imports that pierce internals (`module_a/internal/...` referenced from `module_b`).
- **Circular dependencies** between modules (any cycle is a finding).
- A **shared sink** (`common`, `utils`, `helpers`, `core`) that most modules depend on and that itself
  depends back on many — a hidden hub.
- **Leaky data ownership** — carried over from Axis 4.
- God object / god file — one type or file imported almost everywhere (also surfaced by churn in Pass 6).

---

## Axis 6 — Data-oriented design & hot paths

Where Axes 1–5 ask *how the code is organized for humans*, this axis asks *how the data is organized
for the machine on the paths that actually run hot*. Only the hot paths matter — DOD is a tool for
measured bottlenecks, not a style to impose everywhere.

**Step 1 — find the hot paths.** Candidates:
- Loops over large/growing collections (entities, rows, particles, nodes).
- Per-frame / per-tick / per-request work (game loops, simulations, render/update systems, schedulers).
- Anything in a profile's top-N, or visibly O(n·m) / nested iteration over big sets.
If there's no hot path (small data, no tight loop, IO-bound), say so — DOD has little to offer here.

**Step 2 — judge the data layout on those paths.** Smells:

| Smell | What it looks like | Why it hurts |
|---|---|---|
| Array-of-structs for hot scans | iterating `entities[]` to read one field of a fat object | drags cold bytes through cache; low cache-line utilization |
| Hot/cold fields mixed | `position` (every tick) beside `displayName`, `config` in one record | wastes cache on data the loop never reads |
| Pointer chasing | linked lists / object graphs / `foreach` over heap-scattered objects | cache misses, no prefetch, no SIMD |
| Virtual dispatch in tight loop | polymorphic `update()` called per element | vtable indirection + branch misprediction per iteration |
| Allocation churn | per-iteration `new`/boxing/temp collections in the hot loop | GC pressure, allocator contention |

**Step 3 — data vs systems separation / ECS fit.** Does the design keep **data** separate from the
**systems** that transform it, processing like-with-like in bulk? When many entities share behavior
run over them every tick, a **struct-of-arrays / data-table** layout or an **entity-component-system**
(components = plain data arrays, systems = functions over them) improves cache behavior and parallelism.

ECS / SoA **fits** when: many homogeneous entities, hot bulk iteration, behavior expressible as
passes over component arrays, perf actually matters (games, simulations, real-time).
ECS / SoA is **overkill** when: low entity counts, no measured hot path, highly heterogeneous
per-entity logic, or the cost is readability in code that isn't hot. Say so plainly — recommending
ECS where it doesn't belong is itself a finding against the reviewer.

**Evidence bar:** cite the loop/file, the structure it walks, and the mechanism (cache misses,
dispatch, allocation). Recommend a **profiler/benchmark to confirm** before any layout rewrite.
Never assert a speedup without a mechanism.

---

## Reading the combination

The axes interact. Useful archetypes to recognize:
- *By-type + horizontal + shallow + inheritance* → classic layered monolith; change fan-out is the risk.
- *By-operation + vertical + deep + composition* → modular monolith primed for extraction; check boundary purity is real, not aspirational.
- *Microservices + shared DB (shallow)* → distributed monolith; the worst of both — flag loudly.
Name the archetype if one fits; it makes the recommendation obvious.
