#!/usr/bin/env pwsh
# Git Workflow Script v1.1
# This script implements the workflow defined in git_workflow.md

param(
    [Parameter()]
    [string]$CommitMessage = "",
    
    [Parameter()]
    [ValidateSet("public", "private")]
    [string]$Visibility = "private"
)

function Update-WorkflowTool {
    # Check if we're running from a submodule
    $workflowPath = Split-Path -Parent $PSCommandPath
    if (Test-Path (Join-Path $workflowPath ".git")) {
        Write-Host "Checking for GitWorkflow updates..."
        Push-Location $workflowPath
        git submodule update --remote
        Pop-Location
    }
}

function Initialize-GitRepo {
    # Check if git is already initialized
    if (Test-Path .git) {
        Write-Host "Git repository already initialized"
        git remote -v  # Display remote info if exists
        return $false
    }

    # Check repository name from current directory
    $script:repoName = Split-Path -Leaf (Get-Location)

    # Check if repository exists on GitHub
    gh repo view $env:GITHUB_USERNAME/$repoName 2>$null
    if ($?) {
        Write-Host "Repository already exists on GitHub: $repoName"
        return $false
    }

    # Initialize git and set master branch
    git init
    git branch -M master

    # Create standard files if they don't exist
    if (!(Test-Path README.md)) {
        @"
# $repoName

## Description
Add your project description here.

## Features
- Feature 1
- Feature 2

## Installation
Describe installation steps here.

## Usage
Describe how to use your project.
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

function Initialize-VersionFile {
    # Start with v0.1 for new projects
    "v0.1" | Out-File -FilePath version.txt -Encoding utf8
}

function Push-ToGithub {
    param(
        [string]$CommitMessage,
        [string]$Visibility
    )

    # Stage all changes
    git add .

    # Get current timestamp for commit message
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
    
    # Use provided commit message or default to timestamp
    if ([string]::IsNullOrEmpty($CommitMessage)) {
        $CommitMessage = "Update ${timestamp}: Regular update"
    }

    # Commit with message
    git commit -m $CommitMessage

    # Push to GitHub
    git push -u origin master
}

# Main workflow
try {
    # Update workflow tool first
    Update-WorkflowTool

    # Check prerequisites
    if ([string]::IsNullOrEmpty($env:GITHUB_USERNAME)) {
        throw "GitHub username not set. Please set `$env:GITHUB_USERNAME first."
    }

    # Initialize if needed
    $isNewRepo = Initialize-GitRepo
    if ($isNewRepo) {
        Write-Host "Initializing new repository..."
        
        # Create version and github info files
        Initialize-VersionFile
        Update-GithubInfo

        # Initial commit
        git add .
        git commit -m "Initial commit: Project structure setup"

        # Create GitHub repository and push
        $visibilityFlag = if ($Visibility -eq "private") { "--private" } else { "--public" }
        gh repo create $repoName $visibilityFlag --source=. --remote=origin
        git push -u origin master
        
        # Display repository URL
        $repoUrl = "https://github.com/$env:GITHUB_USERNAME/$repoName"
        Write-Host "`nRepository created successfully!"
        Write-Host "URL: $repoUrl"
    } else {
        # Update existing repository
        Write-Host "Updating existing repository..."
        Push-ToGithub -CommitMessage $CommitMessage -Visibility $Visibility
        Update-GithubInfo
        Write-Host "Repository updated and pushed to GitHub successfully!"
    }
} catch {
    Write-Error "Error occurred: $_"
    exit 1
} 