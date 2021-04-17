<#  Toggle-WSL

    A PowerShell 5 script to automate toggling WSL and Hyper-V related virtualization features on Windows 10 Pro.

    Made by https://github.com/sspacelynx
#>

[String[]] $featureList = "Microsoft-Windows-Subsystem-Linux", "VirtualMachinePlatform", "Microsoft-Hyper-V-All", "HypervisorPlatform", "Containers-DisposableClientVM"
[String] $savedStatePath = "$env:LOCALAPPDATA\toggle-wsl.json"
[String] $startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\toggle-wsl.cmd"
[Console]::OutputEncoding = New-Object System.Text.UTF8Encoding
$host.UI.RawUI.WindowTitle = "Toggle-WSL"


<# Class / Functions Definitions #>

function Elevate {
    if ($env:WT_SESSION) {
        Start-Process -Verb RunAs wt "powershell $PSScriptRoot\toggle-wsl.ps1"
    }
    else {
        Start-Process -Verb RunAs powershell $PSScriptRoot\toggle-wsl.ps1
    }
}

function Test-Administrator {
    [Security.Principal.WindowsPrincipal] $user = [Security.Principal.WindowsIdentity]::GetCurrent();
    return $user.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator);
}

function GetfState([String] $feature) {
    return (Get-WindowsOptionalFeature -Online -FeatureName $feature).State -eq "Enabled"
}

function GetDisplayName([String] $feature) {
    return (Get-WindowsOptionalFeature -Online -FeatureName $feature).DisplayName
}

function SaveState($obj) {
    $obj | ConvertTo-Json | Out-File $savedStatePath
}

function LoadState() {
    return Get-Content -Path $savedStatePath -Raw | ConvertFrom-Json
}

function DeleteSavedState() {
    Remove-Item -Path $savedStatePath
}


<# Main #>

Write-Host "     ╭──────────────────╮
---=/│    TOGGLE-WSL    │\=---
---=\│       v1.1       │/=---
     ╰──────────────────╯`n"

if(-not (Test-Administrator)) {
    Write-Warning "This script must be executed as Administrator!"
    Read-Host -Prompt "Press enter to restart the script with administrator privileges..." | Out-Null
    Elevate
    exit 0
}

[IO.FileInfo] $file = $savedStatePath

Write-Host "Settings
‾‾‾‾‾‾‾‾
Saved state: $savedStatePath
Double reboot script: $startupPath"

if ($file.Exists -and $file.Length -gt 0) {
    # case: saved state found -> all features are likely disabled, restore from saved state
    Write-Host "=> Script is in RESTORE mode."

    [Bool] $doubleRestart = $false
    Write-Host "`nSaved state found! Loading features state."
    $savestate = LoadState

    Write-Host "`nFollowing features will be enabled:"
    foreach ($s in $savestate) {
        if ($s.state) {
            [String] $m = "-> $(GetDisplayName($s.name))"

            # check if double restart is needed
            if ($s.name -eq "Microsoft-Windows-Subsystem-Linux") {
                $doubleRestart = $true
                $m += " (2 reboots needed)"
            }
            Write-Host $m
        }
    }

    Read-Host -Prompt "`nAre you sure you want to enable features and reboot? Press enter to continue..." | Out-Null

    foreach ($feature in $savestate) {
        if ($feature.state) {
            Enable-WindowsOptionalFeature -Online -FeatureName $feature.name -NoRestart 3>&1 | Out-Null
        }
    }

    if ($doubleRestart) {
        Set-Content -Path $startupPath -Value "shutdown /t 5 /r /c `"Your PC will reboot in 5 seconds to apply changes. This is the second reboot.`"`n(goto) 2>nul & del `"%~f0`""
        Write-Host "`nDouble reboot script created."
    }

    Write-Host "`nDeleting saved state..."
    DeleteSavedState
    shutdown /t 5 /r /c "Your PC will reboot TWICE in 5 seconds to apply changes. This is the first reboot, please wait for the second reboot to be completed before using your PC."
}
else {
    # case: saved state not found -> find enabled features, disable them and save state
    $features = @()
    $exit = $true
    Write-Host "=> Script is in SAVE mode."

    foreach ($feature in $featureList) {
        $f = New-Object PSObject -Property @{
            name = $feature
            state = GetfState($feature)
        }

        # If all features are disabled, set exit flag
        if ($f.state) {
            if ($exit) {
                $exit = $false
                Write-Host "`nEnabled features found:"
            }
            Write-Host "-> $(GetDisplayName($f.name))"
        }

        $features += $f
    }

    if ($exit) {
        Write-Host "`nERROR! All features are disabled and no saved state was found, the script cannot continue. Aborting."
        Read-Host -Prompt "Press enter to quit..." | Out-Null
        exit 0
    }

    Read-Host -Prompt "`nAre you sure you want to disable features and reboot? Press enter to continue..." | Out-Null

    foreach ($feature in $features) {
        if ($feature.state) {
            Disable-WindowsOptionalFeature -Online -FeatureName $feature.name -NoRestart 3>&1 | Out-Null
        }
    }

    Write-Host "`nSaving state..."
    SaveState($features)
    shutdown /t 5 /r /c "Your PC will reboot in 5 seconds to apply changes."
}

Write-Host "`nDone! Rebooting."
Start-Sleep -s 3