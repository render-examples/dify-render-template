# Deploy to Render Button

Canonical badge and URL formats the skill emits in template READMEs.

There are two distinct Deploy flows. **Templates use the one-click flow, not the Blueprint deploy flow.** Picking the wrong one breaks the gallery experience.

## Two flows, two URLs

| Flow | URL pattern | What it does | When to use |
|------|-------------|--------------|-------------|
| **One-click template** (this skill) | `https://render.com/deploy-template/api/github/start?template_repo=<repo-slug>` | Creates a **fresh GitHub repo in the user's account** from your GitHub template repo, then runs the Render Blueprint inside that new repo | All Render templates. Always. |
| **Blueprint deploy** | `https://render.com/deploy?repo=<HTTPS_REPO_URL>` | Deploys directly from an existing repo without forking | One-off deploys of the user's own app; never for templates |

The one-click flow gives every gallery user their own copy of the template repo (so they can edit `render.yaml`, customize, push to redeploy) instead of pointing thousands of users at one shared upstream.

## One-click template URL (use this)

```
https://render.com/deploy-template/api/github/start?template_repo=<repo-slug>
```

Where `<repo-slug>` is the **bare repository name** (no `owner/` prefix) of a repo under the `render-examples` GitHub organization that has been marked as a **GitHub template repository**.

Markdown:

```markdown
[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy-template/api/github/start?template_repo=<repo-slug>)
```

HTML (when GitHub-Flavored Markdown stripping is a concern):

```html
<a href="https://render.com/deploy-template/api/github/start?template_repo=<repo-slug>">
  <img src="https://render.com/images/deploy-to-render-button.svg" alt="Deploy to Render">
</a>
```

## Hard requirements for the one-click flow

For the URL above to work, all three must be true:

1. **The repo lives under `render-examples`** on GitHub. The one-click endpoint resolves `template_repo` against that org.
2. **The repo is marked as a GitHub template repository** (`is_template: true`). GitHub then exposes the "Use this template" API the one-click flow calls to fork into the end user's account.
3. **The repo's default branch has a valid `render.yaml`** at the root. After the user-side repo is created, Render runs the Blueprint inside it.

If any of these is false, the user lands on a "repository not found" or "this repo is not a template" error.

## Mark a repo as a GitHub template

Either:

**Via `gh` CLI:**
```bash
gh api -X PATCH repos/render-examples/<repo-slug> -f is_template=true
```

**Via the GitHub UI:**
Repo → **Settings** → **General** → tick **Template repository**.

Verify:
```bash
gh api repos/render-examples/<repo-slug> --jq .is_template
# → true
```

## What happens when a user clicks the button

1. They're sent to `https://render.com/deploy-template/api/github/start?template_repo=<repo-slug>`.
2. Render asks them to authorize the Render GitHub App (one-time).
3. Render asks them to pick a destination GitHub account or org.
4. Render calls GitHub's template-repo API to create `<their-account>/<repo-slug>` from `render-examples/<repo-slug>`.
5. Render reads `render.yaml` from the new user-side repo and opens the Blueprint apply screen.
6. The user fills in any `sync: false` secrets and clicks Apply.
7. First deploy starts inside the user's own repo, which they can clone, edit, and push to for subsequent deploys.

## Branch override

The one-click endpoint does not support `&branch=` — templates must live on the default branch. If you keep a template on a non-default branch for staging, **set that branch as the repo's default before publishing**, or move `render.yaml` to the default branch.

## Repo-name conventions

- Use bare hyphenated slugs: `flowise-render-template`, `n8n`, `mcp-server-python`. Render's templates team will sometimes shorten the gallery slug, but the GitHub repo name is what the one-click URL needs.
- Avoid uppercase letters; URLs are case-sensitive in some flows.
- Avoid trailing version numbers in the repo name; pin the upstream version inside `render.yaml` instead.

## Where to put the button in the README

- **Always at the top**, immediately after the H1 and the one-sentence pitch.
- Repeat once inside the "Quickstart" section so users who scrolled past the hero still see it.

## Common mistakes

| Mistake | Fix |
|---------|-----|
| Used `?repo=` instead of `?template_repo=` | Switch URLs; the `?repo=` flow does not fork |
| Passed `owner/repo` to `template_repo` | Pass the bare repo slug only |
| Repo is under personal account, not `render-examples` | Transfer the repo to `render-examples` (Render team can do this during gallery onboarding) |
| Repo is not marked as GitHub template | Run the `gh api ... -f is_template=true` patch above |
| `render.yaml` lives on a non-default branch | Move it to the default branch or change the default branch |
| README's Deploy button still points at a placeholder slug | Replace `<repo-slug>` with the real bare repo name |
