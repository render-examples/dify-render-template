---
name: render-create-template
description: Turn an upstream project into a standalone Render template repository. Picks the best template pattern (native runtime, static site, image wrapper, Docker fork, source fork, or minimal repo), authors render.yaml and a README with a Deploy to Render button, and preps the repo for submission to render.com/templates. Use when the user says "build a Render template for <project>", "make this a one-click template", "package this for the Render gallery", or wants to repackage any upstream repo or prebuilt image as a deploy-ready Render template.
---

# Create a Render Template

A **Render template** is a standalone GitHub repo, hosted under the `render-examples` org and marked as a GitHub template repository, that someone can deploy to Render in one click via `https://render.com/deploy-template/api/github/start?template_repo=<repo-slug>`. The one-click flow **forks the template into the user's own GitHub account** before deploying, so every gallery user gets their own editable copy. This skill builds that repo: picks a **template pattern** that matches the upstream project, authors `render.yaml` + a gallery-style `README.md`, wires in the right Render services, and produces the handoff steps to publish under `render-examples` with `is_template: true`. It **delegates** the deep details (Blueprint schema, Postgres sizing, Docker fields, etc.) to the existing `render-*` skills rather than restating them.

Docker is **not** the default. Native runtimes are preferred when the project supports them cleanly.

## When to use

Activate when the user asks to:

- Build a Render template, "one-click template", or gallery template for a project
- Repackage an upstream repo (or a public Docker image) into a deploy-ready Render template repo
- Add a Deploy to Render button to a project for distribution
- Prepare a template for submission to `render.com/templates`

For a one-off deploy of the user's own app (not a redistributable template), use **render-deploy** instead.

## Workflow

1. **Check for an existing template.** Call **render-templates** to confirm Render does not already publish a template for this project. If one exists, recommend that URL first and stop unless the user explicitly wants a fork.
2. **Identify the source.** Git URL, local repo, or registry image. Record: primary language(s), build tool, framework, license (must be permissive enough to wrap), Dockerfile presence, public image presence, static-output presence.
3. **Pick the template pattern.** Walk the decision heuristic in order, stop at the first match. Always log: *"Picked <pattern> because <reason>. Alternatives considered: <list>."* so the user can override.

   | # | Pattern | Render runtime | Pick when |
   |---|---------|----------------|-----------|
   | 1 | **static-site** | `static` | Build produces a static directory (Vite, Next export, Hugo, Astro, Gatsby, Docusaurus, Jekyll). |
   | 2 | **native-runtime** *(default for most apps)* | `node`, `python`, `go`, `ruby`, `rust`, `elixir` | Single-language project with idiomatic build files (`package.json`, `requirements.txt`/`pyproject.toml`, `go.mod`, `Gemfile`, `Cargo.toml`, `mix.exs`), no exotic system deps, runtime version pinnable (`.nvmrc`, `runtime.txt`, `.tool-versions`, `go.mod`). |
   | 3 | **image-wrapper** | `image` | Upstream publishes a **public, maintained** Docker image AND the project is large/complex enough that rebuilding from source on every deploy is wasteful (Flowise, n8n, Supabase, Penpot, OpenWebUI). Trades transparency for speed. |
   | 4 | **docker-fork** | `docker` | Project ships a working `Dockerfile` but no public image, OR has heavy native deps that don't play well with native runtimes, OR the build needs system packages. |
   | 5 | **source-fork-with-dockerfile** | `docker` | Native runtime would technically work but you want reproducible builds independent of buildpack changes. |
   | 6 | **minimal-repo** | any | Connector/glue templates with little or no code. |

   Full per-pattern spec (file tree, render.yaml skeleton, worked example, tradeoffs, upgrade/downgrade paths) lives in [references/template-patterns.md](references/template-patterns.md).

4. **Sanity-check the chosen pattern; downgrade if assumptions break:**
   - **static-site** requires a known output dir (`dist`, `build`, `public`, `out`, `_site`). If absent → downgrade to **native-runtime**.
   - **native-runtime** requires a real `buildCommand` + `startCommand` you can extract from `package.json` scripts / `Procfile` / framework convention, plus a pinned runtime version. If either is missing → downgrade to **docker-fork**.
   - **image-wrapper** requires the image to actually resolve (`docker manifest inspect <ref>`). If it 404s or is private → switch to **docker-fork** or **source-fork-with-dockerfile**.

