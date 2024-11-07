Rem Copy Star T2DATA AND Glossary

if not exist "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\System Backups\LIVE%date:/=-%\" md "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\System Backups\Live%date:/=-%\"

copy "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\*.*" "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\System Backups\Live%date:/=-%\"

Rem Also Copy Documentation Folders as it contains excel files in addition to Star help files

copy "\\uknasdata05\stdspudapp\payroll\Star payroll server\Client Install\documentation\Payroll Process Notes\*.*" "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\System Backups\Live%date:/=-%\"

copy "\\uknasdata05\stdspudapp\payroll\Star payroll server\Client Install\documentation\Tracker\*.*" "\\uknasdata05\stdspudapp\payroll\Star payroll server\Shared Data\System Backups\Live%date:/=-%\"






