#!/bin/bash
# Claude Code Hook: Check Documentation Policy
# Warns if creating .md files outside docs/ folder

FILE_PATH="$CLAUDE_TOOL_INPUT_file_path"

if [[ "$FILE_PATH" == *.md ]]; then
  if [[ "$FILE_PATH" != docs/* ]] && [[ "$FILE_PATH" != *CLAUDE.md ]] && [[ "$FILE_PATH" != *README.md ]] && [[ "$FILE_PATH" != *.archive/* ]]; then
    echo "⚠️  WARNING: Creating .md file outside docs/ folder"
    echo "📚 Documentation Policy: All docs go in docs/ folder"
    echo "   - Status updates → Update docs/KNOWN_ISSUES.md"
    echo "   - Session notes → Update CLAUDE.md only"
    echo "   - New docs → Add to docs/ folder (max 10 files)"
    echo ""
    echo "Proceed only if this is intentional."
    echo ""
  fi
fi

# Check for documentation bloat patterns
if [[ "$FILE_PATH" == *SESSION_* ]] || [[ "$FILE_PATH" == *STATUS_* ]] || [[ "$FILE_PATH" == *REPORT_* ]] || [[ "$FILE_PATH" == *HANDOFF_* ]]; then
  echo "🚫 STOP: File name matches bloat pattern!"
  echo "   SESSION_*, STATUS_*, REPORT_*, HANDOFF_* files are not allowed"
  echo "   Use docs/KNOWN_ISSUES.md and CLAUDE.md instead"
  echo ""
  echo "Previous cleanup removed 216 files with these patterns."
  echo "Do NOT recreate the mess!"
  echo ""
fi
