Organizing similar files and folding duplicates
=============================================

Goal: combine similar files (docs, pdfs, SQL scripts, front-end duplicates) into single folders and keep workspace tidy.

Recommended actions:

- Group SQL scripts: move all SQL schemas and seeds into `supabase/migrations/` or `backend/sql/`.
- Consolidate documentation: put proposal/PDFs/MD under `docs/` with subfolders `proposals/`, `database/`, `design/`.
- Frontend duplicates: merge any duplicated `frontend/` and `codeta-full-project/src/` components into a single `frontend/src/` tree. Keep `codeta-full-project` as archive if needed.
- Remove or archive `other/` duplicates into `archive/` or `docs/archive/`.

Safety rules:
- Never move or commit files that contain credentials. If files contain secrets, remove secrets and rotate keys.
- After moving, update references (import paths, build scripts, README) to new locations.

Example commands (PowerShell):

```powershell
# create consolidated folders
mkdir supabase\migrations
mkdir docs\proposals

# move SQL files into migrations
mv .\CREATE_DATABASE_COMPLETE.sql .\supabase\migrations\
mv .\ENHANCED_SEED_DATA.sql .\supabase\migrations\
```
