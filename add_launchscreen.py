#!/usr/bin/env python3
import sys
import uuid
import re

# Generate UUIDs
file_ref_uuid = uuid.uuid4().hex[:24].upper()
build_file_uuid = uuid.uuid4().hex[:24].upper()

print(f"File Ref UUID: {file_ref_uuid}")
print(f"Build File UUID: {build_file_uuid}")

# Read the project file
with open('LanguageTransfer.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Check if already added
if 'LaunchScreen.storyboard' in content:
    print("LaunchScreen.storyboard already in project")
    sys.exit(0)

# Add PBXBuildFile entry
build_file_entry = f"\t\t{build_file_uuid} /* LaunchScreen.storyboard in Resources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* LaunchScreen.storyboard */; }};\n"
content = content.replace(
    "/* End PBXBuildFile section */",
    build_file_entry + "/* End PBXBuildFile section */"
)

# Add PBXFileReference entry  
file_ref_entry = f"\t\t{file_ref_uuid} /* LaunchScreen.storyboard */ = {{isa = PBXFileReference; lastKnownFileType = file.storyboard; path = LaunchScreen.storyboard; sourceTree = \"<group>\"; }};\n"
content = content.replace(
    "/* End PBXFileReference section */",
    file_ref_entry + "/* End PBXFileReference section */"
)

# Add to LanguageTransfer group (541E8F06610751638BD6311A)
# Find the group and add the reference
group_pattern = r"(541E8F06610751638BD6311A /\* LanguageTransfer \*/ = \{[^}]+children = \([^)]+)"
match = re.search(group_pattern, content, re.DOTALL)
if match:
    group_content = match.group(1)
    # Add the file reference before the closing parenthesis
    updated_group = group_content + f"\t\t\t\t{file_ref_uuid} /* LaunchScreen.storyboard */,\n"
    content = content.replace(group_content, updated_group)

# Add to Resources build phase (208692AEFB182E42258CB9E2)
resources_pattern = r"(208692AEFB182E42258CB9E2 /\* Resources \*/ = \{[^}]+files = \([^)]+)"
match = re.search(resources_pattern, content, re.DOTALL)
if match:
    resources_content = match.group(1)
    updated_resources = resources_content + f"\t\t\t\t{build_file_uuid} /* LaunchScreen.storyboard in Resources */,\n"
    content = content.replace(resources_content, updated_resources)

# Write back
with open('LanguageTransfer.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("✅ LaunchScreen.storyboard added to Xcode project")
