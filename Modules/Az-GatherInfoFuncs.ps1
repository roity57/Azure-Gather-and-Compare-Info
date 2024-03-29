﻿# David Roitman - # Gather Azure information via Az Powershell Function to loop through desired "Get-Az" functions 
# v1.1 - 21/6/2020
# v1.2 - 1/7/2020 - Augmented function to check file size of output and if file is empty then delete it
# v2.0 - 11/7/2020 - Added function to get specifics details of Express Route Gateways & Gateway Subnets (switched to Az Module 4.1.0)
# v2.1 - 1/8/2020 - Updated method of enumerating and using Windows Documents folder (switched to Az Module 4.4.0)
# v2.2 - 19/9/2021 - Added Function to extract Azure DNS records for each zone (switched to Az Module )
# v2.3 - 25/9/2021 - Added processing of Private DNS Zones & Removed redundant file cleanup code in DNS records function
# v2.4 - 2/10/2021 - Amended enumeration of profile folder for ExpressRoute and DNS Zones to match v2.1 update above.
# v2.4 - 3/10/2021 - Correct errors for profile folder check and creation for ExpressRoute.
# v2.5 - 2/7/2022 - Added Function to extract Virtual Network with Subnet details (PS 7.2 & Az Module 6.x)
# Tested in PowerShells 5.x & 7.x environments with Az Module 4.x, 6.x & 8.0.0 on a Windows VM - NOT Regression tested against all available versions.
# Utilises Supplied Parameter to determine file output path and name
# Utilises Invoke-Expression
# DOES NOT contain any error control for failure to create directories/files.
# Reference: https://stackoverflow.com/questions/67179808/trying-to-list-azure-virtual-network-and-export-to-csv-using-powershell
# https://dev.to/roberthstrand/list-all-vnet-and-subnets-across-multiple-subscriptions-4028

function Get-AzNetDetails
{

  param (
    [string]$GetAz,
    [string]$Subscription
    )
  
  #Put together Date & time for filename format  
  $date=get-date -Format "ddMMyyyy"
  $time=get-date -Format "HHmm"
  $cdate=$date+"-"+$time
  
  $aztn=Get-AzContext | Select-Object Tenant
  $aztid=$azt.Tenant.Id

  #Get user profile details to piece together profile path
  $uprof= [environment]::getfolderpath("mydocuments")
  
  #Define final output folder
  $outfilestore=$uprof+"\"+$aztid+"\"+$Subscription+"\"
  
  #Check for output directory existance and if not present, create it.
  If(!(test-path $outfilestore))
    {
      New-Item -ItemType Directory -Force -Path $outfilestore
    }
     
  #Define filename for output file  
  $tfile=$cdate+$GetAz.TrimStart("Get")+".txt"
  
  #Put destination folder and filename togethe
  $tfileo=$outfilestore+$tfile
  
  Write-Host "Executing:" $GetAz "within subscription" $Subscription "writing to" $tfileo
  
  #Execute Command and write to file using pre-defined destination filename.  Width 300 is used to prevent word-wrapping for doing file comparisons.
  Invoke-Expression $GetAz | Out-File -FilePath $tfileo  -Width 300
  
  #Test to see if any data was written and if not, delete the file that had been created.  If the file was created, go ahead and strip content from file as detailed below.
  If ((Get-Item $tfileo).Length -eq 0) {
    Write-Host "Execution:" $GetAz "produced no output so" $tfileo "deleted."
    Remove-Item -Path $tfileo
    }
  else
    {
    #Strip any lines that contain information relating to system generated Etag which can dynamically change.
    Set-Content -Path $tfileo -Value (get-content -Path $tfileo | Select-String -Pattern '"Etag"|(Etag *:)' -NotMatch)
    }
  }
  

