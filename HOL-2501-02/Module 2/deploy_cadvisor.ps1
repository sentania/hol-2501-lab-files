# Starting TKC cluster
$VSPHERE_WITH_TANZU_CONTROL_PLANE_IP = '10.80.0.2'
$VSPHERE_WITH_TANZU_CLUSTER_NAMESPACE = 'rainpole'
$VSPHERE_WITH_TANZU_CLUSTER_NAME = 'dev-project'
$VSPHERE_WITH_TANZU_USERNAME = 'holadmin@vcf.holo.lab'
$ENV:KUBECTL_VSPHERE_PASSWORD = 'VMware123!'

# Connect to Supervisor cluster
Write-Output "Login to Supervisor Cluster $VSPHERE_WITH_TANZU_CONTROL_PLANE_IP"
kubectl vsphere login --vsphere-username $VSPHERE_WITH_TANZU_USERNAME --server=$VSPHERE_WITH_TANZU_CONTROL_PLANE_IP --tanzu-kubernetes-cluster-name $VSPHERE_WITH_TANZU_CLUSTER_NAME --tanzu-kubernetes-cluster-namespace $VSPHERE_WITH_TANZU_CLUSTER_NAMESPACE | Out-Null

Write-Output "Deploying the cadvisor app"
kubectl config use-context $VSPHERE_WITH_TANZU_CLUSTER_NAME
kubectl apply -f "C:\labfiles\HOL-2501-02\Module 2\cadvisor.yaml"
Do {
    Write-Output "Verifying the cadvisor app"
    Start-Sleep -s 20
    $pods = kubectl get pods -n kube-system -o json | ConvertFrom-Json
} While (($pods.items.metadata.name -like "cadvisor*").Count -eq 0)

Write-Output "cadvisor app deployment complete:"
kubectl get pods -n kube-system -l app=cadvisor -o wide
