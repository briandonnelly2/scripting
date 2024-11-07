<# 
    Defines application environment information.

    Information that applies across environments is defined in 
    the 'global' hashtable.  This is where we define the app name,
    admins, read-only users, active directory user groups and local 
    groups in scope.  Any exemptions for ITS accounts and groups are 
    also specified.  This is not an application 'environment' and is
    handled separately by the script.

    Application Environemnts are defined as:

        -   'prod'  =   Production
        -   'uat'   =   User Acceptance Testing or Staging
        -   'dev'   =   The Development environment
        -   'qa'    =   The Quality Assurance or test environment
    
    The hosting servers, database instances & database names etc. 
    should be defined here.  This information is required by the 
    scripts in order to gather access information.
    
    More than one of each type of environment can be defined if 
    there is a need to separate access further, e.g. 2 prod environments 
    would be named prod1 and prod2.  the script has logic to recognise 
    this for prod. The script would need to be reworked slightly if there 
    were 2 UAT or DEV environemts for example.
#>
@{
    <# Data that applies within all application environments #>
    global = 
    @(
        @{
            name            =   "Workflow"

            envname         =   "global"

            appadmins       =   "rmills1",
                                "jmoore8",
                                "Jmcateer",
                                "jmcinally",
                                "agray3",
                                "pboyd1",
                                "akhan46",
                                "briandonnelly2",
                                "rjassal"

            envadmins       =   "-oper-Rmills1",
                                "-oper-Jmcateer",
                                "-oper-Jmcinally",
                                "-oper-agray3",
                                "-oper-kcorbett",
                                "-oper-pboyd1",
                                "-oper-akhan",
                                "-oper-briandonnelly2",
                                "-oper-rjassal",
                                "-oper-sushah",
                                "-oper-vsoares"

            envreadonly     =   "ukrctgovardhan",
                                "ukrcsranganath",
                                "ukrcsms1",
                                "ukrcmgdastidar"

            adusrsecgroups  =   "UK-SG PR App Support Admin",
                                "UK-SG RO App Support Access"

            exemptusers     =   "K1_Admin",
                                "UKServerAcc"

            exemptgroups    =   "UK-SG Member Server Admins"

            rsatserver      =   "UKVMWTS006"

            adminlocalsg    =   "Administrators"

            readonlylocalsg =   "Remote Desktop Users",
                                "Event Log Viewers"
        }
    )

    prod1 =
    @(
        @{
            name            =   "Tax Compliance"

            envname         =   "tcprod"

            domain          =   "UK"

            servers         =   "UKVMSAPP033",
                                "UKVMSAPP034",
                                "UKVMSAPP035",
                                "UKVMSAPP036",
                                "UKVMSAPP062",
                                "UKVMSWEB014",
                                "UKVMSWEB015",
                                "UKVMSWEB016",
                                "UKVMSWEB017"

            dbinstance      =   "UKIXESQL005\DB01"

            appdbnames      =   "Sequence",
                                "TaxWFPortalData",
                                "TaxWFReviewToolData",
                                "TaxWFReviewToolDataReporting",
                                "ReportingWarehouse",
                                "TaxClientPortalData_Internal",
                                "TAX_Atlas_KPMGLink"
            
            svcaccounts     =   "-svc-DigitaWFS",
                                "-svc-AlphataxWFS",
                                "-svc-EfilingWFS",
                                "-svc-DocumentWFS",
                                "-svc-WorksiteWebsvc",
                                "-svc-Portal",
                                "-svc-SequenceAdmin",
                                "-svc-Taxwflslas",
                                "-svc-TaxWorkflowDbLi",
                                "-svc-taxIESws",
                                "-svc-uploadtoExtranet",
                                "-svc-TaxWFBus",
                                "-svc-SAPWFS"

            adappsecgroups  =   "UK-SG PR-OP PROD-WorkflowTC",
                                "UK-SG RO-OP PROD-WorkflowTC",
                                "UK-SG PR-DA PROD-WorkflowTC",
                                "UK-SG RO-DA PROD-WorkflowTC"
        }
    )

    prod2 = 
    @(
        @{
            name            =   "Partner's"

            envname         =   "paprod"

            domain          =   "UK"

            servers         =   "UKVMSAPP068",
                                "UKVMSAPP069",
                                "UKVMSWEB024",
                                "UKVMSWEB025"
   

            dbinstance      =   "UKIXESQL006\DB02"

            appdbnames      =   "SequencePA",
                                "TaxWFLoggingPA",
                                "TaxWFPortalDataPa",
                                "TaxWFReviewToolDataPA",
                                "TaxWFReviewToolDataPAReporting"

            svcaccounts     =   "-svc-DigitaWFS",
                                "-svc-AlphataxWFS",
                                "-svc-EfilingWFS",
                                "-svc-DocumentWFS",
                                "-svc-WorksiteWebsvc",
                                "-svc-Portal",
                                "-svc-SequenceAdmin",
                                "-svc-Taxwflslas",
                                "-svc-TaxWorkflowDbLi",
                                "-svc-taxIESws",
                                "-svc-uploadtoExtranet",
                                "-svc-TaxWFBus",
                                "-svc-SAPWFS"

            adappsecgroups  =   "UK-SG PR-OP PROD-WorkflowPA",
                                "UK-SG RO-OP PROD-WorkflowPA",
                                "UK-SG PR-DA PROD-WorkflowPA",
                                "UK-SG RO-DA PROD-WorkflowPA"
        }
    )

    uat =   
    @(
        @{
            name            =   "Staging"

            envname         =   "uat"

            domain          =   "UK"

            servers         =   "UKVMSAPP031",
                                "UKVMSAPP032",
                                "UKVMSWEB012",
                                "UKVMSWEB013"
   

            dbinstance      =   "UKIXESQL384\DB01"

            appdbnames      =   "SequenceSTG",
                                "StgWFPortalData",
                                "TaxWFReviewToolData",
                                "TaxClientPortalData_Internal_Uat",
                                "TaxWFReviewToolDataSTG",
                                "TaxWFReviewToolReportingDataSTG"

            svcaccounts     =   "-svc-DigitaWFS_TST",
                                "-svc-AlphataxWFS_TST",
                                "-svc-EfilingWFS_TST",
                                "-svc-DocumentWFS_TST",
                                "-svc-WorksiteWebsvc_TST",
                                "-svc-Portal_TST",
                                "-svc-SequenceAdmin_T",
                                "-svc-Taxwfslas_TST",
                                "-svc-TaxWFDbLi_TST",
                                "SeqUserStg",
                                "-svc-taxIESws_TST"

            adappsecgroups  =   "UK-SG PR-OP UAT-Workflow",
                                "UK-SG PR-DA UAT-Workflow"
        }
    )

    dev =   
    @(
        @{
            name            =   "Development"

            envname         =   "dev"

            domain          =   "UKX"

            servers         =   "UKVMSAPP031",
                                "UKVMSAPP032",
                                "UKVMSWEB012",
                                "UKVMSWEB013"
   

            dbinstance      =   "UKIXESQL384\DB01"

            appdbnames      =   "SequenceSTG",
                                "StgWFPortalData",
                                "TaxWFReviewToolData",
                                "TaxClientPortalData_Internal_Uat",
                                "TaxWFReviewToolDataSTG",
                                "TaxWFReviewToolReportingDataSTG"
            
            svcaccounts     =   ""

            adappsecgroups  =   "UKX-SG PR-OP DEV-Workflow",
                                "UKX-SG PR-DA DEV-Workflow"
        }
    )

    qa =   
    @(
        @{
            name            =   "Test"

            envname         =   "qa"

            domain          =   "UKX"

            servers         =   "UKVMSAPP031",
                                "UKVMSAPP032",
                                "UKVMSWEB012",
                                "UKVMSWEB013"
   

            dbinstance      =   "UKIXESQL384\DB01"

            appdbnames      =   "SequenceSTG",
                                "StgWFPortalData",
                                "TaxWFReviewToolData",
                                "TaxClientPortalData_Internal_Uat",
                                "TaxWFReviewToolDataSTG",
                                "TaxWFReviewToolReportingDataSTG"
            
            svcaccounts     =   ""

            adappsecgroups  =   "UKX-SG PR-OP QA-Workflow",
                                "UKX-SG PR-DA QA-Workflow"
        }
    )
}

