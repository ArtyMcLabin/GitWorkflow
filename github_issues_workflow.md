# GitHub Issues Workflow Standard

This document defines the standard format for GitHub issue creation and management.

## Issue Format
1. Title Format:
   - Clear and concise
   - Start with type: [Bug], [Feature], [Enhancement], etc.
   - Example: "[Bug] Login button not working"

2. Body Structure:
   IMPORTANT: Always include TWO newlines between sections to ensure proper formatting!
   
   ```markdown
   ## Overview

   Brief overview of the issue or feature request.


   ## Description

   Detailed explanation of what needs to be done or what the problem is.


   ## Technical Details

   - Requirement 1
   - Requirement 2
   - Implementation notes


   ## Expected Behavior

   What should happen when this is implemented.


   ## Current Behavior
   (For bugs only - remove for feature requests)

   What is currently happening that needs to be fixed.


   ## Additional Notes

   Any extra context or information.
   ```

   Key formatting rules:
   - Use TWO blank lines between sections (double \n\n)
   - Start each section with h2 (##) headers
   - Add empty line after lists
   - Keep consistent header hierarchy

3. Standard Labels:
   - `ai-generated`: For issues created by AI
   - `human-approved-request`: For human-approved issues
   - `ai-implemented`: For AI-resolved issues
   - `needs-human-review`: For issues needing human oversight

4. Cross-Repository Support:
   - Include target repository in format: "owner/repo"
   - Example: "ArtyMcLabin/GitWorkflow"

## Issue Management
1. Creation:
   - Follow the format above
   - Include all relevant sections
   - Apply appropriate labels
   - After creation, ALWAYS provide the direct link to the created issue

2. Updates:
   - Keep discussion in comments
   - Update labels as status changes
   - Link related PRs/commits

3. Resolution:
   - Include implementation reference
   - Add resolution comment
   - Apply closure labels

## For LLMs
After creating an issue:
1. Extract the issue number from the creation response
2. Construct and provide the full issue URL in format:
   ```
   https://github.com/owner/repo/issues/NUMBER
   ```
3. Include this URL in your response to the user
4. Example response format:
   ```
   ✓ Issue created successfully: [#42 Bug Report](https://github.com/owner/repo/issues/42)
   ```

## Example Issue Body
```markdown
## Overview

Need to implement automatic dependency updates.


## Description

Add a system to automatically check for outdated dependencies and create update PRs.


## Technical Details

- Scan package.json and requirements.txt files
- Compare versions against latest releases
- Create automated PR with changelog
- Add tests for the changes


## Expected Behavior

- System detects outdated dependencies weekly
- Creates PRs with proper version bumps
- Includes changelog and breaking change warnings


## Additional Notes

Consider using Dependabot as a reference implementation.
``` 