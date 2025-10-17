#!/bin/bash
# Setup git worktrees for parallel development
set -euo pipefail

CLAUDE_DIR="${CLAUDE_PROJECT_DIR:-/Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI}"

echo "🌳 Setting up git worktrees for parallel development..."

# Function to create a worktree safely
create_worktree() {
    local name=$1
    local description=$2

    if [ -d "$CLAUDE_DIR/trees/$name" ]; then
        echo "  ⚠️ Worktree '$name' already exists"
        return 0
    fi

    echo "  Creating worktree: $name"
    git worktree add -b "fix-$name" "trees/$name" 2>/dev/null || {
        # If branch exists, check it out instead
        git worktree add "trees/$name" "fix-$name" 2>/dev/null || {
            echo "  ❌ Could not create worktree '$name'"
            return 1
        }
    }

    # Create todo file for the worktree
    mkdir -p "trees/$name/.claude"
    echo "# TODO: $description" > "trees/$name/.claude/todo.md"
    echo "  ✅ Worktree '$name' created with task: $description"
}

# Navigate to project directory
cd "$CLAUDE_DIR"

# Ensure we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Not a git repository. Please initialize git first."
    exit 1
fi

# Create worktrees directory if it doesn't exist
mkdir -p trees

# Create worktrees for each fix
echo "Creating specialized worktrees..."

create_worktree "keyboard" "Fix keyboard API connection - Replace local methods with URLSession calls"
create_worktree "screenshot" "Add screenshot capture - Implement PHPhotoLibrary integration"
create_worktree "voice" "Implement voice scripts - Add script selection UI"
create_worktree "onboarding" "Connect onboarding flow - Link Fresh button to main app"

# List all worktrees
echo -e "\n📊 Worktree Status:"
git worktree list || true

echo -e "\n✅ Worktrees setup complete!"
echo "🚀 Each worktree is isolated and ready for parallel development"
echo "💡 Use 'cd trees/<name>' to work on a specific fix"