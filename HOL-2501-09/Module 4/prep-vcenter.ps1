# Import the VMware PowerCLI module
Import-Module VMware.PowerCLI

# Variables
$vCenterServer = "vcenter-mgmt.vcf.sddc.lab"
$ContentLibraryName = "holcontentlibrary"
$DatastoreName = "vcf-vsan"
$VMTemplates = @("ubuntu22", "ubuntu22v1", "windows2022")
$OldStoragePolicyName = "wld-cluster-01 vSAN Storage Policy"
$NewStoragePolicyName = "wld-cluster01-vsan-storage-policy"
$User = "administrator@vsphere.local"
$Password = "VMware123!"

# Connect to vCenter
$cred = New-Object PSCredential -ArgumentList $User, (ConvertTo-SecureString $Password -AsPlainText -Force)
Connect-VIServer -Server $vCenterServer -Credential $cred

# Create a new content library
$datastore = Get-Datastore -Name $DatastoreName
$contentLibrary = New-ContentLibrary -Name $ContentLibraryName -Datastore $datastore

# Copy VM templates to the content library
foreach ($vmTemplate in $VMTemplates) {
    $template = Get-template -Name $vmTemplate
    $item = New-ContentLibraryItem -ContentLibrary $contentLibrary -Name $vmTemplate -template $template
}

# Rename the storage policy
$storagePolicy = Get-SpbmStoragePolicy | Where-Object { $_.Name -eq $OldStoragePolicyName }
if ($storagePolicy) {
    $storagePolicy | Set-SpbmStoragePolicy -Name $NewStoragePolicyName
} else {
    Write-Host "Storage policy '$OldStoragePolicyName' not found."
}

# Disconnect from vCenter
Disconnect-VIServer -Confirm:$false

Write-host -foregroundcolor Green "vCenter Prep completed"
