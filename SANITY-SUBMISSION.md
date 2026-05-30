# Sanity submission: Dify

Use when filing a **production** catalog entry for [render.com/templates](https://render.com/templates).

**GitHub repo (ready):** https://github.com/render-examples/dify-render-template  
**One-click deploy:** `https://render.com/deploy-template/api/github/start?template_repo=dify-render-template`  
**Gallery URL (target):** `https://render.com/templates/dify`

---

## Blockers before submit

- [ ] Capture **`assets/hero.png`** (1600×900) from a live deploy (Dify install wizard or console home)
- [ ] Paste README into Sanity `markdownBody` (keep in sync with GitHub `README.md`)
- [ ] Smoke deploy from a account that does not own `render-examples/dify-render-template`

---

## Sanity Studio fields

Create document: **Templates** → new document

| Field | Value |
|-------|--------|
| **Title** | `Dify on Render` |
| **Slug** | `dify` |
| **Description** | Self-host Dify on Render with one click: LLM apps, RAG pipelines, and agent workflows using managed Postgres (pgvector), Key Value, and a Celery worker. |
| **GitHub Repository** | `https://github.com/render-examples/dify-render-template` |
| **Demo URL** | *(optional — add if you host a public demo)* |
| **Image** | Upload `assets/hero.png` |
| **Stack** | `docker`, `postgresql`, `python`, `nextjs` |
| **Tags** | `ai`, `ai-agent`, `llm`, `rag`, `automation` |
| **Sort Order** | *(optional — leave blank unless templates team assigns)* |
| **Body (Markdown)** | Paste full contents of this repo's `README.md` |

---

## gallery-metadata.json

Already at [`gallery-metadata.json`](./gallery-metadata.json). Attach to the handoff email/ticket.

---

## Local preview

See [`LOCAL_GALLERY_PREVIEW.md`](./LOCAL_GALLERY_PREVIEW.md):

1. `bun run dev` in `renderinc/website`
2. `bun run sanity:dev` → **development** dataset
3. Create draft with slug `dify` → Preview → `http://localhost:3000/templates/dify`

---

## Production checklist

- [ ] Document published on Sanity **`production`** dataset (not development only)
- [ ] `https://render.com/templates/dify` returns 200
- [ ] Catalog card shows hero image and description
- [ ] **Deploy this template** forks repo and Apply succeeds
