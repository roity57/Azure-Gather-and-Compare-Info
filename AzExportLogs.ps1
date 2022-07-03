# David Roitman
# Export Azure Log Data script v1.0 - 3/7/2022
# Export Log data by Resource Group as desired - You must specify the desired Resource Groups before running, results will be written to local folder.
# This scripte looks for Delete and Create or Modify type operations in the log, you can customise this as you desire.
# Tested in PowerShells 7.2.5 environment with Az Module 8.0.0 on a Windows VM
# Merging Power Shell Object: https://www.reddit.com/r/PowerShell/comments/62gcdn/combining_two_ps_object_values/

$date=get-date -Format "ddMMyyyy"
$time=get-date -Format "HHmm"
$cdate=$date+"-"+$time

#Set Time period to desired number of days back from today
$tperiod=-7

$rgdateend=get-date -Format "yyyy-MM-dd"
$rgdatestart=(Get-Date).adddays($tperiod)# -Format "yyyy-MM-dd"
  
#specify Resource Group Names
#$rga="rg1","rg2"

foreach ($rg in $rga) {
    write-host "Retreiving Logs for Resource Group" $rg
    #write-host "Operation Name, Caller, Submission Timestamp, Event Timestamp, Status, Category, Resource ProviderName, Resource Group Name, Resource Name, User Name, IP Address"
    $tfile=$cdate+"-"+$rg+".csv"
    
    #Get-AzLog is used against the specified resource group name between set dates, only specific objects are selected with some manipulation required to get the end resource.
    $azlogs=Get-AzLog -ResourceGroupName $rg -StartTime $rgdatestart -EndTime $rgdateend | select OperationName, Caller, SubmissionTimeStamp, EventTimeStamp, Status, Category, ResourceProviderName, ResourceGroupName, @{Name="ResourceName";Expression = {$_.ResourceId.tostring().substring($_.ResourceId.tostring().lastindexof('/')+1)}}, Claims | where-object {($_.OperationName -like "*del*") -or ($_.OperationName -like "*create*")}
    
    #As the Claims object contains an entire set of data within the field, it's processed so that the User Name and IP Address are extracted for each Log Entry.  Then the remaining contect of log data is extracted and both sets of values are merged back together.
    foreach ($log in $azlogs) {
      $user=$log.Claims.Content | select @{Name="Name";Expression = {$_.name.tostring().substring($_.name.tostring().lastindexof(':')+1)}}, @{Name="IP";Expression = {$_.ipaddr.tostring().substring($_.ipaddr.tostring().lastindexof('/')+1)}}
      $logd=$log | select OperationName, Caller, SubmissionTimeStamp, EventTimeStamp, Status, Category, ResourceProviderName, ResourceGroupName, ResourceName, Name, IP
      
      foreach ($property in $user.psobject.Properties) {
        foreach ($array in $user.$($property.Name)) {
                $logd.$($property.Name) += $array
        }
      #Uncomment if you desire to see data output to screen.
      #write-host $logd.OperationName, $logd.Caller, $logd.SubmissionTimestamp, $logd.EventTimestamp, $logd.Status, $logd.Category, $logd.ResourceProviderName, $logd.ResourceGroupName, $logd.ResourceName, $logd.Name, $logd.IP
      #Output the data in CSV to the local folder in unique file name.
      $logd | export-csv -path $tfile -Append
      }
    }
 
}
