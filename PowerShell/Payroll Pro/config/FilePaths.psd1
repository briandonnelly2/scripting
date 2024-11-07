@{
    general    =
    @{
        deploydirectory = "\\ukvmpapp1094\TPLDeploymentShare\PayrollPro\"
    }
    production =
    @{
        appfiles  = "\\ukvmprds1001\C$\Program Files (x86)\Star\Payroll\"

        appdata   = "\\UKNASDATA05\stdspudapp\payroll\Star payroll server\Shared Data\"

        datafiles = @("MCPGLOSS.MDB", "MCPTEMP.MDB", "TAX&NI.MDB")
    }
    staging    =
    @{
        appfiles  = "\\ukvmurds1001\C$\Program Files (x86)\Star\Payroll\"

        appdata   = "\\ukbirdata02\PENSIONSBIR\Admin\Gen\Star\Star payroll server\Shared Data\"

        datafiles = @("MCPGLOSS.MDB", "MCPTEMP.MDB", "TAX&NI.MDB")
    }
    dev        = 
    @{
        AppFiles  = ""

        AppData   = ""

        datafiles = ""
    }
}