# David Roitman
# Export Resource Group script v1.1 - 21/6/2020
# Tested in PowerShells 5.x & 7.x environments with Az Module 4.x & 6.x on a Windows VM
# This Export function will raise warnings about limitations in the content of the Resource template that it exports and exporting resources have some maximum limitations
# Azure has limits for Resource Group exports – https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/azure-subscription-service-limits#resource-group-limits. 
# The Export Resource Group function will fail on a resource group with more than 200 resources

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



