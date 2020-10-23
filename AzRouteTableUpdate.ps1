# David Roitman
# AzRouteTableUpdate.ps1
# Bulk create UDR for CIDR network prefixes destined for Next Hop Type Internet.  This script creates routes, it DOES NOT create the route table.
# Script is only intended to write to a particular Route Table from as many sources as desired.
# v1.0 - 6/8/2020 Take a list of CIDR network prefixes and update Azure Route Table with new UDR for each Prefix 
# v1.1 - 8/8/2020 Amended flag check mechanism for execution of Set-AzRouteTable,
# v1.2 - 23/10/2020 Replaced nested foreach loop with array search and re-factored assessment of source data
# 
# Written/Tested in a PowerShell 7.0.3 environment with Az Module 4.4.0 on a Windows 10 VM using Australian Date/time format
# DOES NOT contain any error control for failure to create directories/files.

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
$rtflagu=$false
$rtcount=0

write-host "Testing: " $rtablepfx.Count "existing route table entries against "$cidrlist.count" Source provided Prefixes"

foreach ($cidr in $cidrlist) {
  # Define a UDR Route Name based on the CIDR destination.  This can be customised as desired.
  $routename="rt"+$rtcomm[1]+"-"+$cidr.replace("/","-")  
  
  # Check to see if the source prefix is already found in the existing Route Table - set a flag true if already found
  $rtflag=$rtablepfx -contains $cidr
    
  # Check to see if the Route flag is false meaning the new prefix is not already in the Route Table
  if ($rtflag -eq $false) {
    write-host "Processing Route:" $cidr.Padright(18,' ') "Adding Route Name:" $routename.Padright(26,' ') "Address Prefix :" $cidr
    #Generate a new Route Table entry with the new Prefix added for Next Hop Type Internet (customise as desired)
    $rtable | Add-AzRouteConfig -Name $routename -AddressPrefix $cidr -NextHopType Internet | out-null 
    $rtflagu=$true
    $rtcount++
  }
}


#If new route entries have been compiled, once the new list is ready commit the updated list into Azure.  Output can be supressed if desired
if ($rtflagu -eq $true)  {
  write-host "Adding" $rtcount "entries to" $rtable.Name
  $rtable | Set-AzRouteTable | Out-Null
}
else {
  write-host "No new prefixes added to" $rtable.Name
}  
