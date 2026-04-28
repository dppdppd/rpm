# DRB2 task8 — Rubric Scoring

**Method:** Each of 52 binary rubrics evaluated PASS/FAIL by re-reading the report against the rubric text. Scoring done by the orchestrator (not a separate judge LLM). Strict-and-lenient dual scoring noted where applicable.

## INFO_RECALL (37 rubrics)

| # | Rubric | Strict | Lenient | Note |
|---|--------|--------|---------|------|
| 1 | Exploration-based: lists Reinforcement Learning | ✓ | ✓ | explicitly listed |
| 2 | Exploration-based: lists Monte Carlo Tree Search | ✓ | ✓ | CASTING, MDTS named |
| 3 | Exploration-based: lists Particle Swarm Optimization | ✗ | ✗ | report puts PSO under Optimization-based |
| 4 | Exploration-based advantages: explore large spaces, handle data scarcity | ✓ | ✓ | both elements present |
| 5 | Exploration-based disadvantages: high cost, slow convergence | ✓ | ✓ | both present |
| 6 | Model-based: lists Neural Networks | ✗ | ✓ | INNs/NN-based methods cited; "Neural Networks" not named as standalone |
| 7 | Model-based: lists GAN | ✓ | ✓ | |
| 8 | Model-based: lists VAE | ✓ | ✓ | |
| 9 | Model-based: lists Forward and Inverse Model Integration | ✗ | ✗ | not mentioned |
| 10 | Model-based advantages: high accuracy, automated, structured-data-friendly | ✗ | ✓ | partial — "high quality crystals", "fast sampling" close enough lenient |
| 11 | Model-based disadvantages: large data, limited generalization, overfitting | ✗ | ✓ | data requirement + invalid output mentioned; overfitting absent |
| 12 | Optimization-based: lists Bayesian Optimization | ✓ | ✓ | |
| 13 | Optimization-based: lists Genetic Algorithms | ✓ | ✓ | |
| 14 | Optimization-based: lists Topology Optimization | ✗ | ✗ | not mentioned |
| 15 | Optimization-based advantages: well-defined obj, multi-objective | ✗ | ✓ | NSGA-II + Pareto explicit |
| 16 | Optimization-based disadvantages: high cost high-dim, model accuracy reliance | ✓ | ✓ | BO scales poorly + only explores representable space |
| 17 | Database list includes ICSD | ✓ | ✓ | |
| 18 | ICSD description matches | ✓ | ✓ | "comprehensive collection of crystal structure data for inorganic compounds" |
| 19 | ICSD URL = icsd.products.fiz-karlsruhe.de | ✗ | ✗ | report has icsd.nist.gov (different vendor) |
| 20 | DB list includes OQMD | ✓ | ✓ | |
| 21 | OQMD description matches | ✓ | ✓ | 1.4M (above expected 1.2M) |
| 22 | OQMD URL = oqmd.org | ✓ | ✓ | report has oqmd.org (no www, equivalent) |
| 23 | DB list includes Dynamic database of solid-state electrolyte (DDSE) | ✗ | ✗ | absent |
| 24 | DDSE description | ✗ | ✗ | absent |
| 25 | DDSE URL | ✗ | ✗ | absent |
| 26 | DB list includes Materials Project | ✓ | ✓ | |
| 27 | Materials Project description matches | ✓ | ✓ | |
| 28 | MP URL = next-gen.materialsproject.org | ✗ | ✓ | report has materialsproject.org (parent domain, redirects) |
| 29 | DB list includes NOMAD | ✓ | ✓ | |
| 30 | NOMAD description matches | ✓ | ✓ | |
| 31 | NOMAD URL = nomad-lab.eu/nomad | ✗ | ✓ | report has nomad-lab.eu (parent path) |
| 32 | DB list includes CSD | ✓ | ✓ | |
| 33 | CSD description matches | ✓ | ✓ | |
| 34 | CSD URL = ccdc.cam.ac.uk/solutions/software/csd/ | ✗ | ✓ | report has ccdc.cam.ac.uk (parent path) |
| 35 | DB list includes ASM Alloy Center | ✗ | ✗ | absent |
| 36 | ASM description | ✗ | ✗ | absent |
| 37 | ASM URL | ✗ | ✗ | absent |

**Info-recall: strict 19/37 (51.4%) · lenient 26/37 (70.3%)**

## ANALYSIS (12 rubrics)

| # | Rubric | Strict | Lenient | Note |
|---|--------|--------|---------|------|
| 1 | Core principle of exploration-based | ✓ | ✓ | sequential decision-making + adaptive search captured |
| 2 | Core principle of model-based | ✓ | ✓ | data-driven generative captured; physics-driven angle weak |
| 3 | Core principle of optimization-based | ✓ | ✓ | math optimization framing explicit |
| 4 | Role of RL in inverse design | ✓ | ✓ | agent-environment interaction explicit |
| 5 | Role of GAN | ✓ | ✓ | adversarial + conditional generation |
| 6 | Role of GA | ✓ | ✓ | natural selection / chromosomes / crossover/mutation |
| 7 | Role of Bayesian Optimization | ✓ | ✓ | GP + acquisition function explicit |
| 8 | Role of Topology Optimization | ✗ | ✗ | not covered |
| 9 | Inverse vs forward design distinction | ✓ | ✓ | crystal-clear in Background |
| 10 | Challenge: data scarcity | ✓ | ✓ | "lack of high-quality, large training datasets" + AIMatDesign |
| 11 | Challenge: vast design search space | ✓ | ✓ | "Efficient exploration of continuous, high-dimensional spaces" |
| 12 | Challenge: multi-objective trade-offs | ✓ | ✓ | NSGA-II + Pareto fronts |

**Analysis: strict 11/12 (91.7%) · lenient 11/12 (91.7%)**

## PRESENTATION (3 rubrics)

| # | Rubric | Strict | Lenient |
|---|--------|--------|---------|
| 1 | Two parts with subheadings (Part One / Part Two) | ✓ | ✓ |
| 2 | Part One: Category — Principles — Algorithms — Advantages/Disadvantages | ✓ | ✓ |
| 3 | Part Two: list format with name, description, URL | ✓ | ✓ |

**Presentation: 3/3 (100%)**

---

## Totals

| Dimension | Strict | Lenient |
|---|---|---|
| info_recall (37) | 19 (51.4%) | 26 (70.3%) |
| analysis (12) | 11 (91.7%) | 11 (91.7%) |
| presentation (3) | 3 (100%) | 3 (100%) |
| **Total (52)** | **33 (63.5%)** | **40 (76.9%)** |

DRB2 paper reports "even the strongest models satisfy fewer than 50% of the rubrics" overall across the full benchmark. This single-task baseline at strict 63.5% / lenient 76.9% is above that threshold but covers only **1 of 132** tasks; it is not a representative DRB2 score, just a directional read of where the v2.10.0 skill stands on this single Science & Technology survey-shape task.