function Get-AzNetGates
{

  param (
    [string]$Subscription
    )
  
  #Put together Date & time for filename format  
  $date=get-date -Format "ddMMyyyy"
  $time=get-date -Format "HHmm"
  $cdate=$date+"-"+$time
  
  Select-AzSubscription -Subscription $Subscription | Out-Null
  $aztn=Get-AzContext | Select-Object Tenant
  $aztid=$aztn.Tenant.Id

  #Get user profile details to piece together profile path
  $uprof= [environment]::getfolderpath("mydocuments")
  
  #Define final output folder
  $outfilestore=$uprof+"\"+$aztid+"\"+$Subscription+"\VirtualNetworkGateway\"
  
  [array]$vnetgwa=Get-AzResource | where ResourceType -Like "*virtualNetworkGateways" | Select-Object Name, ResourceGroupName
  [array]$netera=Get-AzResource | where ResourceType -Like "*expressRouteCircuits" | Select-Object Name, ResourceGroupName

  #Check for output directory existance and if not present, create it.
  If($vnetgwa.Length -gt 0)
    {
    If(!(test-path $outfilestore))
      {
        New-Item -ItemType Directory -Force -Path $outfilestore | Out-Null
      }
    }
  else
    {
      Write-Host "Subscription:" $Subscription "did not contain any Virtual Network Gateways"
    }
     
  foreach ($vnetgw in $vnetgwa) {
    $tfile=$cdate+"-"+$vnetgw.Name+"-LR.txt"
    $tfileo=$outfilestore+$tfile
    Write-Host "Fetch Learned Routes from:" $vnetgw.Name "within subscription" $Subscription "writing to" $tfileo
    Get-AzVirtualNetworkGatewayLearnedRoute -ResourceGroupName $vnetgw.ResourceGroupName -VirtualNetworkGatewayName $vnetgw.Name | Format-Table | Out-File $tfileo
  
    
    #Test to see if any data was written and if not, delete the file that had been created.  If the file was created, go ahead and strip content from file as detailed below.
    If ((Get-Item $tfileo).Length -eq 0) 
      {
      Write-Host "Execution:" $GetAz "produced no output so" $tfileo "deleted."
      Remove-Item -Path $tfileo
      }
      
    $tfile=$cdate+"-"+$vnetgw.Name+"-BGP Peer.txt"
    $tfileo=$outfilestore+$tfile
    Write-Host "Fetch BGP Peer Status from:" $vnetgw.Name "within subscription" $Subscription "writing to" $tfileo
    Get-AzVirtualNetworkGatewayBGPPeerStatus -ResourceGroupName $vnetgw.ResourceGroupName -VirtualNetworkGatewayName $vnetgw.Name | Format-Table | Out-File $tfileo 

    #Test to see if any data was written and if not, delete the file that had been created.  If the file was created, go ahead and strip content from file as detailed below.
    If ((Get-Item $tfileo).Length -eq 0) 
      {
      Write-Host "Execution:" $GetAz "produced no output so" $tfileo "deleted."
      Remove-Item -Path $tfileo
      }
     

    }
  
  #Define final output folder
  $outfilestore=$uprof+"\"+$aztid+"\"+$Subscription+"\Express Route\"
  
  #Check for output directory existance and if not present, create it.
  If($netera.Length -gt 0)
    {
    If(!(test-path $outfilestore))
      { 
        New-Item -ItemType Directory -Force -Path $outfilestore | Out-Null
      }
    }
    else
    {
      Write-Host "Subscription:" $Subscription "did not contain any Express Route Circuits"
    }

  foreach ($er in $netera) {
    $tfile=@(0..2)
    $tfile[0]=$cdate+"-"+$er.Name+"-Config.txt"
    $tfile[1]=$cdate+"-"+$er.Name+"-ARP.txt"
    $tfile[2]=$cdate+"-"+$er.Name+"-Routes.txt"
    $tfileo=$outfilestore+$tfile[0]
      
    Write-Host "Fetch ER Details from:" $er.Name "within subscription" $Subscription "writing to" $tfileo
    
    Get-AzExpressRouteCircuit -Name $er.Name -ResourceGroupName $er.ResourceGroupName | out-file -Append $tfileo
    
    #Strip any lines that contain information relating to system generated Etag which can dynamically change.
    Set-Content -Path $tfileo -Value (get-content -Path $tfileo | Select-String -Pattern '"Etag"|(Etag *:)' -NotMatch)
      
    Write-Host "Fetch ER ARP from    :" $er.Name "within subscription" $Subscription "writing to" $tfileo


    $tfileo=$outfilestore+$tfile[1]
    "Private Peering Primary ARP`r`n" | out-file -append $tfileo
    Get-AzExpressRouteCircuitARPTable -ExpressRouteCircuitName $er.Name -ResourceGroupName $er.ResourceGroupName -PeeringType AzurePrivatePeering -DevicePath Primary | out-file -Append $tfileo
    "Private Peering Secondary ARP`r`n" | out-file -append $tfileo
    Get-AzExpressRouteCircuitARPTable -ExpressRouteCircuitName $er.Name -ResourceGroupName $er.ResourceGroupName -PeeringType AzurePrivatePeering -DevicePath Secondary | out-file -Append $tfileo
    "MS Peering Primary ARP`r`n" | out-file -append $tfileo
    Get-AzExpressRouteCircuitARPTable -ExpressRouteCircuitName $er.Name -ResourceGroupName $er.ResourceGroupName -PeeringType MicrosoftPeering -DevicePath Primary | out-file -Append $tfileo
    "MS Peering Secondary ARP`r`n" | out-file -append $tfileo
    Get-AzExpressRouteCircuitARPTable -ExpressRouteCircuitName $er.Name -ResourceGroupName $er.ResourceGroupName -PeeringType MicrosoftPeering -DevicePath Secondary | out-file -Append $tfileo
    
    Write-Host "Fetch ER Routes from :" $er.Name "within subscription" $Subscription "writing to" $tfileo

    $tfileo=$outfilestore+$tfile[2]
    "Private Peering Primary Route Table`r`n" | out-file -append $tfileo
    Get-AzExpressRouteCircuitRouteTable -ExpressRouteCircuitName $er.Name -ResourceGroupName $er.ResourceGroupName -PeeringType AzurePrivatePeering -DevicePath Primary | Format-Table | out-file -Append $tfileo
    "Private Peering Secondary Route Table" | out-file -append $tfileo
    Get-AzExpressRouteCircuitRouteTable -ExpressRouteCircuitName $er.Name -ResourceGroupName $er.ResourceGroupName -PeeringType AzurePrivatePeering -DevicePath Secondary | Format-Table | out-file -Append $tfileo
    "MS Peering Primary Route Table`r`n" | out-file -append $tfileo
    Get-AzExpressRouteCircuitRouteTable -ExpressRouteCircuitName $er.Name -ResourceGroupName $er.ResourceGroupName -PeeringType MicrosoftPeering -DevicePath Primary | out-file -Append $tfileo
    "MS Peering Secondary Route Table`r`n" | out-file -append $tfileo
    Get-AzExpressRouteCircuitRouteTable -ExpressRouteCircuitName $er.Name -ResourceGroupName $er.ResourceGroupName -PeeringType MicrosoftPeering -DevicePath Secondary | out-file -Append $tfileo
    

    $mfile=$cdate+"-"+$er.Name+".txt"
    $mfileo=$outfilestore+$mfile
    $gfile=@(0..2)    
    $gfile[0]=$outfilestore+$tfile[0]
    $gfile[1]=$outfilestore+$tfile[1]
    $gfile[2]=$outfilestore+$tfile[2]
    Get-Content $gfile[0],$gfile[1],$gfile[2] | Set-Content $mfileo
    Write-Host "Merged Output to     :" $mfileo
    
    }

  }


  function Get-AzDNSDetails
{

  param (
    [string]$Subscription
    )
  
  #Put together Date & time for filename format  
  $date=get-date -Format "ddMMyyyy"
  $time=get-date -Format "HHmm"
  $cdate=$date+"-"+$time
  
  Select-AzSubscription -Subscription $Subscription | Out-Null
  $aztn=Get-AzContext | Select-Object Tenant
  $aztid=$aztn.Tenant.Id

  #Get user profile details to piece together profile path
  $uprof= [environment]::getfolderpath("mydocuments")
    
  #Define final output folders
  $outfilestore=$uprof+"\"+$aztid+"\"+$Subscription+"\PublicDNSZones\"
  $outfilestorep=$uprof+"\"+$aztid+"\"+$Subscription+"\PrivateDNSZones\"

  #Fetch all DNS Zones
  [array]$dnsza=Get-AzDnsZone 
  [array]$dnszpa=Get-AzPrivateDnsZone
 
  #Check for output directory existance and if not present, create it.
  If($dnsza.Length -gt 0)
    {
    If(!(test-path $outfilestore))
      {
        New-Item -ItemType Directory -Force -Path $outfilestore | Out-Null
      }
    }
  else
    {
      Write-Host "Subscription:" $Subscription "did not contain any Public DNS Zones"
    }

  #Check for output directory existance and if not present, create it.
  If($dnszpa.Length -gt 0)
    {
    If(!(test-path $outfilestorep))
      {
        New-Item -ItemType Directory -Force -Path $outfilestorep | Out-Null
      }
    }
  else
    {
      Write-Host "Subscription:" $Subscription "did not contain any Private DNS Zones"
    }
     
  foreach ($dnsz in $dnsza) {
    $tfile=$cdate+"-"+$dnsz.Name+".txt"
    $tfileo=$outfilestore+$tfile
    Write-Host "Fetch DNS Records from:" $dnsz.Name "within subscription" $Subscription "writing to" $tfileo
    $dnsrecs = $dnsz | Get-AzDnsRecordSet
    Write-Host "Fetched DNS Records from:" $dnsz.Name "within subscription" $Subscription "writing to" $tfileo
    $dnsrecs | Out-File $tfileo -Width 600
        
    $tfile=$cdate+"-"+$dnsz.Name+"-table.txt"
    $tfilet=$outfilestore+$tfile
    Write-Host "Fetched DNS Records from:" $dnsz.Name "within subscription" $Subscription "writing to" $tfilet
    $dnsrecs | Select-Object Name,Ttl,RecordType,Records,Metadata,ProvisioningState | Format-Table | Out-File $tfilet -Width 600
   }

   foreach ($dnsz in $dnszpa) {
    $tfile=$cdate+"-"+$dnsz.Name+".txt"
    $tfileo=$outfilestorep+$tfile
    Write-Host "Fetch DNS Records from:" $dnsz.Name "within subscription" $Subscription "writing to" $tfileo
    $dnsrecs = $dnsz | Get-AzPrivateDnsRecordSet
    Write-Host "Fetched DNS Records from:" $dnsz.Name "within subscription" $Subscription "writing to" $tfileo
    $dnsrecs | Out-File $tfileo -Width 600
        
    $tfile=$cdate+"-"+$dnsz.Name+"-table.txt"
    $tfilet=$outfilestorep+$tfile
    Write-Host "Fetched DNS Records from:" $dnsz.Name "within subscription" $Subscription "writing to" $tfilet
    $dnsrecs | Select-Object Name,Ttl,RecordType,Records,Metadata,ProvisioningState | Format-Table | Out-File $tfilet -Width 600
   }

  }

   function Get-AzVirtNetDets
   {
   
     param (
       [string]$Subscription
       )
     
     #Put together Date & time for filename format  
     $date=get-date -Format "ddMMyyyy"
     $time=get-date -Format "HHmm"
     $cdate=$date+"-"+$time
     
     Select-AzSubscription -Subscription $Subscription | Out-Null
     $aztn=Get-AzContext | Select-Object Tenant
     $aztid=$aztn.Tenant.Id
   
     #Get user profile details to piece together profile path
     $uprof= [environment]::getfolderpath("mydocuments")
       
     #Define final output folders
     $outfilestore=$uprof+"\"+$aztid+"\"+$Subscription+"\VNETDetails\"

     #Fetch all Virtual Networks
     [array]$vnets=Get-AzVirtualNetwork | Select Name, @{label='AddressSpace'; expression={$_.AddressSpace.AddressPrefixes}}, Subnets
         
     #Check for output directory existance and if not present, create it.
     If($vnets.Length -gt 0)
       {
       If(!(test-path $outfilestore))
         {
           New-Item -ItemType Directory -Force -Path $outfilestore | Out-Null
         }
       }
     else
       {
         Write-Host "Subscription:" $Subscription "did not contain any Virtual Networks"
       }
      foreach ($vnet in $vnets) {
        $tfile=$cdate+"-VNET-"+$vnet.Name+".txt"
        $tfileo=$outfilestore+$tfile
        Write-Host "Fetch Virtual Network Details from:" $vnet.Name "within subscription" $Subscription "writing to" $tfileo
        #$vnet.Name+" "+$vnet.AddressSpace
        $vnet.Subnets | select Name, AddressPrefix, @{Name="NetworkSecurityGroup";Expression = {$_.NetworkSecurityGroup.Id.tostring().substring($_.NetworkSecurityGroup.Id.tostring().lastindexof('/')+1)}}, @{Name="RouteTable";Expression = {$_.RouteTable.Id.tostring().substring($_.RouteTable.Id.tostring().lastindexof('/')+1)}}, @{Name="BGP Disabled";Expression = {$_.RouteTable.DisableBgpRoutePropagation.tostring().substring($_.RouteTable.DisableBgpRoutePropagation.tostring().lastindexof('/')+1)}} | ft
        $vnet.Subnets | select Name, AddressPrefix, @{Name="NetworkSecurityGroup";Expression = {$_.NetworkSecurityGroup.Id.tostring().substring($_.NetworkSecurityGroup.Id.tostring().lastindexof('/')+1)}}, @{Name="RouteTable";Expression = {$_.RouteTable.Id.tostring().substring($_.RouteTable.Id.tostring().lastindexof('/')+1)}}, @{Name="BGP Disabled";Expression = {$_.RouteTable.DisableBgpRoutePropagation.tostring().substring($_.RouteTable.DisableBgpRoutePropagation.tostring().lastindexof('/')+1)}} | ft | Out-File $tfileo -Width 600
        $cfile="*-VNET-"+$vnet.Name+".txt"
        Comp-AzData -Pattern $cfile -DocDir $outfilestore
        
      }
      
  }