5. **Determine the infra contract.** What does the app actually need? Delegate the *how* to the matching skill:

   | Need | Skill |
   |------|-------|
   | Managed PostgreSQL (plan, HA, replicas, version pin) | **render-postgres** |
   | Key Value / Redis (cache, queue, sessions, maxmemory) | **render-keyvalue** |
   | Persistent disk (uploads, on-disk DB, single-instance constraint) | **render-disks** |
   | Background workers / queue consumers | **render-background-workers** |
   | Cron jobs / scheduled tasks | **render-cron-jobs** |
   | Private services (internal-only) | **render-private-services** |
   | Env var strategy, `sync: false`, `generateValue` | **render-env-vars** |
   | Custom domain / TLS setup notes for the README | **render-domains** |
   | Web service ports, health checks, zero-downtime | **render-web-services** |
   | Static site config (publish path, SPA fallback, headers, redirects) | **render-static-sites** |
   | `runtime: docker` vs `runtime: image`, registry creds | **render-docker** |
   | Full `render.yaml` schema, `fromDatabase`/`fromService`/`fromGroup` wiring, immutable fields | **render-blueprints** |
   | Native-runtime codebase analysis (build/start command extraction) | **render-deploy** (its `codebase-analysis` + `runtimes` references) |

6. **Author `render.yaml`.** Use the skeleton for the chosen pattern from [references/template-patterns.md](references/template-patterns.md), then layer in the infra contract. Defaults the skill enforces unless the user overrides:
   - **Single-resource template** (one web service, nothing else): flat top-level `services:` is fine.
   - **Multi-resource template** (more than one of any combination of `services` + `databases`): **always** wrap everything in the `projects:` / `environments:` structure. Even a web service + one Postgres counts as multi-resource. Even web + Key Value. Even web + disk + Postgres. This is non-negotiable for templates because it gives the end user one named project per template in their Render dashboard instead of loose resources scattered around their workspace, and makes the staging/production layering obvious if they later add environments. Schema details: [render-blueprints](../render-blueprints/SKILL.md). Worked multi-service skeleton: [references/template-patterns.md → projects/environments wrapper](references/template-patterns.md#projectsenvironments-wrapper-for-multi-resource-templates).
   - **Plan sizing:** Default is `starter`, but **do not pick blindly**. For image-wrapper templates of real Node/JVM/ML apps, `starter` (512 MB) is often too small — Flowise, n8n, Keycloak and similar will OOM during startup and Render's port scanner will report "No open ports detected" because the process keeps dying. Heuristic + log signatures in [references/template-patterns.md → Plan sizing](references/template-patterns.md#plan-sizing-do-not-default-to-starter-blindly). When in doubt for an image-wrapper, default to `standard` (2 GB). Use `free` only on explicit request; flag sleep behavior in the README.
   - Explicit `region` (default `oregon`; let the user override)
   - `healthCheckPath` set when the framework supports one
   - Secrets as `sync: false`, generated secrets as `generateValue: true`
   - `previews.generation: off` for templates (gallery deploys are one-shot in the user's fork; PR previews aren't useful in the upstream template repo itself)
   - No `domains:` block (the gallery user adds their own domain after deploy)
   - `render.yaml` lives on the **default branch** of the template repo — the one-click flow does not support `&branch=`

   Multi-resource skeleton (use this shape verbatim and fill in the services/databases):

   ```yaml
   previews:
     generation: off

   projects:
     - name: <template-slug>
       environments:
         - name: production
           services:
             - type: web
               name: <web-name>
               ...
           databases:
             - name: <db-name>
               ...
   ```

   Use the template slug as the project `name` so the user's Render dashboard shows one project per template they deploy.

7. **Author the README — this is the template's gallery page.** Render lifts content from the README straight onto `render.com/templates/<slug>`, so it must function as marketing page, documentation, and support runbook in one file. Copy [assets/README.template.md](assets/README.template.md) and fill **every** placeholder. Full section-by-section guidance, voice rules, length targets, and the final review checklist live in [references/readme-template.md](references/readme-template.md). Hard requirements:
   - Hero block: H1 + one-sentence pitch in a blockquote + Deploy button + 2–3 sentence elaboration + hero screenshot at `assets/hero.png`
   - Table of contents
   - "Why deploy on Render" with concrete value props for this specific combination (not Render-in-general)
   - Use cases — 3–5 specific things people build with this template
   - "What gets deployed" — mermaid diagram + resource table + region note
   - Quickstart with realistic timings
   - Configuration with four required sub-sections: Required secrets / Auto-generated secrets / Wired automatically / Optional tweaks
   - Per-resource cost breakdown table
   - Customization recipes (pin version, custom domain, swap stubs, etc.)
   - Operations (Backups / Monitoring / Scaling / Logs)
   - Upgrading (releases + breaking-change migrations)
   - Troubleshooting with at least image-pull, health-check, and one app-specific entry
   - FAQ with 4–7 real questions
   - Security (encryption, exposure, rotation, vuln reporting)
   - Caveats and limitations stated up front, not hidden
   - Credits and license

   Length target ~500–900 lines. Do not ship a thin README — gallery acceptance and user trust both depend on this file.

8. **Pick a repo name and scaffold the files.** Convention: bare hyphenated slug like `<project>-render-template` or `<project>` (no uppercase, no trailing version numbers — pin upstream version inside `render.yaml`). For each variant the user requests, create a separate folder with `render.yaml`, `README.md`, `LICENSE` (MIT for the template repo if upstream license allows), `.gitignore`, and optionally `.env.example` mirroring the env-var contract. The README's Deploy button uses `<TEMPLATE_REPO_SLUG>` as the placeholder; it gets replaced with the bare repo name at publish time.

9. **Validate.** Delegate to **render-cli**: run `render blueprints validate` in each template folder. Fail loudly on schema/semantic errors; do not hand off an invalid template.

10. **Publish and wire the one-click flow.** Run (or print for the user to run) these steps in order. They must happen in order — the Deploy button URL only works after the repo exists *and* is marked as a GitHub template.

    ```bash
    # 1. Create the repo under render-examples and push
    gh repo create render-examples/<repo-slug> --public --source=<folder> --push \
      --description "<one-line pitch>"

    # 2. Mark it as a GitHub template repository (required for the one-click flow)
    gh api -X PATCH repos/render-examples/<repo-slug> -f is_template=true

    # 3. Verify
    gh api repos/render-examples/<repo-slug> --jq '{url:.html_url, is_template:.is_template}'
    ```

    Then patch the README's Deploy button to point at the **one-click flow** URL (not the Blueprint `?repo=` flow):

    ```
    https://render.com/deploy-template/api/github/start?template_repo=<repo-slug>
    ```

    Find/replace `<TEMPLATE_REPO_SLUG>` → bare repo slug, commit, push. The URL pattern, why it's different from `?repo=`, and the full handoff are documented in [references/deploy-button.md](references/deploy-button.md).

11. **Optional follow-ups (do not auto-execute):**
    - Smoke-test the deploy via the new Deploy button to confirm `live` status (delegate to **render-deploy** post-deploy verification)
    - Capture `assets/hero.png` (1600×900) and `assets/logo.png` (512×512) per [references/gallery-checklist.md](references/gallery-checklist.md)
    - Submit gallery metadata payload to the Render templates team

## Deploy to Render button

Canonical markdown the skill emits at the top of the README (note the `?template_repo=` flow, **not** `?repo=`):

```markdown
[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy-template/api/github/start?template_repo=<TEMPLATE_REPO_SLUG>)
```

`<TEMPLATE_REPO_SLUG>` is the bare GitHub repo name under `render-examples` (no `owner/` prefix). The skill writes the placeholder during scaffolding; the publish step (10) patches it with the real slug after the repo is created and marked as a GitHub template.

Why this URL and not `https://render.com/deploy?repo=...`: the `?template_repo=` flow forks the template into the end user's own GitHub account before deploying, giving them an editable copy. The `?repo=` flow deploys from your repo directly and is for one-off Blueprint deploys, not for gallery templates.

Full rules, requirements, common mistakes, and the GitHub-template setup: [references/deploy-button.md](references/deploy-button.md).

## What this skill does NOT do

- It does not duplicate Blueprint schema docs → use **render-blueprints**.
- It does not decide between `runtime: docker` and `runtime: image` from scratch → use **render-docker**.
- It does not handle one-off deploys of the user's own app → use **render-deploy**.
- It does not create GitHub repos, push, or flip `is_template` (it prints the commands; the user runs them unless explicitly told to execute).
- It does not submit to the official Render gallery (it produces the metadata payload; submission is manual).

## References

| Document | Contents |
|----------|----------|
| [references/template-patterns.md](references/template-patterns.md) | Per-pattern file tree, render.yaml skeleton, worked example, tradeoffs, upgrade/downgrade paths |
| [references/deploy-button.md](references/deploy-button.md) | Canonical Deploy to Render button formats, branch/monorepo variants, label customization |
| [references/gallery-checklist.md](references/gallery-checklist.md) | README sections, screenshots, metadata payload, submission process |
| [references/readme-template.md](references/readme-template.md) | Section-by-section README guidance |
| [references/env-detection.md](references/env-detection.md) | How to extract the env-var contract from upstream docs, Dockerfile `ENV`, `docker-compose.yml`, `.env.example` |

## Related skills

- **render-templates** — Look up existing official Render templates before authoring a new one
- **render-blueprints** — `render.yaml` schema authoring
- **render-deploy** — Generic deploy flow + codebase analysis
- **render-docker** — Docker runtime choices and registry wiring
- **render-postgres**, **render-keyvalue**, **render-disks**, **render-static-sites**, **render-web-services**, **render-env-vars**, **render-cli** — Per-resource details
