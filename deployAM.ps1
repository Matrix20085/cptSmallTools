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
# Instead of exit on bad login we should loop back and allow multiple tries
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
# Instead of exit on bad host we should loop back and allow multiple tries
Write-Host `n`n VM Hosts:`n (Get-VMHost) `n
$vmHostName = Read-Host -Prompt "Chose VM Host from the selection above: "
$vmHost = Get-VMHost -Name $vmHostName -ErrorAction SilentlyContinue
if (-not $vmHost) {
    Write-Host "Host name incorrect!!!" -ForegroundColor Red -BackgroundColor Black
    pause
    exit
}


# Get Datastore object
# Instead of exit on bad datastore we should loop back and allow multiple tries
Write-Host `n`nData Stores:`n (Get-Datastore) `n
$datastoreName = Read-Host -Prompt "Chose datastore from the selection above: "
$datastore = Get-Datastore -Name $datastoreName -ErrorAction SilentlyContinue
if (-not $datastore) {
    Write-Host "Datastore name incorrect!!!" -ForegroundColor Red -BackgroundColor Black
    pause
    exit
}


# Instead of exit on to many we should loop back and allow multiple tries
$numOfOperators = Read-Host -Prompt "`n`nHow many sets of operator VMs are needed"
if ($numOfOperators -gt 10) {
    Write-Host "NO... to many operators." -ForegroundColor Red -BackgroundColor Black
    pause
    exit
}


# Make the folders for organization
# Need to test where the name "vm" comes from. It might be a default just not sure
Get-Folder -Name vm | New-Folder -Name $serverLocation -ErrorAction SilentlyContinue
Get-Folder -Name vm | New-Folder -Name $kaliLocation -ErrorAction SilentlyContinue
Get-Folder -Name vm | New-Folder -Name $commanodLocation -ErrorAction SilentlyContinue


# Set switch vSwitch0 uplink to vmnic0
Get-VirtualSwitch -Name "vSwitch0" | Set-VirtualSwitch -Nic "vmnic0"  # Might need to use Add/Remove-VirtualSwitchPhysicalNetworkAdapter

# Make virtual switch cpt.local with uplink vmnic3 and vmnic4
New-VirtualSwitch -Name "cpt.local" -Nic (Get-VMHostNetworkAdapter -Name "vmnic3")
Add-VirtualSwitchPhysicalNetworkAdapter -VirtualSwitch (Get-VirtualSwitch -Name "cpt.local") -VMHostPhysicalNic (Get-VMHostNetworkAdapter -Name "vmnic4")

# Make virtual swtich Cell Router with uplink vmnic1
New-VirtualSwitch -Name "Cell Router" -Nic (Get-VMHostNetworkAdapter -Name "vmnic1")

# Make virtual switch Emergency with uplink vmnic5
New-VirtualSwitch -Name "Emergency" -Nic (Get-VMHostNetworkAdapter -Name "vmnic5")

# Make portgroup cpt.local assigned to cpt.local
New-VirtualPortGroup -Name "cpt.local" -VirtualSwitch (Get-VirtualSwitch -Name "cpt.local")

# Make portgroup cpt.local Management assigned to cpt.local
New-VirtualPortGroup -Name "cpt.local Management" -VirtualSwitch (Get-VirtualSwitch -Name "cpt.local")

# Check portgroup VM Network assigned to vSwitch0
New-VirtualPortGroup -Name "VM Network" -VirtualSwitch (Get-VirtualSwitch -Name "vSwitch0")

# Make portgroup Cell Router assigned to Cell Router
New-VirtualPortGroup -Name "Cell Router" -VirtualSwitch (Get-VirtualSwitch -Name "Cell Router")

# Make portgroup Emergency Management assigned to Emergency
New-VirtualPortGroup -Name "Emergency Management" -VirtualSwitch (Get-VirtualSwitch -Name "Emergency")

# Make VMKernalNic with portgroup cpt.local Management with static 172.20.20.2 (255.255.255.0) add service management
New-VMHostNetworkAdapter -PortGroup (Get-VirtualPortGroup -Name "cpt.local Management") -IP "172.20.20.2" -SubnetMask "255.255.255.0"

