# Gallery Submission Checklist

Use this when prepping a template for `render.com/templates`. The skill produces every item below; submission itself is manual.

## README requirements

The README **is** the template's gallery page. Render lifts content straight from it. Treat it as the marketing page, the docs, and the support runbook in one file. Full per-section guidance lives in [readme-template.md](readme-template.md); the scaffold to fill is [../assets/README.template.md](../assets/README.template.md).

A gallery-quality README has, in order:

1. **H1 + one-sentence pitch** in a blockquote (becomes the gallery card subtitle)
2. **Deploy to Render button** — see [deploy-button.md](deploy-button.md)
3. **Two-to-three sentence elaboration** — who this is for, what problem it solves, why this combination
4. **Hero screenshot** — `assets/hero.png`, 1600×900, real data
5. **Table of contents**
6. **Why deploy <Project> on Render** — concrete value props for this specific combination, not Render-in-general
7. **Use cases** — 3–5 specific things people build with this
8. **What gets deployed** — mermaid diagram + resource table + region note
9. **Quickstart** — 5–7 numbered steps with realistic timings; Deploy button repeated
10. **Configuration** — four required sub-sections:
    - Required secrets (`sync: false`) with How-to-get-it column
    - Auto-generated secrets (`generateValue: true`) with rotation warning
    - Wired automatically (`fromDatabase`/`fromService`)
    - Optional tweaks with defaults
11. **Cost breakdown** — per-resource table summing to a total; cheaper / scale-up notes
12. **Customization** — 3–5 real recipes with diffs (pin version, custom domain, swap stub resources, enable previews)
13. **Operations** — Backups / Monitoring / Scaling / Logs sub-sections
14. **Upgrading** — pick up upstream releases + breaking-change migration log
15. **Troubleshooting** — 3–6 entries; baseline must include image pull, health check, app-specific 404/login/data
16. **FAQ** — 4–7 questions a real user would ask
17. **Security** — encryption at rest/in transit, network exposure, secret rotation, vuln reporting
18. **Caveats and limitations** — honest list; never hide single-instance / scaling constraints
19. **Credits and license** — upstream, template, maintainer

Skip a section only if it truly does not apply. Never reorder. Length target ~500–900 lines; hard cap 1200 (split into linked docs beyond that).

## Visual assets

Templates in the gallery need:

- **`assets/logo.png`** — 512×512 PNG, transparent background, project's official logo (request from upstream if not in their repo)
- **`assets/hero.png`** — 1600×900 PNG/JPG of the app's main screen post-deploy with real data (no Lorem Ipsum, no placeholder users). This is the primary image on the gallery card.
- **`assets/architecture.png`** *(optional)* — only if the mermaid diagram in the README does not capture the data flow clearly (rare; prefer the mermaid)

Store them in `assets/` inside the template repo. The README references them with relative paths so they render on both GitHub and the gallery page.

## Metadata payload

The skill emits a JSON-ish payload for the user to paste into the gallery submission form. Example:

```json
{
  "name": "Flowise",
  "slug": "flowise",
  "category": "AI / Agents",
  "pitch": "Self-host Flowise to build LLM workflows visually.",
  "repo": "https://github.com/<owner>/flowise-render-template",
  "upstream": "https://github.com/FlowiseAI/Flowise",
  "license_template": "MIT",
  "license_upstream": "Apache-2.0",
  "estimated_monthly_cost_usd": 7,
  "resources": [
    { "type": "web",      "plan": "starter", "notes": "image-wrapper" },
    { "type": "disk",     "sizeGB": 5,       "notes": "/root/.flowise persistence" }
  ],
  "required_secrets": ["FLOWISE_USERNAME", "FLOWISE_PASSWORD"],
  "generated_secrets": ["FLOWISE_SECRETKEY_OVERWRITE"],
  "contact_email": "<maintainer>"
}
```

## Pre-submission validation

Before submitting, the skill must verify:

### Repo and one-click flow

- [ ] Repo lives under `render-examples` on GitHub
- [ ] Repo is marked as a GitHub template repository (`gh api repos/render-examples/<slug> --jq .is_template` → `true`)
- [ ] `render.yaml` lives on the repo's **default branch** (the one-click flow does not honor `&branch=`)
- [ ] Deploy button URL uses the one-click flow: `https://render.com/deploy-template/api/github/start?template_repo=<slug>` — **not** `https://render.com/deploy?repo=...`
- [ ] `<TEMPLATE_REPO_SLUG>` placeholder is fully replaced; the URL resolves to a real `render-examples` repo

### Blueprint

- [ ] `render blueprints validate` passes
- [ ] Smoke deploy via the Deploy button reaches `live` status in a test account that did **not** previously have access to the template repo (proves the fork step works)
- [ ] Health check returns 200
- [ ] All `sync: false` vars are documented in the README's "Required secrets" table
- [ ] Every env var that appears in `render.yaml` appears somewhere in the README's Configuration section
- [ ] **Multi-resource templates use the `projects:` / `environments:` wrapper.** Any template with more than one resource (web + db, web + KV, web + worker, etc.) must wrap everything in a single project. Flat top-level `services:` / `databases:` is only valid for single-resource templates. Project `name` matches the template slug.

### README and assets

- [ ] `assets/logo.png` and `assets/hero.png` exist and load
- [ ] Mermaid diagram in "What gets deployed" renders correctly on GitHub
- [ ] LICENSE matches the upstream license terms (e.g. Apache 2.0 upstream → keep NOTICE, allow MIT for the *template repo* wrapper)
- [ ] README has no `<TODO>`, `<TBD>`, `<PLACEHOLDER>`, `<TEMPLATE_REPO_SLUG>`, `<OWNER>`, or `coming soon` strings
- [ ] Troubleshooting section has at least three named entries
- [ ] FAQ answers do not deflect to upstream for questions a template user would actually ask
- [ ] Caveats section is filled honestly (single-instance, regional pinning, manual upgrade story, etc.)
- [ ] Cost numbers in the breakdown match `render.com/pricing` as of today

## Categories

Gallery slots templates into a category. Pick one:

- AI / Agents
- LLM Tools / MCP servers
- Workflow Automation
- Web Frameworks (Django, FastAPI, Laravel, Rails, Next.js, etc.)
- Databases / Datastores
- DevOps / Internal Tools
- Voice / Realtime
- Observability
- Other

## Submission

Final step (manual): file the metadata payload + repo URL with the Render templates team via the contact channel they document at `https://render.com/templates`. The skill does not automate submission.
