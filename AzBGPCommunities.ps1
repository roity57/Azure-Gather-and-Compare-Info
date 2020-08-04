# David Roitman
# AzBGPCommunities.ps1
# Primarily intended to gather Azure BGP Community IP address information v1.0 - 1/7/2020
# v1.1 - 31/7/2020 Updated method of enumerating and using Windows Documents folder
# You can designate the BGP Communities desired by the Name as MS list it in the "name" field, or enumerate all of them - detailed in the script.
# You can just extract the CIDR prefixes, or the fuller data including prefxies - detailed in the script.
# Written/Tested in a PowerShell 7.0.3 environment with Az Module 4.4.0 on a Windows 10 VM using Australian Date/time format
# Creates folder for data capture and then a sub-folder per Azure BGP Community
# Calls File comparison function to process output files inside each BGP Community directory.
# DOES NOT contain any error control for failure to create directories/files.

$cDir=Get-Location | Select-Object Path
$scriptdir=$cDir.Path
Import-Module $scriptdir"\CompareFunc.ps1" -Force

#Get user profile details to piece together profile path
$uprof= [environment]::getfolderpath("mydocuments")

#############################################################################################################################################
# If you want to extract detailes for only certain BGP Communities, use the first array below.  Otherwise use the second to enumerate ALL   #
#############################################################################################################################################
   
#Specify the Community Names desired as they would appear in the "Name" object.
[array]$bgpclist="AzureAustraliaSoutheast","AzureAustraliaEast","AzureCosmosDBUAENorth"

#Enumerate ALL Microsoft BGP Communities
#[array]$bgpclist=Get-AzBgpServiceCommunity | Select-Object -ExpandProperty Name

#Define BGP root output folder
$outfileroot=$uprof+"\AzBGPCommunity"
  
#Check for output directory existance and if not present, create it.
If(!(test-path $outfileroot))
  {
    New-Item -ItemType Directory -Force -Path $outfileroot | out-null
  }

$date=get-date -Format "ddMMyyyy"
$time=get-date -Format "HHmm"
$cdate=$date+"-"+$time

foreach ($bgpc in $bgpclist) {
  
  #Define final BGP Community folder output location
  $outfilestore=$outfileroot+"\"+$bgpc

  #Check for output directory existance and if not present, create it.
  If(!(test-path $outfilestore))
  {
    New-Item -ItemType Directory -Force -Path $outfilestore | out-null
  }

  #Build filename and location combination
  $tfile=$cdate+"-"+$bgpc+".txt"
  $tfileo=$outfilestore+"\"+$tfile
  
  #############################################################################################################################################
  # If you want to extract just the CIDR notation list of IP address ranges then use the first Get- call, otherwise use the second            #
  #############################################################################################################################################
  
  Write-Host "Fetching : " -NoNewline -ForegroundColor White
  write-host  $bgpc -ForegroundColor Cyan 
  write-host "Saving to: " -NoNewline
  write-host $tfileo -ForegroundColor Cyan

  #Get only CIDR notation list of IP address ranges relevant to the BGP community
  Get-AzBgpServiceCommunity | Where-Object Name -eq $bgpc | Select-Object -ExpandProperty BgpCommunities | Select-Object CommunityPrefixes | Select-Object -ExpandProperty CommunityPrefixes | out-file $tfileo
  
  #Get the full details from including Service Supported Region, Full Community Name & Community BGP Value number.
  #Get-AzBgpServiceCommunity | Where-Object Name -eq $bgpc | out-file $tfileo
  
  #Specify the file pattern for the comparison function to run against the latest gathered information
  $cfile="*"+$bgpc+".txt"
  $outfilestore=$outfilestore+"\"
  Comp-AzData -Pattern $cfile -DocDir $outfilestore

}
