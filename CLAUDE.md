# Branching Strategy

Every feature follows this workflow — no exceptions:

1. Always branch from `dev`: `git checkout dev && git pull && git checkout -b feat/<issue-number>-<short-slug>`
   - Example: `feat/1.1-flutter-scaffold`, `feat/2.3-drift-daos`
2. Do all work on the feature branch
3. When the feature is complete, merge it directly into `dev`:
   ```
   git checkout dev && git pull && git merge feat/<issue-number>-<slug> && git push
   ```
4. After merging, close the corresponding GitHub issue
5. Delete the feature branch after merging
6. After all issues in a phase are merged into `dev`, merge `dev` into `main`:
   ```
   git checkout main && git pull && git merge dev && git push
   ```

No pull requests — all merges are done directly via the command line.

# Post-Merge Review Rule

**After merging every feature branch into `dev`**, always:
1. List all added and modified files from that feature (use `git show --stat <commit>`)
2. Present the review order following the data flow: domain models → events/states → bloc → widgets (smallest first) → page → plumbing (barrel, DI, router) → tests
3. Wait for the user to confirm they have reviewed the code before starting the next issue

```
main   ← phase releases only, merged from dev
  dev  ← all feature branches land here
    feat/<issue-number>-<slug>  ← one branch per issue, created from dev
```

# Code Review Rule

**Before every commit**, run the `code-reviewer` agent on all files changed in that issue. Fix every issue the agent raises before committing. Only commit once the agent reports no critical or warning-level findings.
