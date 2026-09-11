# ForgeBuild 1.2.9 — Phase 4 + Phase 9 Assisted Assembly Editing

ForgeBuild v1.2.9 adds a stronger Phase 4 + Phase 9 workflow that combines direct assembly editing with an AI-assisted edit planner.

## Assisted Assembly Editing

- Added the AI Edit Assistant to the selected assembly Property Inspector.
- Added a Ruby backend `AssemblyEditAssistantService` for deterministic natural-language edit planning.
- Added natural-language parsing for common assembly edits including height, thickness, width, length, depth, elevation, pitch, slope, STC, R-value, fire rating, material, finish, framing, insulation, sheathing, and commercial assembly metadata.
- Added one-click application of suggested parameter and metadata changes to the selected assembly.
- Added apply-to-similar support for matching assemblies with the same builder and object type.

## Phase 4 Editing Workflow

- Expanded editable assembly fields so assisted edits can update geometry parameters and commercial metadata through the existing regeneration workflow.
- Separated geometry parameter changes from metadata changes before applying edits.
- Added safer warnings and follow-up questions for openings, rated assemblies, fixed-side push/pull decisions, and apply-to-similar edits.
- Added quick access to Push/Pull and Regenerate from the AI edit panel.

## Phase 9 AI Workflow

- Added an AI-ready handoff prompt containing the selected assembly, current parameters, requested edit, detected changes, warnings, questions, and safe-edit instructions.
- Kept a browser-side fallback analyzer for compatibility while routing primary analysis through Ruby callbacks.
- Improved the AI panel with ready/review-required status, separated result sections, and apply workflow guidance.

## Notes

This release is the first serious link between the Phase 4 assembly-editing workflow and the Phase 9 AI-assistance workflow. The next work should add grip editing, live preview before commit, richer opening creation, and a true external model-backed assistant call when available.
