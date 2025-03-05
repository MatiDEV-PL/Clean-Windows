#Requires -Version 5.0

param (
	[switch]$UninstallEdge,
	[switch]$RemoveEdgeData,
	[switch]$KeepAppX,
	[switch]$NonInteractive
)

$version = '1.9.4'

$ProgressPreference = "SilentlyContinue"
$sys32 = [Environment]::GetFolderPath('System')
$windir = [Environment]::GetFolderPath('Windows')
$env:path = "$windir;$sys32;$sys32\Wbem;$sys32\WindowsPowerShell\v1.0;" + $env:path
$baseKey = "HKLM:\SOFTWARE" + $(if ([Environment]::Is64BitOperatingSystem) { "\WOW6432Node" }) + "\Microsoft"
$msedgeExe = "$([Environment]::GetFolderPath('ProgramFilesx86'))\Microsoft\Edge\Application\msedge.exe"
$edgeUWP = "$windir\SystemApps\Microsoft.MicrosoftEdge_8wekyb3d8bbwe"

if ($NonInteractive -and (!$UninstallEdge -and !$RemoveEdgeData)) {
	$NonInteractive = $false
}
if ($UninstallEdge -and $RemoveEdgeData) {
	throw "You can't use both -UninstallEdge and -RemoveEdgeData as arguments."
}

function Pause ($message = "Press Enter to exit") {
	if (!$NonInteractive) { $null = Read-Host $message }
}

enum LogLevel {
	Success
	Info
	Warning
	Error
	Critical
}
function Write-Status {
	param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Text,
		[LogLevel]$Level = "Info",
		[switch]$Exit,
		[string]$ExitString = "Press Enter to exit",
		[int]$ExitCode = 1 
	)

	$colour = @(
		"Green",
		"White",
		"Yellow",
		"Red",
		"Red"
	)[$([LogLevel].GetEnumValues().IndexOf($Level))]

	$Text -split "`n" | ForEach-Object {
		Write-Host "[$($Level.ToString().ToUpper())] $_" -ForegroundColor $colour
	}

	if ($Exit) {
		Write-Output ""
		Pause $ExitString
		exit $ExitCode
	}
}

function InternetCheck {
	if ($(Test-Connection "microsoft.com" -Count 1 -EA 0; $?) -eq $false) {
		Write-Status "Failed to ping Microsoft! You must have an internet connection to reinstall Edge and its components." -Level Critical -Exit -ExitCode 404
	}
}

function DeleteIfExist($Path) {
	if (Test-Path $Path) {
		Remove-Item -Path $Path -Force -Recurse -Confirm:$false
	}
}

function Get-MsiexecAppByName {
	param(
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[string]$Name
	)

	$uninstallKeyPath = "Microsoft\Windows\CurrentVersion\Uninstall"
	$uninstallKeys = (Get-ChildItem -Path @(
		"HKLM:\SOFTWARE\$uninstallKeyPath",
		"HKLM:\SOFTWARE\WOW6432Node\$uninstallKeyPath",
		"HKCU:\SOFTWARE\$uninstallKeyPath",
		"HKCU:\SOFTWARE\WOW6432Node\$uninstallKeyPath"
	) -EA SilentlyContinue) -match "\{\b[A-Fa-f0-9]{8}(?:-[A-Fa-f0-9]{4}){3}-[A-Fa-f0-9]{12}\b\}"

	$edges = @()
	foreach ($key in $uninstallKeys.PSPath) {
		if (((Get-ItemProperty -Path $key).DisplayName -like "*$Name*") -and ((Get-ItemProperty -Path $key).UninstallString -like "*MsiExec.exe*")) {
			$edges += Split-Path -Path $key -Leaf
		}
	}

	return $edges
}

# True if it's installed
function EdgeInstalled {
	Test-Path $msedgeExe
}

function KillEdgeProcesses {
	$ErrorActionPreference = 'SilentlyContinue'
	foreach ($service in (Get-Service -Name "*edge*" | Where-Object {$_.DisplayName -like "*Microsoft Edge*"}).Name) {
		Stop-Service -Name $service -Force
	}
	foreach (
		$process in
		(Get-Process | Where-Object {($_.Path -like "$([Environment]::GetFolderPath('ProgramFilesX86'))\Microsoft\*") -or ($_.Name -like "*msedge*")}).Id
	) {
		Stop-Process -Id $process -Force
	}
	$ErrorActionPreference = 'Continue'	
}

