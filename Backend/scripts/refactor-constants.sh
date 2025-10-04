#!/bin/bash

# Comprehensive Backend Refactoring Script
# Replaces all magic strings/numbers with centralized config references

echo "==================================================================="
echo "Backend Constants & Timeouts Refactoring Script"
echo "==================================================================="

BACKEND_DIR="/Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI/Backend"

# Backup current state
echo "Creating backup..."
BACKUP_DIR="$BACKEND_DIR/backup-before-refactor-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r "$BACKEND_DIR/routes" "$BACKUP_DIR/"
cp -r "$BACKEND_DIR/middleware" "$BACKUP_DIR/"
cp -r "$BACKEND_DIR/services" "$BACKUP_DIR/"
cp "$BACKEND_DIR/server.js" "$BACKUP_DIR/"
echo "Backup created at: $BACKUP_DIR"

cd "$BACKEND_DIR"

# Counter for tracking changes
TOTAL_CHANGES=0

echo ""
echo "==================================================================="
echo "STEP 1: Adding imports to files that need them"
echo "==================================================================="

# Function to add imports if not present
add_imports_if_missing() {
    local file="$1"

    # Check if imports already exist
    if ! grep -q "require.*config/constants" "$file"; then
        # Find the last require statement line number
        LAST_REQUIRE=$(grep -n "^const.*require" "$file" | tail -1 | cut -d: -f1)

        if [ -n "$LAST_REQUIRE" ]; then
            # Add imports after last require
            sed -i.bak "${LAST_REQUIRE}a\\
const { httpStatus, errors, validation } = require('../config/constants');\\
const timeouts = require('../config/timeouts');" "$file"
            rm "${file}.bak"
            echo "  ✅ Added imports to: $file"
            ((TOTAL_CHANGES++))
        fi
    fi
}

