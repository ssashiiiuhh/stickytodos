# Parser Behavior

## Philosophy

StickyToDos prioritizes:
- low-friction natural input
- lightweight parsing
- non-destructive behavior
- predictable UX

The parser should feel:
- forgiving
- fast
- natural
- unobtrusive

## Core Rules

- Only remove detected date phrases if confidence is high.
- Failed parses must preserve original text completely.
- Avoid fallback-to-today behavior.
- Preserve punctuation and capitalization.
- Avoid destructive cleanup logic.

## Confidence Gates

A detected date is considered valid if:
- a meaningful future or present date resolves
- remaining task text is still meaningful
- the extracted range appears structurally valid

## Supported Patterns

Examples:
- finish hw tomorrow
- tomorrow finish hw
- meeting this sunday
- cca friday 3pm
- assignment next week

## Ambiguous Inputs

Inputs like:
- friday
- sunday

should remain untouched and should not automatically assign due dates.

## Avoided Approaches

- heavy NLP libraries
- enterprise parsing systems
- strict command syntax
- destructive text mutation