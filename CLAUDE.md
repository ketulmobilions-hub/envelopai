# Branching Strategy

Every issue must follow this workflow — no exceptions:

1. Always branch from `dev`: `git checkout dev && git pull && git checkout -b feat/<issue-number>-<short-slug>`
   - Example: `feat/1.1-flutter-scaffold`, `feat/2.3-drift-daos`
2. Use a Git worktree for the feature branch (keeps the working directory clean)
3. Do all work on the feature branch
4. Open a PR: `feat/*` → `dev` (never directly to `main`)
5. `main` is only updated via PR from `dev` at release milestones

```
main   ← releases only, PR from dev required
  dev  ← all feature PRs land here, no direct push
    feat/<issue-number>-<slug>  ← one branch per issue
```

Both `main` and `dev` have branch protection rules enforced on GitHub (no direct push, PR required).
