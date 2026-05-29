# README Authoring Guide

The template README is **the source of truth for the `render.com/templates/<slug>` page**. Render's gallery surfaces the README directly. Treat it as the marketing page, the documentation, and the support runbook in one file.

Bar to clear: a developer landing on this README cold should be able to (1) decide whether the template fits their use case, (2) understand exactly what gets deployed and what it costs, (3) deploy it in under 5 minutes, (4) recover from common failures without opening a ticket.

Use [../assets/README.template.md](../assets/README.template.md) as the literal scaffold. Fill every placeholder. Cut a section only if it truly does not apply, and note why in the commit message.

## Voice

- Second person ("you click Deploy"), present tense.
- No marketing language ("blazing-fast", "powerful", "seamless"). State facts.
- No "we" — there is no "we" in a template README; there is the template, the upstream, and the user.
- Honest about constraints. Single-instance? Say so up front. Costs money? Say how much.
- US English. Render styleguide rules apply.

## Length targets

| Section | Target | Hard cap |
|---------|--------|----------|
| Hero block (title → elaboration) | 80 words | 120 |
| Why deploy on Render | 4 bullets, ~12 words each | 6 bullets |
| Use cases | 3–5 bullets | 7 |
| What gets deployed | diagram + table + 1 short paragraph | — |
| Quickstart | 5 numbered steps | 7 |
| Configuration | as long as needed; tables, not prose | — |
| Cost breakdown | one table, two prose lines | — |
| Customization | 3–5 sub-headings | 7 |
| Operations | 3–5 short sub-sections | — |
| Upgrading | 2 sub-sections | — |
| Troubleshooting | 3–6 entries | 10 |
| FAQ | 4–7 questions | 10 |
| Security | bullet list | — |
| Caveats | 3–6 bullets | 8 |
| Credits | 3 lines | — |

Total README ~500–900 lines is normal for a gallery template. Anything over 1200 means a section needs to move into a separate doc and be linked.

## Section-by-section

### Hero block

```markdown
# <Project> on Render

> One sentence. What you get. No filler.

[![Deploy to Render](...)](...)

Two-to-three sentence elaboration. Who is this for. What problem does it solve.
Why this combination (Project + Render) specifically.

![alt text](./assets/hero.png)
```

- The blockquote line under the H1 becomes the gallery card's subtitle. Optimize that one sentence.
- The hero screenshot is required for gallery acceptance. 1600×900, real data, no Lorem Ipsum. Store at `assets/hero.png` inside the template repo.
- Put the Deploy button **above** the screenshot so users who skim can click without scrolling.

### Table of contents

Required for any README over ~200 lines. Generate from the section headings; do not invent navigation that doesn't match headings.

### Why deploy <Project> on Render

The angle that justifies *this combination*, not Render-in-general. Concrete benefits the user gets out of the box:

- "Managed Postgres with daily backups wired automatically — no connection string to copy"
- "Auto-deploys when upstream publishes a new image"
- "Free PR previews for chatflows you're prototyping"
- "Persistent disk + snapshots; no S3 setup required"

Avoid generic claims ("scalable", "reliable"). State mechanisms.

### Use cases

What people actually build with this. 3–5 short bullets. Be specific:

- "RAG chatbot over your own docs"
- "Internal LLM workflow runner for ops automation"
- "Multi-agent orchestration for support triage"

This section is what makes the gallery card stop the scroll.

### What gets deployed

Three required artifacts:

1. **Mermaid diagram** showing services, databases, disks, and edges. Keep it readable on the gallery page (8 nodes max).
2. **Resource table** with columns: `Resource | Type | Plan | Purpose`. One row per Render resource.
3. **One short paragraph** explaining region defaults and how to override.

When wiring multi-service templates, the diagram should make the data flow obvious at a glance.

### Quickstart

Numbered list, 5–7 steps. Each step is one imperative sentence. Include realistic wait times so the user knows whether the deploy is hung or just pulling an image.

Repeat the Deploy button at the top of Quickstart for users who jumped here from the TOC.

If the post-deploy flow has visual steps (first-login screen, admin setup), embed one screenshot or GIF. Store in `assets/`.

### Configuration

Always four sub-sections, in order, even if one is empty:

1. **Required secrets** — `sync: false` vars the user must set in the dashboard. Three columns: `Env var | What it's for | How to get it`. If empty, write `**None. <reason>.**`
2. **Auto-generated secrets** — `generateValue: true` vars. Two columns: `Env var | Purpose`. Always include the rotation warning ("Do not rotate later because X breaks").
3. **Wired automatically** — `fromDatabase` / `fromService` vars. Two columns: `Env var | Source`. This is how you show users the magic without making them read YAML.
4. **Optional tweaks** — env vars that are commonly overridden. Three columns: `Env var | Default | What it does`. Link to upstream config docs at the end.

This section is the most-read part of any template README. Spend time on it.

### Cost breakdown

One table:

