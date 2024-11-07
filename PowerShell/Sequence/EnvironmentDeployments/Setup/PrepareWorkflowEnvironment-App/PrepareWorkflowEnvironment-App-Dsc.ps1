param([hashtable]$deploymentDetails, [hashtable]$dscParams, [hashTable]$dscSecureParams)
# deploymentDetails contains 'RootWorkingPath', 'WorkingPath'

# NOTE: This script configures sites in IIS for an app server only. Each site has been given its own configuration.

# ---------------------------------------------------------------------------
# Standard DSC - Web Server
# ---------------------------------------------------------------------------
Configuration WebServer {
    Import-DscResource -Module PSDesiredStateConfiguration
    Import-DscResource -Module xWebAdministration

    node localhost {

        $Server2012Plus = [Environment]::OSVersion.Version -ge (new-object 'Version' 6,3)

        # [REQUIRED] Setup the local configuration manager
        LocalConfigurationManager {
            CertificateID               = $Node.Thumbprint
            ConfigurationMode           = 'ApplyOnly'
        }

        # Install the web server
        WindowsFeature Web-Server {
            Ensure                      = "Present"
            Name                        = "Web-Server"
        }

        # Enable basic authentication
        WindowsFeature Web-Basic-Auth {
            Ensure                      = "Present"
            Name                        = "Web-Basic-Auth"
        }

        # Enable Windows authentication
        WindowsFeature Web-Windows-Auth {
            Ensure                      = "Present"
            Name                        = "Web-Windows-Auth"
        }

        # Ensure the management console exists (saves confusion!)
        WindowsFeature Web-Mgmt-Console {
            Ensure                      = "Present"
            Name                        = "Web-Mgmt-Console"
        }

        if ($Server2012Plus) {
            # Install the ASP.NET 4.5 role
            WindowsFeature AspNet45 {
                Ensure                  = "Present"
                Name                    = "Web-Asp-Net45"
            }

            if ($Node.HostsWcfService) {
                WindowsFeature NetHttpActivation {
                    Ensure              = "Present"
                    Name                = "NET-WCF-HTTP-Activation45" 
                }

                WindowsFeature NetTcpActivation {
                    Ensure              = "Present"
                    Name                = "NET-WCF-TCP-Activation45" 
                }
            }
        } else {
            # Server 2008 - just go for ASP.NET
            WindowsFeature AspNet {
                Ensure                  = "Present"
                Name                    = "Web-Asp-Net"
            }

            if ($Node.HostsWcfService) {
                WindowsFeature ASWebSupport {
                    Ensure              = "Present"
                    Name                = "AS-Web-Support"
                }

                WindowsFeature NetHttpActivation {
                    Ensure              = "Present"
                    Name                = "NET-HTTP-Activation" 
                }

                WindowsFeature NetHttpNonActiv {
                    Ensure              = "Present"
                    Name                = "NET-Non-HTTP-Activ" 
                }
            }
        }
    }
}

# ---------------------------------------------------------------------------
# Standard DSC - Web Site
# ---------------------------------------------------------------------------
Configuration WebSite {
    Import-DscResource -Module PSDesiredStateConfiguration
    Import-DscResource -Module xWebAdministration

    node localhost {

        # [REQUIRED] Setup the local configuration manager
        LocalConfigurationManager {
            CertificateID               = $Node.Thumbprint
            ConfigurationMode           = 'ApplyOnly'
        }

        # Create the deployment directory
        File DeploymentDirectory {
            Ensure                      = "Present"
            Type                        = "Directory"
            DestinationPath             = $Node.AppDestinationPath
        }

        $webApplicationDependencies = @("[File]DeploymentDirectory")

        if ($Node.UsesExistingAppPool -ne $true) {

            $webApplicationDependencies += "[xWebAppPool]AppPool"

            # Create the application pool
            xWebAppPool AppPool {
                Name                    = $Node.AppPoolName
                Ensure                  = "Present"
                autoStart               = $true
                startMode               = "AlwaysRunning"
                identityType            = "SpecificUser"
                Credential              = $Node.AppPoolCredential
                State                   = "Started"
                managedRuntimeVersion   = "v4.0"
            }
            
        }

        # Prepare binding info
        $bindingInfo = @()
        $enabledProtocols = "http"

        # HTTP Binding info
        if ($Node.HttpPort -ne $null) {
            $bindingInfo += MSFT_xWebBindingInformation {
                Protocol                = "http"
                Port                    = $Node.HttpPort
            }
        }

        if ($Node.NetTcpBindingInformation -ne $null) {
            $bindingInfo += MSFT_xWebBindingInformation {
                Protocol                = "net.tcp"
                BindingInformation      = $Node.NetTcpBindingInformation
            }
            $enabledProtocols += ",net.tcp"
        }

        # Create the web site
        xWebSite WebSite 
        {
            Name                        = $Node.WebSiteName
            Ensure                      = "Present"
            PhysicalPath                = $Node.AppDestinationPath
            ApplicationPool             = $Node.AppPoolName
            AuthenticationInfo          = MSFT_xWebAuthenticationInformation {
                Anonymous               = $false
                Basic                   = $false
                Windows                 = $true
            }
            BindingInfo                 = $bindingInfo
            EnabledProtocols            = $enabledProtocols
            DependsOn                   = $webApplicationDependencies
        }
    }
}

