#!/usr/bin/env pwsh
# v1.0 - Initial version of git status checker

function Get-GitStatus {
    $gitStatus = @{
        IsGitRepo = $false
        HasRemote = $false
        HasSubmodules = $false
        SubmodulesList = @()
        CurrentBranch = ""
        RemoteUrl = ""
    }

    # Check if it's a git repo
    $isGit = git rev-parse --is-inside-work-tree 2>$null
    if ($LASTEXITCODE -eq 0) {
        $gitStatus.IsGitRepo = $true
        
        # Get current branch
        $gitStatus.CurrentBranch = git branch --show-current

        # Check for remote
        $remote = git remote get-url origin 2>$null
        if ($LASTEXITCODE -eq 0) {
            $gitStatus.HasRemote = $true
            $gitStatus.RemoteUrl = $remote
        }

        # Check for submodules
        $submodules = git submodule status
        if ($submodules) {
            $gitStatus.HasSubmodules = $true
            $gitStatus.SubmodulesList = $submodules | ForEach-Object {
                if ($_ -match "^[\s+-]([a-f0-9]+)\s+([^\s]+)") {
                    @{
                        Hash = $matches[1]
                        Path = $matches[2]
                    }
                }
            }
        }
    }

    return $gitStatus
}

# If running directly (not sourced)
if ($MyInvocation.InvocationName -ne ".") {
    return Get-GitStatus
} 