Project structure & consolidation plan
=====================================

This file documents the recommended long-lifespan folder structure and provides safe steps to consolidate similar files into canonical folders.

Recommended top-level layout

- frontend/         # React + Vite application (existing)
- backend/          # Admin/service-role helpers, Edge functions, scripts
- supabase/         # Supabase migrations, seeds, RLS policies
- docs/             # Proposals, system guides, database design
- deployments/      # Docker, CI, infra manifests
- scripts/          # Helper scripts (branch creation, consolidation)
- tests/            # Unit & integration tests
- archive/          # Old/duplicated files moved here during consolidation

Consolidation policy

- SQL files: canonical location `supabase/migrations/`
- Documentation (MD/PDF): `docs/` with `proposals/`, `database/`, `design/` subfolders
- Frontend source: `frontend/src/` — consolidate duplicate frontends into this tree
- Keep a copy of moved files in `archive/` for safety

How to apply (safe preview first)

1. Preview moves (dry run):

```powershell
.\scripts\consolidate-files.ps1    # shows planned moves (no changes)
```

2. Execute consolidation:

```powershell
.\scripts\consolidate-files.ps1 -Run
```

3. Review `archive/` and test the app. Update import paths if necessary.

If you'd like, I can run the script to perform the consolidation, or I can update code references after moving files.
