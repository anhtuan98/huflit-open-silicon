# Article Template

The agent reads this file every time it creates or merges an article. Keep the `Connector System` example **as-is** — it's a validated worked example. Adapt only if the target codebase has domain-specific conventions worth showing.

## Frontmatter

    ---
    sources: [path/to/file.py, path/to/other.py]
    related: [[other-article]]
    created: YYYY-MM-DD
    updated: YYYY-MM-DD
    ---

## Sections

### Mandatory (every article):

## Entry Points [Required]
<!-- functions/classes to start reading from, include API endpoints -->

## Key Patterns [Required]
<!-- architecture, design patterns, conventions; inline DB models as "Models: ..." when relevant; include frontend locations -->

## Search Shortcuts [Required]
<!-- grep patterns, anti-patterns ("don't grep X"), directory ownership -->

### Optional (add when relevant):

## Directions [When flow spans 3+ files]
<!-- trace paths: "A → B → C"; include frontend-to-backend flow when it has a UI -->

## Tests [When tests exist]
<!-- test file paths, just paths — no descriptions needed -->

## Gotchas [When non-obvious things exist]
<!-- past bugs, pitfalls, and architecture "why" notes — anything non-obvious -->

## Rules

> Canonical rules live in the schema (the `wiki-memory` SKILL.md / `CLAUDE.md` § Wiki Protocol / `AGENTS.md`) under Constraints. Do not duplicate them here.

## Example: Connector System

---
sources: [connectors/google_drive/connector.py, connectors/tasks.py, connectors/tree_utils.py]
related: [[search-pipeline]]
created: 2026-04-16
updated: 2026-04-16
---

# Connector System

## Entry Points
- `GoogleDriveConnector` in `connectors/google_drive/connector.py`
- `FileConnector` in `connectors/file/connector.py`
- API: `server/documents/connector.py` — connector tree and folder endpoints
- `connectors/tasks.py` — background sync tasks

## Key Patterns
- Sync pipeline: fetch → convert → index with folder_ids → Vespa
- Folder tree: `build_connector_tree()` in `tasks.py` + `tree_utils.py`
- GDrive: retry + 1-day checkpoint for large accounts
- Admin UI: `web/src/app/admin/connectors/`
- Frontend lib: `web/src/lib/connectors/`
- Models: `Document.folder_ids` (db/models.py), `folder_ids` (danswer_chunk.sd), `SearchFilters.folder_ids` (search/models.py)
- Configs: `vespa_constants.py`, `configs/app_configs.py`

## Search Shortcuts
- Grep: `GoogleDriveConnector`, `build_connector_tree`, `folder_ids`, `file_retrieval`
- Don't grep: `google`, `connector` (too broad)
- Dir: `backend/connectors/google_drive/`

## Directions
- Sync: `connector.py` → `file_retrieval.py` → `doc_conversion.py` → `indexing_pipeline.py`
- Tree: `tasks.py` → `tree_utils.py` → `Document.folder_ids`
- Search: query → `preprocessing.py` → Vespa filter

## Tests
- `tests/unit/test_google_drive_search_tool.py`, `tests/unit/test_folder_passthrough.py`
- `cypress/e2e/project_file_cross_tool.cy.js`

## Gotchas
- GDrive rate limits: retry in `file_retrieval.py`, checkpoint at 1-day intervals (PR #1183)
- Raw content not stored: check `store_raw_file_content` in `doc_conversion.py` (PR #1167)
- `folder_ids` on docs (not just tree) because Vespa can't join at query time
