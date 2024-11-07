Rem *****************************************************************************************************
Rem * Author : Graham Healing 27/01/2014
Rem *
Rem * Purpose : Create a log file showing files present in EXL, IES and Pensions directories
Rem *           
Rem * 
Rem *****************************************************************************************************


if not exist "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\FileAnalysis\\%date:/=-%\" md "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\FileAnalysis\%date:/=-%\"



dir "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\EXL Clients\"*.* >> "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\FileAnalysis\\%date:/=-%\"EXLLog.csv

dir "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\EXL Clients\"*.mcp >> "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\FileAnalysis\\%date:/=-%\"EXLLog.csv


dir "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\EXL Clients\TEST\"*.* >> "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\FileAnalysis\\%date:/=-%\"TESTLog.csv

dir "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\EXL Clients\TEST\"*.mcp >> "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\FileAnalysis\\%date:/=-%\"TESTLog.csv


dir "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\Star payroll clients\IES\"*.* >> "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\FileAnalysis\%date:/=-%\"IESLog.csv

dir "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\Star payroll clients\IES\"*.mcp >> "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\FileAnalysis\%date:/=-%\"IESLog.csv


dir "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\Star payroll clients\IES\Consultancy\"*.* >> "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\FileAnalysis\%date:/=-%\"ConsultancyLog.csv

dir "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\Star payroll clients\IES\Consultancy\"*.mcp >> "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\FileAnalysis\%date:/=-%\"ConsultancyLog.csv


dir "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\Star payroll clients\IES\Annual\"*.* >> "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\FileAnalysis\%date:/=-%\"AnnualLog.csv

dir "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\Star payroll clients\IES\Annual\"*.mcp >> "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\FileAnalysis\%date:/=-%\"AnnualLog.csv


dir "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\Star payroll clients\A_Pension schemes\"*.* >> "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\FileAnalysis\%date:/=-%\"PenLog.csv

dir "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\Star payroll clients\A_Pension schemes\"*.mcp >> "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\FileAnalysis\%date:/=-%\"PenLog.csv

Rem - copy latest T2DATA linked to file analysis log
Rem - remmed out 19/11 as now SQL
Rem - copy "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\T2DATA.MDB" "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\FileAnalysis\T2DATA.MDB"


