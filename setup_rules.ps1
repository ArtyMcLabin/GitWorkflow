#!/usr/bin/env pwsh
# v1.1 - Updated for new rule architecture

# Create .cursor/rules directory if it doesn't exist
$rulesDir = ".cursor/rules"
if (!(Test-Path $rulesDir)) {
    New-Item -ItemType Directory -Path $rulesDir -Force | Out-Null
    Write-Host "✓ Created $rulesDir directory"
}

# Check for existing rules
$useRule = "$rulesDir/use_gitworkflow.mdc"
$noUseRule = "$rulesDir/no_gitworkflow.mdc"

if (Test-Path $noUseRule) {
    Write-Host "! This project is explicitly marked to not use GitWorkflow"
    Write-Host "Delete $noUseRule if you want to start using GitWorkflow"
    exit 0
}

if (Test-Path $useRule) {
    Write-Host "GitWorkflow rules already exist"
    Write-Host "Updating to latest version..."
}

# Create or update use_gitworkflow.mdc
$ruleContent = @"
# GitWorkflow Usage Rules

This project uses GitWorkflow for all git operations.

1) Git Operations:
   - ALWAYS use `.git_workflow/git_workflow.ps1` for ANY git operations
   - NEVER use raw git commands unless explicitly approved by human
   - If operation not supported by GitWorkflow:
     a) STOP - do not use raw git commands
     b) Report to user: "Human, operation X is not defined in GitWorkflow. Should we add it officially?"
     c) Only proceed with raw git if explicitly approved

2) Repository Operations:
   - Check for updates before operations: `.git_workflow/git_workflow.ps1`
   - Follow security warnings if shown
   - Use standard commit message format
   - Always include issue references if applicable

3) Issue Management:
   - Use GitWorkflow's issue creation system
   - Follow standard labeling conventions
   - Use proper issue templates
   - Link commits to issues when resolving

4) Security:
   - Review security warnings during updates
   - Never bypass security checks without user approval
   - Report suspicious changes to repository owner
"@

Set-Content -Path $useRule -Value $ruleContent
Write-Host "✓ Created/Updated GitWorkflow usage rules"

Write-Host "`nGitWorkflow rules setup complete!"
Write-Host "The project will now use GitWorkflow for all git operations." 