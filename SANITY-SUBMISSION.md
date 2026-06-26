# Sanity submission: Dify

Use when filing a **production** catalog entry for [render.com/templates](https://render.com/templates).

**GitHub repo:** https://github.com/render-examples/dify-render-template  
**One-click deploy:** `https://render.com/deploy-template/api/github/start?template_repo=dify-render-template`  
**Gallery URL (target):** `https://render.com/templates/dify`

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

Attach [`gallery-metadata.json`](./gallery-metadata.json) to the handoff email or ticket.

---

## Production checklist

- [ ] Document published on Sanity **`production`** dataset (not development only)
- [ ] `https://render.com/templates/dify` returns 200
- [ ] Catalog card shows hero image and description
- [ ] **Deploy this template** forks repo and Apply succeeds
