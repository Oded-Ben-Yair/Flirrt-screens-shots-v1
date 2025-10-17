#!/usr/bin/env python3
"""
Xcode project.pbxproj File Adder
Safely adds a Swift file to an Xcode project with proper structure preservation.

This script was developed to add MinimalHomeView.swift to the Flirrt iOS project.
It properly handles all required sections of the pbxproj file:
- PBXBuildFile: Links the file to the build process
- PBXFileReference: Declares the file exists in the project
- PBXGroup: Adds the file to the Views folder in the project navigator
- PBXSourcesBuildPhase: Adds the file to the compilation phase

Key features:
- Creates timestamped backups before modification
- Generates unique 24-character UUIDs to avoid conflicts
- Validates syntax before writing changes
- Preserves exact formatting and indentation
- Fails safely if errors occur

Usage:
    python3 add_swift_file_to_xcode.py

Author: Claude Code
Date: October 11, 2025
"""

import os
import re
import hashlib
import time
from datetime import datetime

# Configuration
PROJECT_ROOT = "/Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI/FlirrtAI/iOS"
PBXPROJ_PATH = os.path.join(PROJECT_ROOT, "Flirrt.xcodeproj/project.pbxproj")
SWIFT_FILE_PATH = os.path.join(PROJECT_ROOT, "Flirrt/Views/MinimalHomeView.swift")
SWIFT_FILE_NAME = "MinimalHomeView.swift"
TARGET_GROUP = "Views"
TARGET_NAME = "Flirrt"

# Derived values
RELATIVE_PATH = SWIFT_FILE_NAME  # Path relative to the Views group


def generate_uuid(seed):
    """
    Generate a unique 24-character hex UUID that matches Xcode's format.
    Uses MD5 hash of seed + timestamp for uniqueness.
    """
    unique_seed = f"{seed}_{time.time()}_{os.urandom(8).hex()}"
    hash_obj = hashlib.md5(unique_seed.encode())
    return hash_obj.hexdigest()[:24].upper()


def collect_existing_uuids(content):
    """Extract all existing UUIDs from the project file to avoid conflicts."""
    uuid_pattern = r'\b[A-F0-9]{24}\b'
    return set(re.findall(uuid_pattern, content))


def generate_unique_uuid(seed, existing_uuids):
    """Generate a UUID that doesn't conflict with existing ones."""
    max_attempts = 1000
    for attempt in range(max_attempts):
        uuid = generate_uuid(f"{seed}_{attempt}")
        if uuid not in existing_uuids:
            existing_uuids.add(uuid)
            return uuid
    raise ValueError(f"Failed to generate unique UUID after {max_attempts} attempts")


def find_section_boundaries(content, section_name):
    """
    Find the start and end positions of a section in the pbxproj file.
    Returns (start_pos, end_pos) or None if not found.
    """
    pattern = rf'/\* Begin {re.escape(section_name)} section \*/'
    start_match = re.search(pattern, content)
    if not start_match:
        return None

    end_pattern = rf'/\* End {re.escape(section_name)} section \*/'
    end_match = re.search(end_pattern, content[start_match.end():])
    if not end_match:
        return None

    return (start_match.end(), start_match.end() + end_match.start())


def find_target_sources_build_phase(content, target_id):
    """Find the PBXSourcesBuildPhase UUID for the target."""
    # Look for the target definition
    target_pattern = rf'{target_id} /\* {re.escape(TARGET_NAME)} \*/ = {{'
    target_match = re.search(target_pattern, content)
    if not target_match:
        return None

    # Find the buildPhases section within this target
    # Look for a larger section to ensure we capture the buildPhases array
    target_section = content[target_match.start():target_match.start() + 3000]

    # Pattern to match build phases - Sources appears on its own line
    # Format: "UUID /* Sources */," on a line within buildPhases = ( ... );
    sources_pattern = r'buildPhases\s*=\s*\([^)]*?([A-F0-9]{24})\s*/\*\s*Sources\s*\*/'
    sources_match = re.search(sources_pattern, target_section, re.DOTALL)
    if sources_match:
        return sources_match.group(1)
    return None


def validate_file_exists():
    """Verify the Swift file exists."""
    if not os.path.exists(SWIFT_FILE_PATH):
        raise FileNotFoundError(f"Swift file not found: {SWIFT_FILE_PATH}")
    print(f"✓ Found Swift file: {SWIFT_FILE_PATH}")


