# Contributing

ForgeBuild uses `main`, `develop`, `feature/*`, and `hotfix/*` branches. Work should normally enter `develop` through a focused pull request.

Before committing, run:

```bash
rake syntax test
```

Keep SketchUp APIs at the UI/geometry boundaries, inject dependencies into domain services, add a regression test for every bug fix, and update the changelog for user-visible changes.
