# Install ADDS, DHCP, and DNS
Install-WindowsFeature -Name AD-Domain-Services, DHCP, DNS -IncludeManagementTools

# Promote to Domain Controller
Install-ADDSForest -DomainName "IaCtestServer.com" -InstallDNS -SafeModeAdministratorPassword (ConvertTo-SecureString -AsPlainText "Aspire2" -Force) -Force

# Install Windows MDT
Start-Process -FilePath "C:\deploymentsoftware\MicrosoftDeploymentToolkit_x64.msi" -ArgumentList "/quiet", "/norestart" -Wait



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


