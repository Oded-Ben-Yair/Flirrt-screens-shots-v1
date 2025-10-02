#!/usr/bin/env python3
"""
Add PersonalizationData.swift to Xcode project targets
"""
import uuid
import re

pbxproj_path = '/Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI/iOS/Flirrt.xcodeproj/project.pbxproj'

# Generate unique IDs (24 hex chars format used in this project)
def gen_id():
    return 'B' + uuid.uuid4().hex[:23].upper()

# Read the pbxproj file
with open(pbxproj_path, 'r') as f:
    content = f.read()

# Generate IDs for new entries
file_ref_id = gen_id()
build_file_flirrt_id = gen_id()
build_file_keyboard_id = gen_id()

file_path = "Flirrt/Models/PersonalizationData.swift"
file_name = "PersonalizationData.swift"

# 1. Add PBXFileReference
file_ref_entry = f'\t\t{file_ref_id} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file_name}; sourceTree = "<group>"; }};\n'

# Find the end of PBXFileReference section
file_ref_pattern = r'(\/\* End PBXFileReference section \*\/)'
content = re.sub(file_ref_pattern, file_ref_entry + r'\1', content)

# 2. Add PBXBuildFile for Flirrt target
build_file_flirrt_entry = f'\t\t{build_file_flirrt_id} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {file_name} */; }};\n'

# 3. Add PBXBuildFile for FlirrtKeyboard target
build_file_keyboard_entry = f'\t\t{build_file_keyboard_id} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {file_name} */; }};\n'

# Find the end of PBXBuildFile section
build_file_pattern = r'(\/\* End PBXBuildFile section \*\/)'
content = re.sub(build_file_pattern, build_file_flirrt_entry + build_file_keyboard_entry + r'\1', content)

# 4. Add to Models group (find the Models group and add file reference)
# Search for Models group: A0070000000000000070000 /* Models */
models_group_pattern = r'(A0070000000000000070000 \/\* Models \*\/ = \{[^}]+children = \([^)]+)'
models_replacement = r'\1\t\t\t\t' + file_ref_id + ' /* ' + file_name + ' */,\n'
content = re.sub(models_group_pattern, models_replacement, content, flags=re.DOTALL)

# 5. Add to Flirrt target's Sources build phase
# Find Flirrt target sources
flirrt_sources_pattern = r'(A0082000000000000082000 \/\* Sources \*\/ = \{[^}]+files = \([^)]+)'
flirrt_sources_replacement = r'\1\t\t\t\t' + build_file_flirrt_id + ' /* ' + file_name + ' in Sources */,\n'
content = re.sub(flirrt_sources_pattern, flirrt_sources_replacement, content, flags=re.DOTALL)

# 6. Add to FlirrtKeyboard target's Sources build phase
# Find FlirrtKeyboard sources (A0086000000000000086000)
keyboard_sources_pattern = r'(A0086000000000000086000 \/\* Sources \*\/ = \{[^}]+files = \([^)]+)'
keyboard_sources_replacement = r'\1\t\t\t\t' + build_file_keyboard_id + ' /* ' + file_name + ' in Sources */,\n'
content = re.sub(keyboard_sources_pattern, keyboard_sources_replacement, content, flags=re.DOTALL)

# Write back
with open(pbxproj_path, 'w') as f:
    f.write(content)

print(f"✅ Added {file_name} to Xcode project")
print(f"   File Reference ID: {file_ref_id}")
print(f"   Flirrt Build File ID: {build_file_flirrt_id}")
print(f"   Keyboard Build File ID: {build_file_keyboard_id}")
