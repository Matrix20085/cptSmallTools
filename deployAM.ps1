# Make the folders for organization
# Need to test where the name "vm" comes from. It might be a default just not sure
Get-Folder -Name vm | New-Folder -Name $serverLocation -ErrorAction SilentlyContinue
Get-Folder -Name vm | New-Folder -Name $kaliLocation -ErrorAction SilentlyContinue
Get-Folder -Name vm | New-Folder -Name $commanodLocation -ErrorAction SilentlyContinue


# pfsense     <-------------------------------------------------------------------------------Put pfsense here when it is ready


# List of all servers.
# Names and order matter here as they are used as template refrences and DNS
$serverList = "PTP","C2","Share","Nessus","Planka","Mattermost"

$macCounter = 10
# Loop to deploy servers
foreach ($server in $serverList) {
    Write-Host "Deploying $server"
    $template = Get-Template -Name "$server Gold"
    $server = "Test $server" # <--------------------------------------------------------------------------REMOVE THIS. FOR TESTING ONLY
    New-VM -Name $server -Template $template -Location $serverLocation -Datastore $datastore -DiskStorageFormat Thin -VMHost $vmHost | Out-Null
    $currentVM = Get-VM -Name $server
    $currentNIC = Get-NetworkAdapter -VM $currentVM
    Set-NetworkAdapter -NetworkAdapter $currentNIC -MacAddress "00:50:56:17:90:$macCounter" -Confirm:$false | Out-Null
    Get-VMStartPolicy -VM $currentVM | Set-VMStartPolicy -StartAction PowerOn | Out-Null
    $macCounter++
}


# Deploying Kali
$template = Get-Template -Name "Kali Gold"
$macCounter = 31
for ($i=1 ; $i -le $numOfOperators ; $i++) {
    Write-Host "Deploying Kali $i"
    New-VM -Name "Kali $i" -Template $template -Location $kaliLocation -Datastore $datastore -DiskStorageFormat Thin -VMHost $vmHost | Out-Null
    $currentVM = Get-VM -Name "Kali $i"
    $currentNIC = Get-NetworkAdapter -VM $currentVM
    Set-NetworkAdapter -NetworkAdapter $currentNIC -MacAddress "00:50:56:17:90:$macCounter" -Confirm:$false | Out-Null
    $macCounter++
}


# Deploying Commando
$template = Get-Template -Name "Commando Gold"
$macCounter = 41
for ($i=1 ; $i -le $numOfOperators ; $i++) {
    Write-Host "Deploying Commando $i"
    New-VM -Name "Commando $i" -Template $template -Location $commanodLocation -Datastore $datastore -DiskStorageFormat Thin -VMHost $vmHost | Out-Null
    $currentVM = Get-VM -Name "Commando $i"
    $currentNIC = Get-NetworkAdapter -VM $currentVM
    Set-NetworkAdapter -NetworkAdapter $currentNIC -MacAddress "00:50:56:17:90:$macCounter" -Confirm:$false | Out-Null
    $macCounter++
}
