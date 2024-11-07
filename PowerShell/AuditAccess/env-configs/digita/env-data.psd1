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
            name            =   "Digita"

            envname         =   "global"


            appadmins       =   "rmills1",
                                "jmoore8",
                                "Jmcateer",
                                "jmcinally",
                                "agray3",
                                "pboyd1",
                                "akhan46",
                                "briandonnelly2",
                                "rjassal",
                                "kcorbett"

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

            adminusersg     =   "UK-SG PR App Support Admin"

            readonlyusersg  =   "UK-SG RO App Support Access"

            exemptusers     =   "K1_Admin",
                                "UKServerAcc"

            exemptgroups    =   "UK-SG Member Server Admins"

            adminlocalsg    =   "Administrators"

            readonlylocalsg =   "Remote Desktop Users",
                                "Event Log Readers"
        }
    )

    prod =
    @(
        @{
            name            =   "Production"

            envname         =   "prod"

            servers         =   "UKVMSWTS006"

            dbinstance      =   "UKIXESQL023\DB01"

            appdbnames      =   "PracticeManagement_TaxAid",
                                "PracticeManagement1",
                                "PracticeManagementCoE",
                                "PracticeManagementFarringdonSecure",
                                "PracticeManagementSecure1",
                                "TaxyWin_TaxAid",
                                "Taxywin1",
                                "TaxywinCOE",
                                "TaxywinFarringdonSecure",
                                "TaxywinSecure1",
                                "DataMining" ##Need to check this
            
            svcaccounts     =   ""

            srvadminsg      =   "UK-SG PR-OP PROD-Digita"

            srvreadonlysg   =   "UK-SG RO-OP PROD-Digita"

            dbadminsg       =   "UK-SG PR-DA PROD-Digita"

            dbreadonlysg    =   "UK-SG RO-DA PROD-Digita"

            
        }
    )

    uat =   
    @(
        @{
            name            =   "Staging"

            envname         =   "uat"

            servers         =   ""

            dbinstance      =   "UKIXESQL384\DB01"

            appdbnames      =   ""

            svcaccounts     =   ""

            srvadminsg      =   "UK-SG PR-OP UAT-Digita"

            dbadminsg       =   "UK-SG PR-DA UAT-Digita"
        }
    )

    dev =   
    @(
        @{
            name            =   ""

            envname         =   "dev"

            servers         =   ""
   
            dbinstance      =   ""

            appdbnames      =   ""
            
            svcaccounts     =   ""

            srvadminsg      =   ""

            dbadminsg       =   ""
        }
    )

    qa =   
    @(
        @{
            name            =   ""

            envname         =   "qa"

            servers         =   ""
   
            dbinstance      =   ""

            appdbnames      =   ""
            
            svcaccounts     =   ""

            srvadminsg      =   ""

            dbadminsg       =   ""
        }
    )
}

