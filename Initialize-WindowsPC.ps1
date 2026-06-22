<#
.SYNOPSIS
Audits and optionally applies selected Windows workstation settings.
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [switch]$Apply,
    [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9-]{0,14}$')][string]$ComputerName,
    [switch]$EnableSystemRestore,
    [switch]$ShowFileExtensions,
    [string[]]$InstallPackageId,
    [string]$LogRoot="$env:ProgramData\WindowsPCProvisioning\Logs"
)

Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$runPath=Join-Path $LogRoot (Get-Date -Format 'yyyyMMdd_HHmmss')
$warnings=New-Object System.Collections.Generic.List[string]
$transcript=$false

function Test-Admin{
    $id=[Security.Principal.WindowsIdentity]::GetCurrent()
    (New-Object Security.Principal.WindowsPrincipal($id)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

try{
    if($env:OS -ne 'Windows_NT'){throw 'Windows is required.'}
    if($Apply -and -not(Test-Admin)){throw 'Run PowerShell as Administrator when using -Apply.'}
    New-Item $runPath -ItemType Directory -Force|Out-Null
    Start-Transcript -Path (Join-Path $runPath 'Transcript.txt') -Force|Out-Null
    $transcript=$true

    Get-CimInstance Win32_ComputerSystem|
        Select-Object Name,Manufacturer,Model,Domain,PartOfDomain,TotalPhysicalMemory|
        Export-Csv (Join-Path $runPath 'Computer-Before.csv') -NoTypeInformation
    Get-CimInstance Win32_OperatingSystem|
        Select-Object Caption,Version,BuildNumber,OSArchitecture,InstallDate,LastBootUpTime|
        Export-Csv (Join-Path $runPath 'OperatingSystem.csv') -NoTypeInformation
    Get-Volume -ErrorAction SilentlyContinue|
        Select-Object DriveLetter,FileSystemLabel,FileSystem,HealthStatus,Size,SizeRemaining|
        Export-Csv (Join-Path $runPath 'Volumes.csv') -NoTypeInformation
    Get-NetAdapter -ErrorAction SilentlyContinue|
        Select-Object Name,Status,LinkSpeed,MacAddress|
        Export-Csv (Join-Path $runPath 'NetworkAdapters.csv') -NoTypeInformation

    if($Apply -and $ComputerName -and $ComputerName -ne $env:COMPUTERNAME -and $PSCmdlet.ShouldProcess($env:COMPUTERNAME,"Rename computer to $ComputerName")){
        Rename-Computer -NewName $ComputerName -Force -ErrorAction Stop
        'Computer rename requires a restart.'|Out-File (Join-Path $runPath 'RestartRequired.txt')
    }

    if($Apply -and $EnableSystemRestore -and $PSCmdlet.ShouldProcess($env:SystemDrive,'Enable System Restore and create restore point')){
        try{
            Enable-ComputerRestore -Drive ($env:SystemDrive+'\') -ErrorAction Stop
            Checkpoint-Computer -Description 'Windows PC Provisioning' -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        }catch{$warnings.Add("System Restore: $($_.Exception.Message)")}
    }

    if($Apply -and $ShowFileExtensions -and $PSCmdlet.ShouldProcess('Current user Explorer settings','Show file extensions')){
        $path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
        Set-ItemProperty -Path $path -Name HideFileExt -Type DWord -Value 0 -ErrorAction Stop
        $hideFileExt=(Get-ItemProperty -Path $path -Name HideFileExt -ErrorAction Stop).HideFileExt
        if($hideFileExt -ne 0){$warnings.Add('File-extension visibility setting could not be verified.')}
    }

    if($Apply -and $InstallPackageId){
        if(-not(Get-Command winget.exe -ErrorAction SilentlyContinue)){$warnings.Add('WinGet was not found.')}
        else{
            foreach($id in $InstallPackageId){
                if([string]::IsNullOrWhiteSpace($id)){$warnings.Add('An empty WinGet package ID was skipped.');continue}
                if($PSCmdlet.ShouldProcess($id,'Install package with WinGet')){
                    $safeName=$id -replace '[^A-Za-z0-9.-]','_'
                    winget.exe install --id $id --exact --accept-package-agreements --accept-source-agreements --disable-interactivity 2>&1|
                        Tee-Object -FilePath (Join-Path $runPath ("winget_{0}.txt" -f $safeName))
                    if($LASTEXITCODE -ne 0){$warnings.Add("Package $id returned $LASTEXITCODE")}
                }
            }
        }
    }

    Get-CimInstance Win32_ComputerSystem|
        Select-Object Name,Manufacturer,Model,Domain,PartOfDomain,TotalPhysicalMemory|
        Export-Csv (Join-Path $runPath 'Computer-After.csv') -NoTypeInformation

    [pscustomobject]@{
        Computer=$env:COMPUTERNAME
        ApplyRequested=[bool]$Apply
        RequestedName=$ComputerName
        SystemRestore=[bool]$EnableSystemRestore
        ShowExtensions=[bool]$ShowFileExtensions
        PackageCount=@($InstallPackageId).Count
        WarningCount=$warnings.Count
        Completed=Get-Date
    }|ConvertTo-Json|Out-File (Join-Path $runPath 'Summary.json') -Encoding UTF8

    $warnings|Out-File (Join-Path $runPath 'Warnings.txt') -Encoding UTF8
    if($transcript){Stop-Transcript|Out-Null;$transcript=$false}
    if($warnings.Count -gt 0){Write-Host "[WARN] Completed with warnings. Logs: $runPath" -ForegroundColor Yellow;exit 2}
    Write-Host "[OK] Completed. Logs: $runPath" -ForegroundColor Green;exit 0
}catch{
    if($transcript){try{Stop-Transcript|Out-Null}catch{}}
    Write-Error $_.Exception.Message;exit 1
}
