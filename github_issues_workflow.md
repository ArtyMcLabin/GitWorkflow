# GitHub Issues Workflow Standard

This document defines the standard format for GitHub issue creation and management.

## Issue Format
1. Title Format:
   - Clear and concise
   - Start with type: [Bug], [Feature], [Enhancement], etc.
   - Example: "[Bug] Login button not working"

2. Body Structure:
   ```markdown
   | Description |
   |-------------|
   | Detailed explanation of the issue |

   | Expected Behavior |
   |------------------|
   | What should happen |

   | Current Behavior |
   |------------------|
   | What is happening |
   ```

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