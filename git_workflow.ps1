#!/usr/bin/env pwsh
# Git Workflow Script v1.29
# This script implements the workflow defined in README.md

param(
    [Parameter()]
    [string]$CommitMessage = "",
    
    [Parameter()]
    [ValidateSet("public", "private")]
    [string]$Visibility = "private",

    [Parameter()]
    [string]$License = "MIT",

    [Parameter()]
    [switch]$CreateIssue,

    [Parameter()]
    [string]$IssueTitle = "",

    [Parameter()]
    [string]$IssueBody = "",

    [Parameter()]
    [string[]]$IssueLabels = @(),

    [Parameter()]
    [string]$IssueRepo = "",  # Format: "owner/repo" or empty for current repo

    [Parameter()]
    [switch]$ApproveIssue,

    [Parameter()]
    [string]$IssueNumber = "",

    [Parameter()]
    [switch]$CloseIssue,

    [Parameter()]
    [string]$Implementation = ""  # Commit hash or PR link for issue resolution
)

# Source the git status checker
. (Join-Path $PSScriptRoot "git_status_check.ps1")

function Test-UpdateSecurity {
    param(
        [string]$CurrentCommit,
        [string]$NewCommit
    )

    $securityChecks = @{
        HasSuspiciousFiles = $false
        HasSuspiciousCommands = $false
        HasLargeChanges = $false
        Warnings = @()
    }

    # Get the diff
    $diff = git diff $CurrentCommit..$NewCommit --name-status

    # Check for suspicious files
    $suspiciousExtensions = @('.exe', '.dll', '.so', '.dylib', '.sh', '.bat', '.cmd', '.ps1')
    $suspiciousFiles = $diff | Where-Object { 
        $_ -match '^[AM]' -and ($suspiciousExtensions | Where-Object { $_ -eq [System.IO.Path]::GetExtension($_) })
    }
    if ($suspiciousFiles) {
        $securityChecks.HasSuspiciousFiles = $true
        $securityChecks.Warnings += "⚠️ New executable or script files detected in update"
    }

    # Check for suspicious commands in PowerShell files
    $suspiciousCommands = @(
        'Invoke-Expression', 'iex', 'Invoke-WebRequest', 'wget', 'curl',
        'Start-Process', 'New-Service', 'Set-ExecutionPolicy',
        'Add-MpPreference', 'Set-MpPreference', # Windows Defender modifications
        'reg', 'regedit', # Registry modifications
        'netsh', 'route', # Network modifications
        'Remove-Item.*-Recurse.*-Force', # Dangerous deletions
        'Format-Volume', 'Clear-Disk' # Disk operations
    )

    $psFiles = git diff $CurrentCommit..$NewCommit --diff-filter=AM --name-only -- '*.ps1'
    foreach ($file in $psFiles) {
        $content = git show "$NewCommit`:$file"
        foreach ($cmd in $suspiciousCommands) {
            if ($content -match $cmd) {
                $securityChecks.HasSuspiciousCommands = $true
                $securityChecks.Warnings += "⚠️ Suspicious PowerShell command detected: $cmd"
            }
        }
    }

    # Check for large changes
    $stats = git diff --shortstat $CurrentCommit..$NewCommit
    if ($stats -match '(\d+) insertion.*, (\d+) deletion') {
        $insertions = [int]$Matches[1]
        $deletions = [int]$Matches[2]
        if (($insertions + $deletions) -gt 500) {
            $securityChecks.HasLargeChanges = $true
            $securityChecks.Warnings += "⚠️ Large number of changes detected ($($insertions + $deletions) lines)"
        }
    }

    return $securityChecks
}

