# Variables
$namespace = "cci-config"
$supervisorName = "vcf-mgmt-vcenter:domain-c4001"

# Step 1: Get the current Supervisor resource YAML and save it to a file
kubectl get supervisor $supervisorName -n $namespace -o yaml > supervisor.yaml

# Step 2: Modify the YAML file

# Read the YAML file content into an array
$yamlContent = Get-Content -Path "supervisor.yaml"

# Modify the labels and add the regionNames field under spec:
$updatedYamlContent = @()
$labelsAdded = $false
$regionNamesAdded = $false

foreach ($line in $yamlContent) {
    # Add the environment label under the labels section if not already added
    if ($line -match "labels: \{\}") {
        $updatedYamlContent += $line.split("{")[0]
        $updatedYamlContent += "    environment: development"  # Proper indentation for environment label
        $labelsAdded = $true
    }
    # Add the regionNames under the spec section (after cloudAccountName) if not already added
    elseif ($line -match "cloudAccountName:" -and -not $regionNamesAdded) {
        $updatedYamlContent += $line
        $updatedYamlContent += "  regionNames:"  # Correct spacing and indentation
        $updatedYamlContent += "    - cci-region"  # Correct spacing and indentation for the region name list
        $regionNamesAdded = $true
    }
    else {
        $updatedYamlContent += $line
    }
}

# Step 3: Write the updated YAML content back to the file
Set-Content -Path "supervisor.yaml" -Value $updatedYamlContent

# Step 4: Apply the modified YAML back to the cluster
kubectl apply -f supervisor.yaml

# Cleanup: Remove the temporary file if needed
Remove-Item "supervisor.yaml"
