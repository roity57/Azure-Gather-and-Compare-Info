# David Roitman
# AzRouteTableSync.ps1
# Synchronise CIDR network prefixes destined for Next Hop Type Internet.  This script edits a route table, it DOES NOT create the route table.
# Script is only intended to:
# * Synchronise an Azure Route Table with a specified Source.
# * Deals with Public prefixes as the default is for next hope type Internet, Azure does not accept RFC1918 routes for next hop Internet.
#  
# v1.0 - 23/10/2020 Augmented AzRouteTableUpdate.ps1 to create this script to synchronise Azure Route Table with a single specific source
# 
# Written/Tested in a PowerShell 7.0.3 environment with Az Module 4.4.0 on a Windows 10 VM using Australian Date/time format
# DOES NOT contain any error control for lack of Azure access, incorrect Route Table name or incorrect source file.

# Specify the desired Azure BGP Community - review options via "Get-AzBgpServiceCommunity" Az module command or use API call
# https://docs.microsoft.com/en-us/rest/api/expressroute/bgpservicecommunities/list
# Specify the destination Route Table (Line 20)

#Comment out following line to have script process ".txt" file in local folder called CIDRList.txt or modify script as required
$bgpname="AzureActiveDirectory"

# Specify the name of the Azure Route Table
$routetable="RT1"


# Split the BGP AS & Community details so that the Community number can be extracted later and used as part of the Route Name.
# Split only done if value is not empty incase a text CIDR list was utilised.  If not a BGP extract, then set route name definer variable to blank as it's used later.
if ($bgpname.length -gt 0) {
  write-host "Fetching BGP Community"$bgpname" CIDR Prefixes"
  $cidrlist=Get-AzBgpServiceCommunity | Where-Object Name -eq $bgpname | Select-Object -ExpandProperty BgpCommunities | Select-Object CommunityPrefixes | Select-Object -ExpandProperty CommunityPrefixes
  write-host "Fetching BGP Community"$bgpname" AS:Community Number"
  $bgpc=Get-AzBgpServiceCommunity | Where-Object Name -eq $bgpname | Select-Object -ExpandProperty BgpCommunities | Select-Object CommunityValue
  write-host "Splitting BGP details"$bgpc.CommunityValue"belonging to"$bgpname
  $rtcomm=$bgpc.CommunityValue.Split(":")
  }
else {
  # Optionally, specify a source text file with CIDR Prefixes listed once per line of desired network ranges.
  $cidrlist=Get-Content -Path CIDRList.txt
  $rtcomm=""
}

# Fetch the Route Table details
$rtable=Get-AzRouteTable -Name $routetable 
# Extract the destination route prefixes from the route table into an array
$rtablepfx=$rtable.Routes.AddressPrefix
$rtflagua=$false
$rtflagur=$false
$rtcounta=0
$rtcountr=0

write-host "Testing:"$rtablepfx.Count "existing route table entries against"$cidrlist.Count"Source provided Prefixes"

foreach ($cidr in $cidrlist) {
  # Check to see if the source prefix is already found in the existing Route Table - set a flag true if already found
  $rtflag=$rtablepfx -contains $cidr
    
  # Check to see if the Route flag is false meaning the new prefix is not already in the Route Table
  if ($rtflag -eq $false) {
    # Define a UDR Route Name based on the CIDR destination.  This can be customised as desired.
    $routename="rt"+$rtcomm[1]+"-"+$cidr.replace("/","-")  
    write-host "Processing Route:" $cidr.Padright(18,' ') "Adding Route Name:" $routename.Padright(26,' ') "Address Prefix :" $cidr
    #Generate a new Route Table entry with the new Prefix added for Next Hop Type Internet (customise as desired)
    $rtable | Add-AzRouteConfig -Name $routename -AddressPrefix $cidr -NextHopType Internet | out-null 
    $rtflagua=$true
    $rtcounta++
  }
}

foreach ($rt in $rtablepfx) {
  
  #Check the list of externally sources routes against the current route table entry and set resulting flag    
  $rtflag=$cidrlist -contains $rt
   
  # Check to see if the Route flag is false meaning the prefix found is not in the source list provided
  if ($rtflag -eq $false)  {
    $routename=Get-AzRouteTable -Name $routetable | Select-Object -ExpandProperty Routes | Where-Object AddressPrefix -eq $rt | Select-Object Name 
    $routename=$routename.Name
    write-host "Processing Route:" $rt.Padright(18,' ') "Remove Route Name:" $routename.Padright(26,' ') "Address Prefix :" $rt
    $rtable | Remove-AzRouteConfig -Name $routename | out-null
    #Set a flag to indicate an Azure Route table update needs to be committed to Azure
    $rtflagur=$true
    $rtcountr++
  }
}

#If new route entries have been compiled, once the new list is ready commit the updated list into Azure.  Output can be supressed if desired

if ($rtflagua -eq $true -or $rtflagur -eq $true) {
    write-host "Changes to route table" $rtable.Name "- Adding" $rtcounta "routes & Removing" $rtcountr "routes"
    write-host "Please wait, committing changes to Azure"
    $erc=$error.count
    $rtable | Set-AzRouteTable | Out-Null
    if ($erc -eq $error.count) {
      write-host "Changes Committed to route table" $rtable.Name "in Azure"    
    }
    else {
      write-error "Changes failed to committ to route table in Azure - see error message above"  
    }
    
}
else {
    write-host "No changes required"
}
