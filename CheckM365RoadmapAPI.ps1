<#
  .SYNOPSIS
  Checks the Microsoft 365 Roadmap API for new Roadmap items
  
  .DESCRIPTION
  Checks the Microsoft 365 Roadmap API (https://www.microsoft.com/releasecommunications/api/v2) for new Roadmap items
  Version: 0.2

  .NOTES
  Author: Andrés Gorzelany

  Workflow:
  - Before running, make sure to checkout the repository 
  so the data can be pulled from local file
  - Get current data from Markdown files
  - Update checked file so that PR can be opened

  Known issues:
  - 

  .EXAMPLE
  CheckM365RoadmapAPI.ps1
#>

# ================
#region Variables
# ================

$dataFolderPath = "./_data"
$roadmapFolderPath = "./roadmap"
$productsCSV="products.csv"
$roadmapTemplateFilename="RoadmapTemplate.html"
$countOfItems=0

# ================
#endregion Variables
# ================

# ================
#region Processing
# ================

$products=Import-Csv -Path (Join-Path $dataFolderPath $productsCSV)

foreach($product in $products){

$productName=$product.product
Write-Output "Processing " $productName
$webRequest = Invoke-WebRequest -Uri $product.uri
$webRequestContent = $webRequest.Content -replace "\\n", " "
$result=ConvertFrom-Json $webRequestContent

$countOfItems = if ($result.value) { $result.value.Count } else { $result.Count }

Write-Output $countOfItems +" items"

$counter=0
$timeline=""
$resultsArray = @()

if($countOfItems -eq 1){ #if result = 1 it returns a PSCustomObject object instead of an array
	$resultsArray+= $result.value
}elseif ($countOfItems -gt 1)
{
	$resultsArray=$result.value
}

	foreach($item in $resultsArray){
		
		$counter++
		#availabilities can have more than one month due to diff rings
		$date=$item.availabilities[0].month+"."+$item.availabilities[0].year
		#$title=$item.title -replace "'s", "\\'s" #Should I escape any aposthrope?
		$title=$item.title -replace "`r?`n", ""
		$title=$item.title -replace '"', ' '
		$id=$item.id
		$renderItem=""
		
		##### Date calc
		# Parse as date using invariant (English) culture
		$monthYear=$date.Replace("."," ")
		$targetDate = [datetime]::ParseExact(
			"1 $monthYear",
			"d MMMM yyyy",
			[Globalization.CultureInfo]::InvariantCulture
		)

		# Get the first day of the current month for consistent comparison
		$currentMonth = Get-Date -Day 1

		# Compare both Month and Year
		if ($targetDate -ge $currentMonth) {
			$renderItem="{ date: ""$date"", title:""$title"", url:'https://www.microsoft.com/microsoft-365/roadmap?searchterms=$id', textStyle: {""font-weight"": ""bold""} }"
		} else {
			$renderItem="{ date: ""$date"", title:""$title"", url:'https://www.microsoft.com/microsoft-365/roadmap?searchterms=$id'}"
		}


		if($counter -ne $countOfItems){
			$renderItem=$renderItem+" , "
		}
		$timeline=$timeline+[Environment]::NewLine+$renderitem
		
		
	}


$template=Get-Content (Join-Path $dataFolderPath $roadmapTemplateFilename)
$finalHTML=$template+$timeline+"    ]);</script>"

# save file with UTF-8 encoding
$outFile = $product.product + ".html"
$finalHTML | Out-File -FilePath (Join-Path $roadmapFolderPath $outFile) -Encoding UTF8

}
# ================
#endregion Processing
# ================
