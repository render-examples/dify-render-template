# Template Patterns

Each pattern below documents: the **repo file tree**, the **render.yaml skeleton**, a **worked example**, **tradeoffs**, and **upgrade/downgrade paths**. The skill walks the heuristic in `SKILL.md` and picks the first match.

## 1. static-site

Build produces a static directory served from Render's CDN.

### File tree

```
my-template/
├── render.yaml
├── README.md
├── LICENSE
├── .gitignore
├── package.json          # or content source
└── src/                  # site source
```

For wrapping an upstream static-site generator project, fork it and add `render.yaml` + `README.md`. For a brand-new template, scaffold the framework with its idiomatic CLI first.

### render.yaml skeleton

```yaml
services:
  - type: web
    name: site
    runtime: static
    plan: starter
    buildCommand: npm ci && npm run build
    staticPublishPath: ./dist
    pullRequestPreviewsEnabled: true
    headers:
      - path: /*
        name: X-Frame-Options
        value: DENY
    routes:
      - type: rewrite
        source: /*
        destination: /index.html   # SPA fallback; drop for MPAs
```

### Worked example

A Vite + React dashboard. `buildCommand: npm ci && npm run build`, `staticPublishPath: ./dist`. SPA fallback rewrite for client-side routing. PR previews on (cheap, since static).

### Tradeoffs

- **Pros:** Free PR previews, CDN-fronted, no cold starts, no server costs.
- **Cons:** Server-side rendering needs a web service instead. Build-time API keys leak into bundle if not careful.

### Upgrade/downgrade

- Need SSR or API routes → upgrade to **native-runtime** (`runtime: node` with a Next/Remix server).
- Output dir unknown → downgrade to **native-runtime** and serve via a tiny static-file server.

Full static-site config details: **render-static-sites**.

## 2. native-runtime (default)

Standard framework app built and run by Render's native buildpacks. Preferred for most single-language projects.

### File tree

```
my-template/
├── render.yaml
├── README.md
├── LICENSE
├── .gitignore
├── .nvmrc                # or runtime.txt / .tool-versions / go.mod
├── package.json          # or requirements.txt / Gemfile / Cargo.toml / mix.exs
└── src/
```

When wrapping an upstream repo, **fork** and add `render.yaml` + `README.md` at the root.

### render.yaml skeletons

**Node:**

```yaml
services:
  - type: web
    name: api
    runtime: node
    plan: starter
    region: oregon
    buildCommand: npm ci && npm run build
    startCommand: npm start
    healthCheckPath: /healthz
    envVars:
      - key: NODE_ENV
        value: production
```

**Python:**

```yaml
services:
  - type: web
    name: api
    runtime: python
    plan: starter
    region: oregon
    buildCommand: pip install -r requirements.txt
    startCommand: gunicorn app:app --bind 0.0.0.0:$PORT
    healthCheckPath: /healthz
```

**Go:**

```yaml
services:
  - type: web
    name: api
    runtime: go
    plan: starter
    region: oregon
    buildCommand: go build -o app ./cmd/server
    startCommand: ./app
    healthCheckPath: /healthz
```

Ruby, Rust, Elixir follow the same shape with their idiomatic build/start. See **render-deploy** → `references/runtimes.md`.

### Worked examples

- **Node:** A Fastify API with `package.json` scripts `build` and `start`, `.nvmrc` pinning Node 20. → `runtime: node`.
- **Python:** A FastAPI app with `requirements.txt` and `runtime.txt` pinning `python-3.12.4`. → `runtime: python`.
- **Go:** A Chi HTTP server with `go.mod` declaring `go 1.22`. → `runtime: go`.

### Tradeoffs

- **Pros:** Fastest builds (no Docker layer overhead), cheapest PR previews, easy for users to fork-and-edit, clearest `buildCommand`/`startCommand` semantics.
- **Cons:** Tied to Render's buildpack versions; if upstream needs system packages (`libpq-dev`, `ffmpeg`, `tesseract`), native runtime often can't supply them.

### Upgrade/downgrade

- Needs system packages, monorepo with multiple languages, or build script gets too clever → upgrade to **docker-fork**.
- Project is a documentation site or pure static bundle → downgrade to **static-site**.

Native runtime details: **render-deploy** → `references/codebase-analysis.md` + `references/runtimes.md`.

## 3. image-wrapper

Pull a public, maintained Docker image. The template repo holds only the Render config; no upstream source.

### File tree

```
my-template/
├── render.yaml
├── README.md
└── LICENSE
```

