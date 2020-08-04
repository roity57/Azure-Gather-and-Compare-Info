# David Roitman
# Gather Azure information via Az Powershell "Get-Az" commands v2.0 - 27/6/2020
# v2.1 - 12/7/2020 - Added call to new function to enumerate Virtual Network Gateways and Express Route Circuits and gather info, comment out if undesired.
# Written/Tested in a PowerShell 7.0.3 environment with Az Module 4.4.0 on a Windows 10 VM
# Utilised two other modules which each contain one function

#connect-azaccount


#Define the commands to run
[array]$azget="Get-AzResource","Get-AzNetworkSecurityGroup","Get-AzVirtualNetwork","Get-AzRouteTable","Get-AzPublicIpAddress","Get-AzNetworkInterface","Get-AzLoadBalancer","Get-AzNetworkWatcher","Get-AzRouteFilter"

#Enumerate the Azure Contexts available to loop through
[array]$aztenant=Get-AzContext -ListAvailable 

$cDir=Get-Location | Select-Object Path
$scriptdir=$cDir.Path

Import-Module $scriptdir"\Az-GatherInfoFuncs.ps1" -Force
Import-Module $scriptdir"\CompareFunc.ps1" -Force

#Nested Foreach executes the "Get-AzNetDetails" function for each of the commands in the azget array

foreach ($azt in $aztenant) {
  #Extract the Subscription Name
  $aztenantname=$azt.Subscription.Name
  #Ensure the current Subscription is selected
  Select-AzContext -Name $azt.Name
    
  $aztid=$azt.Tenant.Id
  $uprof= [environment]::getfolderpath("mydocuments")
  #Specify the output directory for the files
  $docdir=$uprof+"\"+$aztid+"\"+$aztenantname+"\"

  #Loop through each command
  
  foreach ($azg in $azget) {
    Get-AzNetDetails -GetAz $azg -Subscription $aztenantname
    
    #Specify the file pattern for the comparison function to run against the latest gathered information
    $cfile=$azg -Replace "Get-",""
    $cfile="*"+$cfile+".txt"
    Comp-AzData -Pattern $cfile -DocDir $docdir
  }
  

  Get-AzNetGates $aztenantname
  
}



