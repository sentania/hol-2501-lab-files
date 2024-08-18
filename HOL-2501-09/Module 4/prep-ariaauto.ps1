# Variables
$ariaServer = "https://rainpole.auto.vcf.sddc.lab"
$authUri = "$ariaServer/csp/gateway/am/api/login?access_token"
$tokenExchangeUri = "$ariaServer/iaas/api/login"
$apiVersion = "2021-01-30"  # Replace with the appropriate API version if needed
$projectOldName = "HOL Project"
$projectNewName = "hol-project"
$cloudAccountOldName = "VCF MGMT vCenter"
$cloudAccountNewName = "vcf-mgmt-vcenter"
$user = "holadmin@vcf.holo.lab"
$password = "VMware123!"

# Obtain Refresh Token
$authBody = @{
    "username" = $user
    "password" = $password
    "domain"   = "vcf.holo.lab"
} | ConvertTo-Json

$authResponse = Invoke-RestMethod -Method Post -Uri $authUri -Body $authBody -ContentType "application/json" -UseBasicParsing -SkipCertificateCheck
$refreshToken = $authResponse.refresh_token

# Exchange Refresh Token for Access Token
$tokenBody = @{
    "refreshToken" = $refreshToken
} | ConvertTo-Json

$tokenResponse = Invoke-RestMethod -Method Post -Uri $tokenExchangeUri -Body $tokenBody -ContentType "application/json" -UseBasicParsing -SkipCertificateCheck
$accessToken = $tokenResponse.token

# Helper function to make API requests
function Invoke-AriaApiRequest {
    param (
        [string]$method,
        [string]$uri,
        [hashtable]$body = $null
    )
    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Accept" = "application/json"
        "Content-Type" = "application/json"
    }
    if ($body) {
        $bodyJson = $body | ConvertTo-Json
        Invoke-RestMethod -Method $method -Uri $uri -Headers $headers -Body $bodyJson -SkipCertificateCheck
    } else {
        Invoke-RestMethod -Method $method -Uri $uri -Headers $headers -SkipCertificateCheck
    }
}

# Get the project by name
$projectUri = "$ariaServer/iaas/api/projects?apiVersion=$apiVersion&$filter=name eq '$projectOldName'"
$project = Invoke-AriaApiRequest -method Get -uri $projectUri

if ($project) {
    $projectId = $project.content[0].id
    $updateProjectUri = "$ariaServer/iaas/api/projects/${projectId}?apiVersion=$apiVersion"
    $projectBody = @{
        "name" = $projectNewName
    }
    Invoke-AriaApiRequest -method Patch -uri $updateProjectUri -body $projectBody
    Write-Host "Project renamed to $projectNewName"
} else {
    Write-Host "Project '$projectOldName' not found."
}

# Get the cloud account by name
$cloudAccountUri = "$ariaServer/iaas/api/cloud-accounts?apiVersion=$apiVersion&$filter=name eq '$cloudAccountOldName'"
$cloudAccount = Invoke-AriaApiRequest -method Get -uri $cloudAccountUri

if ($cloudAccount) {
    $cloudAccountId = $cloudAccount.content[0].id
    $updateCloudAccountUri = "$ariaServer/iaas/api/cloud-accounts/${cloudAccountId}?apiVersion=$apiVersion"
    $cloudAccountBody = @{
        "name" = $cloudAccountNewName
    }
    Invoke-AriaApiRequest -method Patch -uri $updateCloudAccountUri -body $cloudAccountBody
    Write-Host "Cloud account renamed to $cloudAccountNewName"
} else {
    Write-Host "Cloud account '$cloudAccountOldName' not found."
}
Write-host -foregroundcolor Green "Aria Automation prep completed"