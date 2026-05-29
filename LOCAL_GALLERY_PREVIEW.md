# Preview on the real Render templates site (local)

The gallery at [render.com/templates](https://render.com/templates) is **`renderinc/website`**, not the template repo README alone. Template pages are **Sanity CMS documents** (`markdownBody` + metadata), served by Next.js.

## 1. Run the marketing site locally

From a clone of [renderinc/website](https://github.com/renderinc/website) (already at `github-repos/render-website` in this workspace):

```bash
cd github-repos/render-website
bun install
bun run dev
```

Open **http://localhost:3000/templates** (catalog). Example detail page: **http://localhost:3000/templates/flowise-with-postgres**.

Optional: add `GITHUB_ACCESS_TOKEN` to `.env` so repo star/fork counts load on cards.

## 2. Run Sanity Studio (to add / preview Dify)

In a second terminal:

```bash
cd github-repos/render-website
bun run sanity:dev
```

Open **http://localhost:3333**. Use the **`development`** dataset (dropdown, upper left), not `production`.

## 3. Create a draft Dify template in Sanity

In Studio → **Templates** → create document:

| Field | Value |
|-------|--------|
| Title | `Dify` |
| Slug | `dify` |
| Description | One-line pitch from README blockquote |
| GitHub Repository | `https://github.com/render-examples/dify-render-template` (or your fork while testing) |
| Image | Upload `assets/hero.png` when you have it (required for cards) |
| Stack | `docker`, `postgresql` (taxonomy multi-select) |
| Tags | `ai`, `ai-agent`, `llm` |
| Body (Markdown) | Paste contents of this repo's `README.md` (gallery page body) |

Click **Publish** (development dataset only). Use the **Preview** control in Studio to open **http://localhost:3000/templates/dify** with draft mode.

## 4. What you are previewing

- **Catalog card**: `/templates` grid (title, description, image, tags).
- **Detail page**: `/templates/dify` (markdown body, deploy button, repo stats, sidebar).

This matches production layout. Copy edits belong in Sanity `markdownBody` for the live site; keep `README.md` in the template repo in sync for GitHub and gallery submission.

## Do not edit `render-website` for template work

Pushing templates means updating **`dify-render-template`** (`render.yaml`, `README.md`, assets) and Sanity content via the templates team / Studio. No code changes to `renderinc/website` are required.
