#Requires -Version 7.4
#Requires -Modules Az.Accounts
#Requires -Modules powershell-yaml

[CmdletBinding(SupportsShouldProcess=$true)]

param(
    [ValidateSet('all', 'bicep', 'terraform', 'helm')]
    [string]$Stage = 'all',

    [Parameter(Mandatory)][string]$TfStateResourceGroupName,
    [Parameter(Mandatory)][string]$TfStateStorageAccountName,

    [Parameter(Mandatory)][string]$DefaultName,
    [Parameter(Mandatory)][string]$ReleaseName,
    [hashtable]$DefaultTags = @{},
    
    [Parameter(Mandatory)][string]$MetadataLocation,
    [Parameter(Mandatory)][string]$ResourceLocation,

    [string]$PlatformSubscriptionId,
    [Parameter(Mandatory)][string]$PlatformName,

    [Parameter(Mandatory)][string]$PlatformDnsZoneName,
    [Parameter(Mandatory)][string]$DnsZoneName,
    [Parameter(Mandatory)][string]$PlatformInternalDnsZoneName,
    [Parameter(Mandatory)][string]$InternalDnsZoneName,

    [Parameter(Mandatory)][string]$AksVnetSubnetAddressPrefix,

    [string]$AksSkuName = 'Basic',
    [string]$AksSkuTier = 'Free',
    [string[]]$AksAadAdminGroupObjectIds = @(),
    [string[]]$AksAvailabilityZones = @( '1', '2', '3' ),
    [Parameter(Mandatory)][string]$AksServiceCidr,
    [Parameter(Mandatory)][string]$AksDnsServiceIp,
    [Parameter(Mandatory)][string]$AksPodCidr,
    [Parameter(Mandatory)][string]$AksSysNodeSize,
    [AllowNull()][Nullable[int]]$AksSysMinNodeCount = $null,
    [AllowNull()][Nullable[int]]$AksSysMaxNodeCount = $null,

    [Parameter(Mandatory)][string]$PrivateLinkZoneResourceGroupId
)

$ErrorActionPreference = "Stop"

if ((Get-Command 'az').CommandType -ne 'Application') {
    throw 'Missing az command.'
}

$SubscriptionId = $(az account show --query id --output tsv)
if (!$SubscriptionId) {
        throw 'Missing current Azure subscription.'
}

if ($Stage -eq 'all' -or $Stage -eq 'bicep') {
    # create tfstate resource group
    az group create -l $MetadataLocation -n $TfStateResourceGroupName `
    ; if ($LASTEXITCODE -ne 0) { throw $LASTEXITCODE }

    # use bicep for initial tfstate deployment
    az deployment group create `
        --resource-group $TfStateResourceGroupName `
        --template-file tfstate.bicep `
        --parameters resourceLocation="$ResourceLocation" `
        --parameters storageAccountName="$TfStateStorageAccountName" `
        ; if ($LASTEXITCODE -ne 0) { throw $LASTEXITCODE }
}

if ($Stage -eq 'all' -or $Stage -eq 'tf') {
    if ((Get-Command 'terraform').CommandType -ne 'Application') {
        throw 'Missing terraform command.'
    }

    New-Item -ItemType Directory .tmp -Force | Out-Null

    @{
        subscription_id = $SubscriptionId
        default_name = $DefaultName
        release_name = $ReleaseName
        default_tags = $DefaultTags
        metadata_location = $MetadataLocation
        resource_location = $ResourceLocation
        platform_subscription_id = $PlatformSubscriptionId
        platform_name = $PlatformName
        platform_dns_zone_name = $PlatformDnsZoneName
        dns_zone_name = $DnsZoneName
        platform_internal_dns_zone_name = $PlatformInternalDnsZoneName
        internal_dns_zone_name = $InternalDnsZoneName
        aks_vnet_subnet_address_prefixes = @( $AksVnetSubnetAddressPrefix )
        aks_sku_name = $AksSkuName
        aks_sku_tier = $AksSkuTier
        aks_aad_admin_group_object_ids = $AksAadAdminGroupObjectIds
        aks_availability_zones = $AksAvailabilityZones
        aks_service_cidr = $AksServiceCidr
        aks_dns_service_ip = $AksDnsServiceIp
        aks_pod_cidr = $AksPodCidr
        aks_sys_node_size = $AksSysNodeSize
        aks_sys_node_min_count = $AksSysMinNodeCount
        aks_sys_node_max_count = $AksSysMaxNodeCount
        privatelink_zone_resource_group_id = $PrivateLinkZoneResourceGroupId
    } | ConvertTo-Json | Out-File .tmp/${DefaultName}.tfvars.json

    Push-Location .\terraform

    try {
        # configure terraform against target environment
        terraform init -reconfigure `
            -backend-config "subscription_id=${SubscriptionId}" `
            -backend-config "resource_group_name=${TfStateResourceGroupName}" `
            -backend-config "storage_account_name=${TfStateStorageAccountName}" `
            -backend-config "container_name=tfstate" `
            -backend-config "key=${DefaultName}.tfstate" `
            ; if ($LASTEXITCODE -ne 0) { throw $LASTEXITCODE }

        # apply terraform against target environment
        terraform apply `
            -var-file="../.tmp/${DefaultName}.tfvars.json" `
            -auto-approve `
            ; if ($LASTEXITCODE -ne 0) { throw $LASTEXITCODE }

    } finally {
        Pop-Location
    }
}


