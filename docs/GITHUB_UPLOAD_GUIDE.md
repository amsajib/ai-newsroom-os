# Upload this bundle to GitHub from a phone or computer

Target repository: `https://github.com/amsajib/ai-newsroom-os`

## Option A — GitHub website

1. Download and extract `ai-newsroom-os-starter.zip` on a computer if possible.
2. Open the repository and ensure the `main` branch is selected.
3. Choose **Add file → Upload files**.
4. Upload the extracted bundle's contents (including folders), not the ZIP file itself.
5. Review the file list. Do not upload `.env`, tokens, credentials, or generated secret files.
6. Enter commit message: `chore: add AI Newsroom OS starter bundle`.
7. Commit to `main` or create a feature branch and open a pull request.

Mobile browser upload support for folders can be limited. If GitHub cannot upload directories from the phone, use GitHub Desktop or the Git CLI on a computer, or upload smaller folders through the website.

## Option B — Git CLI

Extract the ZIP, then from the extracted folder:

```bash
git clone https://github.com/amsajib/ai-newsroom-os.git
cd ai-newsroom-os
# Copy the extracted bundle contents into this repository directory.
git add .
git status
git commit -m "chore: add AI Newsroom OS starter bundle"
git push origin main
```

If `git clone` says the repository is empty or your local clone was created earlier, initialize/clone as appropriate and inspect `git status` before committing. Never force-push to resolve an ordinary upload problem.

## After upload

- Check that `README.md`, `docs/architecture.md`, `database/`, `apps/`, `contracts/`, and `tests/` appear in the repository.
- Keep the repository private if it will contain non-public project logic.
- Configure secrets in the deployment platform's secret settings, not GitHub source files.
- Do not run the production database migration until it has been reviewed and explicitly approved.