function RemoveEdgeChromium([bool]$AlreadyUninstalled) {
	Write-Status -Text "Trying to find Edge uninstallers..."

	# get Edge MsiExec uninstallers
	# commonly installed with WinGet (it installs the Enterprise MSI)
	$msis = Get-MsiexecAppByName -Name "Microsoft Edge"

	# find using common locations - used as a backup
	function UninstallStringFail {
		if ($msis.Count -le 0) {
			Write-Status -Text "Couldn't parse uninstall string for Edge. Trying to find uninstaller manually." -Level Warning
		}

		$script:edgeUninstallers = @()
		'LocalApplicationData','ProgramFilesX86','ProgramFiles' | ForEach-Object {
			$folder = [Environment]::GetFolderPath($_)
			$script:edgeUninstallers += Get-ChildItem "$folder\Microsoft\Edge*\setup.exe" -Recurse -EA 0 |
				Where-Object {($_ -like '*Edge\Application*') -or ($_ -like '*SxS\Application*')}
		}
	}

	# find using Registry
	$uninstallKeyPath = "$baseKey\Windows\CurrentVersion\Uninstall\Microsoft Edge"
	$uninstallString = (Get-ItemProperty -Path $uninstallKeyPath -EA 0).UninstallString
	if ([string]::IsNullOrEmpty($uninstallString) -and ($msis.Count -le 0)) {
		$uninstallString = $null
		UninstallStringFail
	} else {
		# split uninstall string for path & args
		$uninstallPath, $uninstallArgs = $uninstallString -split '"', 3 |
			Where-Object { $_ } |
			ForEach-Object { [System.Environment]::ExpandEnvironmentVariables($_.Trim()) }

		# check if fully qualified (should normally be), otherwise it could be null or something in the working dir
		if (![System.IO.Path]::IsPathRooted($uninstallPath) -or !(Test-Path $uninstallPath -PathType Leaf)) {
			$uninstallPath = $null
			UninstallStringFail
		}
	}

	# throw if installers aren't found
	if (($msis.Count -le 0) -and ($script:edgeUninstallers.Count -le 0) -and !$uninstallPath) {
		$uninstallError = @{
			Text = "Failed to find uninstaller! " + $(if ($AlreadyUninstalled) {
				"This likely means Edge is already uninstalled."
			} else {
				"The uninstall can't continue. :("
			})
			Level = if ($AlreadyUninstalled) { 'Warning' } else { 'Critical' }
			Exit = $true
			ExitCode = 2
		}
		Write-Status @uninstallError
	} else {
		Write-Status "Found Edge uninstallers."
	}

	# toggles an EU region - this is because anyone in the EEA can uninstall Edge
	# this key is checked by the Edge uninstaller
	function ToggleEURegion([bool]$Enable) {
		$geoKey = "Registry::HKEY_USERS\.DEFAULT\Control Panel\International\Geo"

		# sets Geo to France, which is in the EEA
		$values = @{
			"Name" = "FR"
			"Nation" = "84"
		}
		$geoChange = 'EdgeSaved'

		if ($Enable) {
			$values.GetEnumerator() | ForEach-Object {
				Rename-ItemProperty -Path $geoKey -Name $_.Key -NewName "$($_.Key)$geoChange" -Force
				Set-ItemProperty -Path $geoKey -Name $_.Key -Value $_.Value -Force
			}
		} else {
			$values.GetEnumerator() | ForEach-Object {
				Remove-ItemProperty -Path $geoKey -Name $_.Key -Force -EA 0
				Rename-ItemProperty -Path $geoKey -Name "$($_.Key)$geoChange" -NewName $_.Key -Force -EA 0
			}
		}
	}

	function ModifyRegionJSON {
		$cleanup = $false
		$script:integratedServicesPath = "$sys32\IntegratedServicesRegionPolicySet.json"

		if (Test-Path $integratedServicesPath) {
			$cleanup = $true
			try {
				$admin = [System.Security.Principal.NTAccount]$(New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')).Translate([System.Security.Principal.NTAccount]).Value

				# get perms (normally TrustedInstaller only)
				$acl = Get-Acl -Path $integratedServicesPath
				$script:backup = [System.Security.AccessControl.FileSecurity]::new()
				$script:backup.SetSecurityDescriptorSddlForm($acl.Sddl)
				# full control
				$acl.SetOwner($admin)
				$rule = New-Object System.Security.AccessControl.FileSystemAccessRule($admin, "FullControl", "Allow")
				$acl.AddAccessRule($rule)
				# set modified ACL
				Set-Acl -Path $integratedServicesPath -AclObject $acl

				# modify the stuff
				$integratedServices = Get-Content $integratedServicesPath | ConvertFrom-Json
				($integratedServices.policies | Where-Object { ($_.'$comment' -like "*Edge*") -and ($_.'$comment' -like "*uninstall*") }).defaultState = 'enabled'
				$modifiedJson = $integratedServices | ConvertTo-Json -Depth 100

				$script:backupIntegratedServicesName = "IntegratedServicesRegionPolicySet.json.$([System.IO.Path]::GetRandomFileName())"
				Rename-Item $integratedServicesPath -NewName $script:backupIntegratedServicesName -Force
				Set-Content $integratedServicesPath -Value $modifiedJson -Force -Encoding UTF8
			} catch {
				Write-Error "Failed to modify region policies. $_"
			}
		} else {
			Write-Status -Text "'$integratedServicesPath' not found." -Level Warning
		}

		return $cleanup
	}


	# Edge uninstalling logic
	function UninstallEdge {
		# MSI packages have to be uninstalled first, otherwise it breaks
		foreach ($msi in $msis) {
			Write-Status 'Uninstalling Edge using Windows Installer...'
			Start-Process -FilePath "msiexec.exe" -ArgumentList "/qn /X$(Split-Path -Path $msi -Leaf) REBOOT=ReallySuppress /norestart" -Wait
		}

		# uninstall standard Edge installs
		if ($uninstallPath) {  # found from Registry
			Start-Process -Wait -FilePath $uninstallPath -ArgumentList "$uninstallArgs --force-uninstall" -WindowStyle Hidden
		} else {  # found from system files
			foreach ($setup in $edgeUninstallers) {
				if (Test-Path $setup) {
					$sulevel = ('--system-level','--user-level')[$setup -like '*\AppData\Local\*']
					Start-Process -Wait $setup -ArgumentList "--uninstall --msedge $sulevel --channel=stable --verbose-logging --force-uninstall"
				}
			}
		}

		# return if Edge is installed or not
		return EdgeInstalled
	}

	# things that should always be done before uninstall
	function GlobalRemoveMethods {
		Write-Status "Using method $method..." -Level Warning

		# delete experiment_control_labels for key that prevents (or prevented) uninstall
		Remove-ItemProperty -Path "$baseKey\EdgeUpdate\ClientState\{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}" -Name 'experiment_control_labels' -Force -EA 0

		# allow Edge uninstall
		$devKeyPath = "$baseKey\EdgeUpdateDev"
		if (!(Test-Path $devKeyPath)) { New-Item -Path $devKeyPath -ItemType "Key" -Force | Out-Null }
		Set-ItemProperty -Path $devKeyPath -Name "AllowUninstall" -Value "" -Type String -Force
	
		Write-Status "Terminating Microsoft Edge processes..."
		KillEdgeProcesses
	}

	# go through each uninstall method
	# yes, i'm aware this seems excessive, but i'm just trying to make sure it works on the most installs possible
	# it does bloat the script lots though... i'll clean it up in a future release, but for now, i'm just fixing it
	$fail = $true
	$method = 1
	function CleanupMsg { Write-Status "Cleaning up after method $method..." }
	while ($fail) {
		switch ($method) {
			# makes Edge think the old legacy UWP is still installed
			# seems to fail on some installs?
			1 {
				GlobalRemoveMethods
				if (!(Test-Path "$edgeUWP\MicrosoftEdge.exe")) {
					New-Item $edgeUWP -ItemType Directory -ErrorVariable cleanup -EA 0 | Out-Null
					New-Item "$edgeUWP\MicrosoftEdge.exe" -EA 0 | Out-Null
					$cleanup = $true
				}

				# attempt uninstall
				$fail = UninstallEdge

				if ($cleanup) {
					CleanupMsg
					Remove-Item $edgeUWP -Force -EA 0 -Recurse
				}
			}

			# not having windir defined is a condition to allow uninstall
			# found in the strings of the setup ^
			2 {
				GlobalRemoveMethods
				$envPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
				try {
					# delete windir variable temporarily
					Set-ItemProperty -Path $envPath -Name 'windir' -Value '' -Type ExpandString
					$env:windir = [System.Environment]::GetEnvironmentVariable('windir', [System.EnvironmentVariableTarget]::Machine)

					# attempt uninstall
					$fail = UninstallEdge
				} finally {
					CleanupMsg
					# this is the default
					Set-ItemProperty -Path $envPath -Name 'windir' -Value '%SystemRoot%' -Type ExpandString
				}
			}

			# changes region in Registry
			# currently not known to work, kept for legacy reasons
			3 {
				GlobalRemoveMethods
				ToggleEURegion $true

				$fail = UninstallEdge

				CleanupMsg
				ToggleEURegion $false
			}

			# modifies IntegratedServicesRegionPolicySet to add current region to allow list
			# currently not known to work, kept for legacy reasons
			4 {
				GlobalRemoveMethods
				$cleanup = ModifyRegionJSON
				
				# attempt uninstall
				$fail = UninstallEdge

				# cleanup
				if ($cleanup) {
					CleanupMsg
					Remove-Item $integratedServicesPath -Force
					Rename-Item "$sys32\$backupIntegratedServicesName" -NewName $integratedServicesPath -Force
					Set-Acl -Path $integratedServicesPath -AclObject $backup
				}
			}

			# everything fails ╰（‵□′）╯
			default {
				Write-Status "The uninstall methods failed for the Edge installers found. Nothing else can be done." -Level Critical -Exit -ExitCode 3
			}
		}

		$method++
	}
	Write-Status "Successfully removed Edge! :)" -Level Success

	# remove old shortcuts
	"$([Environment]::GetFolderPath('Desktop'))\Microsoft Edge.lnk",
	"$([Environment]::GetFolderPath('CommonStartMenu'))\Microsoft Edge.lnk" | ForEach-Object { DeleteIfExist $_ }

	# restart explorer if Copilot is enabled - this will hide the Copilot button
	if ((Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCopilotButton" -EA 0)."ShowCopilotButton" -eq 1) {
		Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
	}
}

function RemoveEdgeAppX {
	# i'm aware of how this is deprecated
	# kept for legacy purposes just in case someone's using an older build of Windows

	$SID = (New-Object System.Security.Principal.NTAccount([Environment]::UserName)).Translate([Security.Principal.SecurityIdentifier]).Value

	# remove from Registry
	$appxStore = '\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore'
	$pattern = "HKLM:$appxStore\InboxApplications\Microsoft.MicrosoftEdge_*_neutral__8wekyb3d8bbwe"
	$edgeAppXKey = (Get-Item -Path $pattern).PSChildName
	if (Test-Path "$pattern") { reg delete "HKLM$appxStore\InboxApplications\$edgeAppXKey" /f | Out-Null }

	# make the Edge AppX able to uninstall and uninstall
	New-Item -Path "HKLM:$appxStore\EndOfLife\$SID\Microsoft.MicrosoftEdge_8wekyb3d8bbwe" -Force | Out-Null
	Get-AppxPackage -Name Microsoft.MicrosoftEdge | Remove-AppxPackage | Out-Null
	Remove-Item -Path "HKLM:$appxStore\EndOfLife\$SID\Microsoft.MicrosoftEdge_8wekyb3d8bbwe" -Force | Out-Null
}

# SYSTEM check - using SYSTEM previously caused issues
if ([Security.Principal.WindowsIdentity]::GetCurrent().User.Value -eq 'S-1-5-18') {
	Write-Status "This script can't be ran as TrustedInstaller/SYSTEM.
Please relaunch this script under a regular admin account." -Level Critical -Exit
} else {
	if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
		throw "This script must be run as an administrator."
	}
}

# Uninstall Edge if the parameter is set
if ($UninstallEdge) {
	Write-Status "Uninstalling Edge Chromium..."
	RemoveEdgeChromium $(!$edgeInstalled)
	if ($null -ne (Get-AppxPackage -Name Microsoft.MicrosoftEdge)) {
		if ($KeepAppX) {
			Write-Status "AppX Edge is being left, there might be a stub..." -Level Warning
		} else {
			Write-Status "Uninstalling AppX Edge..." -Level Warning
			RemoveEdgeAppx
		}
	}
	Write-Output ""
}

# Remove Edge data if the parameter is set
if ($RemoveEdgeData) {
	KillEdgeProcesses
	DeleteIfExist "$([Environment]::GetFolderPath('LocalApplicationData'))\Microsoft\Edge"
	Write-Status "Removed any existing Edge Chromium user data."
	Write-Output ""
}

Write-Host "Completed." -ForegroundColor Cyan
if ($NonInteractive) { exit }
Pause