function Update-WorkflowTool {
    # Check if we're running from a submodule
    $workflowPath = Split-Path -Parent $PSCommandPath
    if (Test-Path (Join-Path $workflowPath ".git")) {
        Write-Host "Checking for GitWorkflow updates..."
        try {
            Push-Location $workflowPath
            $currentCommit = git rev-parse HEAD
            
            # Fetch updates but don't apply yet
            git fetch origin master
            $newCommit = git rev-parse origin/master

            if ($currentCommit -ne $newCommit) {
                Write-Host "`nNew GitWorkflow update available!"
                Write-Host "Current version: $currentCommit"
                Write-Host "New version: $newCommit"
                Write-Host "`nChanges:"
                git log --oneline $currentCommit..$newCommit

                # Perform security checks
                $securityChecks = Test-UpdateSecurity -CurrentCommit $currentCommit -NewCommit $newCommit

                if ($securityChecks.HasSuspiciousFiles -or 
                    $securityChecks.HasSuspiciousCommands -or 
                    $securityChecks.HasLargeChanges) {
                    
                    Write-Host "`n⚠️ SECURITY WARNING ⚠️"
                    Write-Host "The update contains potentially suspicious changes:"
                    foreach ($warning in $securityChecks.Warnings) {
                        Write-Host $warning
                    }
                    Write-Host "`nWould you like to:"
                    Write-Host "1) View the exact changes (recommended)"
                    Write-Host "2) Apply the update anyway"
                    Write-Host "3) Skip this update"
                    
                    $choice = Read-Host "Enter your choice (1-3)"
                    
                    switch ($choice) {
                        "1" {
                            git diff $currentCommit..$newCommit | more
                            $confirm = Read-Host "Would you like to apply this update? (y/N)"
                            if ($confirm -ne "y") {
                                Write-Host "Update skipped."
                                return
                            }
                        }
                        "2" {
                            Write-Host "Proceeding with update..."
                        }
                        "3" {
                            Write-Host "Update skipped."
                            return
                        }
                        default {
                            Write-Host "Invalid choice. Update skipped for safety."
                            return
                        }
                    }
                }

                # Apply the update
                git merge origin/master
                Write-Host "`n✓ Updated GitWorkflow from $currentCommit to $newCommit"
            } else {
                Write-Host "GitWorkflow is already up to date"
            }
        } catch {
            Write-Error "Failed to update GitWorkflow: $_"
        } finally {
            Pop-Location
        }
    }
}

function Initialize-GitRepo {
    # Get current git status
    $gitStatus = Get-GitStatus

    # If it's already a git repo with a remote, we don't need to initialize
    if ($gitStatus.IsGitRepo -and $gitStatus.HasRemote) {
        Write-Host "Git repository already initialized with remote: $($gitStatus.RemoteUrl)"
        return $false
    }

    # If it's a git repo but no remote, we just need to add the remote
    if ($gitStatus.IsGitRepo) {
        Write-Host "Git repository exists locally but has no remote."
        $script:repoName = Split-Path -Leaf (Get-Location)
        return $true
    }

    # Check repository name from current directory
    $script:repoName = Split-Path -Leaf (Get-Location)

    # Check if repository exists on GitHub
    gh repo view $env:GITHUB_USERNAME/$repoName 2>$null
    if ($?) {
        Write-Host "Repository already exists on GitHub: $repoName"
        
        # If we're here, it means the repo exists on GitHub but not locally
        # Let's clone it instead of initializing
        Write-Host "Cloning existing repository..."
        git clone "https://github.com/$env:GITHUB_USERNAME/$repoName" .
        return $false
    }

    # Initialize git and set master branch
    git init
    git branch -M master

    # Create standard files if they don't exist
    if (!(Test-Path README.md)) {
        @"
# $repoName

# DISCLAIMER
This README was auto-generated by AI using GitWorkflow tool. Content might need human review and adjustments.

## Description
Add your project description here.

## Features
- Feature 1
- Feature 2

## Installation
Describe installation steps here.

## Usage
Describe how to use your project.

## License
This project is licensed under the $License License - see the [LICENSE](LICENSE) file for details.
"@ | Out-File -FilePath README.md -Encoding utf8
    }
    if (!(Test-Path .gitignore)) {
        New-Item .gitignore
    }

    # Add standard .gitignore contents
    @'
# Windows system files
Thumbs.db
desktop.ini

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Node
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# IDEs
.idea/
.vscode/
*.swp
*.swo
*~

# Environment
.env
.venv
venv/
ENV/
'@ | Out-File -FilePath .gitignore -Encoding utf8

    # Add license file
    Add-License -LicenseType $License -RepoOwner $env:GITHUB_USERNAME

    return $true
}

function Update-GithubInfo {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $repoName = Split-Path -Leaf (Get-Location)
    
    $githubInfo = @{
        repository_name = $repoName
        last_push = $timestamp
        github_url = "https://github.com/$env:GITHUB_USERNAME/$repoName"
    }

    $githubInfo | ConvertTo-Json | Out-File -FilePath .github_info -Encoding utf8
}

