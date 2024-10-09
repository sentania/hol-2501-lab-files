Write-Output "$(Get-Date) Lab Files Clean Up Script"

Get-ChildItem -path "C:\labfiles" -Recurse -Filter ".gitattributes" | Remove-Item -Force -Recurse
Get-ChildItem -path "C:\labfiles" -Recurse -Filter ".gitignore" | Remove-Item -Force -Recurse
Get-ChildItem -path "C:\labfiles" -Recurse -Filter "README.md" | Remove-Item -Force -Recurse

$list = @('hol-moad','hol-demo')
$path = "c:\gitlab"
$origin = "$path\rainpole"
$user = "buildadmin"

Get-ChildItem -path "c:\gitlab" -Directory -Recurse -Filter ".git" -Hidden | Remove-Item -Force -Recurse

$list | ForEach-Object {
    $target = "$path\$_"
    If ( -Not (Test-Path -Path $loc))
    {
        Write-Output "Creating $target folder"
        New-Item -Path $path -Name $_ -ItemType Directory
    }
    If (Test-Path -Path $target)
    {
        Write-Output "Copying files / folders in $origin to $target folder"
        Copy-Item -Path "$origin\*" -Destination $target -Recurse -Force
    
        Set-Location $target
    
        If (-Not (Test-Path -Path ".git" -PathType Container)) {
            Invoke-Command -ScriptBlock { git init -b main }
            Invoke-Command -ScriptBlock { git remote add origin https://$user:VMware123!@gitlab.vcf.sddc.lab/$user/$($_) }
        }
        Invoke-Command -ScriptBlock { git add . }
        Invoke-Command -ScriptBlock { git commit -m "$(Get-Date) Refresh" }
        Invoke-Command -ScriptBlock { git push -f -u origin main }
        Invoke-Command -ScriptBlock { git checkout -b development }
        Invoke-Command -ScriptBlock { git push -f -u origin development }
        Invoke-Command -ScriptBlock { git checkout -b production }
        Invoke-Command -ScriptBlock { git push -f -u origin production }
    }
}

$password = "VMware123!"
$username = "administrator@vsphere.local"
$vcName = "vcenter-mgmt.vcf.sddc.lab"
$machine = "gitlab.vcf.sddc.lab"

$EncryptedPassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $EncryptedPassword

Connect-VIserver -Server $vcName -Credential $Credential

$exists = get-vm -name $machine -ErrorAction SilentlyContinue

if (-Not ($exists)) {
    $resourcePool = Get-Cluster -Name 'mgmt-cluster-01' | Get-ResourcePool "Resources" 
    $pg = Get-VDPortgroup -Name 'xregion-seg01' -VDSwitch 'mgmt-vds01'
    New-VM -Name $machine -ResourcePool $resourcePool -NumCpu 1 -MemoryGB 1 -DiskGB 1 -Portgroup $pg
    if (-Not (Get-VM | where {$_.PowerState -eq $PoweredOn}))
    {
        Start-VM $machine
    }
}

Disconnect-VIserver -Server * -Confirm:$false
