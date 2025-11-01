# Git Worktrees Workflow for Vibe8 Development

## Why Git Worktrees?

Git worktrees allow multiple agents to work on different features simultaneously in isolated working directories, all sharing the same .git directory. This enables true parallel development without branch switching conflicts.

## Directory Structure

```
~/FlirrtAI/                           # Main repository
~/FlirrtAI-worktrees/                 # Isolated worktrees for parallel development
├── feature-architecture/             # iOS Developer Agent
├── feature-design-system/            # UX/UI Designer Agent
├── feature-tests/                    # QA Engineer Agent
├── feature-multi-model-ai/           # AI/ML Engineer Agent
└── feature-gamification/             # Gamification Specialist Agent
```

## Creating a Worktree

```bash
cd ~/FlirrtAI
git worktree add ~/FlirrtAI-worktrees/feature-name develop
```

This creates a new worktree based on the `develop` branch.

## Working in a Worktree

```bash
cd ~/FlirrtAI-worktrees/feature-name

# Create feature branch
git checkout -b feature/my-feature

# Make changes
# ... edit files ...

# Commit changes
git add .
git commit -m "feat: Add new feature"

# Push to remote
git push origin feature/my-feature
```

## Merging Back to Main Repository

### Option 1: Via Pull Request (Recommended)
```bash
# Push your branch
git push origin feature/my-feature

# Create PR via GitHub
gh pr create --title "Feature: My Feature" --body "Description of changes"

# After approval and CI passes
gh pr merge --squash
```

### Option 2: Direct Merge (for small changes)
```bash
cd ~/FlirrtAI
git checkout develop
git merge --no-ff feature/my-feature
git push origin develop
```

## Cleaning Up a Worktree

After your feature is merged:

```bash
cd ~/FlirrtAI
git worktree remove ~/FlirrtAI-worktrees/feature-name

# Delete the feature branch
git branch -d feature/my-feature
git push origin --delete feature/my-feature
```

## Best Practices

1. **One feature per worktree** - Keep worktrees focused on single features
2. **Regular commits** - Commit often with clear messages
3. **Stay up to date** - Regularly merge/rebase from develop
4. **CI must pass** - Never merge if CI is failing
5. **Code review** - Always request code review before merging
6. **Clean up** - Remove worktrees after feature is merged

## Coordination Between Agents

- **Memory MCP**: Document major decisions and progress
- **GitHub Issues**: Track bugs and feature requests
- **Pull Requests**: Code review between agents
- **CI/CD**: Automated testing ensures integration works

## Common Commands

```bash
# List all worktrees
git worktree list

# Prune removed worktrees
git worktree prune

# Check status across all worktrees
git worktree list

# Move to main repo
cd ~/FlirrtAI

# Move to worktree
cd ~/FlirrtAI-worktrees/feature-name
```

## Troubleshooting

### Worktree already exists
```bash
git worktree remove ~/FlirrtAI-worktrees/feature-name --force
git worktree add ~/FlirrtAI-worktrees/feature-name develop
```

### Conflicts when merging
```bash
cd ~/FlirrtAI-worktrees/feature-name
git fetch origin
git rebase origin/develop
# Resolve conflicts
git add .
git rebase --continue
```

### Worktree is locked
```bash
cd ~/FlirrtAI
rm .git/worktrees/feature-name/lock
```

---

This worktree workflow enables the 6 Vibe8 implementation agents to work truly in parallel without stepping on each other's toes.
