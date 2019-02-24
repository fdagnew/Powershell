
#####################################################
#                                                   #
# File:           VCDMaintenace.ps1		    #
# Version:        1.0	                            #
#                                                   #
# Copyright (C) 2016 Intel Corporation              #
# Authors:        Fitsume Dagnew                    #
#						    #
#####################################################
<# Change Log
1.0 Released
<#
	.Description
		This script maintains the virtual center database
	.Synopsis
		Used to do increase performance and storage. It will also avoid most of our vceneter incidents
	.Example
		VCDMaintenace.ps1	
	.Notes
		Author: Fitsume Dagnew
		Date: July 07, 2016
		Version: 1.0
#>


#To run as Admin
#C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe Start-Process powershell -Verb runAs C:\Support\scripts\VCDMaintenace.ps1

#clear and start time
clear
Remove-Item c:\support\scripts\VCDMaintenace_Log_*
$LogPath = "c:\support\scripts\"
$VCName = hostname
$LogFile = $LogPath + "VCDMaintenace_Log_$VCName.txt"
$Time = Get-Date
$RunTime = "Script start on $Time."
$MsgLine = "---------------------------------------------"
$MsgLineDay = "=========================================="

#Set logging path and filenames for LogFile 
Function WriteLogFile{
	Param(
		[parameter(Mandatory=$true)]$Message
	)
    $Message | Out-File -FilePath $LogFile -Append 
}
WriteLogFile -Message $MsgLineDay
WriteLogFile -Message $RunTime
WriteLogFile -Message $MsgLineDay

#Adding PowerCli to PowerShell window and load SQL snap-in
         if ((Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) -eq $null){
             
             Add-PSSnapin VMware.VimAutomation.Core      
             
             Add-PSSnapin *SQL*
             
             #Set No timeout for unmapping and certification
             Set-PowerCLIConfiguration -WebOperationTimeoutSeconds -1 -Scope Session -Confirm:$false 
             Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Scope Session -Confirm:$false 
             echo "----------------------------------------------------------------------------------------------------------------"
             echo "----------------------------------------------------------------------------------------------------------------"
             echo ""
            }



#Set Send Email
Function SendEmail{
	Param(
		[parameter(Mandatory=$true)]$emailFrom,$SendTo,$LogFile,$vc
	)
    Send-MailMessage -From $emailFrom -To $SendTo -Subject "Virtual Center Database Maintenance Status for $vc"  -Body "Attached is the log file" -Attachments $LogFile -SmtpServer "Mail.intel.com"
    }

#Maintenance Email to GSM and the team
Function SendMaintEmail{
	Param(
		[parameter(Mandatory=$true)]$emailFrom,$SendTo,$vc, $status
	)
    Send-MailMessage -From $emailFrom -To $SendTo -Subject "Virtual Center Database Maintenance for $vc : $status <EOM>"   -SmtpServer "Mail.intel.com"
    }


