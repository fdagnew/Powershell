#Author - Fitsume Dagnew
<#TEST:

- SSH to an ESXi Host
- Disable SSH for the ESXi Host from a VC.
- Make sure your SSH Session is still on and operational

Use the below commands to script:

-	Get a status of SSH on all ESXi hosts in the environment (Weekly)
-	Disable SSH for any host that have SSH enabled.


GET SSH Status
Get-Cluster fm1-prod-igbn-clu02 | Get-VMHost | Get-VMHostService | Where { $_.Key -eq "TSM-SSH" } | select VMHost, Label, Running

ENABLE SSH
Get-Cluster fm1-prod-igbn-clu02 | Get-VMHost | Foreach {
  Start-VMHostService -HostService ($_ | Get-VMHostService | Where { $_.Key -eq "TSM-SSH"} ) -Confirm:$false
}

Disable SSH
Get-Cluster fm1-OCP-clu01 | Get-VMHost | Foreach {
  Stop-VMHostService -HostService ($_ | Get-VMHostService | Where { $_.Key -eq "TSM-SSH"} ) -Confirm:$false
} 
#>
#clear and start time
clear
#clear log
Remove-Item c:\support\scripts\SSH_RUNNING_Log_*
$LogPath = "c:\support\scripts\"
$VCName = hostname
$LogFile = $LogPath + "SSH_RUNNING_Log_$VCName.txt"
$Time = Get-Date
$RunTime = "Script start on $Time."
$send = $false


Function CheckDate{
#Date information for when to run script
$Date = Get-Date
$Day = $Date.DayOfWeek
$First = Get-Date $date -day 1
$Last = (($first).AddMonths(1).AddDays(-1))
#Run script between 00:00 and 08:00
$TimeWindowStart = 0
$TimeWindow = 23
$TimeWindowStop = ($TimeWindowStart+$TimeWindow)
$tmpDate = $First
#Run script on 1st Sunday of each month
$DayOfWeek = "Sunday"
$NumDay = 3
$i = 0
DO{
	If($tmpDate.DayOfWeek -eq $DayofWeek){
		$i++
		If($i -eq $NumDay){
			If($tmpDate -eq $date){
				$DayOfWeekWindow = "true"
			}
		}
	}
	$tmpDate = $tmpDate.AddDays(1)
} Until ($tmpDate.Day -eq $last.Day)
If($DayOfWeekWindow -ne "true"){EXIT}

#Time window
$Time = [Math]::Round($Date.TimeOfDay.TotalHours)
If(($Time -le $TimeWindowStop) -and ($Time -ge $TimeWindowStart)){
$sMsg = "Today is the right day to run the script, Continue..." 
Write-Host $sMsg -Foregroundcolor Green 
WriteLogFile -Message $sMsg
	
}Else{
EXIT
}

}




#Set logging path and filenames for LogFile 
Function WriteLogFile{
	Param(
		[parameter(Mandatory=$true)]$Message
	)
    $Message | Out-File -FilePath $LogFile -Append 
}

WriteLogFile -Message "********************************************************************"

WriteLogFile -Message $RunTime

WriteLogFile -Message "********************************************************************"

#Adding PowerCli to PowerShell window
         if ((Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) -eq $null){
             Add-PSSnapin VMware.VimAutomation.Core      
            
            }
#connect
Connect-VIServer ([System.Net.Dns]::GetHostByName((hostname)).HostName)


Function CheckESXiSSH{

                    #Get a list of Clusters
	                $Clusters = Get-Cluster 
		            Foreach($cluster in $clusters){
                    WriteLogFile -Message ""
                    WriteLogFile -Message "ESXi Hosts that have SSH running on Cluster:"
                    WriteLogFile -Message $cluster.name
                    WriteLogFile -Message "==========================================================="
                    $hosts = Get-VMHost
                    #if($hosts.Count -ge 1){
                    #Get-VMHost | Get-VMHostService | Where { $_.Key -eq "TSM-SSH" } | select VMHost, Label, Running >> C:\support\scripts\SSH_RUNNING.txt
                    #}
                     Foreach ($vmhost in ($cluster | Get-VMHost| ?{($_.ConnectionState -ne "Disconnected") -and ($_.ConnectionState -ne "NotResponding")}))
                     {
                     
                                     
                     #$Target = Get-VMHost |Where { $_.name -eq $vmhost.name }| Get-VMHostService | Where { $_.Key -eq "TSM-SSH" } | select VMHost, Label, Running 
                    
                     $ESXi = $vmhost.name
                     $AllServices = Get-VMHostService -vmhost $ESXi 
                     $SShService = $AllServices | Where-Object {$_.Key -eq 'TSM-SSH'}   
                     if ($SShService.running -eq $true) {  
                     $msg = "* " + $ESXi
                     WriteLogFile -Message $msg
                     $send = $true                     
                     }
                     
                     #Call here to start or stop ssh service. Also move the Send an email to the bottom of the script
                     #STOPESXiSSH $ESXi
                     #STARTESXiSSH $ESXi
                     }
                     
                   
                    }
     
                    #Send an email
                    if($send){
                    SendEmail -emailFrom "compute.hosting.security.team@intel.com" -SendTo "chandrashekar.j.madalli@intel.com","compute.hosting.security.team@intel.com" -LogFile $LogFile -vc $VCName
                    }
     
                  }


#Set Send Email
Function SendEmail{
	Param(
		[parameter(Mandatory=$true)]$emailFrom,$SendTo,$LogFile,$vc
	)
    Send-MailMessage -From $emailFrom -To $SendTo -Subject "SSH Status on $vc"  -Body "Attached is the log file" -Attachments $LogFile -SmtpServer "Mail.intel.com"
    }

#STOP SSH
Function STOPESXiSSH($ESXi){

        $AllServices = Get-VMHostService -vmhost $ESXi 
        $SShService = $AllServices | Where-Object {$_.Key -eq 'TSM-SSH'}   
        if ($SShService.running -eq $true) {  
        $SShService | Stop-VMHostService -confirm:$false 
        
        }
echo "SSH Running for $ESXI :"
$SShService.Running


}
              
#START SSH
Function STARTESXiSSH($ESXi){
        
        $AllServices = Get-VMHostService -VMHost $ESXi   
        $SShService = $AllServices | Where-Object {$_.Key -eq 'TSM-SSH'}   
        if ($SShService.running -eq $false) {  
        $SShService | Start-VMHostService -confirm:$false  
     }  

echo "SSH Running for $ESXI :"
$SShService.Running
}



#Check the Date
CheckDate

#Disable Hibernate
POWERCFG /HIBERNATE OFF

#Check Status of SSH
CheckESXiSSH

#STOP SSH on ESXi
#STOPESXiSSH

#Cleanup C drive
Remove-Item C:\Users\sys_vcsadmin\AppData\Local\CrashDumps\* -recurse