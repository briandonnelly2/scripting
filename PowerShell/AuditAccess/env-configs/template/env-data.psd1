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
            name            =   ""

            envname         =   "global"

            appadmins       =   ""

            envadmins       =   ""

            envreadonly     =   ""

            adminusersg     =   ""

            readonlyusersg  =   ""

            exemptusers     =   ""

            exemptgroups    =   ""

            adminlocalsg    =   ""

            readonlylocalsg =   ""
        }
    )

    prod =
    @(
        @{
            name            =   ""

            envname         =   "prod"

            servers         =   ""

            dbinstance      =   ""

            appdbnames      =   ""
            
            svcaccounts     =   ""

            srvadminsg      =   ""

            srvreadonlysg   =   ""

            dbadminsg       =   ""

            dbreadonlysg    =   ""

            
        }
    )

    uat =   
    @(
        @{
            name            =   ""

            envname         =   "uat"

            servers         =   ""   

            dbinstance      =   ""

            appdbnames      =   ""

            svcaccounts     =   ""

            srvadminsg      =   ""

            dbadminsg       =   ""
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