# ---------------------------------------------------------------------------
# Standard DSC - Web Application
# ---------------------------------------------------------------------------
Configuration WebApplication {
    Import-DscResource -Module PSDesiredStateConfiguration
    Import-DscResource -Module xWebAdministration

    node localhost {
        
        # [REQUIRED] Setup the local configuration manager
        LocalConfigurationManager {
            CertificateID               = $Node.Thumbprint
            ConfigurationMode           = 'ApplyOnly'
        }

        # Create the deployment directory
        File DeploymentDirectory {
            Ensure                      = "Present"
            Type                        = "Directory"
            DestinationPath             = $Node.AppDestinationPath
        }

        $webApplicationDependencies     = @("[File]DeploymentDirectory")

        if ($Node.UsesExistingAppPool -ne $true) {

            $webApplicationDependencies += "[xWebAppPool]AppPool"

            # Create the application pool
            xWebAppPool AppPool {
                Name                    = $Node.AppPoolName
                Ensure                  = "Present"
                autoStart               = $true
                startMode               = "AlwaysRunning"
                identityType            = "SpecificUser"
                Credential              = $Node.AppPoolCredential
                State                   = "Started"
                managedRuntimeVersion   = "v4.0"
            }

        }

        # Create the web application
        xWebApplication WebApplication {
            Name                        = $Node.WebApplicationName
            Website                     = $Node.WebSiteName
            PhysicalPath                = $Node.AppDestinationPath
            WebAppPool                  = $Node.AppPoolName
            DependsOn                   = $webApplicationDependencies
        }
    }
}

# ---------------------------------------------------------------------------
# Applied Configurations
# ---------------------------------------------------------------------------

# General Web Server Setup
PerformDsc WebServer `
    -LocalhostConfigData @{
        HostsWcfService = $true;
    }

# ExternalServices.Alphatax
PerformDsc WebSite `
    -LocalhostConfigData @{
        AppDestinationPath = "$($dscParams.DeploymentPath)\$($dscParams.Environment)\ExternalServices.Alphatax";
        AppPoolName = "ExternalServices.Alphatax";
        WebSiteName = "ExternalServices.Alphatax";
        HttpPort = 9000;
        NetTcpBindingInformation = "9200:*";
        AppPoolCredential = $dscSecureParams.SvcAlphataxCredential;
    }

# ExternalServices.ClientPortalInternal
PerformDsc WebSite `
    -LocalhostConfigData @{
        AppDestinationPath = "$($dscParams.DeploymentPath)\$($dscParams.Environment)\ExternalServices.ClientPortalInternal";
        AppPoolName = "ExternalServices.ClientPortalInternal";
        WebSiteName = "ExternalServices.ClientPortalInternal";
        HttpPort = 9020;
        NetTcpBindingInformation = "9021:*";
        AppPoolCredential = $dscSecureParams.SvcPortalCredential;
    }

# ExternalServices.Digita
PerformDsc WebSite `
    -LocalhostConfigData @{
        AppDestinationPath = "$($dscParams.DeploymentPath)\$($dscParams.Environment)\ExternalServices.Digita";
        AppPoolName = "ExternalServices.Digita";
        WebSiteName = "ExternalServices.Digita";
        HttpPort = 9001;
        NetTcpBindingInformation = "9201:*";
        AppPoolCredential = $dscSecureParams.SvcDigitaCredential;
    }

# ExternalServices.DigitaV2
PerformDsc WebSite `
    -LocalhostConfigData @{
        AppDestinationPath = "$($dscParams.DeploymentPath)\$($dscParams.Environment)\ExternalServices.DigitaV2";
        AppPoolName = "ExternalServices.Digita";
        WebSiteName = "ExternalServices.DigitaV2";
        HttpPort = 9007;
        NetTcpBindingInformation = "9207:*";
        AppPoolCredential = $dscSecureParams.SvcDigitaCredential;
    }

# ExternalServices.Drt.Wcf
PerformDsc WebSite `
    -LocalhostConfigData @{
        AppDestinationPath = "$($dscParams.DeploymentPath)\$($dscParams.Environment)\ExternalServices.Drt.Wcf";
        AppPoolName = "ExternalServices.Drt.Wcf";
        WebSiteName = "ExternalServices.Drt.Wcf";
        HttpPort = 9004;
        NetTcpBindingInformation = "9204:*";
        AppPoolCredential = $dscSecureParams.SvcPortalCredential;
    }

