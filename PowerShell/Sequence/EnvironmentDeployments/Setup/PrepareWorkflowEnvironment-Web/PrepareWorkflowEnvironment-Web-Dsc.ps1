param([hashtable]$deploymentDetails, [hashtable]$dscParams, [hashTable]$dscSecureParams)
# deploymentDetails contains 'RootWorkingPath', 'WorkingPath'

# NOTE: This script configures sites in IIS for a web server only. Each site has been given its own configuration.

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

# Drt.Web
PerformDsc WebSite `
    -LocalhostConfigData @{
        AppDestinationPath = "$($dscParams.DeploymentPath)\$($dscParams.Environment)\Drt.Web";
        AppPoolName = "Drt.Web";
        WebSiteName = "Drt.Web";
        HttpPort = 8102;
        AppPoolCredential = $dscSecureParams.SvcPortalCredential;
    }

# ExternalServices.Document
PerformDsc WebSite `
    -LocalhostConfigData @{
        AppDestinationPath = "$($dscParams.DeploymentPath)\$($dscParams.Environment)\ExternalServices.Document";
        AppPoolName = "ExternalServices.Document";
        WebSiteName = "ExternalServices.Document";
        HttpPort = 9004;
        NetTcpBindingInformation = "9050:*";
        # This runs as the Sequence Admin account in production, but a separate service account in staging / UAT
        AppPoolCredential = $dscSecureParams.SvcSequenceAdminCredential;
    }

# Portal.Web.UI
PerformDsc WebSite `
    -LocalhostConfigData @{
        AppDestinationPath = "$($dscParams.DeploymentPath)\$($dscParams.Environment)\Portal.Web.UI";
        AppPoolName = "Portal.Web.UI";
        WebSiteName = "Portal.Web.UI";
        HttpPort = 80;
        AppPoolCredential = $dscSecureParams.SvcPortalCredential;
    }

# Process.Forms
PerformDsc WebSite `
    -LocalhostConfigData @{
        AppDestinationPath = "$($dscParams.DeploymentPath)\$($dscParams.Environment)\Process.Forms";
        AppPoolName = "Process.Forms";
        WebSiteName = "Process.Forms";
        HttpPort = 8103;
        AppPoolCredential = $dscSecureParams.SvcSequenceAdminCredential;
    }

# Process.Forms - ClientInformationRequest.Forms
PerformDsc WebApplication `
    -LocalhostConfigData @{
        AppDestinationPath = "$($dscParams.DeploymentPath)\$($dscParams.Environment)\ClientInformationRequest.Forms";
        WebApplicationName = "ClientInformationRequest.Forms";
        AppPoolName = "Process.Forms";
        WebSiteName = "Process.Forms";
        UsesExistingAppPool = $true;
    }

# Process.Forms - Service.OnHold.Web
PerformDsc WebApplication `
    -LocalhostConfigData @{
        AppDestinationPath = "$($dscParams.DeploymentPath)\$($dscParams.Environment)\Service.OnHold.Web";
        WebApplicationName = "Service.OnHold.Web";
        AppPoolName = "Process.Forms";
        WebSiteName = "Process.Forms";
        UsesExistingAppPool = $true;
    }

# Process.Web.UI
PerformDsc WebSite `
    -LocalhostConfigData @{
        AppDestinationPath = "$($dscParams.DeploymentPath)\$($dscParams.Environment)\Process.Web.UI";
        AppPoolName = "Process.Web.UI";
        WebSiteName = "Process.Web.UI";
        HttpPort = 8101;
        AppPoolCredential = $dscSecureParams.SvcSequenceAdminCredential;
    }