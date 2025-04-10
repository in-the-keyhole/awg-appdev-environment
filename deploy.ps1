#Requires -Version 7.4
#Requires -Modules Az.Accounts
#Requires -Modules powershell-yaml

[CmdletBinding(SupportsShouldProcess=$true)]

param(
    [ValidateSet('all', 'tf', 'xpkg', 'crossplane', 'helmsman')]
    [string]$Stage = 'all',

    [string]$TfStateResourceGroupName = "tfstate",
    [string]$TfStateStorageAccountName = "awgapptfstate",

    [string]$DefaultName = 'awg-app',
    [string]$ReleaseName = '1.0.0',
    [hashtable]$DefaultTags = @{},
    
    [Parameter(Mandatory)][string]$MetadataLocation,
    [Parameter(Mandatory)][string]$ResourceLocation,

    [Parameter(Mandatory)][string]$DnsZoneName,
    [Parameter(Mandatory)][string]$InternalDnsZoneName,

    [Parameter(Mandatory)][string]$VnetAddressPrefix,
    [Parameter(Mandatory)][string]$DefaultVnetSubnetAddressPrefix,
    
    [string]$StorageAccountSkuName = 'Standard_LRS',
    
    [string]$AksSkuName = 'Basic',
    [string]$AksSkuTier = 'Free',
    [string[]]$AksAadAdminGroupObjectIds = @(),
    [string[]]$AksAvailabilityZones = @( '1', '2', '3' ),
    [Parameter(Mandatory)][string]$AksVnetSubnetAddressPrefix,
    [Parameter(Mandatory)][string]$AksServiceCidr,
    [Parameter(Mandatory)][string]$AksDnsServiceIp,
    [Parameter(Mandatory)][string]$AksPodCidr,
    [Parameter(Mandatory)][string]$AksSysNodeSize,
    [AllowNull()][Nullable[int]]$AksSysMinNodeCount = $null,
    [AllowNull()][Nullable[int]]$AksSysMaxNodeCount = $null
)

$ErrorActionPreference = "Stop"

if ((Get-Command 'az').CommandType -ne 'Application') {
    throw 'Missing az command.'
}

$SubscriptionId = $(az account show --query id --output tsv)
if (!$SubscriptionId) {
        throw 'Missing current Azure subscription.'
}

if ($Stage -eq 'all' -or $Stage -eq 'tf') {
    if ((Get-Command 'terraform').CommandType -ne 'Application') {
        throw 'Missing terraform command.'
    }

    @{
        subscription_id = $SubscriptionId
        default_name = $DefaultName
        release_name = $ReleaseName
        default_tags = $DefaultTags
        metadata_location = $MetadataLocation
        resource_location = $ResourceLocation
        dns_zone_name = $DnsZoneName
        int_dns_zone_name = $InternalDnsZoneName
        vnet_address_prefixes = @( $VnetAddressPrefix )
        default_vnet_subnet_address_prefixes = @( $DefaultVnetSubnetAddressPrefix )
        aks_sku_name = $AksSkuName
        aks_sku_tier = $AksSkuTier
        aks_aad_admin_group_object_ids = $AksAadAdminGroupObjectIds
        aks_availability_zones = $AksAvailabilityZones
        aks_vnet_subnet_address_prefixes = @( $AksVnetSubnetAddressPrefix )
        aks_service_cidr = $AksServiceCidr
        aks_dns_service_ip = $AksDnsServiceIp
        aks_pod_cidr = $AksPodCidr
        aks_sys_node_size = $AksSysNodeSize
        aks_sys_node_min_count = $AksSysMinNodeCount
        aks_sys_node_max_count = $AksSysMaxNodeCount
    } | ConvertTo-Json | Out-File .tf.tfvars.json

    Push-Location .\tf

    try {
        # configure terraform against target environment
        terraform init -reconfigure `
            -backend-config "subscription_id=$SubscriptionId" `
            -backend-config "resource_group_name=$TfStateResourceGroupName" `
            -backend-config "storage_account_name=$TfStateStorageAccountName" `
            -backend-config "container_name=tfstate" `
            -backend-config "key=${DefaultName}.tfstate"; if ($LASTEXITCODE -ne 0) { throw $LASTEXITCODE }

        # apply terraform against target environment
        terraform apply `
            -var-file="../.tf.tfvars.json" `
            -auto-approve; if ($LASTEXITCODE -ne 0) { throw $LASTEXITCODE }

    } finally {
        Pop-Location
    }
}

if ($Stage -eq 'all' -or $Stage -eq 'helmsman') {
    if ((Get-Command 'helmsman').CommandType -ne 'Application') {
        throw 'Missing helmsman command.'
    }

    # login to AKS
    az aks get-credentials -g "$DefaultName-aks" -n "$DefaultName" --overwrite-existing; if ($LASTEXITCODE -ne 0) { throw $LASTEXITCODE }

    Push-Location helmsman

    try {
        helmsman --apply -f helmsman.yaml
    } finally {
        Pop-Location
    }
}
