Rem Copy Star T2DATA AND Glossary

if not exist "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\System Backups\LIVE%date:/=-%\" md "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\System Backups\Live%date:/=-%\"

copy "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\T2DATA.MDB" "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\System Backups\Live%date:/=-%\"

copy "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\MCPGLOSS.MDB" "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\System Backups\Live%date:/=-%\"


