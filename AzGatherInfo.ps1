# David Roitman
# Gather Azure information via Az Powershell "Get-Az" commands v2.0 - 27/6/2020
# v2.1 - 12/7/2020 - Added call to new function to enumerate Virtual Network Gateways and Express Route Circuits and gather info, comment out if undesired.
# v2.2 - 19/9/2021 - Added call to new function to fetch DNS zones and record details, comment out if undesired. Also added Application Gateway Get command to array.
# v2.3 - 2/10/2021 - Added Get-AzApiManagement to the array
# v2.4 - 2/7/2022 - Added call to new function to report specific Virtual Network and Subnet details
# Tested in PowerShells 5.x & 7.x environments with Az Module 4.x, 6.x & 8.0.0 on a Windows VM - NOT Regression tested against all available versions.
# Utilised two other modules which each contain one function

#connect-azaccount


#Define the commands to run
[array]$azget="Get-AzResource","Get-AzNetworkSecurityGroup","Get-AzVirtualNetwork","Get-AzRouteTable","Get-AzPublicIpAddress","Get-AzNetworkInterface","Get-AzLoadBalancer","Get-AzNetworkWatcher","Get-AzRouteFilter","Get-AzApplicationGateway","Get-AzApiManagement"



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
  Get-AzDNSDetails $aztenantname
  Get-AzVirtNetDets $aztenantname
  
}



