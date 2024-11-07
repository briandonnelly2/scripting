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
            name            =   "Alphatax"

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

            envreadonly     =   ""

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

            servers         =   "null"

            dbinstance      =   "UKIXESQL027\DB01"

            appdbnames      =   "AlphataxClients",
                                "AlphataxCOE",
                                "AlphataxLoader",
                                "AlphaTaxLoaderEXL",
                                "AlphataxLoaderRDS",
                                "AlphataxTraining",
                                "AlphataxUserClients",
                                "AlphataxUserCOE",
                                "AlphataxUserTraining",
                                "AlphataxWatford"
            
            svcaccounts     =   ""

            srvadminsg      =   "UK-SG PR-OP PROD-Alphatax"

            srvreadonlysg   =   "UK-SG RO-OP PROD-Alphatax"

            dbadminsg       =   "UK-SG PR-DA PROD-Alphatax"

            dbreadonlysg    =   "UK-SG RO-OP PROD-Alphatax"

            
        }
    )

    uat =   
    @(
        @{
            name            =   "Staging"

            envname         =   "uat"

            servers         =   "null"   

            dbinstance      =   "UKIXESQL384\DB01"

            appdbnames      =   ""

            svcaccounts     =   ""

            srvadminsg      =   "UK-SG PR-OP UAT-Alphatax"

            dbadminsg       =   "UK-SG PR-DA UAT-Alphatax"
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