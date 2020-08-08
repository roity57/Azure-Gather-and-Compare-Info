# David Roitman
# AzRouteTableUpdate.ps1
# Bulk create UDR for CIDR network prefixes destined for Next Hop Type Internet.  This script creates routes, it DOES NOT create the route table.
# v1.0 - 6/8/2020 Take a list of CIDR network prefixes and update Azure Route Table with new UDR for each Prefix 
# v1.1 - 8/8/2020 Amended flag check mechanism for execution of Set-AzRouteTable 
# 
# Written/Tested in a PowerShell 7.0.3 environment with Az Module 4.4.0 on a Windows 10 VM using Australian Date/time format
# DOES NOT contain any error control for failure to create directories/files.

# Specify the desired Azure BGP Community - review options via "Get-AzBgpServiceCommunity" Az module command or use API call
# https://docs.microsoft.com/en-us/rest/api/expressroute/bgpservicecommunities/list

$bgpname="AzureActiveDirectory"

write-host "Fetching BGP Community"$bgpname" CIDR Prefixes"
$cidrlist=Get-AzBgpServiceCommunity | Where-Object Name -eq $bgpname | Select-Object -ExpandProperty BgpCommunities | Select-Object CommunityPrefixes | Select-Object -ExpandProperty CommunityPrefixes
write-host "Fetching BGP Community"$bgpname" AS:Community Number"
$bgpc=Get-AzBgpServiceCommunity | Where-Object Name -eq $bgpname | Select-Object -ExpandProperty BgpCommunities | Select-Object CommunityValue

# Optionally, specify a source text file with CIDR Prefixes listed once per line of desired network ranges.
#$cidrlist=Get-Content -Path CIDRlist.txt

# Specify the name of the Azure Route Table
$routetable="RT1"

# Split the BGP AS & Community details so that the Community number can be extracted later and used as part of the Route Name.
# Split only done if value is not empty incase a text CIDR list was utilised.  If not a BGP extract, then set route name definer variable to blank as it's used later.

if ($bgpc.length -gt 0)
  {
  write-host "Splitting BGP details"$bgpc.CommunityValue"belonging to"$bgpname
  $rtcomm=$bgpc.CommunityValue.Split(":")
  }
  else
  {
  $rtcomm=""
  }

# Fetch the Route Table details
$rtable=Get-AzRouteTable -Name $routetable 
# Extract the destination route prefixes from the route table into an array
$rtablepfx=$rtable.Routes.AddressPrefix
$rtflagu=$false

write-host "Testing: " $rtablepfx.Count "route table entries against "$cidrlist.count" Prefixes"

foreach ($cidr in $cidrlist) {
  # A flag is used to determine if the current route table already has a route for the prefix to be added so reset the existing route check flag to false
  $rtflag=$false
  # Define a UDR Route Name based on the CIDR destination.  This can be customised as desired.
  $routename="rt"+$rtcomm[1]+"-"+$cidr.replace("/","-")  
   
  foreach($rt in $rtablepfx) {
    #$rtflag=$false
    #write-host "Testing: " $rt "against " $cidr
    # Check to see if the new destionation prefix is already found in the existing Route Table
    if ($rt -eq $cidr)
      {
      # If the prefix is found within the current Route Table, set the flag to true
      $rtflag=$true
      #write-host "Found  :" $rt "Flag: " $rtflag
      break
      }
    }

    # Check to see if the Route flag is false meaning the new prefix is not already in the Route Table
    if ($rtflag -eq $false)
      {
      write-host "Processing Route:" $cidr.Padright(18,' ') "Adding Route Name:" $routename.Padright(26,' ') "Address Prefix :" $cidr
      #Generate a new Route Table entry with the new Prefix added for Next Hop Type Internet (customise as desired)
      $rtable | Add-AzRouteConfig -Name $routename -AddressPrefix $cidr -NextHopType Internet | out-null 
      $rtflagu=$true
      }
    }
    #If new route entries have been compiled, once the new list is ready commit the updated list into Azure.  Output can be supressed if desired
    if ($rtflagu -eq $true)
      {
      $rtable | Set-AzRouteTable | Out-Null
      }
    
