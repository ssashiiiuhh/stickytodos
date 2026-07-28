# Session State

## Project Overview

StickyToDos is a native macOS productivity app that combines:
- reminders/task management
- sticky note visualization
- lightweight natural language parsing
- semantic search
- menu bar-first workflows

Core philosophy:
- lightweight
- native-feeling
- low-latency
- calm UI
- intelligent without feeling bloated

---

# Current Priorities

1. Stabilize natural language parsing
2. Preserve lightweight architecture
3. Improve persistence responsiveness
4. Maintain fast launch and menu bar performance
5. Avoid feature bloat

---

# Active Systems

## Task Management
- quick add
- due dates
- checklists
- active/completed filtering
- smart date parsing

## UI Architecture
- menu bar-first interaction
- sticky note visualization
- searchable task lists
- SwiftUI-based interface

## Persistence
- JSON-based persistence
- background persistence queue
- debounced saves
- compact encoding
- lightweight architecture

## Search
- semantic search integrated into menu bar search
- low-latency search expectations

## Release Pipeline
- automated local release workflow
- DMG generation
- Applications deployment
- dist/ staging architecture

---

# Current Architecture Decisions

## Persistence Philosophy
Keep persistence:
- lightweight
- local-first
- transparent
- debuggable

Avoid:
- premature SQLite migration
- enterprise persistence systems
- unnecessary abstractions

## Parser Philosophy
Natural language parsing should:
- feel forgiving
- preserve user text safely
- avoid destructive cleanup
- avoid strict command syntax
- remain lightweight

Confidence-gated parsing:
- only remove date text if confidence is high
- preserve original input on failed parses

## UI Philosophy
The app should:
- feel instant
- minimize cognitive load
- preserve native macOS aesthetics
- avoid clutter
- avoid feature overload

---

# Known Issues

## Parser Edge Cases
Potential remaining edge cases:
- midnight rollover
- ambiguous weekday parsing
- timezone edge behavior
- NSDateDetector inconsistencies

## Performance Unknowns
Not yet fully profiled:
- semantic search scaling
- persistence behavior with very large datasets
- menu bar responsiveness under heavy task counts

---

# Deferred Ideas

These are intentionally NOT priorities right now:
- SQLite persistence
- cloud sync
- collaborative features
- cross-platform rewrite
- enterprise architectures
- plugin systems
- heavy AI integrations

Reason:
Preserve simplicity and performance first.

---

# Rejected Approaches

Avoid:
- overengineering
- dependency injection frameworks
- unnecessary protocols/abstractions
- heavy NLP frameworks
- aggressive parser mutation
- bloated feature sets
- uncontrolled agent rewrites

---

# Release Workflow

Current release system:
- local-first
- script-driven
- transparent
- reproducible

release.sh handles:
- build
- bundle assembly
- DMG generation
- Applications deployment

dist/ acts as staging area.

---

# AI Agent Instructions

Before making changes:
1. Read:
   - architecture.md
   - parser-behavior.md
   - release-workflow.md
   - session-state.md

2. Prioritize:
   - minimal invasiveness
   - maintainability
   - responsiveness
   - low memory usage

3. Avoid:
   - massive rewrites
   - architecture explosions
   - unnecessary dependencies
   - feature creep

4. Preserve:
   - native macOS feel
   - fast interaction speed
   - lightweight resource usage
   - simple mental model

5. Prefer:
   - incremental improvements
   - confidence-gated behavior
   - debuggable systems
   - transparent logic

---

# Current Development Workflow

Typical flow:
1. investigate
2. understand system interactions
3. identify root cause
4. propose minimally invasive improvements
5. implement incrementally
6. build using release.sh
7. manually verify behavior

---

# Product Identity

StickyToDos should feel like:
- a modern native macOS utility
- calm and fast
- smart but unobtrusive
- lightweight instead of enterprise-heavy

The app should prioritize:
- polish
- responsiveness
- usability
- clarity
over excessive feature quantity.