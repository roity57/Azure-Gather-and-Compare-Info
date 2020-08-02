# David Roitman
# Az-ExportRGFuncsAll.ps1
# v1.1 - 21/6/2020
# v1.2 - 2/8/2020 Updated enumeration of user documents (tested in Az 4.4.0)
# Written in a PowerShell 5.1.19041.1 environment with Az Module 4.4.0 on a Windows 10 VM using Australian Date/time format
# Utilises Get-AzResourceGroup & Get-AzContext functions to determine file output path and name
# Utilises Export-AzResourceGroup 
# DOES NOT contain any error control for file system issues (failure to create directories/files).
# Azure has limits for Resource Group exports - https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/azure-subscription-service-limits#resource-group-limits
# The Export Resource Group function will fail on a resource group with more than 200 resources

function Export-AzResourceGroupsAll
{

  param (
    [string]$Subscription
    )
  
  #Put together Date & time for filename format  
  $date=get-date -Format "ddMMyyyy"
  $time=get-date -Format "HHmm"
  $cdate=$date+"-"+$time
  
  $azrg=Get-AzResourceGroup | select ResourceGroupName
  $aztn=Get-AzContext | Select-Object Tenant
  $aztid=$aztn.Tenant.Id

  #Get user profile details to piece together profile path
  $uprof= [environment]::getfolderpath("mydocuments")
  
  #Define final output folder
  $outfilestore=$uprof+"\"+$aztid+"\"+$Subscription+"\"
  
  #Check for output directory existance and if not present, create it.
  If(!(test-path $outfilestore))
    {
      New-Item -ItemType Directory -Force -Path $outfilestore
    }
    

  
  foreach ($rg in $azrg) {

    #Loop through each Resource Group within the subscription
  
    #Define filename for output file  
    $tfile=$cdate+"-"+$rg.ResourceGroupName+".json"
    $cfile=$rg.ResourceGroupName+".json"

    #Put destination folder and filename togethe
    $tfileo=$outfilestore+$tfile    

    Write-Host "Export:" $rg.ResourceGroupName "within subscription" $Subscription " to" $tfileo "`r`n"
  
    #Execute Export Command and write to file using pre-defined destination filename.
    Export-AzResourceGroup -ResourceGroupName $rg.ResourceGroupName -Path $tfileo
    
    #Specify the file location & pattern for the comparison function to run against the latest gathered information
    $docdir=$uprof.Value+"\Documents\"+$aztid+"\"+$azcontextname+"\"
    $cfile="*"+$cfile
    Comp-AzData -Pattern $cfile -DocDir $docdir
   
  }


}