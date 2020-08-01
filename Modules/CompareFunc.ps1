# David Roitman
# File comparison function v2.0 - 27/6/2020
# v2.1 - 26/7/2020 - Replaced TrimEnd method to replace .txt extension with Replace method.
# v2.2 - 1/8/2020 Updated to cater for both either .txt or .json files being compared with regards to creating a .log file output
# Written/Tested in a PowerShell 5.1.19041.1 environment with Az Module 4.4.0 on a Windows 10 VM
# Compare two files matching a certain pattern for the two newest files based on file system date/time stamp.
# The function takes in two parameters, being the partially prepared file pattern source and the folder location of the files to be compared


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

$azfile=Get-ChildItem $docdir -Filter $pattern | Sort-Object -Property CreationTime -Descending | select name
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
    #Formulate .log extension for difference file output filename for .txt file content
    $lf1=$azfile[0].Name.Replace(".txt",".log")
    #Formulate .log extension for difference file output filename for .json file content
    $dfile=$lf1.Replace(".json",".log")
    $compf="Change between "+$azfile[0].Name+" and "+$azfile[1].Name
    $compc=Compare-Object -ReferenceObject $az1 -DifferenceObject $az2 - #-IncludeEqual
    $compf | out-file -FilePath $docdir$dfile
    $compc | Out-File -Append -FilePath $docdir$dfile
    if ($compc.Length -eq 0) {
      write "Compare-Object function results were blank so File content has not changed - ORDER of output data likely changed" | out-file -Append -FilePath $DocDir$dfile
      write-host "File content change has NOT occurred however ORDER of output data likely changed between"$azfile[0].Name "and" $azfile[1].Name "`r`n"
      } 
    else
      {
      write-host "File content change has occurred between"$azfile[0].Name "and" $azfile[1].Name "`r`n"
      } 
    }
  }
  else { Write-Host "Compare did not find relevant comparison files for"$pattern "`r`n" }

}