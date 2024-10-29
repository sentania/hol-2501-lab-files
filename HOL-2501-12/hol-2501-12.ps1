Write-Host "HOL-2501-12 Management Pack Builder PreReqs - Started" -ForegroundColor Green
Write-Host "=====================================================" -ForegroundColor Green

# Create Gitlab entries

$list = @('hol-moad','hol-demo')
$path = "c:\gitlab"
$origin = "$path\rainpole"
$user = "buildadmin"

Write-Host "TASK: Remove Git Repo Flags" -ForegroundColor Yellow
Get-ChildItem -path $path -Directory -Recurse -Filter ".git" -Hidden | Remove-Item -Force -Recurse | Out-Null

Write-Host "TASK: Create Git Repo(s) and Sync Content" -ForegroundColor Yellow
$list | ForEach-Object {
    $target = "$path\$_"
    If ( -Not (Test-Path -Path $target))
    {
        Write-Host "Creating $target folder"
        New-Item -Path $path -Name $_ -ItemType Directory | Out-Null
    }
    If (Test-Path -Path $target)
    {
        Write-Host "Copying files / folders in $origin to $target folder"
        Copy-Item -Path "$origin\*" -Destination $target -Recurse -Force | Out-Null
    
        Set-Location $target
    
        If (-Not (Test-Path -Path ".git" -PathType Container)) {
            Invoke-Command -ScriptBlock { git init -b main }
            Invoke-Command -ScriptBlock { git remote add origin https://$user:VMware123!@gitlab.vcf.sddc.lab/$user/$($_) }
        }
        Write-Host "Pushing $target folder to git"
        Invoke-Command -ScriptBlock { git add . }
        Invoke-Command -ScriptBlock { git commit -m "$(Get-Date) Refresh" }
        Invoke-Command -ScriptBlock { git push -f -u origin main }
        Invoke-Command -ScriptBlock { git checkout -b development }
        Invoke-Command -ScriptBlock { git push -f -u origin development }
        Invoke-Command -ScriptBlock { git checkout -b production }
        Invoke-Command -ScriptBlock { git push -f -u origin production }
    }
}

# Create Ref VM

Write-Host "TASK: Create Reference Virtual Machine" -ForegroundColor Yellow

$password = "VMware123!"
$username = "administrator@vsphere.local"
$vcName = "vcenter-mgmt.vcf.sddc.lab"
$machine = "gitlab"

$EncryptedPassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username, $EncryptedPassword

Write-Host "Connecting to $vcName"
Connect-VIserver -Server $vcName -Credential $Credential | Out-Null

$exists = get-vm -name $machine -ErrorAction SilentlyContinue | Out-Null

if (-Not ($exists)) {
    $resourcePool = Get-Cluster -Name 'mgmt-cluster-01' | Get-ResourcePool "Resources"
    $pg = Get-VDPortgroup -Name 'xregion-seg01' -VDSwitch 'mgmt-vds01'
    Write-Host "Creating $machine VM"
    New-VM -Name $machine -ResourcePool $resourcePool -NumCpu 1 -MemoryGB 1 -DiskGB 1 -Portgroup $pg | Out-Null
    if (-Not (Get-VM | Where-Object {$_.PowerState -eq $PoweredOn}))
    {
        Write-Host "Starting $machine"
        Start-VM $machine | Out-Null
    }
}

Write-Host "Disconnecting $vcName"
Disconnect-VIserver -Server * -Confirm:$false

# Create Bookmark

Write-Host "TASK: Create Management Pack Builder Bookmark" -ForegroundColor Yellow

$registryPath = "HKLM:\\SOFTWARE\\Policies\\Mozilla\\FireFox\\Bookmarks\22"

Set-ItemProperty $registryPath -Name "Title" -Value "Aria Operations MP Builder" -Type "String"
Set-ItemProperty $registryPath -Name "URL" -Value "https://mpb.vcf.sddc.lab/login" -Type "String"
Set-ItemProperty $registryPath -Name "Favicon" -Value "https://mpb.vcf.sddc.lab/favicon.ico" -Type "String"
Set-ItemProperty $registryPath -Name "Placement" -Value "toolbar" -Type "String"
Set-ItemProperty $registryPath -Name "Folder" -Value "VCF Cloud Management" -Type "String"

Write-Host "TASK: Run Group Policy Update - Force" -ForegroundColor Yellow
Invoke-GPUpdate -Force | Out-Null

Write-Host "=======================================================" -ForegroundColor Green
Write-Host "HOL-2501-12 Management Pack Builder PreReqs - Completed" -ForegroundColor Green

Write-Host "Please restart Firefox for Bookmark to show"