<# 

            sbinstance      =   "UKIXESQL006\DB02"

            sbdatabases     =   "PortalSbGatewayDatabase",
                                "PortalSbManagementDB",
                                "PortalSbMessageContainer01",
                                "PortalSbMessageContainer02",
                                "PortalSbMessageContainer03",
                                "PortalSbMessageContainer04",
                                "PortalSbMessageContainer05",
                                "PortalSbMessageContainer06"


$GroupNames = @("UK-SG PR-OP PROD-WorkflowTC","UK-SG PR-DA PROD-WorkflowTC","UK-SG RO-OP PROD-WorkflowTC","UK-SG RO-DA PROD-WorkflowTC",
                "UK-SG PR-OP PROD-WorkflowPA","UK-SG PR-DA PROD-WorkflowPA","UK-SG RO-OP PROD-WorkflowPA","UK-SG RO-DA PROD-WorkflowPA",
                "UK-SG PR-OP UAT-Workflow","UK-SG PR-DA UAT-Workflow","UK-SG PR-OP PROD-Digita","UK-SG PR-DA PROD-Digita","UK-SG RO-OP PROD-Digita",
                "UK-SG RO-DA PROD-Digita","UK-SG PR-OP UAT-Digita","UK-SG PR-DA UAT-Digita","UK-SG PR-OP PROD-Alphatax","UK-SG PR-DA PROD-Alphatax",
                "UK-SG RO-OP PROD-Alphatax","UK-SG RO-DA PROD-Alphatax","UK-SG PR-OP UAT-Alphatax","UK-SG PR-DA UAT-Alphatax",
                "UK-SG PR App Support Admin","UK-SG RO App Support Access","UK-SG PR App Support Approvers")
#>

