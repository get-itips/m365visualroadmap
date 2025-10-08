<#
  .SYNOPSIS
  Checks the Microsoft 365 Roadmap API for new Roadmap items
  
  .DESCRIPTION
  Checks the Microsoft 365 Roadmap API (https://www.microsoft.com/releasecommunications/api/v2) for new Roadmap items
  Version: 0.1

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

$products=Import-Csv -Path ./_data/products.csv
$countOfItems=0

# ================
#endregion Variables
# ================

# ================
#region Processing
# ================

foreach($product in $products){

$productName=$product.product
Write-Output "Processing " $productName
$webRequest = Invoke-WebRequest -Uri $product.uri
$webRequestContent = $webRequest.Content -replace "\\n", " "
$result=ConvertFrom-Json $webRequestContent

$countOfItems = if ($result.value) { $result.value.Count } else { $result.Count }

Write-Output $countOfItems +" items"

}
