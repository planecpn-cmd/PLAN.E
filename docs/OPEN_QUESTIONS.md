# PLAN E — Open Questions

This file logs unresolved questions, underspecified details, and design decisions encountered during development.

| # | Question | Impact / Blocks | Assumption / Default Picked | Status |
|---|---|---|---|---|
| 1 | `realtime.enabled` was set to `false` in `supabase/config.toml` to ensure container stability during local dev database startup. | Phase 8 Trip Chat real-time messaging updates. | Keep `realtime.enabled = false` for dev DB stability during Stage A/B core phases; re-enable in `supabase/config.toml` during Phase 8 Trip Chat implementation. | LOGGED |
