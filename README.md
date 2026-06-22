# Windows PC Provisioning

> **Testing note:** This was tested by me to be working. User experience may vary.

Included script: `Initialize-WindowsPC.ps1`

```powershell
.\Initialize-WindowsPC.ps1
.\Initialize-WindowsPC.ps1 -Apply -ShowFileExtensions
.\Initialize-WindowsPC.ps1 -Apply -ComputerName CLIENT-PC01
```

The default run creates an inventory. Optional settings require `-Apply` and support `-WhatIf`. Logs are written to `C:\ProgramData\WindowsPCProvisioning\Logs`.

Exit codes: `0` success, `1` fatal error, `2` warnings.

Review names, package IDs and organisational standards before applying changes. Use at your own risk.

MIT License.
