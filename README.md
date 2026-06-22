# Windows PC Provisioning

> **Testing note:** This was tested by me to be working. User experience may vary.

## One-click use

1. Download and extract the repository.
2. Double-click `Run-OneClick.bat`.
3. Approve the Windows administrator prompt.
4. The launcher collects the workstation inventory and applies the safe baseline setting to show known file extensions. There is no menu.
5. Review the exit code and logs in `C:\ProgramData\WindowsPCProvisioning\Logs`.

Computer renaming, System Restore creation and package installation remain explicit parameters because those values and choices differ between organisations.

Included script: `Initialize-WindowsPC.ps1`

## PowerShell usage

```powershell
.\Initialize-WindowsPC.ps1
.\Initialize-WindowsPC.ps1 -Apply -ShowFileExtensions
.\Initialize-WindowsPC.ps1 -Apply -EnableSystemRestore
.\Initialize-WindowsPC.ps1 -Apply -ComputerName CLIENT-PC01
.\Initialize-WindowsPC.ps1 -Apply -InstallPackageId 'Microsoft.PowerToys'
.\Initialize-WindowsPC.ps1 -Apply -ShowFileExtensions -WhatIf
```

The default PowerShell run creates an inventory. Optional settings require `-Apply`, administrator rights and support `-WhatIf`. Computer names are validated and WinGet installs run non-interactively with agreement handling.

Exit codes: `0` success, `1` fatal error, `2` warnings.

Review names, package IDs and organisational standards before applying custom changes. MIT License.