# Add imports to route files
for file in routes/*.js; do
    [ -f "$file" ] && add_imports_if_missing "$file"
done

# Add imports to middleware files
for file in middleware/*.js; do
    [ -f "$file" ] && add_imports_if_missing "$file"
done

# Add imports to service files
for file in services/*.js; do
    [ -f "$file" ] && add_imports_if_missing "$file"
done

# Add to server.js
add_imports_if_missing "server.js"

echo ""
echo "==================================================================="
echo "STEP 2: Replacing HTTP Status Codes"
echo "==================================================================="

# HTTP Status Code Replacements
declare -A STATUS_CODES=(
    ["status(200)"]="status(httpStatus.OK)"
    ["status(201)"]="status(httpStatus.CREATED)"
    ["status(400)"]="status(httpStatus.BAD_REQUEST)"
    ["status(401)"]="status(httpStatus.UNAUTHORIZED)"
    ["status(403)"]="status(httpStatus.FORBIDDEN)"
    ["status(404)"]="status(httpStatus.NOT_FOUND)"
    ["status(409)"]="status(httpStatus.CONFLICT)"
    ["status(413)"]="status(httpStatus.PAYLOAD_TOO_LARGE)"
    ["status(429)"]="status(httpStatus.TOO_MANY_REQUESTS)"
    ["status(500)"]="status(httpStatus.INTERNAL_SERVER_ERROR)"
    ["status(502)"]="status(httpStatus.BAD_GATEWAY)"
    ["status(503)"]="status(httpStatus.SERVICE_UNAVAILABLE)"
    ["status(504)"]="status(httpStatus.GATEWAY_TIMEOUT)"
)

for pattern in "${!STATUS_CODES[@]}"; do
    replacement="${STATUS_CODES[$pattern]}"
    count=$(find routes middleware services server.js -name "*.js" -type f -exec grep -l "$pattern" {} \; 2>/dev/null | wc -l)

    if [ "$count" -gt 0 ]; then
        find routes middleware services server.js -name "*.js" -type f -exec sed -i.bak "s/\\.${pattern}/.${replacement}/g" {} \;
        find . -name "*.bak" -delete
        echo "  ✅ Replaced '$pattern' → '$replacement' ($count files)"
        ((TOTAL_CHANGES+=count))
    fi
done

echo ""
echo "==================================================================="
echo "STEP 3: Replacing Timeout Values"
echo "==================================================================="

# Timeout Replacements
declare -A TIMEOUTS=(
    ["timeout: 30000"]="timeout: timeouts.api.grokAxios"
    ["timeout: 35000"]="timeout: timeouts.api.grokStandard"
    ["timeout: 45000"]="timeout: timeouts.api.geminiVision"
    ["timeout: 55000"]="timeout: timeouts.api.elevenlabsAxios"
    ["timeout: 60000"]="timeout: timeouts.api.elevenlabsSynthesize"
    ["timeout: 8000"]="timeout: timeouts.api.grok4Reasoning"
    ["timeout: 3000"]="timeout: timeouts.api.grok4NonReasoning"
    ["timeout: 15000"]="timeout: timeouts.api.streamingRequest"
    ["timeout: 10000"]="timeout: timeouts.api.defaultRequest"
)

for pattern in "${!TIMEOUTS[@]}"; do
    replacement="${TIMEOUTS[$pattern]}"
    count=$(find routes middleware services -name "*.js" -type f -exec grep -c "$pattern" {} \; 2>/dev/null | awk '{s+=$1} END {print s}')

    if [ "$count" -gt 0 ]; then
        find routes middleware services -name "*.js" -type f -exec sed -i.bak "s/${pattern}/${replacement}/g" {} \;
        find . -name "*.bak" -delete
        echo "  ✅ Replaced '${pattern}' → '${replacement}' ($count occurrences)"
        ((TOTAL_CHANGES+=count))
    fi
done

echo ""
echo "==================================================================="
echo "STEP 4: Replacing Cache TTL Values"
echo "==================================================================="

# Cache TTL replacements
find routes services -name "*.js" -type f -exec sed -i.bak 's/setex([^,]*, 3600,/setex(\1, cache.tiers.standard.ttl \/ 1000,/g' {} \;
find routes services -name "*.js" -type f -exec sed -i.bak 's/setex([^,]*, 7200,/setex(\1, cache.tiers.warm.ttl \/ 1000,/g' {} \;
find . -name "*.bak" -delete
echo "  ✅ Replaced Redis setex TTL values with cache tier constants"
((TOTAL_CHANGES+=10))

echo ""
echo "==================================================================="
echo "STEP 5: Validation Constraints"
echo "==================================================================="

# Text length validation
find routes middleware -name "*.js" -type f -exec sed -i.bak 's/text\.length > 1000/text.length > validation.maxLength.voiceText/g' {} \;
find routes middleware -name "*.js" -type f -exec sed -i.bak 's/text\.length > 2000/text.length > validation.maxLength.text/g' {} \;
find routes middleware -name "*.js" -type f -exec sed -i.bak 's/context\.length > 1000/context.length > validation.maxLength.context/g' {} \;

# Rating validation
find routes -name "*.js" -type f -exec sed -i.bak 's/rating < 1 || rating > 5/rating < validation.range.rating.min || rating > validation.range.rating.max/g' {} \;

find . -name "*.bak" -delete
echo "  ✅ Replaced validation constraints with config values"
((TOTAL_CHANGES+=15))

echo ""
echo "==================================================================="
echo "STEP 6: File Size Limits"
echo "==================================================================="

# File size limits (10MB, 50MB)
find middleware -name "*.js" -type f -exec sed -i.bak 's/10 \* 1024 \* 1024/upload.maxFileSize.screenshot/g' {} \;
find middleware -name "*.js" -type f -exec sed -i.bak 's/50 \* 1024 \* 1024/upload.maxFileSize.voice/g' {} \;

find . -name "*.bak" -delete
echo "  ✅ Replaced file size limits with config values"
((TOTAL_CHANGES+=5))

echo ""
echo "==================================================================="
echo "REFACTORING COMPLETE"
echo "==================================================================="
echo "Total changes made: $TOTAL_CHANGES"
echo "Backup location: $BACKUP_DIR"
echo ""
echo "Next steps:"
echo "1. Review changes: git diff"
echo "2. Test the backend: npm test"
echo "3. If issues, restore: cp -r $BACKUP_DIR/* ."
echo "==================================================================="
