$VCName = hostname
$LogFile = gci "C:\ProgramData\VMware\VMware VirtualCenter\Logs\vpxd-*" | sort LastWriteTime | select -last 1 name | select name
$file = $logFile.Name

Function SendEmail{
	Param(
		[parameter(Mandatory=$true)]$emailFrom,$SendTo,$vc
	)
    Send-MailMessage -From $emailFrom -To $SendTo -Subject "VMware VirtualCenter Server(vpxd) on $vc, STOPPED!!!.After failure, the System tried to restart the service twice and failed.Please review the log(C:\ProgramData\VMware\VMware VirtualCenter\Logs\$file) on the server and resolve.<EOM> "  -SmtpServer "Mail.intel.com"
    }

SendEmail -emailFrom "dch.compute.hosting.services.operations@intel.com" -SendTo "dch.compute.hosting.services.operations@intel.com","jesse.e.phillips@intel.com" -vc $VCName 