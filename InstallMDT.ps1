# Install ADDS, DHCP, and DNS
Install-WindowsFeature -Name AD-Domain-Services, DHCP, DNS -IncludeManagementTools

# Promote to Domain Controller
Install-ADDSForest -DomainName "IaCtestServer.com" -InstallDNS -SafeModeAdministratorPassword (ConvertTo-SecureString -AsPlainText "Aspire2" -Force) -Force

# Install Windows MDT
Start-Process -FilePath "C:\deploymentsoftware\MicrosoftDeploymentToolkit_x64.msi" -ArgumentList "/quiet", "/norestart" -Wait