# Make VMKernalNic with portgroup Emergency Management with static 172.17.90.1 (255.255.255.0) add service management
New-VMHostNetworkAdapter -PortGroup (Get-VirtualPortGroup -Name "Emergency Management") -IP "172.17.90.1" -SubnetMask "255.255.255.0"


# Deploying pfSense
Write-Host "Deploying pfSense"
$template = Get-Template -Name "pfSense Gold"
$server = "Test pfSense" # <--------------------------------------------------------------------------REMOVE THIS. FOR TESTING ONLY
New-VM -Name $server -Template $template -Location $serverLocation -Datastore $datastore -DiskStorageFormat Thin -VMHost $vmHost | Out-Null
$currentVM = Get-VM -Name $server
Get-VMStartPolicy -VM $currentVM | Set-VMStartPolicy -StartAction PowerOn -StartOrder 1 -StartDelay 120 | Out-Null


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
    Get-VMStartPolicy -VM $currentVM | Set-VMStartPolicy -StartAction PowerOn -StartDelay 300 | Out-Null
    $macCounter++
}


# Add to deployment "sudo sed -i 's/kali/kali-$i/g' /etc/hosts" using Invoke-VMScript
# Need to bootup host run this, then shutdown

# Deploying CPT Kali 
Write-Host "Deploying CPT-Kali"
$template = Get-Template -Name "Kali Gold"
New-VM -Name "CPT-Kali" -Template $template -Location $kaliLocation -Datastore $datastore -DiskStorageFormat Thin -VMHost $vmHost | Out-Null
$currentVM = Get-VM -Name "CPT-Kali"
$currentNIC = Get-NetworkAdapter -VM $currentVM
Set-NetworkAdapter -NetworkAdapter $currentNIC -MacAddress "00:50:56:17:90:21" -Confirm:$false | Out-Null
New-NetworkAdapter -VM $currentVM -StartConnected -NetworkName "VM Network" | Out-Null


# Deploying Kali
$macCounter = 30
for ($i=0 ; $i -le $numOfOperators ; $i++) {
    Write-Host "Deploying Kali-$i"
    New-VM -Name "Kali-$i" -Template $template -Location $kaliLocation -Datastore $datastore -DiskStorageFormat Thin -VMHost $vmHost | Out-Null
    $currentVM = Get-VM -Name "Kali-$i"
    $currentNIC = Get-NetworkAdapter -VM $currentVM
    Set-NetworkAdapter -NetworkAdapter $currentNIC -MacAddress "00:50:56:17:90:$macCounter" -Confirm:$false | Out-Null
    $macCounter++
}


#Deploying CPT Commanod
Write-Host "Deploying CPT-Commando"
$template = Get-Template -Name "Commando Gold"
New-VM -Name "CPT-Commando" -Template $template -Location $commanodLocation -Datastore $datastore -DiskStorageFormat Thin -VMHost $vmHost | Out-Null
$currentVM = Get-VM -Name "CPT-Commando"
$currentNIC = Get-NetworkAdapter -VM $currentVM
Set-NetworkAdapter -NetworkAdapter $currentNIC -MacAddress "00:50:56:17:90:22" -Confirm:$false | Out-Null
New-NetworkAdapter -VM $currentVM -StartConnected -NetworkName "VM Network" | Out-Null


# Deploying Commando
$macCounter = 40
for ($i=0 ; $i -le $numOfOperators ; $i++) {
    Write-Host "Deploying Commando-$i"
    New-VM -Name "Commando-$i" -Template $template -Location $commanodLocation -Datastore $datastore -DiskStorageFormat Thin -VMHost $vmHost | Out-Null
    $currentVM = Get-VM -Name "Commando-$i"
    $currentNIC = Get-NetworkAdapter -VM $currentVM
    Set-NetworkAdapter -NetworkAdapter $currentNIC -MacAddress "00:50:56:17:90:$macCounter" -Confirm:$false | Out-Null
    $macCounter++
}
