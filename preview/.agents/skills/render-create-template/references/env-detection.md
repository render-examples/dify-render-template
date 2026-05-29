# Env Var Detection

How the skill extracts the env-var contract from an upstream project. Walk these sources in order and merge — later sources refine earlier ones.

## Sources, in priority order

1. **`.env.example` or `example.env`** — authoritative if present. Keys + comments tell you intent.
2. **`docker-compose.yml` / `compose.yaml`** — `environment:` blocks on the relevant service show the runtime contract the maintainers test against.
3. **`Dockerfile` `ENV` lines** — defaults baked into the image. Note: never read `ARG` as a secret source.
4. **Upstream docs** — `README.md`, `docs/` site, "Configuration" / "Environment" sections.
5. **Code grep** — last resort. Search for `process.env.`, `os.getenv(`, `os.environ[`, `ENV[`, `System.getenv(`, `std::env::var(` in the source. Cross-reference matches against the above sources to filter false positives (test fixtures, internal tools).

## Classification

For every var the skill finds, classify it into one of:

| Class | Render YAML treatment |
|-------|----------------------|
| **Hard-coded by template** (e.g. `DATABASE_TYPE=postgres`) | `value: ...` |
| **Wired from another Render resource** (DB host, Redis URL) | `fromDatabase:` / `fromService:` |
| **User-provided secret** (API keys, admin passwords) | `sync: false` |
| **Generated secret** (session keys, encryption keys) | `generateValue: true` |
| **Render-injected** (`PORT`, `RENDER_*`) | omit; Render sets it |
| **Optional with sane default** | `value: <default>` plus a README note that users can override |

## Pitfalls

- **Secrets in `ARG`:** Docker `ARG` values bake into image layers. If the upstream uses `ARG MY_SECRET`, do **not** mirror it as `value:` in `render.yaml`. Convert to a runtime env var with `sync: false`.
- **`PORT` mismatch:** The upstream image may hard-code a port via `EXPOSE 8080`. Render sets `PORT` and expects the app to bind it. Test before assuming. If the image ignores `PORT`, set `value: "<hardcoded>"` in `render.yaml` to match the image's port and let Render's port detection pick it up.
- **`localhost` defaults:** Vars like `REDIS_URL=redis://localhost:6379` from `.env.example` need to be rewritten to point at the Render Key Value service: `fromService: { type: keyvalue, name: cache, property: connectionString }`.
- **Compound vars:** Some apps use `DATABASE_URL`, others use `DB_HOST`/`DB_PORT`/`DB_USER`/`DB_PASS`/`DB_NAME`. Detect which the app supports — many support both and the URL form is shorter to wire.

- **Upstream env-var parsing is not always what the `.env.example` implies.** The fact that a var is documented does not mean the code reads it the way you'd expect. Common traps:
  - **Strict TLS env vars that only apply when a CA bundle is also supplied.** Example from Flowise (`packages/server/src/DataSource.ts::getDatabaseSSLFromEnv`): `DATABASE_REJECT_UNAUTHORIZED=false` is *ignored* unless `DATABASE_SSL_KEY_BASE64` is also set. `DATABASE_SSL=true` alone returns `ssl: true` (= strict verification) regardless of the reject-unauthorized flag. Result: against Render's internal-CA-signed Postgres cert, startup fails with `self-signed certificate` and the service exits before binding the port. The fix for Render's internal Postgres is `DATABASE_SSL=false` (private network, TLS not required), or supply Render's CA bundle via `DATABASE_SSL_KEY_BASE64`.
  - **Boolean strings parsed as truthy.** Some upstreams check `if (process.env.FOO)` instead of `if (process.env.FOO === 'true')`. Setting `FOO=false` then evaluates *truthy* and the feature stays on. Read the source before trusting the docs.
  - **`PORT` ignored.** Apps that hard-code their listen port via `app.listen(8080)` or `EXPOSE 8080` will not pick up Render's `PORT`. Match the env var to the hard-coded port instead of fighting it.
  - **Defaults that hide a required setting.** If an env var has a sane-looking default in code but is actually required for production (e.g. `JWT_SECRET=default-change-me`), Render should generate it with `generateValue: true` rather than leave the upstream default in place.

  **For every Postgres / Redis / TLS-touching env var in the contract, grep the upstream source for the env-var name and confirm the code path before adding it to `render.yaml`.** It's a 30-second check that prevents deploy-time TLS / connection failures.

## Output

The skill emits two artifacts per template:

1. The `envVars:` block in `render.yaml`.
2. A `.env.example` file at the template repo root that mirrors every key with placeholder values and one-line comments, so users running the template locally (outside Render) have a starting point.