#check the date and send downtime a week from now
Function CheckDateForAdvanceNotice{
#Date information for when to run script
$Date = Get-Date
$Day = $Date.DayOfWeek
$month =$Date.Month

$First = Get-Date $date -day 1
$Last = (($first).AddMonths(1).AddDays(-1))
#Run script between 00:00 and 08:00
$TimeWindowStart = 0
$TimeWindow = 23
$TimeWindowStop = ($TimeWindowStart+$TimeWindow)
$tmpDate = $First
#Run script on 3rd Sunday of each month
$DayOfWeek = "Sunday"
$NumDay = 3
$i = 0
DO{
	#If($tmpDate.DayOfWeek -eq $DayofWeek -and ($month -eq 3 -or $month -eq 6 -or  $month -eq 9 -or  $month -eq 12)){
        If($tmpDate.DayOfWeek -eq $DayofWeek -and  ($month -eq 9)){
		$i++
		If($i -eq $NumDay){
			If($tmpDate -eq $date){
				$DayOfWeekWindow = "true"
                 SendMaintEmail -emailFrom "dch.compute.hosting.services.operations@intel.com" -SendTo "dch.compute.hosting.services.operations@intel.com", "gsm.apps@intel.com","toinette.perez.trevino@intel.com","chad.sharp@intel.com","open.cloud.support@intel.com","it.opencloud.team@intel.com","emc.gsm.infrapps@intel.com","SR.Hub.INFRA@intel.com","VM.provisioning@intel.com","managed.hosting.teams@intel.com"  -vc $VCName -status "A week from now(on Sunday), we will have our quarterly downtime for vcenter maintenance."
			# Send an email to all stakeholders a week in advance notice for scheduled maintenace
            # Include Perez Trevino, Toinette <toinette.perez.trevino@intel.com>, Sharp, Chad <chad.sharp@intel.com>, DCH Compute Hosting Services Operations <dch.compute.hosting.services.operations@intel.com>
            #,DCH Compute Hosting Services Operations <dch.compute.hosting.services.operations@intel.com>; Open Cloud Support <open.cloud.support@intel.com>; IT OpenCloud Team <it.opencloud.team@intel.com>; 
            # EMC GSM INFRAPPS <emc.gsm.infrapps@intel.com>; SR Hub INFRA <SR.Hub.INFRA@intel.com>; VM provisioning <VM.provisioning@intel.com>; GSM INFRA <GSMINFRA@intel.com>, Managed Hosting Teams <managed.hosting.teams@intel.com> 

            }
		}
	}
	$tmpDate = $tmpDate.AddDays(1)
} Until ($tmpDate.Day -eq $last.Day)


}
     
