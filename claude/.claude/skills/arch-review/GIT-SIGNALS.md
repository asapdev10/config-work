# Git & static signals

Copy-pasteable queries for the history-based passes. All assume you're at the repo root.
Adjust `--since` to the project's age; default to the last ~12 months so churn reflects the
*current* shape, not ancient history. Skip this whole file if `.git` is absent — say so.

Sanity first:
```bash
git rev-parse --is-inside-work-tree && git log -1 --format='%ci' && \
  echo "commits in window:" && git log --since='12 months ago' --oneline | wc -l
```

---

## Churn hotspots (most-changed files)
```bash
git log --since='12 months ago' --name-only --format='' \
  | grep -v '^$' | sort | uniq -c | sort -rn | head -40
```
A file far above the rest is a god-file / change magnet. Cross-check against Pass 5's god-object find.

## Temporal coupling — files that change together (Pass 6 core)
For each commit, emit the set of files; count pairs that co-occur. This script ranks the most
frequently co-changed file pairs:
```bash
git log --since='12 months ago' --name-only --format='@%H' \
| awk '
  /^@/ { for(i in f) for(j in f) if(i<j) pair[i SUBSEP j]++; delete f; next }
  /./  { f[$0]=1 }
  END  { for(p in pair) { split(p,a,SUBSEP); print pair[p]"\t"a[1]"\t"a[2] } }
' | sort -rn | head -40
```
Interpretation: a high-count pair that lives in **two different modules** is temporal coupling —
the boundary between them is not real. Pairs inside one module are expected and fine.

## Module-level co-change (roll files up to their top folder)
Replace `MOD='[^/]*/[^/]*'` depth to match where modules live (e.g. `src/[^/]*`):
```bash
git log --since='12 months ago' --name-only --format='@%H' \
| sed -E 's#^(src/[^/]+)/.*#\1#' \
| awk '
  /^@/ { for(i in f) for(j in f) if(i<j) p[i SUBSEP j]++; delete f; next }
  /./  { f[$0]=1 }
  END  { for(k in p){ split(k,a,SUBSEP); print p[k]"\t"a[1]"\t"a[2] } }
' | sort -rn | head -30
```
This is the headline number for Pass 6: high cross-module co-change contradicts a clean boundary.

## Co-change for a specific file (what drags along when X changes?)
```bash
F='src/path/to/file'; git log --since='12 months ago' --name-only --format='@%H' \
| awk -v target="$F" '/^@/{if(hit)for(x in f)c[x]++;hit=0;delete f;next}{f[$0]=1;if($0==target)hit=1}
  END{for(x in c)print c[x]"\t"x}' | sort -rn | head -20
```

## Co-authorship / ownership of a path (who owns this module?)
```bash
git log --since='12 months ago' --format='%an' -- src/MODULE | sort | uniq -c | sort -rn
```
Many authors lightly touching a module = diffuse ownership; pairs with high cross-module co-change.

---

## Static signals (not git) used by Passes 1–5

Deployable units / service count:
```bash
fd -H -t f 'Dockerfile|docker-compose.ya?ml|Procfile|serverless.ya?ml|.*\.csproj|pom\.xml|go\.mod|package\.json|pyproject\.toml|Cargo\.toml'
```

Import graph seed (language-specific — adapt the pattern):
```bash
# JS/TS
rg -n "^\s*import .* from ['\"]" --type ts --type js
# Python
rg -n "^\s*(from|import) " --type py
# C#
rg -n "^\s*using " --type cs
# Go
rg -n -U "import \(([^)]*)\)" --type go
```
Roll the import targets up to module folders to sketch who-depends-on-whom and to spot cycles
and the shared-sink hub (`common`/`utils`/`core` imported by many).

Cross-module internal reaches (leaky boundaries — adapt path convention):
```bash
rg -n "from ['\"].*/internal/" ; rg -n "import .*\.internal\."
```

Data ownership — find schema/migrations and map tables to writers:
```bash
fd -H 'migrat|schema' -t d; fd -H '.*\.sql$|schema\..*|models?\.(py|rb|ts|cs)'
# which code references a given table:
rg -n -i "\b(from|join|insert into|update)\s+ORDERS\b"
```

Hot-path discovery (Pass 7 — static heuristics; a profiler is the real answer):
```bash
# tight loops over collections (eyeball the body for fat-object access / dispatch)
rg -n "for\s*\(|forEach|\.map\(|\.filter\(|while\s*\(" -g '!*test*' | head -60
# per-frame / per-tick / per-request entry points
rg -n -i "fn update|void Update|def tick|on_?frame|fixed_?update|game_?loop|render\(|step\(" 
# array-of-structs holding likely hot + cold fields together
rg -n "struct |class .*\{|@dataclass" -A8 | rg -n -i "position|velocity|transform|displayname|description|config"
# allocation in loops / virtual dispatch hints
rg -n "new |malloc|virtual |override " -g '!*test*'
```
If the project ships a profiler config or benchmark suite, prefer that over these greps:
```bash
fd -H 'bench|perf|profil' ; rg -n -i "benchmark|criterion|pytest-benchmark|BenchmarkDotNet"
```
