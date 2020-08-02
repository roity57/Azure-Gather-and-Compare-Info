# David Roitman
# Export Resource Group script v1.1 - 21/6/2020
# Written/Tested in a PowerShell 5.1.19041.1 environment with Az Module 4.4.0 on a Windows 10 VM

#connect-azaccount

#Enumerate the Azure Contexts available to loop through
[array]$azcontext=Get-AzContext -ListAvailable 

$cDir=Get-Location | Select-Object Path
$scriptdir=$cDir.Path

Import-Module $scriptdir"\Az-ExportRGFuncsAll.ps1" -Force
Import-Module $scriptdir"\CompareFunc.ps1" -Force

#Foreach executes loops through each Subscription present

foreach ($azc in $azcontext) {
  $azcontextname=$azc.Subscription.Name
  $azcc=Select-AzContext -Name $azc.Name
       
  Export-AzResourceGroupsAll -Subscription $azcontextname
    
}



