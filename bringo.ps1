$storelist = @("carrefour_vulcan","carrefour_berceni","carrefour_orhideea","carrefour_militari","carrefour_baneasa","carrefour_park_lake","carrefour_mega_mall","carrefour_unirii","carrefour_hipermarket-carrefour-obor-veranda","carrefour_soseaua_chitilei_284")

$store = $storelist | out-gridview -title "Select store" -PassThru

Write-Host "== Searching for categories =="
Write-Host " "
Write-Host "Configured store: $($store)"
Write-Host -NoNewline "Working...  "

$categ = Invoke-RestMethod -Uri "https://apis.bringo.ro/public/v1/ro/stores/$($store)/categories?limit=999&page=1" -Method GET | select -expand "_embedded" | select -expand "items" | select -expand "translations" 

$taxon = @()

foreach ($i in $categ.slug) {
$t = Invoke-RestMethod -Uri "https://apis.bringo.ro/public/v1/ro/stores/$($store)/categories/$($i)?limit=999&page=1" -Method GET | select -expand "_embedded" | select -expand "items" | select -expand "translations"
$taxon += $t.slug
}

Write-Host "Done."

$prod = @()

Write-Host " "
Write-Host "== Downloading categories =="
Write-Host " "

foreach ($j in $taxon) {
Write-Host -NoNewline "Processing $($j)...  "
$y = Invoke-RestMethod -Uri "https://apis.bringo.ro/public/v1/ro/stores/$($store)/taxons/$($j)/products?limit=1500&page=1" -Method GET | select -expand "_embedded" | select -expand "items" | select @{N='RAION';E={$_.product.isleName}}, @{N='CATEGORIE';E={$_.product.familyName}}, @{N='BRAND';E={$_.product.brandName}}, @{N='NUME';E={$_.product.name}}, @{N='PRET';E={$_.channelPricings.US_WEB.price/100}}, @{N='POZA';E={"https://storage.googleapis.com/bringoimg/web/cache/sylius_large/$($_.product.images[0].path)"}}
Write-Host "$($y.Count) products found."
$prod += $y
}

$sub = $prod | where {$_.poza -eq "https://storage.googleapis.com/bringoimg/web/cache/sylius_large/"}
foreach ($k in $sub) { $k.poza = "" }

$sorted = $prod | Sort-Object -Property NUME -Unique

$sorted | export-csv -NoTypeInformation -path "$($store).csv"
Write-Host " "
Write-Host "Found $($sorted.Count) products."
Write-Host "File saved: $($store).csv"
pause