function Push-ToGithub {
    param(
        [string]$CommitMessage,
        [string]$Visibility
    )

    try {
        # Stage all changes
        git add .

        # Get current timestamp for commit message
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
        
        # Check if commit message contains issue references
        if ($CommitMessage -match '#\d+') {
            # Extract issue numbers
            $issueNumbers = [regex]::Matches($CommitMessage, '#(\d+)') | ForEach-Object { $_.Groups[1].Value }
            
            # Add "Closes" keyword for each issue if not already present
            foreach ($issueNum in $issueNumbers) {
                if ($CommitMessage -notmatch "(?i)closes\s*#$issueNum") {
                    $CommitMessage = "$CommitMessage`n`nCloses #$issueNum"
                }
            }
        }

        # Create commit with timestamp
        git commit -m "$CommitMessage [$timestamp]"

        # Push to GitHub
        git push -u origin master
        Write-Host "Successfully pushed changes to GitHub"
    } catch {
        Write-Error "Failed to push to GitHub: $_"
        throw
    }
}

function Add-License {
    param(
        [string]$LicenseType,
        [string]$RepoOwner
    )

    # Get current year
    $year = (Get-Date).Year.ToString()

    switch ($LicenseType.ToUpper()) {
        "MIT" {
            try {
                # Primary method: Fetch MIT license template from official source
                $licenseText = (Invoke-WebRequest -Uri "https://raw.githubusercontent.com/licenses/license-templates/master/templates/mit.txt").Content
                $licenseText = $licenseText.Replace("[year]", $year).Replace("[fullname]", $RepoOwner)
                $licenseText | Out-File -FilePath LICENSE -Encoding utf8
            }
            catch {
                Write-Warning "Failed to fetch MIT license online. Using fallback template..."
                # Fallback method: Use embedded template
                $mitTemplate = @"
MIT License

Copyright (c) $year $RepoOwner

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"@
                $mitTemplate | Out-File -FilePath LICENSE -Encoding utf8
            }
        }
        default {
            Write-Host "License type $LicenseType not supported yet. Using MIT license."
            Add-License -LicenseType "MIT" -RepoOwner $RepoOwner
        }
    }
}

function Remove-UnnecessaryFiles {
    # List of files to always remove
    $filesToRemove = @(
        'desktop.ini',
        '.github_info',  # We don't need this anymore as README contains all info
        'Thumbs.db',
        '.DS_Store'      # For Mac users
    )

    foreach ($file in $filesToRemove) {
        if (Test-Path $file) {
            # Remove from filesystem
            Remove-Item $file -Force
            # Remove from git tracking if it was tracked
            git rm -f --cached $file 2>$null
            Write-Host "Removed unnecessary file: $file"
        }
    }
}

# Add new function for general file removal
function Remove-GitFile {
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )

    if (Test-Path $FilePath) {
        # Remove from filesystem
        Remove-Item $FilePath -Force
        # Remove from git tracking if it was tracked
        git rm -f --cached $FilePath 2>$null
        Write-Host "Removed file: $FilePath"
        return $true
    } else {
        Write-Host "File not found: $FilePath"
        return $false
    }
}

function New-FormattedIssue {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,
        
        [Parameter()]
        [string]$Body = "",
        
        [Parameter()]
        [string[]]$Labels = @(),

        [Parameter()]
        [string]$TargetRepo = ""
    )

    # Validate inputs
    if ([string]::IsNullOrWhiteSpace($Title)) {
        throw "Issue title is required"
    }

    # Add standard AI-generated label
    $Labels += "ai-generated"

    # Format the body with standard GitWorkflow header
    $formattedBody = "🤖 GitWorkflow: This Issue/FeatureRequest was generated and submitted by LLM, according to GitWorkflow standard`n`n"
    
    # Add the original body - if it contains markdown headers (##), pass it as is
    if (![string]::IsNullOrWhiteSpace($Body)) {
        if ($Body -match '##') {
            $formattedBody += $Body
        } else {
            # If no markdown headers found, wrap in table format
            $lines = $Body -split "`n"
            $formattedBody += "| Description |`n|-------------|`n"
            foreach ($line in $lines) {
                # Escape pipe characters and properly format newlines
                $escapedLine = $line.Replace("|", "\|").Replace("`n", "<br>")
                $formattedBody += "| $escapedLine |`n"
            }
        }
    }

    # Create the issue
    $labelArgs = @()
    if ($Labels.Count -gt 0) {
        $labelArgs = "--label", ($Labels -join ",")
    }

    # Build command arguments
    $ghArgs = @("issue", "create")
    if (![string]::IsNullOrWhiteSpace($TargetRepo)) {
        $ghArgs += "-R", $TargetRepo
        Write-Host "Creating issue in repository: $TargetRepo"
    } else {
        Write-Host "Creating issue in current repository"
    }

    if ([string]::IsNullOrWhiteSpace($formattedBody)) {
        & gh @ghArgs --title $Title @labelArgs
    } else {
        $formattedBody | & gh @ghArgs --title $Title @labelArgs --body-file -
    }

    Write-Host "✓ Issue created successfully: $Title"
}

