# David Roitman
# File comparison function v2.0 - 27/6/2020
# v2.1 - 26/7/2020 Replaced TrimEnd method to replace .txt extension with Replace method.
# v2.2 - 01/8/2020 Updated to cater for both either .txt or .json files being compared with regards to creating a .log file output
# v3.0 - 04/8/2020 Added function to compare latest files to ALL previous files and produce basic diff file
# v3.1 - 07/8/2020 Amended output commentary to cover for files that only have subtle differences, amended to prevent null variable error if source file blank
# Written/Tested in a PowerShell 7.0.3 environment with Az Module 4.4.0 on a Windows 10 VM
# Function Comp-AzData
# Compare two files matching a certain pattern for the two newest files based on file system date/time stamp.
# The function takes in two parameters, being the partially prepared file pattern source and the folder location of the files to be compared
# Function Comp-Choice
# Compares latest files to all previous files matching pattern


function Comp-AzData
{

  param (
    [string]$Pattern,
    [string]$DocDir
    )

#If the supplied document dir parameter is blank, then set the document directory to the current folder location
if (!$docdir) {
  $cDir=Get-Location | Select-Object Path
  $docdir=$cDir.Path+"\"
}

write-host "Comparison Pattern: " $docdir "-" $Pattern

$azfile=Get-ChildItem $docdir -Filter $pattern | Sort-Object -Property CreationTime -Descending | Select-Object name
$azstate=$azfile.Count
  
if ($azstate -gt 1) {
  $az1source=$docdir+$azfile[0].Name
  $az2source=$docdir+$azfile[1].Name
  $az0h=Get-FileHash $az1source
  $az1h=Get-FileHash $az2source
  write-host "Compare" $azfile[0].Name $azfile[1].Name
  if ($az0h.Hash -eq $az1h.Hash) {
    }
  else {
    write-host "A file hash change has occurred between"$azfile[0].Name "and" $azfile[1].Name
    $az1=get-content $az1source
    $az2=get-content $az2source
    if ($az1 -eq $null)
      { $az1=" "}
    if ($az2 -eq $null)
      { $az2=" "}
    #Formulate .log extension for difference file output filename for .txt file content
    $lf1=$azfile[0].Name.Replace(".txt",".log")
    #Formulate .log extension for difference file output filename for .json file content
    $dfile=$lf1.Replace(".json",".log")
    $compf="Change between "+$azfile[0].Name+" and "+$azfile[1].Name
    $compc=Compare-Object -ReferenceObject $az1 -DifferenceObject $az2
    $compf | out-file -FilePath $docdir$dfile
    $compc | Out-File -Append -FilePath $docdir$dfile
    if ($compc.Length -eq 0) {
      Tee-Object -InputObject "Powershell Compare-Object function results were blank - use a file comparison tool to analyse`r`n" -FilePath $DocDir$dfile -Append
      } 
    }
  }
  else { Write-Host "Compare did not find relevant comparison files for"$pattern "`r`n" }

}

function Comp-Choice
{

  param (
    [string]$Pattern,
    [string]$DocDir
    )

#If the supplied document dir parameter is blank, then set the document directory to the current folder location
if (!$docdir) {
  $cDir=Get-Location | Select-Object Path
  $docdir=$cDir.Path+"\" 
}

write-host "Comparison Pattern: " $docdir "-" $Pattern

$azfile=Get-ChildItem $docdir -Filter $pattern | Sort-Object -Property CreationTime -Descending | Select-Object name
$azstate=$azfile.Count

#$azfile | Select-Object CreationTime, Name | Format-Table -AutoSize

if ($azstate -gt 1) {
  $az1source=$docdir+$azfile[0].Name
  $az2source=$docdir+$azfile[1].Name
  foreach ($pfile in $azfile.Name) {
    $az0h=Get-FileHash $az1source
    $az1h=Get-FileHash $pfile
    write-host "Compare" $azfile[0].Name $pfile
    if ($az0h.Hash -eq $az1h.Hash) {
      }
    else {
      write-host "A file hash change has occurred between"$azfile[0].Name "and" $pfile
      $az1=get-content $az1source
      $az2=get-content $az2source
      if ($az1 -eq $null)
        { $az1=" "}
      if ($az2 -eq $null)
        { $az2=" "}
      #Formulate .log extension for difference file output filename for .txt file content
      $lf1=$azfile[0].Name.Replace(".txt",".log")
      #Formulate .log extension for difference file output filename for .json file content
      $dfile=$lf1.Replace(".json",".log")
      $dfiletail="-"+$pfile.Substring(0,13)+".log"
      $dfile=$dfile.Replace(".log",$dfiletail)
      $compf="Change between "+$azfile[0].Name+" and "+$pfile
      $compc=Compare-Object -ReferenceObject $az1 -DifferenceObject $az2
      $compf | out-file -FilePath $docdir$dfile
      $compc | Out-File -Append -FilePath $docdir$dfile
      if ($compc.Length -eq 0) {
        Tee-Object -InputObject "Powershell Compare-Object function results were blank - use a file comparison tool to analyse`r`n" -FilePath $DocDir$dfile -Append
        } 
      }
    }
  }
  else { Write-Host "Compare did not find relevant comparison files for"$pattern "`r`n" }
}
