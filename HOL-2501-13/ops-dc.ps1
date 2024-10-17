#Las Vegas
#Adapter Type: Container
#Object Type: GEO Location & Physical Data Center


$opsUrl = "https://ops.vcf.sddc.lab/suite-api/api/auth/token/aquire"
$headers = @{
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}

$body =@{
    "username" = "admin"
    "password" = "VMware123!"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri $opsUrl -Method 'POST' -Headers $headers -Body $body

$jResponse = $response | ConvertTo-Json

$jResponse