function Approve-Issue {
    param(
        [Parameter(Mandatory=$true)]
        [string]$IssueNumber,
        
        [Parameter()]
        [string]$TargetRepo = ""
    )

    # Build command arguments
    $ghArgs = @("issue", "comment")
    if (![string]::IsNullOrWhiteSpace($TargetRepo)) {
        $ghArgs += "-R", $TargetRepo
    }

    # Get current user
    $username = (gh api user --jq '.login')

    # Format approval message
    $approvalMessage = @"
✅ Hooman Approval
By: $username
Status: Approved for implementation
Time: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")
"@

    # Add comment and label
    $ghArgs += $IssueNumber, "--body", $approvalMessage
    & gh @ghArgs

    # Add human-approved-request label
    $labelArgs = @("issue", "edit")
    if (![string]::IsNullOrWhiteSpace($TargetRepo)) {
        $labelArgs += "-R", $TargetRepo
    }
    $labelArgs += $IssueNumber, "--add-label", "human-approved-request"
    & gh @labelArgs

    Write-Host "✓ Issue #$IssueNumber approved successfully"
}

function Close-ResolvedIssue {
    param(
        [Parameter(Mandatory=$true)]
        [string]$IssueNumber,
        
        [Parameter()]
        [string]$Implementation = "",
        
        [Parameter()]
        [string]$TargetRepo = ""
    )

    # Build command arguments
    $ghArgs = @("issue", "comment")
    if (![string]::IsNullOrWhiteSpace($TargetRepo)) {
        $ghArgs += "-R", $TargetRepo
    }

    # Format resolution message
    $resolutionMessage = @"
🤖 Issue Resolution by AI
Status: Implemented
$(if (![string]::IsNullOrWhiteSpace($Implementation)) { "Implementation: $Implementation`n" })

If this doesn't fully resolve your issue:
- Comment below for further assistance
- Add label 'needs-human-review' if human oversight is needed
"@

    # Add comment and labels
    $ghArgs += $IssueNumber, "--body", $resolutionMessage
    & gh @ghArgs

    # Add ai-implemented label and close the issue
    $labelArgs = @("issue", "edit")
    if (![string]::IsNullOrWhiteSpace($TargetRepo)) {
        $labelArgs += "-R", $TargetRepo
    }
    $labelArgs += $IssueNumber, "--add-label", "ai-implemented"
    & gh @labelArgs

    # Close the issue
    $closeArgs = @("issue", "close")
    if (![string]::IsNullOrWhiteSpace($TargetRepo)) {
        $closeArgs += "-R", $TargetRepo
    }
    $closeArgs += $IssueNumber
    & gh @closeArgs

    Write-Host "✓ Issue #$IssueNumber closed successfully"
}

# Main execution
try {
    # Handle issue operations
    if ($CreateIssue) {
        if ([string]::IsNullOrWhiteSpace($IssueTitle)) {
            throw "Issue title is required when creating an issue"
        }
        New-FormattedIssue -Title $IssueTitle -Body $IssueBody -Labels $IssueLabels -TargetRepo $IssueRepo
        return
    }
    elseif ($ApproveIssue) {
        if ([string]::IsNullOrWhiteSpace($IssueNumber)) {
            throw "Issue number is required for approval"
        }
        Approve-Issue -IssueNumber $IssueNumber -TargetRepo $IssueRepo
        return
    }
    elseif ($CloseIssue) {
        if ([string]::IsNullOrWhiteSpace($IssueNumber)) {
            throw "Issue number is required for closing"
        }
        Close-ResolvedIssue -IssueNumber $IssueNumber -Implementation $Implementation -TargetRepo $IssueRepo
        return
    }

    # Regular git workflow
    Update-WorkflowTool
    Remove-UnnecessaryFiles
    $isNewRepo = Initialize-GitRepo
    
    # Only create repository if it's new
    if ($isNewRepo) {
        Write-Host "Creating new repository on GitHub..."
        gh repo create $repoName --$Visibility
        $repoUrl = "https://github.com/$env:GITHUB_USERNAME/$repoName"
        Write-Host "`nRepository successfully created at: $repoUrl"
        Write-Host "✓ Repository creation successful"
        Write-Host "✓ Initial setup complete"
    }
    
    # Always update and push
    Update-GithubInfo
    Push-ToGithub -CommitMessage $CommitMessage -Visibility $Visibility
    Write-Host "✓ Code pushed successfully"
    Write-Host "`nGit workflow completed successfully"
} catch {
    Write-Error "Git workflow failed: $_"
    exit 1
} 