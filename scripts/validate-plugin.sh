#!/bin/bash
# Static validation script for compound-engineering plugin
# Checks YAML frontmatter, cross-references, and component counts

set -e

PLUGIN_DIR="plugins/compound-engineering"
ERRORS=0

echo "=== Compound Engineering Plugin Validator ==="
echo ""

# 1. Count components
AGENT_COUNT=$(find "$PLUGIN_DIR/agents" -name "*.md" | wc -l)
COMMAND_COUNT=$(find "$PLUGIN_DIR/commands" -name "*.md" | wc -l)
SKILL_COUNT=$(find "$PLUGIN_DIR/skills" -maxdepth 1 -type d | grep -v "^$PLUGIN_DIR/skills$" | wc -l)

echo "Component counts:"
echo "  Agents:   $AGENT_COUNT"
echo "  Commands: $COMMAND_COUNT"
echo "  Skills:   $SKILL_COUNT"
echo ""

# 2. Check plugin.json description matches counts
PLUGIN_JSON="$PLUGIN_DIR/.claude-plugin/plugin.json"
if [ -f "$PLUGIN_JSON" ]; then
    DESC=$(grep '"description"' "$PLUGIN_JSON")
    echo "plugin.json description:"
    echo "  $DESC"

    # Check if counts in description match actual
    DESC_AGENTS=$(echo "$DESC" | grep -oP '\d+ agents' | grep -oP '\d+')
    DESC_COMMANDS=$(echo "$DESC" | grep -oP '\d+ commands' | grep -oP '\d+')
    DESC_SKILLS=$(echo "$DESC" | grep -oP '\d+ skills' | grep -oP '\d+')

    if [ "$DESC_AGENTS" != "$AGENT_COUNT" ]; then
        echo "  ERROR: Description says $DESC_AGENTS agents, found $AGENT_COUNT"
        ERRORS=$((ERRORS + 1))
    fi
    if [ "$DESC_COMMANDS" != "$COMMAND_COUNT" ]; then
        echo "  ERROR: Description says $DESC_COMMANDS commands, found $COMMAND_COUNT"
        ERRORS=$((ERRORS + 1))
    fi
    if [ "$DESC_SKILLS" != "$SKILL_COUNT" ]; then
        echo "  ERROR: Description says $DESC_SKILLS skills, found $SKILL_COUNT"
        ERRORS=$((ERRORS + 1))
    fi
    echo ""
fi

# 3. Check YAML frontmatter for required fields
echo "Checking YAML frontmatter..."
for f in $(find "$PLUGIN_DIR/agents" "$PLUGIN_DIR/commands" -name "*.md"); do
    # Check for name field
    if ! head -20 "$f" | grep -q "^name:"; then
        echo "  WARN: Missing 'name' in frontmatter: $f"
    fi
    # Check for description field
    if ! head -20 "$f" | grep -q "^description:"; then
        echo "  WARN: Missing 'description' in frontmatter: $f"
    fi
done
echo "  Done."
echo ""

# 4. Check skill SKILL.md files exist
echo "Checking skill SKILL.md files..."
for d in $(find "$PLUGIN_DIR/skills" -maxdepth 1 -type d | grep -v "^$PLUGIN_DIR/skills$"); do
    if [ ! -f "$d/SKILL.md" ]; then
        echo "  ERROR: Missing SKILL.md in $d"
        ERRORS=$((ERRORS + 1))
    fi
done
echo "  Done."
echo ""

# 5. Check review command agent references
echo "Checking review command agent references..."
REVIEW_FILE="$PLUGIN_DIR/commands/workflows/review.md"
if [ -f "$REVIEW_FILE" ]; then
    # Extract agent names referenced in review command
    for agent in $(grep -oP 'Task [a-z][-a-z]*' "$REVIEW_FILE" | sed 's/Task //' | sort -u); do
        found=$(find "$PLUGIN_DIR/agents" -name "${agent}.md" | wc -l)
        if [ "$found" -eq 0 ]; then
            echo "  WARN: Agent '$agent' referenced in review.md but not found in agents/"
        fi
    done
fi
echo "  Done."
echo ""

# 6. Check for Ruby/Rails remnants
echo "Checking for Ruby/Rails remnants..."
REMNANTS=$(grep -rl "Rails\|Gemfile\|bundle exec\|bin/rails\|rspec\|ActiveRecord\|schema\.rb" \
    "$PLUGIN_DIR/agents/" "$PLUGIN_DIR/commands/" "$PLUGIN_DIR/skills/" 2>/dev/null \
    | grep -v "kieran-typescript" || true)
if [ -n "$REMNANTS" ]; then
    echo "  WARN: Found Ruby/Rails references in:"
    echo "$REMNANTS" | while read -r f; do
        echo "    $f"
    done
else
    echo "  Clean - no Ruby/Rails remnants found."
fi
echo ""

# Summary
echo "=== Validation Summary ==="
if [ "$ERRORS" -gt 0 ]; then
    echo "FAILED: $ERRORS error(s) found"
    exit 1
else
    echo "PASSED: No errors found"
fi
