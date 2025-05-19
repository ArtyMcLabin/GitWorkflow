# Example Project Setup

This example shows how to integrate the Git Workflow tool into your project.

## 1. Using Symbolic Link (Recommended)

```pwsh
# Navigate to your project
cd YourProject

# Create symbolic link to GitWorkflow
New-Item -ItemType SymbolicLink -Path ".git_workflow" -Target "C:\path\to\GitWorkflow"

# Initialize repository using the workflow
.\.git_workflow\git_workflow.ps1
```

## 2. Using Git Submodule

```pwsh
# Navigate to your project
cd YourProject

# Add GitWorkflow as a submodule
git submodule add https://github.com/YourUsername/GitWorkflow.git .git_workflow

# Initialize repository using the workflow
.\.git_workflow\git_workflow.ps1
```

## 3. Using in Cursor IDE

1. Add this to your Cursor project settings:
```json
{
    "git_workflow_path": "path/to/GitWorkflow",
    "auto_git_workflow": true
}
```

2. The workflow will be automatically available in your project.

## Project Structure After Integration

```
YourProject/
├── .git_workflow/          # Symlink or submodule to GitWorkflow
├── .github_info           # Created by workflow
├── version.txt           # Created by workflow
├── .gitignore           # Created by workflow
└── ... your project files
``` 