def create_backup(filepath):
    """Create a timestamped backup of the project file."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = f"{filepath}.backup_{timestamp}"

    with open(filepath, 'r', encoding='utf-8') as src:
        content = src.read()

    with open(backup_path, 'w', encoding='utf-8') as dst:
        dst.write(content)

    print(f"✓ Created backup: {backup_path}")
    return backup_path


def check_if_file_already_added(content):
    """Check if the file is already in the project."""
    if SWIFT_FILE_NAME in content:
        raise ValueError(f"File '{SWIFT_FILE_NAME}' appears to already exist in project.pbxproj")


def add_to_pbxbuildfile_section(content, build_file_uuid, file_ref_uuid, existing_uuids):
    """Add entry to PBXBuildFile section."""
    section_bounds = find_section_boundaries(content, "PBXBuildFile")
    if not section_bounds:
        raise ValueError("Could not find PBXBuildFile section")

    start_pos, end_pos = section_bounds

    # Find the last entry in the section (before the End comment)
    section_content = content[start_pos:end_pos]

    # Create the new build file entry
    new_entry = f"\t\t{build_file_uuid} /* {SWIFT_FILE_NAME} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {SWIFT_FILE_NAME} */; }};\n"

    # Insert before the "/* End" line
    # Find the last semicolon before the end
    last_entry_end = section_content.rfind(';')
    if last_entry_end == -1:
        raise ValueError("Could not find insertion point in PBXBuildFile section")

    insert_pos = start_pos + last_entry_end + 2  # After ";\n"

    return content[:insert_pos] + new_entry + content[insert_pos:]


def add_to_pbxfilereference_section(content, file_ref_uuid, existing_uuids):
    """Add entry to PBXFileReference section."""
    section_bounds = find_section_boundaries(content, "PBXFileReference")
    if not section_bounds:
        raise ValueError("Could not find PBXFileReference section")

    start_pos, end_pos = section_bounds
    section_content = content[start_pos:end_pos]

    # Create the new file reference entry
    new_entry = f"\t\t{file_ref_uuid} /* {SWIFT_FILE_NAME} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {SWIFT_FILE_NAME}; sourceTree = \"<group>\"; }};\n"

    # Find insertion point (last entry before End comment)
    last_entry_end = section_content.rfind(';')
    if last_entry_end == -1:
        raise ValueError("Could not find insertion point in PBXFileReference section")

    insert_pos = start_pos + last_entry_end + 2

    return content[:insert_pos] + new_entry + content[insert_pos:]


def add_to_pbxgroup_section(content, file_ref_uuid, views_group_uuid):
    """Add file reference to the Views PBXGroup."""
    # Find the Views group
    group_pattern = rf'{views_group_uuid} /\* Views \*/ = {{'
    group_match = re.search(group_pattern, content)
    if not group_match:
        raise ValueError(f"Could not find Views group with UUID {views_group_uuid}")

    # Find the children array
    children_start = content.find('children = (', group_match.start())
    if children_start == -1:
        raise ValueError("Could not find children array in Views group")

    # Find the closing of children array
    children_end = content.find(');', children_start)
    if children_end == -1:
        raise ValueError("Could not find end of children array in Views group")

    # Insert the new file reference before the closing
    new_entry = f"\t\t\t\t{file_ref_uuid} /* {SWIFT_FILE_NAME} */,\n"

    # Find the last entry in children (just before ");")
    children_section = content[children_start:children_end]
    last_comma = children_section.rfind(',')
    if last_comma == -1:
        # No entries yet, insert after "children = ("
        insert_pos = children_start + len('children = (') + 1
    else:
        insert_pos = children_start + last_comma + 2  # After ",\n"

    return content[:insert_pos] + new_entry + content[insert_pos:]


def add_to_pbxsourcesbuildphase_section(content, build_file_uuid, sources_build_phase_uuid):
    """Add build file to PBXSourcesBuildPhase section."""
    # Find the specific sources build phase
    phase_pattern = rf'{sources_build_phase_uuid} /\* Sources \*/ = {{'
    phase_match = re.search(phase_pattern, content)
    if not phase_match:
        raise ValueError(f"Could not find Sources build phase with UUID {sources_build_phase_uuid}")

    # Find the files array
    files_start = content.find('files = (', phase_match.start())
    if files_start == -1:
        raise ValueError("Could not find files array in Sources build phase")

    # Find the closing of files array
    files_end = content.find(');', files_start)
    if files_end == -1:
        raise ValueError("Could not find end of files array in Sources build phase")

    # Create the new entry
    new_entry = f"\t\t\t\t{build_file_uuid} /* {SWIFT_FILE_NAME} in Sources */,\n"

    # Find last entry in files array
    files_section = content[files_start:files_end]
    last_comma = files_section.rfind(',')
    if last_comma == -1:
        insert_pos = files_start + len('files = (') + 1
    else:
        insert_pos = files_start + last_comma + 2

    return content[:insert_pos] + new_entry + content[insert_pos:]


def validate_pbxproj_syntax(content):
    """Basic validation of the pbxproj structure."""
    # Check that braces are balanced
    open_braces = content.count('{')
    close_braces = content.count('}')
    if open_braces != close_braces:
        raise ValueError(f"Unbalanced braces: {open_braces} open, {close_braces} close")

    # Check that all required sections exist
    required_sections = [
        "PBXBuildFile",
        "PBXFileReference",
        "PBXGroup",
        "PBXSourcesBuildPhase"
    ]

    for section in required_sections:
        if f"/* Begin {section} section */" not in content:
            raise ValueError(f"Missing required section: {section}")
        if f"/* End {section} section */" not in content:
            raise ValueError(f"Missing end marker for section: {section}")

    print("✓ Syntax validation passed")
    return True


def main():
    """Main execution function."""
    print("=" * 70)
    print("Xcode Project File Adder")
    print("=" * 70)
    print(f"Project: {PBXPROJ_PATH}")
    print(f"File: {SWIFT_FILE_NAME}")
    print(f"Target: {TARGET_NAME}")
    print(f"Group: {TARGET_GROUP}")
    print("=" * 70)
    print()

    try:
        # Step 1: Validate Swift file exists
        print("[1/9] Validating Swift file...")
        validate_file_exists()

        # Step 2: Create backup
        print("\n[2/9] Creating backup...")
        backup_path = create_backup(PBXPROJ_PATH)

        # Step 3: Read project file
        print("\n[3/9] Reading project file...")
        with open(PBXPROJ_PATH, 'r', encoding='utf-8') as f:
            content = f.read()
        print(f"✓ Read {len(content)} characters")

        # Step 4: Check if file already added
        print("\n[4/9] Checking for duplicates...")
        check_if_file_already_added(content)
        print("✓ File not found in project (good)")

        # Step 5: Collect existing UUIDs
        print("\n[5/9] Collecting existing UUIDs...")
        existing_uuids = collect_existing_uuids(content)
        print(f"✓ Found {len(existing_uuids)} existing UUIDs")

        # Step 6: Generate new UUIDs
        print("\n[6/9] Generating unique UUIDs...")
        file_ref_uuid = generate_unique_uuid("file_ref_MinimalHomeView", existing_uuids)
        build_file_uuid = generate_unique_uuid("build_file_MinimalHomeView", existing_uuids)
        print(f"✓ File Reference UUID: {file_ref_uuid}")
        print(f"✓ Build File UUID: {build_file_uuid}")

        # Step 7: Find required IDs from existing structure
        print("\n[7/9] Locating project structure...")

        # Find Views group UUID
        views_group_pattern = r'(A0079000000000000079000) /\* Views \*/'
        views_match = re.search(views_group_pattern, content)
        if not views_match:
            raise ValueError("Could not find Views group UUID")
        views_group_uuid = views_match.group(1)
        print(f"✓ Views Group UUID: {views_group_uuid}")

        # Find Flirrt target UUID
        target_pattern = r'(A0055000000000000055000) /\* Flirrt \*/ = {'
        target_match = re.search(target_pattern, content)
        if not target_match:
            raise ValueError("Could not find Flirrt target UUID")
        target_uuid = target_match.group(1)
        print(f"✓ Target UUID: {target_uuid}")

        # Find Sources build phase UUID
        # Known UUID from project structure analysis
        sources_phase_uuid = "A0081000000000000081000"
        print(f"✓ Sources Build Phase UUID: {sources_phase_uuid}")

        # Step 8: Add file to all sections
        print("\n[8/9] Adding file to project sections...")

        print("  - Adding to PBXFileReference...")
        content = add_to_pbxfilereference_section(content, file_ref_uuid, existing_uuids)

        print("  - Adding to PBXBuildFile...")
        content = add_to_pbxbuildfile_section(content, build_file_uuid, file_ref_uuid, existing_uuids)

        print("  - Adding to PBXGroup (Views)...")
        content = add_to_pbxgroup_section(content, file_ref_uuid, views_group_uuid)

        print("  - Adding to PBXSourcesBuildPhase...")
        content = add_to_pbxsourcesbuildphase_section(content, build_file_uuid, sources_phase_uuid)

        print("✓ All sections updated")

        # Step 9: Validate and write
        print("\n[9/9] Validating and writing changes...")
        validate_pbxproj_syntax(content)

        with open(PBXPROJ_PATH, 'w', encoding='utf-8') as f:
            f.write(content)

        print(f"✓ Written updated project file")

        print("\n" + "=" * 70)
        print("SUCCESS!")
        print("=" * 70)
        print(f"\nFile '{SWIFT_FILE_NAME}' has been added to the Xcode project.")
        print(f"\nNext steps:")
        print(f"1. Open Xcode: open {os.path.join(PROJECT_ROOT, 'Flirrt.xcodeproj')}")
        print(f"2. Verify the file appears in the Views folder")
        print(f"3. Build the project to confirm no errors")
        print(f"\nBackup saved at: {backup_path}")
        print("\nIf something goes wrong, restore with:")
        print(f"  cp {backup_path} {PBXPROJ_PATH}")
        print()

    except Exception as e:
        print("\n" + "=" * 70)
        print("ERROR!")
        print("=" * 70)
        print(f"\n{type(e).__name__}: {str(e)}")
        print(f"\nThe project file was NOT modified.")
        if 'backup_path' in locals():
            print(f"Backup is available at: {backup_path}")
        print("\nPlease review the error and try again.")
        print()
        return 1

    return 0


if __name__ == "__main__":
    exit(main())
