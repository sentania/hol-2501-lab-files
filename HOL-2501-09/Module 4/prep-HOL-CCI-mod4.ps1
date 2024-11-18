###This script updates the HOL projects and cloud accounts to be DNS/kubernetes compliant which is a requirement
# for CCI
#It also creates a content library and uploads a single image to it.

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
$projectUri = "$ariaServer/iaas/api/projects?apiVersion=$apiVersion&`$filter=name eq '$projectOldName'"
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
$cloudAccountUri = "$ariaServer/iaas/api/cloud-accounts?apiVersion=$apiVersion&`$filter=name eq '$cloudAccountOldName'"
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


Write-host "Sleeping 30 seconds to help prevent any race conditions..." -ForegroundColor Green
sleep 30


##Now that aria is prepped we need to create the kubernetes resources for CCI.
# Set the path to kubectl if it's needed explicitly
$kubectlPath = "C:\kubectl\bin\kubectl.exe"

# Function to check command success and handle failure
function Check-Success {
    if (-not $?) {
        Write-Host "ERROR: The HOL pod is likely in a bad state. Please ask for help or launch a new pod." -ForegroundColor Red
        Exit 1  # Exit with a non-zero code to indicate failure
    }
}

# Step 1: Export the password to an environment variable for non-interactive login
$env:KUBECTL_CCI_PASSWORD="VMware123!"

# Step 2: Login to CCI
$result = & $kubectlPath cci login -u holadmin@vcf.holo.lab --server rainpole.auto.vcf.sddc.lab --insecure-skip-tls-verify
Check-Success

# Step 3: Set CCI context
& $kubectlPath config use-context cci
Check-Success

# Step 4: Check current Kubernetes resources
& $kubectlPath get supervisors -n cci-config
Check-Success

& $kubectlPath get projects -n cci-config
Check-Success

# Step 5: Create base environment config resources
$yamlFiles = @(
    "C:\labfiles\HOL-2501-09\Module 4\cci-project.yaml",
    "C:\labfiles\HOL-2501-09\Module 4\cci-projectrolerolebinding-users.yaml",
    "C:\labfiles\HOL-2501-09\Module 4\cci-region.yaml"
)

foreach ($yamlFile in $yamlFiles) {
    Write-Host "Applying $yamlFile..." -ForegroundColor Green
    & $kubectlPath create -f $yamlFile
    Check-Success
}

# Step 6: Modify Supervisor resource to reference the newly created region
# Variables
$namespace = "cci-config"
$supervisorName = "vcf-mgmt-vcenter:domain-c4001"

# Get the current Supervisor resource YAML
Write-Host "Patching supervisor with region labels..." -ForegroundColor Green
& $kubectlPath get supervisor $supervisorName -n $namespace -o yaml > supervisor.yaml
Check-Success

# Modify the YAML file
$yamlContent = Get-Content -Path "supervisor.yaml"
$updatedYamlContent = @()
$labelsAdded = $false
$regionNamesAdded = $false

foreach ($line in $yamlContent) {
    if ($line -match "labels: \{\}") {
        $updatedYamlContent += $line.split("{")[0]
        $updatedYamlContent += "    environment: development"
        $labelsAdded = $true
    }
    elseif ($line -match "cloudAccountName:" -and -not $regionNamesAdded) {
        $updatedYamlContent += $line
        $updatedYamlContent += "  regionNames:"
        $updatedYamlContent += "    - cci-region"
        $regionNamesAdded = $true
    }
    else {
        $updatedYamlContent += $line
    }
}

# Write the modified YAML back to the file
Set-Content -Path "supervisor.yaml" -Value $updatedYamlContent

# Apply the modified YAML
& $kubectlPath apply -f supervisor.yaml
Check-Success

# Cleanup the temporary file
Remove-Item "supervisor.yaml"

# Step 7: Apply remaining Kubernetes resources
$yamlFilesRemaining = @(
    "C:\labfiles\HOL-2501-09\Module 4\cci-regionbinding.yaml",
    "C:\labfiles\HOL-2501-09\Module 4\cci-regionbindingconfig.yaml",
    "C:\labfiles\HOL-2501-09\Module 4\cci-supervisor-ns-class.yaml",
    "C:\labfiles\HOL-2501-09\Module 4\cci-supervisor-ns-class-binding.yaml",
    "C:\labfiles\HOL-2501-09\Module 4\cci-supervisor-ns-class-config.yaml"
)

foreach ($yamlFile in $yamlFilesRemaining) {
    Write-Host "Applying $yamlFile..." -ForegroundColor Green
    & $kubectlPath create -f $yamlFile
    Check-Success
}

Write-Host "All resources have been successfully created."

Write-host "Aria Automation CCI has been successfully setup for HOL-2501-09 Module 4."
