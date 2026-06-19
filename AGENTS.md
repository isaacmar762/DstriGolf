# DistriGolf - Project Guide

## Stack
- Flutter (stable channel)
- Dart
- Supabase (PostgreSQL REST API)
- SQLite local (sqflite)
- http package for Supabase REST calls

## Build
- APK release: `flutter build apk --release` (from `distrigolf_app/`)
- GitHub Actions builds on push to `main` (`.github/workflows/build_apk.yml`)

## Architecture
- **Services** (`lib/services/`): SupabaseService (HTTP calls), LocalDbService (SQLite), SyncService
- **Repositories** (`lib/repositories/`): Bridge between services and providers; Supabase calls always return data immediately; local DB save is fire-and-forget (`unawaited`)
- **Providers** (`lib/providers/`): State management with ChangeNotifier
- **Models** (`lib/models/`): ProductModel, ClientModel, PriceModel, etc.

## SupabaseService Rules
- ALWAYS use `http.get` directly with `_authHeaders()`, NEVER use `_client.from().select()` (postgrest 2.7.0 has issues on Android with large GETs)
- `lastDebugInfo` static var captures last operation state for debugging
- `_authHeaders()` always includes `apikey`; adds `Authorization: Bearer <token>` if session exists
- Product query: `productos?select=*&activo=eq.true&order=id.asc`
- Custom RPC calls use `_client.rpc()` for Postgres functions

## Repositories Pattern
- `try { data = await supabase.call(); fireAndForget(localDb.save(data)); return data; } catch (e) { return localDb.get(); }`
- The `unawaited` + `.catchError` pattern prevents local DB failures from blocking Supabase data delivery
- Import `dart:async` for `unawaited`

## Local Database
- File: `distrigolf_local.db`
- Version 2 (migration adds `imagen_url` to productos_local)
- Tables: clientes_local, productos_local, precios_local
- All columns must match the model's `toMap()` keys or guardará will fail

## Common Issues
- If products show 0 but HTTP works: check `guardarProductos` — likely a column mismatch between `toMap()` and the SQLite table schema
- Fresh install vs upgrade: `onCreate` runs for new DBs, `onUpgrade` for existing ones; bump version + add migration
- Always test with `flutter build apk --release` on real device; emulator may behave differently

## Project Structure
```
distrigolf_app/
  lib/
    models/       # Data models with fromMap/toMap
    services/     # SupabaseService, LocalDbService, SyncService
    repositories/ # Data access layer
    providers/    # State management
    screens/      # UI screens
    widgets/      # Reusable widgets
```
