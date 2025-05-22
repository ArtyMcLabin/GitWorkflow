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

2. Updates:
   - Keep discussion in comments
   - Update labels as status changes
   - Link related PRs/commits

3. Resolution:
   - Include implementation reference
   - Add resolution comment
   - Apply closure labels 