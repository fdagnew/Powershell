#Author: Fitsume Dagnew
#Date: July 06/2016
#Review: 1.0 - Fitsume Dagnew 

#clear and start time
clear
#clear log
Remove-Item c:\support\scripts\Automap_Log_*
$LogPath = "c:\support\scripts\"
$VCName = hostname
$LogFile = $LogPath + "Automap_Log_$VCName.txt"
$Time = Get-Date
$RunTime = "Script start on $Time."

#Set logging path and filenames for LogFile 
Function WriteLogFile{
	Param(
		[parameter(Mandatory=$true)]$Message
	)
    $Message | Out-File -FilePath $LogFile -Append 
}

WriteLogFile -Message $RunTime

#Adding PowerCli to PowerShell window
         if ((Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) -eq $null){
             Add-PSSnapin VMware.VimAutomation.Core      
            
            }

#Set No timeout for unmapping and certification
        Set-PowerCLIConfiguration -WebOperationTimeoutSeconds -1 -Scope Session -Confirm:$false -ErrorAction SilentlyContinue
        Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Scope Session -Confirm:$false -ErrorAction SilentlyContinue
        echo "----------------------------------------------------------------------------------------------------------------"
        echo "----------------------------------------------------------------------------------------------------------------"
        echo ""





#Set Send Email
Function SendEmail{
	Param(
		[parameter(Mandatory=$true)]$emailFrom,$SendTo,$LogFile,$vc
	)
    Send-MailMessage -From $emailFrom -To $SendTo -Subject "AutoMap Status $vc"  -Body "Attached is the log file" -Attachments $LogFile -SmtpServer "Mail.intel.com"
    }

#change the date to current bfore running
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
#Run script on 2nd Sunday of each month
$DayOfWeek = "Sunday"
$NumDay = 2
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

Function ConnectVC {
	    $vc = Connect-VIServer ([System.Net.Dns]::GetHostByName((hostname)).HostName)
        return $vc
        }

Function RunUnMap{
    #Get a list of Clusters
	$Clusters = Get-Cluster 
	#Clusters count 
	$percentComplete = $Clusters.Count

	
	Foreach($cluster in $clusters){
     $Targets =@()
     $Target = ""
     
     echo ""
     $listofhosts = "List of Eligible hosts to connect and perform Unmap activity for cluster:$cluster."
     WriteLogFile -Message $listofhosts
	 Write-host $listofhosts
     echo ""
     #Getting all hosts in the cluster who are not disconnected or Not Responding
     
     Foreach ($vmhost in ($cluster | Get-VMHost| ?{($_.ConnectionState -ne "Disconnected") -and ($_.ConnectionState -ne "NotResponding") -and ($_.version -eq "5.5.0")}))
     {
     $Targets += $vmhost.name
     }#Foreach
     if($Targets.count -ne 0){
     WriteLogFile -Message $Targets
	 Write-host $Targets
     $Target = $Targets[0]
     
     #Running ScriptBlock for Multithreading
     StorageUnMap $Target
     }else{
      $sMsgLineBreak = "==============================="
      WriteLogFile -Message $sMsgLineBreak
      WriteLogFile -Message "None"
	  Write-host "None"
      WriteLogFile -Message $sMsgLineBreak
     }
   }#Foreach
}

Function StorageUnmap($Target){
        
        #Check if vccenter is connected
        if($vc.IsConnected){
        echo ""
        Write-Host "Continue..."
        echo ""
        }else{
        ConnectVC
        }
		#Set esxcli to host
		#Setting ESXCLI to Host
        $esxcli = Get-EsxCli -VMHost $Target
        
		#Get list of LUN's that support delete
		$vaai = $esxcli.storage.core.device.vaai.status.get() | ?{($_.DeleteStatus -ne "unsupported") -and ($_.Device -like "naa*")} | foreach {$_.device}
		If($vaai -eq $null){
		$sMsgNoLUNS = "### There are no supported Luns ###" 
        WriteLogFile -Message $sMsgNoLUNS
	    Write-host $sMsgNoLUNS -Foregroundcolor Red
			BREAK
		}
		#Get list of All data stores
		$DataStores = Get-VMHost $Target | Get-Datastore | ?{($_.Name -notlike "*local")}
		#Find All Data stores that support unmap
		Foreach($ds in $DataStores){
			$naa = $ds.ExtensionData.info.vmfs.extent | select DiskName
			$numTotal = $vaai.count
			If($vaai -contains $naa.DiskName){
				#UnMap - Reclaim Storage
				$num++
                $sMSgTarget = "Note:" +$Target+ " - is chosen to run Unmap for cluster $cluster." 
                $sMsgDataStore = "Data Store ID:"+ $ds.Name 
                $sMsgDataStoreDevice = "Data Store Device Name:" + $naa.DiskName
                 

                Write-Host $sMSgTarget -Foregroundcolor Yellow
                Write-host $sMsgDataStore -Foregroundcolor Green
                Write-host $sMsgDataStoreDevice -Foregroundcolor Green
                WriteLogFile -Message $sMSgTarget
                writeLogFile -Message $sMsgDataStore
                writeLogFile -Message $sMsgDataStoreDevice

                Try{
				#Reclaiming Storage (default value is 200)
				$run = $esxcli.storage.vmfs.unmap(200,$ds.Name,$null)
                }catch{
                $ErrorType  = $_.Exception.GetType().FullName
                $ErrorMsg = $_.Exception.Message
                Write-Host $ErrorType 
                Write-Host $ErrorMsg
                WriteLogFile -Message  $ErrorType
                WriteLogFile -Message  $ErrorMsg
                }
                if($run) {
                $sMsgReclaimYes = "Have we reclaimed the space?" + ":" + $run
                Write-Host $sMsgReclaimYes -Foregroundcolor Green
                WriteLogFile -Message $sMsgReclaimYes
                }else{
                $sMsgReclaimNo = "Have we reclaimed the space?" + ":" + "No, it failed." 
                Write-Host $sMsgReclaimNo -Foregroundcolor Red
                WriteLogFile -Message $sMsgReclaimNo
                }
                
                
			} Else {
				#Remove Data store if DeleteStatus is not supported
				$numTotal--
			}
		}
}


#Connect to Virtual Center
$vc = ConnectVC

#Check Date
CheckDate

#Run UnMap
RunUnMap

#Send Email
SendEmail -emailFrom "fitsume.dagnew@intel.com" -SendTo "fitsume.dagnew@intel.com" -LogFile $LogFile -vc $VCName