# ExternalServices.Efiling
PerformDsc WebSite `
    -LocalhostConfigData @{
        AppDestinationPath = "$($dscParams.DeploymentPath)\$($dscParams.Environment)\ExternalServices.Efiling";
        AppPoolName = "ExternalServices.Efiling";
        WebSiteName = "ExternalServices.Efiling";
        HttpPort = 9002;
        NetTcpBindingInformation = "9202:*";
        AppPoolCredential = $dscSecureParams.SvcEfilingCredential;
    }

# ExternalServices.PortalData
PerformDsc WebSite `
    -LocalhostConfigData @{
        AppDestinationPath = "$($dscParams.DeploymentPath)\$($dscParams.Environment)\ExternalServices.PortalData";
        AppPoolName = "ExternalServices.PortalData";
        WebSiteName = "ExternalServices.PortalData";
        HttpPort = 9003;
        NetTcpBindingInformation = "9203:*";
        AppPoolCredential = $dscSecureParams.SvcPortalCredential;
    }

# ExternalServices.PortalDataV2
PerformDsc WebSite `
    -LocalhostConfigData @{
        AppDestinationPath = "$($dscParams.DeploymentPath)\$($dscParams.Environment)\ExternalServices.PortalDataV2";
        AppPoolName = "ExternalServices.PortalData";
        WebSiteName = "ExternalServices.PortalDataV2";
        HttpPort = 9005;
        NetTcpBindingInformation = "9205:*";
        AppPoolCredential = $dscSecureParams.SvcPortalCredential;
    }

# ExternalServices.Sap
PerformDsc WebSite `
    -LocalhostConfigData @{
        AppDestinationPath = "$($dscParams.DeploymentPath)\$($dscParams.Environment)\ExternalServices.Sap";
        AppPoolName = "ExternalServices.Sap";
        WebSiteName = "ExternalServices.Sap";
        HttpPort = 9008;
        NetTcpBindingInformation = "9208:*";
        AppPoolCredential = $dscSecureParams.SvcSapCredential;
    }

# ExternalServices.WorkflowSlas
PerformDsc WebSite `
    -LocalhostConfigData @{
        AppDestinationPath = "$($dscParams.DeploymentPath)\$($dscParams.Environment)\ExternalServices.WorkflowSlas";
        AppPoolName = "ExternalServices.WorkflowSlas";
        WebSiteName = "ExternalServices.WorkflowSlas";
        HttpPort = 9006;
        NetTcpBindingInformation = "9206:*";
        AppPoolCredential = $dscSecureParams.SvcPortalCredential;
    }

# Process.Services
PerformDsc WebSite `
    -LocalhostConfigData @{
        AppDestinationPath = "$($dscParams.DeploymentPath)\$($dscParams.Environment)\Process.Services";
        AppPoolName = "Process.Services";
        WebSiteName = "Process.Services";
        HttpPort = 9010;
        NetTcpBindingInformation = "9210:*";
        AppPoolCredential = $dscSecureParams.SvcSequenceAdminCredential;
    }

# Process.Services
PerformDsc WebSite `
    -LocalhostConfigData @{
        AppDestinationPath = "$($dscParams.DeploymentPath)\$($dscParams.Environment)\Process.Services";
        AppPoolName = "Process.Services";
        WebSiteName = "Process.Services";
        HttpPort = 9010;
        NetTcpBindingInformation = "9210:*";
        AppPoolCredential = $dscSecureParams.SvcSequenceAdminCredential;
    }

# Process.Services - ClientInformationRequest.Service
PerformDsc WebApplication `
    -LocalhostConfigData @{
        AppDestinationPath = "$($dscParams.DeploymentPath)\$($dscParams.Environment)\ClientInformationRequest.Service";
        WebApplicationName = "ClientInformationRequest.Service";
        AppPoolName = "Process.Services";
        WebSiteName = "Process.Services";
        UsesExistingAppPool = $true;
    }

# Process.Services - Service.OnHold.Api
PerformDsc WebApplication `
    -LocalhostConfigData @{
        AppDestinationPath = "$($dscParams.DeploymentPath)\$($dscParams.Environment)\Service.OnHold.Api";
        WebApplicationName = "Service.OnHold.Api";
        AppPoolName = "Process.Services";
        WebSiteName = "Process.Services";
        UsesExistingAppPool = $true;
    }