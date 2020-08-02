# David Roitman
# Gather Effective Route Tables for NICs v1.0 - 1/7/2020
# v1.1 - 26/7/2020 Enumerated subnet NIC is attached to as well and recording in output file, alter subfolder output, build in comparison. (switched to Az Module 4.1.0)
# v1.2 - 26/7/2020 Added enumeration of Effective Network Security Groups
# v1.3 - 2/8/2020 Altered output to Format-Table (to make file comparison function more accurate) with custom processing for single destination routes vs multi prefix destination routes and updated Effective NSG capture process.
# This is designed to be run within a manually selected subscription of your choice
# Written/Tested in a PowerShell 5.1.19041.1 environment with Az Module 4.4.0 on a Windows 10 VM using Australian Date/time format
# Utilised one other module which contains one function

#connect-azaccount

#Remove default format enumeration limit.  User defined routes can contain "numerous" routes that PowerShell will by default truncate to the first 4 routes.
$FormatEnumerationLimit=-1

$cDir=Get-Location | Select-Object Path
$scriptdir=$cDir.Path

Import-Module $scriptdir"\CompareFunc.ps1" -Force

$uprof= [environment]::getfolderpath("mydocuments")

$date=get-date -Format "ddMMyyyy"
$time=get-date -Format "HHmm"
$cdate=$date+"-"+$time

$azt=Get-AzContext | Select-Object Tenant, Subscription
$aztid=$azt.Tenant.Id
$Subscription=$azt.Subscription.Name

#Define final output folder
$outfilestore=$uprof+"\"+$aztid+"\"+$Subscription+"\NIC Effective Details\"

write-host "Enumerating Network Interfaces within Subscription" $Subscription
[array]$aznics=Get-AzNetworkInterface | Select-Object Name, ResourceGroupName

#Initialise arrays to fill with settings to specify filename formats and compare function pattern match parameter.
$azniclim=$aznics.Count
[array]$tfile=@(1..$azniclim)
[array]$cfile=@(1..$azniclim)
[array]$nsgtfile=@(1..$azniclim)
[array]$nsgcfile=@(1..$azniclim)
$tfilenum=0

#Check to see if any Network interfaces found and if so, validate output directory exists and if not create it.
If($aznics.Length -gt 0)
    {
    If(!(test-path $outfilestore))
      {
        New-Item -ItemType Directory -Force -Path $outfilestore | Out-Null
      }
    }
  else
    {
      Write-Host "Subscription:" $Subscription "did not contain any Network Interfaces"
    }

#If Network Interfaces exist then proceed to fill the arrays with output file format and compare function match parameter
foreach ($azvmnic in $aznics) {
  [array]$tfile[$tfilenum]=$cdate+"-"+$aznics[$tfilenum].Name+".txt"
  [array]$nsgtfile[$tfilenum]=$cdate+"-"+$aznics[$tfilenum].Name+"-NSG.txt"
  [array]$cfile[$tfilenum]=$aznics[$tfilenum].Name+".txt"
  [array]$nsgcfile[$tfilenum]=$aznics[$tfilenum].Name+"-NSG.txt"
  
  $tfilenum++
  }


$tfilenum=0

#If Network Interfaces exist then proceed to get effective route tables and output to file.  This involves determining the VM the NIC is attached to and validating the VM is actually running.
foreach ($azvmnic in $aznics) {
 
  $tfileo=$outfilestore+$tfile[$tfilenum]
  $nsgtfileo=$outfilestore+$nsgtfile[$tfilenum]
  
  #Determine which VM the NIC is attached to
  write-host "Enumerating NIC VM owner for" $azvmnic.Name
  $vm=Get-AzNetworkInterface -Name $azvmnic.Name | Select @{Name="VMName";Expression = {$_.VirtualMachine.Id.tostring().substring($_.VirtualMachine.Id.tostring().lastindexof('/')+1)}},@{Name="VMSubNet";Expression = {$_.ipConfigurations.Subnet.Id.tostring().substring($_.ipConfigurations.Subnet.Id.tostring().lastindexof('/')+1)}},NetworkSecurityGroup
  
  write-host "Checking Running State of" $vm.VMName
  #Check the Running state of the VM
  $vmstate=Get-AzVM -Name $vm.VMName -Status | Select-Object -ExpandProperty PowerState
  
  #If the VM is powered on, attempt Effective Route Table fetch
  if ($vmstate -eq "VM running") {
    write-host "Fetching Routes for: " $azvmnic.Name "that is attached to" $vm.VMName "on subnet" $vm.VMSubnet
    write-host "Output saving to   : " $tfileo
    $rfheader="Routes for: "+$azvmnic.Name+" that is attached to "+$vm.VMName+" on subnet "+$vm.VMSubnet
    $nsgfheader="Effective Network Security Groups for: "+$azvmnic.Name+" that is attached to "+$vm.VMName+" on subnet "+$vm.VMSubnet
    write $rfheader | Out-File -FilePath $tfileo 
    
    #Populate Array with effective route table, for further manipulation later.  This is primarily used so that destination prefix numbers can be counted.
    [array]$ert=Get-AzEffectiveRouteTable -NetworkInterfaceName $azvmnic.Name -ResourceGroupName $azvmnic.ResourceGroupName
    
    #Process each effective route and where there is just one destination prefix then it gets added to an array to be written to file, this effectively filters out routes that have more than one destination prefix.
    foreach ($er in $ert) {
      if ($er.AddressPrefix.count -eq 1) {
        [array]$sdarray+=$er
      }
    }
    $sdarray | Format-Table | out-file -Append $tfileo
    Clear-Variable sdarray
    Clear-Variable er
    
    #Process each effective route and where there is more than one destination prefix the full list of IPs is extracted and recorded.
    foreach ($er in $ert) {
      if ($er.AddressPrefix.count -gt 1) {
        Write "Multiple Destination Prefix Route" | out-file -Append $tfileo
        [array]$mdarray+=$er | Select-Object Name, DisableBgpRoutePropagation, State, Source, NextHopType, NextHopIPAddress
        $mdarray | Format-Table | out-file -Append $tfileo
        write "Destination Address Prefixes: " | out-file -Append $tfileo
        $er.AddressPrefix | out-file -Append $tfileo
        write "`n`r" | out-file -Append $tfileo
        Clear-Variable mdarray
        }
      }
      
  
    #Specify the file pattern for the comparison function to run against the latest gathered information
    $pattern="*"+$cfile[$tfilenum]
    Comp-AzData -Pattern $pattern -DocDir $outfilestore

    #Enumerate Effective Network Security Groups.  This will attempt to gather effective rules even if there is no NSG directly attached as there could be inherited NSGs from the subnet.
    write-host "Fetching NSG for   : " $azvmnic.Name "that is attached to" $vm.VMName "on subnet" $vm.VMSubnet "if NSG associated"
    $ensg=Get-AzEffectiveNetworkSecurityGroup -NetworkInterfaceName $azvmnic.Name -ResourceGroupName $azvmnic.ResourceGroupName 
    if ($ensg.length -gt 0) {
      write-host "Output saving to   : " $nsgtfileo
      write $nsgfheader | Out-File -FilePath $nsgtfileo 
      $ensg | Out-File -Append $nsgtfileo
      #Specify the file pattern for the comparison function to run against the latest gathered information
      $pattern="*"+$nsgcfile[$tfilenum]
      Comp-AzData -Pattern $pattern -DocDir $outfilestore
    }
  }
  $tfilenum++
}
  
 