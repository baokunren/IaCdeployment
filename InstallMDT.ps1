﻿# Install ADDS, DHCP, and DNS
Install-WindowsFeature -Name AD-Domain-Services, DHCP, DNS -IncludeManagementTools

# Promote to Domain Controller
Install-ADDSForest -DomainName "IaCtestServer.com" -InstallDNS -SafeModeAdministratorPassword (ConvertTo-SecureString -AsPlainText "Aspire2" -Force) -Force

# Install Windows MDT
Start-Process -FilePath "C:\deploymentsoftware\MicrosoftDeploymentToolkit_x64.msi" -ArgumentList "/quiet", "/norestart" -Wait

New-Item -path "c:\deploymentshare" -itemtype directory
New-Smbshare -name "deployment share" -path "C:\deploymentshare" -FullAccess Administrators 

# Script to automate the deployment of Windows 11 using MDT and WDS

# Step 1: Import the MDT module
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\Bin\MicrosoftDeploymentToolkit.psd1"
Write-Output "MDT module imported successfully."

# Step 2: Create a Deployment Share
$deploymentSharePath = "C:\DeploymentShare"
$PSDriveName = "DS001"
$Description = "MDT Deployment Share"
$ShareName="DeploymentShare$"
New-PSDrive -Name $PSDriveName -PSProvider "MDTProvider" -Root $deploymentsharePath -Description $Description -NetworkPath \\$env:COMPUTERNAME\$ShareName | add-MDTPersistentDrive
Write-Output "Deployment share created at $deploymentSharePath."

# Step 3: input winOS into MDT
New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root "C:\DeploymentShare"
import-mdtoperatingsystem -path "DS001:\Operating Systems" -SourcePath "D:\" -DestinationFolder "Windows 11" -Verbose


# Step 4: Import Applications into MDT
# Import Google Chrome
New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root "C:\DeploymentShare"
import-MDTApplication -path "DS001:\Applications" -enable "True" -Name "Google Chrome" -ShortName "Google Chrome" -Version "" -Publisher "" -Language "" -CommandLine "ChromeSetup.exe /s" -WorkingDirectory ".\Applications\Google Chrome" -ApplicationSourcePath "C:\deploymentsoftware" -DestinationFolder "Google Chrome" -Verbose


# Import VLC Media Player
New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root "C:\DeploymentShare"
import-MDTApplication -path "DS001:\Applications" -enable "True" -Name "VLC" -ShortName "VLC" -Version "" -Publisher "" -Language "" -CommandLine "vlc-3.0.21-win64.exe" -WorkingDirectory ".\Applications\VLC" -ApplicationSourcePath "C:\deploymentsoftware" -DestinationFolder "VLC" -Verbose


# Import Adobe Acrobat Reader
New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root "C:\DeploymentShare"
import-MDTApplication -path "DS001:\Applications" -enable "True" -Name "AcroReader" -ShortName "AcroReader" -Version "" -Publisher "" -Language "" -CommandLine "AcroRdrDC2400221005_en_US.exe" -WorkingDirectory ".\Applications\AcroReader" -ApplicationSourcePath "C:\deploymentsoftware" -DestinationFolder "AcroReader" -Verbose

# import MDT tasks sequences
New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root "C:\DeploymentShare"
import-mdttasksequence -path "DS001:\Task Sequences" -Name "OS with APPs" -Template "Client.xml" -Comments "" -ID "1" -Version "1.0" -OperatingSystemPath "DS001:\Operating Systems\Windows 11 Home in Windows 11 install.wim" -FullName "Windows User" -OrgName "IaCtestServer" -HomePage "about:blank" -Verbose

# Step 5: Configure Bootstrap.ini
$bootstrap = @"
UserID=Administrator
UserPassword=Aspire2
UserDomain=IaCtestServer.com
TaskSequenceID=1
SkipTaskSequence=YES
KeyboardLocale=en-US
SkipBDDWelcome=YES
"@
$bootstrapFile = "$deploymentSharePath\Control\Bootstrap.ini"
$bootstrap | Out-File $bootstrapFile -Force
Write-Output "Bootstrap.ini configured at $bootstrapFile."

# Step 6: Configure CustomSettings.ini
$customSettings = @"
[Settings]
Priority=Default
Properties=MyCustomProperty
 
[Default]
OSInstall=Y
SkipCapture=YES
SkipAdminPassword=YES
SkipProductKey=YES
SkipComputerBackup=YES
SkipBitLocker=YES
 
SkipBDDWelcome=YES
SkipUserData=YES
SkipTimeZone=YES
SkipLocaleSelection=YES
SkipComputerName=YES
SkipSummary=YES
SkipDomainMembership=YES
SkipApplications=YES
 
KeyboardLocale=en-US
TimeZoneName=GMT StandardTime
EventService=http://Deployment:9800
"@
$customSettingsFile = "$deploymentSharePath\Control\CustomSettings.ini"
$customSettings | Out-File $customSettingsFile -Force
Write-Output "CustomSettings.ini configured at $customSettingsFile."

#Disable the X86 boot wim and change the selection profile for the X64 boot wim
$XMLfile = "C:\deploymentShare\control\settings.xml"
    [xml]$settingsXML = Get-Content $XMLfile
    $SettingsXML.settings."SupportX86" = "False"
    $SettingsXML.Save($XMLfile)


# Step 7: Install and Configure WDS (Windows Deployment Services)
Install-WindowsFeature -Name WDS, WDS-Deployment, WDS-Transport -IncludeManagementTools

# Step 8: Update the Deployment Share to Reflect Changes
Update-MDTDeploymentShare -Path $deploymentSharePath

#installing WDS using powershell
$WDSPath = "C:\RemoteInstall"
WDSutil /verbose /progress /Initialize-Server /RemInst:$WDSPath
Start-Sleep -s 10
WDSutil /verbose /Start-server
Start-Sleep -s 10
WDSutil /set-Server /AnswerClients:ALL
Import-WDSBootImage -Path C:\DeploymentShare\Boot\LiteTouchPE_x64.wim
NewImageName "LiteTouchPE_x64" -SkipVerify

