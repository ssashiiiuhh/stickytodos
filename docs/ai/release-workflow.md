# Release Workflow

## Goals

The release pipeline should:
- support fast local iteration
- remain transparent and debuggable
- avoid unnecessary complexity
- preserve lightweight architecture

## Release Flow

1. Build project using Swift Package Manager
2. Discover binary path dynamically
3. Copy app bundle template
4. Inject fresh binary into bundle
5. Validate executable presence
6. Generate DMG in staging directory
7. Atomically replace release DMG
8. Optionally deploy to /Applications

## Directory Structure

dist/
├── app/
├── dmg/
└── logs/

## Scripts

### release.sh

Handles:
- build
- packaging
- deployment
- release artifact generation

## Usage

Standard:
./release.sh

Clean:
./release.sh --clean

## Design Principles

- no hidden privileged operations
- no CI/CD complexity
- no overengineering
- preserve debuggability
- preserve reproducibility

## Known Constraints

- Swift Package Manager does not generate the .app bundle directly
- build/StickyTodos.app acts as the bundle template source
- dist/ acts as the staging area