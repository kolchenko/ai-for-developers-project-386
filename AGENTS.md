# AGENTS.md

Frontend for the «Календарь звонков» booking app. The API contract is defined in TypeSpec (`main.tsp`); there is **no backend** — during development the API is mocked by Prism from the generated OpenAPI spec. UI is React 19 + Mantine 9 + React Query 5, served by Vite.

## Commands

```sh
npm run dev      # Vite dev server on :5173 (proxies /api -> http://127.0.0.1:4010)
npm run mock     # compile main.tsp -> OpenAPI, then Prism mock on :4010
npm run openapi  # compile main.tsp -> tsp-output/openapi.yaml (gitignored)
npm run build    # verification: tsc --noEmit && vite build
```

There is no test or lint script. `npm run build` is the only local verification; Hexlet tests run in CI on push (`.github/workflows/hexlet-check.yml`, do not edit).

## Environment gotchas

- `npm run openapi` / `npm run mock` require **Node >= 22** (TypeSpec 1.12 crashes on Node 20 with `fs/promises.glob`). `.nvmrc` pins 22. `dev`/`build` work on Node 20.19+.
- Both `tsp compile` and the Vite proxy target `127.0.0.1`; Prism binds there by default.

## API contract workflow

- `main.tsp` is the source of truth. After changing it, run `npm run openapi` and check `tsp-output/openapi.yaml` before touching UI code.
- `src/api/endpoints.ts` must match the emitted OpenAPI paths. Known trap: the `upcoming()` operation under `@route("/admin/bookings")` emits as **`GET /admin/bookings`**, not `/admin/bookings/upcoming`.
- Prism runs in static mode: it returns `@example` blocks from `main.tsp`, not dynamic data. Keep examples realistic. Its in-memory state resets on restart.
- In `main.tsp`, `plainTime`/`utcDateTime` example values must use constructors: `plainTime.fromISO("09:00:00")`, `utcDateTime.fromISO("2026-08-24T09:00:00Z")`. String literals fail type-check.
- Error responses (404/409/422) come from the spec's `@error` models; Prism returns the 2xx example for valid requests, so business-rule errors (e.g. 409 conflict) are only reproducible with malformed requests.

## Code layout & conventions

- `src/api/` — types, axios client (interceptor maps HTTP status -> `ApiError`), endpoints, React Query hooks + query keys. All requests go through the axios instance with `baseURL: '/api'`.
- `src/pages/` — route components; `src/components/` — shared UI (layout, modals).
- Routes: `/` (guest list), `/event-types/:eventTypeId` (slots + booking), `/admin` (bookings), `/admin/event-types` (CRUD). No auth anywhere.
- Temporal values come from the API as `HH:mm:ss` (`availableFrom`/`availableTo`) and ISO timestamps; use `src/utils/time.ts` helpers for grouping/formatting.
- Tabler icons in this version are prefixed: `IconCalendarEvent`, `IconInfoCircle`, etc. (no bare `CalendarEvent`).
