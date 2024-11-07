#region Information

#This file lists the security groups needed to access application servers and databases
#These are split by environment (dev, uat, prod), infrastructure (databases & servers),
#and privilege level (read-only & read/write/admin privileges).  Within this, I have 
#listed by application what SG's grant access.  The tool I have built will read this file
#to determine which group to add the user to.  This can then be updated with other groups
#as and when we get them created.

#I used a convention when having the security groups created. Obviously, every SG in KPMG
#is prefixed with 'UK-SG' so this is mandatory.  I have detailed below what the other 
#4 letters separated by a hyphen indicate in terms of access. I've then simply used the 
#abbreviations 'PROD' to indicate production access and 'UAT' to indicate UAT/Staging access.
#this is then followed by the name of the application.

#RO stands for read-only and is for developers and the like to get read access.
#PR stands for privileged and is for admin users like the app support team to get access
#DA stands for data and is exclusively for SQL database access
#OP is for operations and is used to grant access to any hosting servers 

#RO-DA: These data groups grant read-only access to all database objects and tables for an application
#PR-DA: These data groups grant read/write access to all database tables and read-only access to all other 
        #database objects for an application. **I am of the opinion that no one other than admin support users get this access.**

#RO-OP: These operations groups grant remote logon rights and allow access to the event logs on the hosting servers for an application
#PR-OP: These operations groups grant local admin rights on the hosting servers for an application.  
        #**I am of the opinion that no one other than admin support users get this access.**   

