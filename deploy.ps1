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
    [Parameter(Mandatory)][string]$RootCaCerts,

    [string]$CoreSubscriptionId,
    [Parameter(Mandatory)][string]$CoreName,

    [Parameter(Mandatory)][string]$CoreDnsZoneName,
    [Parameter(Mandatory)][string]$DnsZoneName,
    [Parameter(Mandatory)][string]$AcmeServer,
    [Parameter(Mandatory)][string]$AcmeEmail,

    [Parameter(Mandatory)][string]$CoreInternalDnsZoneName,
    [Parameter(Mandatory)][string]$InternalDnsZoneName,
    [Parameter(Mandatory)][string]$InternalAcmeServer,
    [Parameter(Mandatory)][string]$InternalAcmeEmail,

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
        root_ca_certs = $RootCaCerts
        core_subscription_id = $CoreSubscriptionId
        core_name = $CoreName
        core_dns_zone_name = $CoreDnsZoneName
        dns_zone_name = $DnsZoneName
        acme_server = $AcmeServer
        acme_email = $AcmeEmail
        core_internal_dns_zone_name = $CoreInternalDnsZoneName
        internal_dns_zone_name = $InternalDnsZoneName
        internal_acme_server = $InternalAcmeServer
        internal_acme_email = $InternalAcmeEmail
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