```markdown
| Resource | Plan | Monthly cost |
|----------|------|--------------|
| api      | starter      | $7  |
| postgres | basic-256mb  | $6  |
| disk     | 2 GB         | $0.50 |
| **Total** | | **$13.50** |
```

Use real numbers from `render.com/pricing` at the time of writing; do not invent estimates. Add two prose lines:

- **Cheaper:** how to drop to the free plan, smaller disk, etc.
- **Scale up:** which dial to turn for more traffic.

### Customization

Three to five sub-headings showing common modifications. Each is a real recipe with the actual diff or YAML change, not vague advice. Cover at minimum:

- **Pin the upstream version** (image tag or fork commit)
- **Add a custom domain** (one paragraph + link to render-domains)
- **Swap a stub resource for a real one** (e.g. disk → S3, SQLite → Postgres)
- **Enable PR previews** if turned off in the template

If the upstream has plugins, integrations, or themes worth highlighting, add a sub-heading per major one.

### Operations

Four short sub-sections:

- **Backups** — what gets backed up and how (Render's automatic Postgres backups, disk snapshots, what is NOT backed up)
- **Monitoring** — link to dashboard metrics; mention any healthCheckPath behavior
- **Scaling** — single-instance vs scaling.numInstances; when zero-downtime works
- **Logs** — where to find them; CLI invocation

This section is what saves the maintainer from a flood of "how do I…" issues.

### Upgrading

Two sub-sections:

- **Pick up upstream releases** — exact steps. Manual deploy? Bump image tag? Sync fork?
- **Breaking-change migrations** — running list of known migrations. Start with one example placeholder; maintainers append as upstream evolves.

### Troubleshooting

3–6 named entries in `### Error or symptom` format, each followed by the cause and the one-paragraph fix. Always include:

- A "Deploy fails during image pull" or equivalent build-time entry
- A "Health check fails" entry
- A 404/login/data entry specific to the app

End with a four-bullet pointer to dashboard logs, deploy events, template repo issues, and upstream issues.

### FAQ

4–7 questions a real user would ask before or after deploying. Sample backbone:

- "Can I run this on Render's free plan?"
- "How do I migrate from my existing self-hosted install?"
- "What happens if I delete the disk?"
- "Can I move my data off the disk later?"
- "Why <Project> on Render and not <competitor cloud>?"

Be honest. If the free plan does not work, say so.

### Security

Bullet list covering at minimum:

- What is encrypted at rest (managed Postgres yes, disks yes)
- What is encrypted in transit (TLS terminations)
- What is publicly exposed vs private
- Which secrets are safe to rotate vs dangerous to rotate
- Where to report vulnerabilities (this repo vs upstream)

### Caveats and limitations

The single most underrated section. Honest list of things the template cannot do:

- "Single instance only; no zero-downtime deploys (disk constraint)"
- "Image tag pinning is your responsibility; this template does not auto-bump"
- "Postgres is regional; if you need multi-region read replicas, see the Render Postgres docs"
- "First image pull takes 90+ seconds; subsequent deploys are <30s"

Users who hit these later without a heads-up file angry issues. Front-loading the caveats earns trust.

### Credits and license

Three lines:

- Upstream link + upstream license
- Template license (MIT for this scaffold) with link to LICENSE
- Template maintainer GitHub handle

End with one optional sentence directing stars to the upstream.

## Repo layout the README implies

For the README's links to resolve, the template repo needs:

```
<template>/
├── README.md
├── LICENSE
├── render.yaml
├── .gitignore
├── .env.example
└── assets/
    ├── hero.png            # 1600×900, real screenshot
    ├── logo.png            # 512×512, transparent background
    └── architecture.png    # optional; only if mermaid in README isn't enough
```

## What to leave out

- "What is <Project>?" sections — link to upstream instead.
- Marketing copy. Users clicked Deploy already.
- Disclaimers, ToS, generic terms — that's the LICENSE.
- "Why Render?" general pitches — users are on Render's gallery.
- ASCII art, badge collections (CI, Discord, Twitter). One Deploy button is enough.
- Roadmaps and changelogs — link to upstream.

## Final review checklist

Before declaring the README done, verify:

- [ ] Every `<PLACEHOLDER>` from the scaffold is replaced
- [ ] Hero screenshot exists at `assets/hero.png`
- [ ] Deploy button URL points at the real public repo (not `<HTTPS_REPO_URL>`)
- [ ] Cost numbers match `render.com/pricing` today
- [ ] Mermaid diagram renders on GitHub (preview the README on the repo before publishing)
- [ ] Every env var in `render.yaml` is documented in Configuration
- [ ] Required secrets table has the "How to get it" column filled (links if possible)
- [ ] Troubleshooting has at least the three baseline entries
- [ ] FAQ answers are direct, not deflective
- [ ] Caveats are surfaced before the user discovers them in production
- [ ] No "TODO", "TBD", or "coming soon" strings anywhere