#check the date to current before running
Function CheckDate{
#Date information for when to run script
$Date = Get-Date
$Day = $Date.DayOfWeek
$month =$Date.Month
$First = Get-Date $date -day 1
$Last = (($first).AddMonths(1).AddDays(-1))
#Run script between 00:00 and 08:00
$TimeWindowStart = 0
$TimeWindow = 23
$TimeWindowStop = ($TimeWindowStart+$TimeWindow)
$tmpDate = $First
#Run script on 4th Sunday of each month
$DayOfWeek = "Sunday"
$NumDay = 4
$i = 0
DO{
	#If($tmpDate.DayOfWeek -eq $DayofWeek -and ($month -eq 3 -or $month -eq 6 -or $month -eq 9 -or $month -eq 12)){
        If($tmpDate.DayOfWeek -eq $DayofWeek -and ($month -eq 9)){
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
$sMsg = "Today is the right day to do maintenance, Continue..." 
Write-Host $sMsg -Foregroundcolor Green 
WriteLogFile -Message "#############################################"
Write-Host "#############################################"
WriteLogFile -Message $sMsg
Write-Host "#############################################"
WriteLogFile -Message "#############################################"
	
}Else{
EXIT
}

}

Function ConnectVC {
	    $vc = Connect-VIServer ([System.Net.Dns]::GetHostByName((hostname)).HostName)
        Write-Host "#############################################"
        WriteLogFile -Message "#############################################"
        WriteLogFile -Message $vc
        Write-Host "#############################################"
        WriteLogFile -Message "#############################################"
        return $vc
        }

# Get VCCENTER DATATABASE server for Current VCCENTER appliance server
Function GetVCD{

         #Selects VC Database Server
    Switch ($VCName){
	                 FMS07VCAIGBN001{$VCD = "FMS07VCDIGBN001\VCS"}
	                 FMS01VCAIGBN001{$VCD = "FMS01VCDIGBN001\VCS"}
	                 FMS01VCAIGBN003{$VCD = "FMS01VCDIGBN003\VCS"}
	                 AZSVC001       {$VCD = "AZSVC002\VCS"}
	                 CRS03VCAGPB0001{$VCD = "CRS03VCDGPB0001\VCS"}
	                 EGS02VCAIGBN002{$VCD = "EGS02VCDIGBN002\VCS"}
	                 SHZS01VCAGPB001{$VCD = "SHZS01VCDGPB001\VCS"}
	                 SRRS01VCAGPB001{$VCD = "SRRS01VCDGPB001\VCS"}
	                 PGS12VCAGPB001 {$VCD = "PGS12VCDGPB001\VCS"}
	                 LCS12VCAIGBN001{$VCD = "LCS12VCDIGBN001\VCS"}
	                 IRS05VCAGPB0001{$VCD = "IRS05VCDGPB0001\VCS"}
	                 RRS07VCAIGBN001{$VCD = "RRS07VCDIGBN001\VCS"}
                         FMS07VCALAB002 {$VCD = "FMS07VCDLAB002\VCS"}
                         FMS01VCAHTZ001 {$VCD = "FMS01VCDHTZ001\VCS"}
                         AZS02VCAHTZ001 {$VCD = "AZS02VCDHTZ001\VCS"}
                         PGS12VCACBS002 {$VCD = "PGS12VCDCBS002\VCS"}
                         IRS01VCACBS001 {$VCD = "IRS01VCDCBS001\VCS"}
                         EGS02VCACBS001 {$VCD = "EGS02VCDCBS001\VCS"}
                         FMS07VCAHTZ002 {$VCD = "FMS07VCDHTZ002\VCS"}
                         FMS07VCAMGMT001{$VCD = "FMS07VCDMGMT001\VCS"}
                         HFS02VCACAS001 {$VCD = "HFS02VCDCAS001\VCS"}
                         FMS01VCACBS001 {$VCD = "FMS01VCDCBS001\VCS"}
                         FMS07VCACBS002 {$VCD = "FMS07VCDCBS002\VCS"}
                         FMS01VCACAS002 {$VCD = "FMS01VCDCAS002\VCENTER"}
                         FMS7DCUDLIB01  {$VCD = "FMS7DCUDLIB01\VCS"}
                         VMS01VCAHTZ003 {$VCD = "VMS01VCDHTZ003\VCS"}
                         VMS07VCAHTZ003 {$VCD = "VMS07VCDHTZ003\VCS"}
                         FMS07VCAOCE002 {$VCD = "FMS07VCDOCE002\VCENTER"}
                         FMS07VCAOCE002 {$VCD = "FMS07VCDOCE002\VCENTER"}
                         EGS02VCAIGBN001 {$VCD = "EGS02VCDIGBN001\VCS"}
                    }#End Switch
                    Write-Host "#############################################"
                    WriteLogFile -Message "#############################################"
                    WriteLogFile -Message "We are going to use server $VCD as our database server!!!"
                    Write-Host "#############################################"
                    WriteLogFile -Message "#############################################"
  return $VCD
}


# Check the log and data file sizes before maintenance
Function checkfileSizeBeforeMaint{
	Param(
		[parameter(Mandatory=$true)]
			$VCD
		)
    $ServerInstance = $VCD
    $Database = "master"
    $ConnectionTimeout = 30
    $Query = "DECLARE @DBNAME VARCHAR(255)
              SELECT @DBNAME = name FROM master.dbo.sysdatabases where name Like 'vc%'
              SELECT DB_NAME(database_id) AS DBName,Name AS Logical_Name, Physical_Name,(size*8)/1024 Size_MB
              FROM sys.master_files
              WHERE DB_NAME(database_id) =  @DBNAME

	         "
    $QueryTimeout = 120

    $conn=new-object System.Data.SqlClient.SQLConnection
    $ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $ServerInstance,    $Database,$ConnectionTimeout
    $conn.ConnectionString=$ConnectionString
    $conn.Open()
    $cmd=new-object system.Data.SqlClient.SqlCommand($Query,$conn)
    $cmd.CommandTimeout=$QueryTimeout
    $ds=New-Object system.Data.DataSet
    $da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
    
    [void]$da.fill($ds)
   
    $conn.Close()
    Write-Host "#############################################"
    WriteLogFile -Message "#############################################"
    WriteLogFile -Message "The size of MDF and LDF files before Maintenance..."
    WriteLogFile -Message $ds.Tables
    Write-Host "#############################################"
    WriteLogFile -Message "#############################################"

    return $ds.Tables
 
	
   }

   # Check the log and data file sizes before maintenance
Function checkfileSizeAfterMaint{
	Param(
		[parameter(Mandatory=$true)]
			$VCD
		)
    $ServerInstance = $VCD
    $Database = "master"
    $ConnectionTimeout = 30
    $Query = "DECLARE @DBNAME VARCHAR(255)
              SELECT @DBNAME = name FROM master.dbo.sysdatabases where name Like 'vc%'
              SELECT DB_NAME(database_id) AS DBName,Name AS Logical_Name, Physical_Name,(size*8)/1024 Size_MB
              FROM sys.master_files
              WHERE DB_NAME(database_id) =  @DBNAME

	         "
    $QueryTimeout = 120

    $conn=new-object System.Data.SqlClient.SQLConnection
    $ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $ServerInstance,    $Database,$ConnectionTimeout
    $conn.ConnectionString=$ConnectionString
    $conn.Open()
    $cmd=new-object system.Data.SqlClient.SqlCommand($Query,$conn)
    $cmd.CommandTimeout=$QueryTimeout
    $ds=New-Object system.Data.DataSet
    $da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
    
    [void]$da.fill($ds)
   
    $conn.Close()
    Write-Host "#############################################"
    WriteLogFile -Message "#############################################"
    WriteLogFile -Message "The size of MDF and LDF files after Maintenance..."
    WriteLogFile -Message $ds.Tables
    Write-Host "#############################################"
    WriteLogFile -Message "#############################################"

    return $ds.Tables
 
	
   }


# Check if we have recent VCCENTER DATABASE backup
Function isFullbackup{
	Param(
		[parameter(Mandatory=$true)]
			$VCD
		)
    $ServerInstance = $VCD
    $Database = "master"
    $ConnectionTimeout = 30
    $Query = "DECLARE @job_id binary(16); 
              SELECT @job_id = job_id FROM msdb.dbo.sysjobs WHERE (name = N'User_DB_Backup.Subplan_1');
              SELECT TOP 1
              *
              FROM
                  msdb..sysjobhistory sjh
              WHERE
                  sjh.step_id = 0 
                  AND sjh.run_status = 1 
                  AND sjh.job_id = @job_id
	              --AND run_date > (SELECT convert(varchar, getdate(), 112) -1) 
                  AND run_date >= (SELECT convert(varchar, getdate(), 112)) 
                  --ORDER BY
                  --run_datetime DESC
	         "
    $QueryTimeout = 120

    $conn=new-object System.Data.SqlClient.SQLConnection
    $ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $ServerInstance,    $Database,$ConnectionTimeout
    $conn.ConnectionString=$ConnectionString
    $conn.Open()
    $cmd=new-object system.Data.SqlClient.SqlCommand($Query,$conn)
    $cmd.CommandTimeout=$QueryTimeout
    $ds=New-Object system.Data.DataSet
    $da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
    
    [void]$da.fill($ds)
   
    $conn.Close()
    #runstatus is row 7
    
    return $ds.Tables[0].Rows[0][7]
 
	
   }


# Take the current backup

Function takeFullbackup{
	Param(
		[parameter(Mandatory=$true)]
			$VCD
		)
    $ServerInstance = $VCD
    $Database = "master"
    $ConnectionTimeout = 30
    $Query = "EXEC msdb.dbo.sp_start_job N'User_DB_Backup.Subplan_1';
              DECLARE @status VARCHAR(250) 
              SET @status = 'still taking backup...'

              WHILE EXISTS (
	                        SELECT
                                  job.Name
	                              --, job.job_ID
                                  --,job.Originating_Server
                                  --,activity.run_requested_Date
                                  --,datediff(minute, activity.run_requested_Date, getdate()) AS Elapsed
                            FROM
                                msdb.dbo.sysjobs_view job 
                                INNER JOIN msdb.dbo.sysjobactivity activity
                                ON (job.job_id = activity.job_id)
                            WHERE
                                 run_Requested_date is not null 
                                 AND stop_execution_date is null
                                 AND job.name like 'User_DB_Backup.Subplan_1'
                         )
             BEGIN
                  --wait one second
                  WAITFOR DELAY '00:00:01'
                  select @status AS STATUS
              END 
	       "
    $QueryTimeout = 120

    $conn=new-object System.Data.SqlClient.SQLConnection
    $ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $ServerInstance,    $Database,$ConnectionTimeout
    $conn.ConnectionString=$ConnectionString
    $conn.Open()
    $cmd=new-object system.Data.SqlClient.SqlCommand($Query,$conn)
    $cmd.CommandTimeout=$QueryTimeout
    $ds=New-Object system.Data.DataSet
    $da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
    [void]$da.fill($ds)
       
    $conn.Close()
   
    $ds.Tables 
           
 }


 #START services
function checkANDstartServices{
 $vctomcatService = Get-Service -Name vctomcat
 $vpxdService = Get-Service -Name vpxd
 
 if (($vctomcatService.Status -ne "Running") -OR ($vpxdService.Status -ne "Running") ){
 
    $services= @() 
    $services += (Get-Service -Name vpxd).Name
    ## Add the dependencies to the variable.
    (Get-Service -Name vpxd).DependentServices | ForEach-Object {
        $services += $_.Name
    }
    
    ## We need to start the services in reverse order 
    $services | Sort-Object -Descending | ForEach-Object {
        Write-Host Starting $_
        Get-Service $_ | Start-Service
        sleep 5
    }

 $serviceMsg = "Starting VMware VirtualCenter Management Webservices (vctomcat) and VMware VirtualCenter Server (vpxd) services..." 
 Write-Host "#############################################"
 WriteLogFile -Message "#############################################"
 Write-Host $MsgLine -Foregroundcolor DarkYellow
 Write-Host $serviceMsg -Foregroundcolor Green 
 WriteLogFile -Message $MsgLine
 WriteLogFile -Message $serviceMsg
 Write-Host "#############################################"
 WriteLogFile -Message "#############################################"

 
 }
 if (($vctomcatService.Status -eq "running") -AND ($vpxdService.Status -eq "running")){ 
 
 $serviceMsg = "VMware VirtualCenter Management Webservices (vctomcat) and VMware VirtualCenter Server (vpxd) services are already started."
 Write-Host $MsgLine -Foregroundcolor DarkYellow
 Write-Host $serviceMsg -Foregroundcolor Green 
 WriteLogFile -Message $MsgLine
 WriteLogFile -Message $serviceMsg
 
 }
 }

#STOP services
function checkANDstopServices{
 $vctomcatService = Get-Service -Name vctomcat
 $vpxdService = Get-Service -Name vpxd
 
 if (($vctomcatService.Status -ne "Stopped") -OR ($vpxdService.Status -ne "Stopped") ){
 
    $services= @() 
    $services += (Get-Service -Name vpxd).Name
    ## Add the dependencies to the variable.
    (Get-Service -Name vpxd).DependentServices | ForEach-Object {
        $services += $_.Name
    }
    ## First put the services in the correct order and then stop them 
    $services | Sort-Object | ForEach-Object {
        Write-Host Stopping $_
        ## -Force was used because the services have dependencies - even though they are stopped
        Get-Service $_ | Stop-Service -Force
        sleep 5
    }
 
 $serviceMsg = "Stopping VMware VirtualCenter Management Webservices (vctomcat) and VMware VirtualCenter Server (vpxd) services..." 
 Write-Host "#############################################"
 WriteLogFile -Message "#############################################"  
 Write-Host $MsgLine -Foregroundcolor DarkYellow
 Write-Host $serviceMsg -Foregroundcolor Green 
 WriteLogFile -Message $MsgLine
 WriteLogFile -Message $serviceMsg
 Write-Host "#############################################"
 WriteLogFile -Message "#############################################"
 
 }
 if (($vctomcatService.Status -eq "Stopped") -AND ($vpxdService.Status -eq "Stopped")){ 
 
 $serviceMsg = "VMware VirtualCenter Management Webservices (vctomcat) and VMware VirtualCenter Server (vpxd) services are already stopped."
 Write-Host "#############################################"
 WriteLogFile -Message "#############################################"
 Write-Host $MsgLine -Foregroundcolor DarkYellow
 Write-Host $serviceMsg -Foregroundcolor Green 
 WriteLogFile -Message $MsgLine
 WriteLogFile -Message $serviceMsg
 Write-Host "#############################################"
 WriteLogFile -Message "#############################################"
 }
 }
 
 
#Run maintenance script
function runMaintenace{

Param(
		[parameter(Mandatory=$true)]
			$VCD
		)
    $ServerInstance = $VCD
    $Database = "master"
    $ConnectionTimeout = 30
    $Query = " EXEC [dbo].[MaintVcenterDatabase]
	       "
    $QueryTimeout = 120

    $conn=new-object System.Data.SqlClient.SQLConnection
    $ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $ServerInstance,    $Database,$ConnectionTimeout
    $conn.ConnectionString=$ConnectionString
    $conn.Open()
    $cmd=new-object system.Data.SqlClient.SqlCommand($Query,$conn)
    $cmd.CommandTimeout=$QueryTimeout
    $ds=New-Object system.Data.DataSet
    $da=New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
    #[void]$da.fill($ds)
          
    $conn.Close()
    
    Write-Host "#############################################"
    WriteLogFile -Message "#############################################"
    WriteLogFile -Message "*********************************************"
    WriteLogFile -Message "We are running a maintenance on database now..."
    WriteLogFile -Message "*********************************************"
    Write-Host "#############################################"
    WriteLogFile -Message "#############################################"
    #$ds.Tables 
           
 }




 





#********************************Execution******************************************

#Connect to VC
ConnectVC

#send a week notice
CheckDateForAdvanceNotice

#Check Date
CheckDate


#Send an email to GSM and the team before starting maintenance
SendMaintEmail -emailFrom "dch.compute.hosting.services.operations@intel.com" -SendTo "dch.compute.hosting.services.operations@intel.com", "gsm.apps@intel.com","toinette.perez.trevino@intel.com","chad.sharp@intel.com","open.cloud.support@intel.com","it.opencloud.team@intel.com","emc.gsm.infrapps@intel.com","SR.Hub.INFRA@intel.com","VM.provisioning@intel.com","managed.hosting.teams@intel.com"  -vc $VCName -status "Started"


#Get VCD 
$VCD = GetVCD

#Check the mdf and ldf file sizes before maintenace
checkfileSizeBeforeMaint $VCD
 
#Stop services before taking backup
checkANDstopServices
    
#Take full backup
takeFullbackup  $VCD

#Check recent fullbackup
if(isFullBackup $VCD){
Write-Host "#############################################"
WriteLogFile -Message "#############################################"
$sMsg = "Recent full backup in place.Backout Plan is validated ...Continue"
Write-Host $MsgLine -Foregroundcolor DarkYellow
Write-Host $sMsg -Foregroundcolor Green 

WriteLogFile -Message $MsgLine
WriteLogFile -Message $sMsg 
Write-Host "#############################################"
WriteLogFile -Message "#############################################"
}else{
Write-Host "EXIT NO RECENT BACKUP########################################"
WriteLogFile -Message "EXIT NO RECENT BACKUP###################################"
checkANDstartServices 
SendMaintEmail -emailFrom "dch.compute.hosting.services.operations@intel.com" -SendTo "dch.compute.hosting.services.operations@intel.com", "gsm.apps@intel.com","toinette.perez.trevino@intel.com","chad.sharp@intel.com","open.cloud.support@intel.com","it.opencloud.team@intel.com","emc.gsm.infrapps@intel.com","SR.Hub.INFRA@intel.com","VM.provisioning@intel.com","managed.hosting.teams@intel.com"  -vc $VCName -status "Completed. Please resume monitoring."
exit
}

#Run Maintenace script on The VCD server
runMaintenace $VCD

# Start Services before sending an email
checkANDstartServices 

#Check the mdf and ldf file sizes before maintenace
checkfileSizeAfterMaint $VCD

#Send a log Email to the Admin
SendEmail -emailFrom "fitsume.dagnew@intel.com" -SendTo "fitsume.dagnew@intel.com","adilia.rodriguez@intel.com" -LogFile $LogFile -vc $VCName

#Send an email to GSM and the team after completing maintenance
SendMaintEmail -emailFrom "dch.compute.hosting.services.operations@intel.com" -SendTo "dch.compute.hosting.services.operations@intel.com", "gsm.apps@intel.com","toinette.perez.trevino@intel.com","chad.sharp@intel.com","open.cloud.support@intel.com","it.opencloud.team@intel.com","emc.gsm.infrapps@intel.com","SR.Hub.INFRA@intel.com","VM.provisioning@intel.com","managed.hosting.teams@intel.com"  -vc $VCName -status "Completed. Please resume monitoring."