#endregion Information
@{  
    #Production 
    prod    =   
    @{  #Managed SQL Databases
        databases   =   
        @{  #ACE (CORP & GMS)
            ace         =
            @{
                        readonly    =   "UK-SG RO-DA PROD-ACE"
                        privileged  =   "UK-SG PR-DA Prod ACE"
            }#Alphatax
            alphatax    =
            @{
                        readonly    =   "UK-SG RO-DA PROD-Alphatax"
                        privileged  =   "UK-SG PR-DA PROD-Alphatax"
            }#Digita
            digita      =
            @{
                        readonly    =   "UK-SG RO-DA PROD-Digita"
                        privileged  =   "UK-SG PR-DA PROD-Digita"
            }#KPMG Vault
            vault       =
            @{
                        readonly    =   "UK-SG RO-DA PROD-Vault"
                        privileged  =   "UK-SG PR-DA PROD-Vault"
            }#Intellidox
            intellidox  =
            @{
                        readonly    =   "UK-SG RO-DA PROD-Intellidox"
                        privileged  =   "UK-SG PR-DA PROD-Intellidox"
            }#Sequence BPM
            sequence    =
            @{
                        readonly    =   "UK-SG RO-DA PROD-TPLWorkflow"
                        privileged  =   "UK-SG PR-DA PROD-TPLWorkflow"
            }
        }#Microsoft Windows Servers
        servers     =
        @{  #ACE (CORP & GMS)
            ace         =
            @{
                        readonly    =   "UK-SG RO-OP PROD-ACE"
                        privileged  =   "UK-SG PR-OP PROD-ACE"
            }#Alphatax
            alphatax    =
            @{
                        readonly    =   "UK-SG RO-OP PROD-Alphatax"
                        privileged  =   "UK-SG PR-OP PROD-Alphatax"
            }#Digita
            digita      =
            @{
                        readonly    =   "UK-SG RO-OP PROD-Digita"
                        privileged  =   "UK-SG PR-OP PROD-Digita"
            }#KPMG Vault
            vault       =
            @{
                        readonly    =   "UK-SG RO-OP PROD-Vault"
                        privileged  =   "UK-SG PR-OP PROD-Vault"
            }#Intellidox
            intellidox  =
            @{
                        readonly    =   "UK-SG RO-OP PROD-Intellidox"
                        privileged  =   "UK-SG PR-OP PROD-Intellidox"
            }#Sequence BPM
            sequence    =
            @{
                        readonly    =   "UK-SG RO-OP PROD-TPLWorkflow"
                        privileged  =   "UK-SG PR-OP PROD-TPLWorkflow"
            }
        }
    }
    #UAT/Staging
    uat     =
    @{  #Managed SQL Databases
        databases   =   
        @{  #ACE (CORP & GMS)
            ace         =
            @{
                        readonly    =   "UK-SG RO-DA UAT-ACE"
                        privileged  =   "UK-SG PR-DA UAT ACE"
            }#Alphatax
            alphatax    =
            @{
                        readonly    =   ""#UK-SG RO-DA UAT-Alphatax
                        privileged  =   "UK-SG PR-DA UAT-Alphatax"
            }#Digita
            digita      =
            @{
                        readonly    =   ""#UK-SG RO-DA UAT-Digita
                        privileged  =   "UK-SG PR-DA UAT-Digita"
            }#KPMG Vault
            vault       =
            @{
                        readonly    =   ""#UK-SG RO-DA UAT-Vault
                        privileged  =   "UK-SG PR-DA UAT-Vault"
            }#Intellidox
            intellidox  =
            @{
                        readonly    =   ""#UK-SG RO-DA UAT-Intellidox
                        privileged  =   "UK-SG PR-DA UAT-Intellidox"
            }#Sequence BPM
            sequence    =
            @{
                        readonly    =   ""#UK-SG RO-DA UAT-TPLWorkflow
                        privileged  =   "UK-SG PR-DA UAT-TPLWorkflow"
            }
        }#Microsoft Windows Servers
        servers     =
        @{  #ACE (CORP & GMS)
            ace         =
            @{
                        readonly    =   ""#UK-SG RO-OP UAT-ACE
                        privileged  =   "UK-SG PR-OP UAT-ACE"
            }#Alphatax
            alphatax    =
            @{
                        readonly    =   ""#UK-SG RO-OP UAT-Alphatax
                        privileged  =   "UK-SG PR-OP UAT-Alphatax"
            }#Digita
            digita      =
            @{
                        readonly    =   ""#UK-SG RO-OP UAT-Digita
                        privileged  =   "UK-SG PR-OP UAT-Digita"
            }#KPMG Vault
            vault       =
            @{
                        readonly    =   ""#UK-SG RO-OP UAT-Vault
                        privileged  =   "UK-SG PR-OP UAT-Vault"
            }#Intellidox
            intellidox  =
            @{
                        readonly    =   ""#UK-SG RO-OP UAT-Intellidox
                        privileged  =   "UK-SG PR-OP UAT-Intellidox"
            }#Sequence BPM
            sequence    =
            @{
                        readonly    =   ""#UK-SG RO-OP UAT-TPLWorkflow
                        privileged  =   "UK-SG PR-OP UAT-TPLWorkflow"
            }
        }
    }
    #UKX Developmemt Domain
    dev     =
    @{  #Managed SQL Databases
        databases   =   
        @{  #ACE (CORP & GMS)
            ace         =
            @{
                        readonly    =   ""
                        privileged  =   ""
            }#Alphatax
            alphatax    =
            @{
                        readonly    =   ""
                        privileged  =   ""
            }#Digita
            digita      =
            @{
                        readonly    =   ""
                        privileged  =   ""
            }#KPMG Vault
            vault       =
            @{
                        readonly    =   ""
                        privileged  =   ""
            }#Intellidox
            intellidox  =
            @{
                        readonly    =   ""
                        privileged  =   ""
            }#Sequence BPM
            sequence    =
            @{
                        readonly    =   ""
                        privileged  =   ""
            }
        }#Microsoft Windows Servers
        servers     =
        @{  #ACE (CORP & GMS)
            ace         =
            @{
                        readonly    =   ""
                        privileged  =   ""
            }#Alphatax
            alphatax    =
            @{
                        readonly    =   ""
                        privileged  =   ""
            }#Digita
            digita      =
            @{
                        readonly    =   ""
                        privileged  =   ""
            }#KPMG Vault
            vault       =
            @{
                        readonly    =   ""
                        privileged  =   ""
            }#Intellidox
            intellidox  =
            @{
                        readonly    =   ""
                        privileged  =   ""
            }#Sequence BPM
            sequence    =
            @{
                        readonly    =   ""
                        privileged  =   ""
            }
        }
    }
}