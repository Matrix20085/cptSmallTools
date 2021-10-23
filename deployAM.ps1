# Hard variables
$serverLocation = "Servers"
$kaliLocation = "Kalis"
$commanodLocation = "Commandos"


# Download and import PowerCli
Write-Host "Downloading VMWare Tools, this may take a while..." -ForegroundColor Cyan -BackgroundColor Black
Install-Module -Name VMware.PowerCLI -Scope CurrentUser -Force:$true
Write-Host "Importing VMWare Tools, this may take a while..." -ForegroundColor Cyan -BackgroundColor Black
Get-Module -ListAvailable VMware* | Import-Module | Out-Null
cls


# Get user information and loginto vCenter
# Insted of exit on bad login we should loop back and allow multiple tries
$vCenterServer = Read-Host -Prompt "IP or FQDN of vCenter server"
$vCenterUsername = Read-Host -Prompt "vCenter username"
$vCenterPassword = Read-Host -Prompt "vCenter password" -AsSecureString
$vCenterPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($vCenterPassword))
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false | Out-Null
if (Connect-VIServer -Server $vCenterServer -Protocol https -User $vCenterUsername -Password $vCenterPassword -ErrorAction SilentlyContinue) {
    Write-Output 'Connected'
} 
else {
    $Error[0]
    pause
    exit
}


# Get VMHost object
# Insted of exit on bad host we should loop back and allow multiple tries
Write-Host `n`n VM Hosts:`n (Get-VMHost) `n
$vmHostName = Read-Host -Prompt "Chose VM Host from the selection above: "
$vmHost = Get-VMHost -Name $vmHostName -ErrorAction SilentlyContinue
if (-not $vmHost) {
    Write-Host "Host name incorrect!!!" -ForegroundColor Red -BackgroundColor Black
    pause
    exit
}


#Get Datastore object
# Insted of exit on bad datastore we should loop back and allow multiple tries
Write-Host `n`nData Stores:`n (Get-Datastore) `n
$datastoreName = Read-Host -Prompt "Chose datastore from the selection above: "
$datastore = Get-Datastore -Name $datastoreName -ErrorAction SilentlyContinue
if (-not $datastore) {
    Write-Host "Datastore name incorrect!!!" -ForegroundColor Red -BackgroundColor Black
    pause
    exit
}


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
for ($i=1 ; $i -lt 10 ; $i++) {
    Write-Host "Deploying Kali $i"
    New-VM -Name "Kali $i" -Template $template -Location $kaliLocation -Datastore $datastore -DiskStorageFormat Thin -VMHost $vmHost | Out-Null
    $currentVM = Get-VM -Name "Kali $i"
    $currentNIC = Get-NetworkAdapter -VM $currentVM
    Set-NetworkAdapter -NetworkAdapter $currentNIC -MacAddress "00:50:56:17:90:$macCounter" -Confirm:$false | Out-Null
    Get-VMStartPolicy -VM $currentVM | Set-VMStartPolicy -StartAction PowerOn | Out-Null
    $macCounter++
}


# Deploying Commando
$template = Get-Template -Name "Commando Gold"
$macCounter = 41
for ($i=1 ; $i -lt 10 ; $i++) {
    Write-Host "Deploying Commando $i"
    New-VM -Name "Commando $i" -Template $template -Location $commanodLocation -Datastore $datastore -DiskStorageFormat Thin -VMHost $vmHost | Out-Null
    $currentVM = Get-VM -Name "Commando $i"
    $currentNIC = Get-NetworkAdapter -VM $currentVM
    Set-NetworkAdapter -NetworkAdapter $currentNIC -MacAddress "00:50:56:17:90:$macCounter" -Confirm:$false | Out-Null
    Get-VMStartPolicy -VM $currentVM | Set-VMStartPolicy -StartAction PowerOn | Out-Null
    $macCounter++
}
