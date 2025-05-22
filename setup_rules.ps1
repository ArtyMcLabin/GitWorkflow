#!/usr/bin/env pwsh
# v1.2 - Simplified rules to reference README.md

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
For detailed implementation guidelines, refer to the AI Agent Instructions section in GitWorkflow's README.md.

Core Runtime Rules:
1) Git Operations:
   - Use `.git_workflow/git_workflow.ps1` for ALL git operations
   - NEVER use raw git commands without explicit human approval
   - Report unsupported operations to human for official implementation

2) Security:
   - Follow all security prompts
   - Never bypass security checks without human approval

For complete instructions, see: https://github.com/ArtyMcLabin/GitWorkflow/README.md#-ai-agent-instructions
"@

Set-Content -Path $useRule -Value $ruleContent
Write-Host "✓ Created/Updated GitWorkflow usage rules"

Write-Host "`nGitWorkflow rules setup complete!"
Write-Host "The project will now use GitWorkflow for all git operations." 