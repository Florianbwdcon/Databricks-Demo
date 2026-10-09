# Databricks-Demo

Sample data and storyline for a Databricks demo using Genie. The storyline is in `Context.md`.

## Project language

- The project language is English. All files, documentation, table and column names, sample data values, code comments and commit messages are written in English.
- Chat with Florian may be in German, but everything that ends up in the repository is English.

## Git workflow

- `dev` is the working branch. Florian keeps `dev` checked out locally.
- A finished feature is always merged into `dev` and pushed to `origin/dev`.
- Right after pushing to `origin/dev`, Claude also updates the local checkout (`git pull --ff-only` on `dev`) so that local and GitHub are in sync.
- When Claude works isolated in a worktree, its branch is temporary: after the merge into `dev` it is not reused and not pushed to GitHub as a separate branch.
- Do not push to `master`.
- The `.claude` folders are not checked in (see `.gitignore`).
