# Git Workflow Standard v1.1

## Repository Status Check
Before initializing any new repository, check if it's already on GitHub:
```pwsh
#!/usr/bin/env pwsh

# Check if git is already initialized
if (Test-Path .git) {
    Write-Host "Git repository already initialized"
    git remote -v  # Display remote info if exists
    exit
}

# Check repository name from current directory
$repoName = Split-Path -Leaf (Get-Location)

# Check if repository exists on GitHub (requires gh CLI tool)
gh repo view $env:GITHUB_USERNAME/$repoName 2>$null
if ($?) {
    Write-Host "Repository already exists on GitHub: $repoName"
    exit
}
```

## Initial Setup (New Repository)
```pwsh
#!/usr/bin/env pwsh

# Initialize git
git init

# Create standard files if they don't exist
if (!(Test-Path README.md)) {
    New-Item README.md
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

# Initial commit
git add .
git commit -m "Initial commit: Project structure setup"

# Create GitHub repository and push
gh repo create $repoName --private --source=. --remote=origin
git push -u origin main
```

## Update Workflow
```pwsh
#!/usr/bin/env pwsh

# Stage all changes
git add .

# Get current timestamp for commit message
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"

# Commit with timestamp
git commit -m "Update $timestamp: <description>"

# Push to GitHub
git push origin main
```

## Version Control Files
To help Cursor track repository status, create/update these files:

1. `.github_info`:
```json
{
    "repository_name": "<repo_name>",
    "last_push": "<timestamp>",
    "github_url": "https://github.com/<username>/<repo_name>"
}
```

2. `version.txt`:
```
v1.1
```

## Prerequisites
1. Git installed and configured
2. GitHub CLI (gh) installed and authenticated
3. PowerShell Core (pwsh) installed
4. GitHub username set in environment:
```pwsh
$env:GITHUB_USERNAME = "YourUsername"  # Add to PowerShell Core profile for persistence
```

## Usage in Cursor
1. This workflow can be added to Cursor's settings for standardization
2. The status check prevents duplicate repository creation
3. Version tracking helps maintain consistent updates
4. `.github_info` file serves as a flag for Cursor to identify already-published repositories

## Maintenance
1. Update version numbers in `version.txt` for significant changes
2. Keep `.github_info` current with latest push timestamps
3. Regular commits with descriptive messages
4. Use semantic versioning for version numbers 