(Plus optional `.env.example` documenting the upstream image's env contract.)

### render.yaml skeleton

```yaml
services:
  - type: web
    name: app
    runtime: image
    plan: starter
    region: oregon
    image:
      url: docker.io/<org>/<image>:<tag>
    healthCheckPath: /healthz
    envVars:
      - key: PORT
        value: "<port>"
```

For private images, add `registryCredential.fromRegistryCreds.name` → see **render-docker** → `references/registry-setup.md`.

### Worked example

**Flowise:** `flowiseai/flowise` on Docker Hub, port 3000, persistence at `/root/.flowise`. Template is ~3 files. Chosen because the upstream is a pnpm + turbo monorepo with ~4 GB heap builds — rebuilding from source on every deploy is wasteful, and the image is actively maintained by upstream.

### Tradeoffs

- **Pros:** Tiny repo. No build step on Render → fast deploys. Upstream owns the build pipeline.
- **Cons:** Opaque (users can't easily customize). Sticky `latest` tag means manual redeploy / deploy hook to pick up upstream releases. No PR-preview value in the template repo itself.
- **Ops:** Pin to an immutable digest (`@sha256:...`) or a versioned tag (`v1.2.3`) for production; document `latest` only as a "easy mode" default.

### Plan sizing (do not default to `starter` blindly)

The default `plan: starter` (512 MB) is too small for many real upstream images, especially **Node and JVM apps**. Symptoms when the plan is undersized:

- `Reached heap limit Allocation failed - JavaScript heap out of memory` in logs (Node)
- `OutOfMemoryError` (JVM)
- `==> No open ports detected` from Render's port scanner, because the process keeps dying before binding

The skill must size the plan based on the upstream image's startup memory, not on the default. Heuristic:

| Image profile | Minimum plan |
|---------------|--------------|
| Static binary (Go, Rust) with minimal runtime state | `starter` (512 MB) |
| Lightweight Node/Python/Ruby app, small dependency graph | `starter` |
| Real Node app with TypeORM, NestJS, big node_modules (Flowise, n8n, Strapi) | `standard` (2 GB) |
| JVM app (Keycloak, Sonarqube, Confluence) | `standard` minimum, often `pro` |
| ML inference (transformers, llama.cpp) | `pro` (4 GB) or higher |

When in doubt, default to `standard` and let the user downgrade if they prove startup fits in 512 MB. `NODE_OPTIONS=--max-old-space-size=...` workarounds are **not a substitute** for the right plan — they only matter when the container has room Node isn't using. If the container itself is too small, no Node flag helps.

The README's **Caveats** section must call out the plan floor explicitly (e.g. "Standard plan is the floor. Downgrading to starter will fail with `Reached heap limit ...`"), and the **Troubleshooting** section must include the exact log signature so users who downgrade and break things can self-diagnose.

### Upgrade/downgrade

- Users keep asking to customize the build → downgrade to **docker-fork** or **source-fork-with-dockerfile**.
- Upstream stops publishing images → forced downgrade to **docker-fork**.

Image runtime details: **render-docker**.

## 4. docker-fork

Fork (or scaffold a fresh repo around) an upstream project that ships a `Dockerfile` but no public image, or whose native build is impractical.

### File tree

```
my-template/                   # fork of upstream OR scaffold around it
├── render.yaml
├── README.md                  # template-focused; upstream README kept as README.UPSTREAM.md
├── README.UPSTREAM.md
├── LICENSE                    # template repo LICENSE
├── .dockerignore
├── Dockerfile                 # from upstream
└── <upstream source tree>
```

### render.yaml skeleton

```yaml
services:
  - type: web
    name: app
    runtime: docker
    plan: starter
    region: oregon
    dockerfilePath: ./Dockerfile
    dockerContext: .
    healthCheckPath: /healthz
    envVars:
      - key: PORT
        value: "8080"
```

### Worked example

A Rust+wasm SaaS whose upstream ships a working multi-stage `Dockerfile`. Native Rust runtime would work but the build needs `wasm-pack` and a node tool in the same stage. Fork it, keep the Dockerfile, add `render.yaml`.

### Tradeoffs

- **Pros:** Reproducible builds. Full control over system packages.
- **Cons:** Heavy repo. Long build times. Need `.dockerignore` hygiene to keep build context small.

### Upgrade/downgrade

- Upstream publishes a maintained public image → consider downgrade to **image-wrapper**.
- Build is actually clean native? → downgrade to **native-runtime** for a thinner template.

Dockerfile patterns: **render-docker** → `references/dockerfile-patterns.md`.

## 5. source-fork-with-dockerfile

Like docker-fork but the project *could* run native and you're explicitly choosing Docker for reproducibility (locked OS image, locked toolchain version, locked binary deps).

### File tree, skeleton, ops

Same as **docker-fork**. The difference is intent: you're hand-rolling a Dockerfile rather than reusing an upstream one.

### When to pick

- Long-lived template that must survive buildpack version drift.
- Compliance / supply-chain requirements (pin everything to digests).
- Need exact parity between local dev (`docker compose up`) and production.

### Tradeoffs

- **Pros:** Maximum reproducibility, no buildpack lock-in.
- **Cons:** You now own the Dockerfile forever; native-runtime would have been one fewer thing to maintain.

## 6. minimal-repo

Glue templates: webhook receivers, connector starters, AI agent boilerplates, MCP servers — small enough that "scaffold from scratch" is cheaper than forking.

### File tree

```
my-template/
├── render.yaml
├── README.md
├── LICENSE
├── .gitignore
├── package.json        # or pyproject.toml / go.mod
└── src/
    └── index.ts        # ~50–200 lines
```

### render.yaml skeleton

Use whichever native runtime fits (Node/Python/Go are most common for glue):

```yaml
services:
  - type: web
    name: server
    runtime: node
    plan: starter
    region: oregon
    buildCommand: npm ci
    startCommand: node src/index.js
    envVars:
      - key: API_KEY
        sync: false
```

### Worked example

An MCP server starter that exposes one tool. ~80 lines of TypeScript, deploys in 30 seconds, ready for users to extend.

### Tradeoffs

- **Pros:** Lowest friction for users. Easy to read and customize. Doubles as documentation.
- **Cons:** Skill needs to *write code* (not just config). Keep it short and idiomatic.

### Upgrade/downgrade

- Code grows past ~500 LOC → consider migrating to **native-runtime** with a proper repo layout.
- Needs a daemon or system deps → upgrade to **docker-fork**.

## Pattern selection quick reference

```
static output?            → static-site
single-lang, clean build? → native-runtime    ← default
heavy monorepo + image?   → image-wrapper
Dockerfile, no image?     → docker-fork
need reproducibility?     → source-fork-with-dockerfile
glue / boilerplate?       → minimal-repo
```

## projects/environments wrapper (for multi-resource templates)

The patterns above show `services:` and `databases:` at the **top level** for brevity. That shape is only valid for single-resource templates (one web service, nothing else).

**Any template with more than one resource — web + Postgres, web + Key Value, web + disk + Postgres, web + worker, etc. — must wrap everything in `projects:` / `environments:`.** This is a hard rule for templates regardless of which pattern (image-wrapper, native-runtime, docker-fork, …) the rest of the template uses. The wrapper groups the deployed resources into one named Render project in the end user's dashboard, makes the staging/production seam obvious if they later add environments, and matches the multi-service shape Render expects.

### Skeleton

```yaml
# yaml-language-server: $schema=https://render.com/schema/render.yaml.json

previews:
  generation: off

projects:
  - name: <template-slug>
    environments:
      - name: production
        services:
          - type: web
            name: <web-name>
            runtime: <runtime>
            plan: starter
            region: oregon
            healthCheckPath: /healthz
            envVars:
              - key: DATABASE_URL
                fromDatabase:
                  name: <db-name>
                  property: connectionString
              - key: REDIS_URL
                fromService:
                  type: keyvalue
                  name: <kv-name>
                  property: connectionString

          - type: worker
            name: <worker-name>
            runtime: <runtime>
            plan: starter
            envVars:
              - key: DATABASE_URL
                fromDatabase:
                  name: <db-name>
                  property: connectionString

          - type: keyvalue
            name: <kv-name>
            plan: starter
            maxmemoryPolicy: noeviction
            ipAllowList: []

        databases:
          - name: <db-name>
            plan: basic-256mb
            region: oregon
```

### Rules the skill must enforce

- Use the **template slug** as the project `name` so the user sees one Render project per template they deploy (e.g. `flowise-render-template-postgres`).
- Use `production` for the single environment in templates. Add more environments only if the template is deliberately a staging+production starter — most templates aren't.
- Each environment owns its own `services:` and `databases:` lists. **Never** duplicate the same logical resource at top level *and* inside an environment — that's a validation error.
- `previews:` stays at top level (it's a Blueprint-wide setting, not project-scoped).
- `envVarGroups:` can stay at top level (shared across the workspace) or move into an environment (project-scoped). For most templates, top-level is fine.
- `fromDatabase` / `fromService` / `fromGroup` references work identically inside the wrapper — they look up by `name` within the same Blueprint.

### When the wrapper is **not** required

A template with exactly one resource — one web service (with or without a disk), or one static site, or one private service — can use the flat `services: [...]` top-level shape. The moment you add a database, a Key Value, a worker, a cron, or any second compute service, switch to the wrapper.

Schema details and the broader projects/environments mechanics: [render-blueprints](../../render-blueprints/SKILL.md).
