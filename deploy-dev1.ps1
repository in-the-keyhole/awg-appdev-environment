#Requires -Version 7.4
#Requires -Modules Az.Accounts
#Requires -Modules powershell-yaml

[CmdletBinding(SupportsShouldProcess=$true)]

param(
    [ValidateSet('all', 'tf', 'xpkg', 'crossplane', 'helmsman')]
    [string]$Stage = 'all'
)

.\deploy.ps1 `
    -Stage $Stage `
    -TfStateResourceGroupName "rg-awg-appdev-labs-tfstate" `
    -TfStateStorageAccountName "awgappdevlabstfstate" `
    -DefaultName "awg-appdev-dev1" `
    -ReleaseName "1.0.0" `
    -DefaultTags @{} `
    -MetadataLocation "northcentralus" `
    -ResourceLocation "southcentralus" `
    -PlatformSubscriptionId "6190d2d3-f65d-4f7a-939e-ad9829c27fd5" `
    -PlatformName "awg-appdev-labs" `
    -PlatformDnsZoneName "labs.appdev.az.awginc.com" `
    -DnsZoneName "dev1.labs.appdev.az.awginc.com" `
    -PlatformInternalDnsZoneName "labs.appdev.az.int.awginc.com" `
    -InternalDnsZoneName "dev1.labs.appdev.az.int.awginc.com" `
    -InternalCaFingerprint "557cf983fe75a59c1d1dabbf49f7ff0617383a0ffd454bd06709a2c01effe8c1" `
    -AksVnetSubnetAddressPrefix "10.224.64.0/18" `
    -AksSkuName "Base" `
    -AksSkuTier "Free" `
    -AksAadAdminGroupObjectIds @() `
    -AksAvailabilityZones @() `
    -AksServiceCidr "192.168.0.0/16" `
    -AksDnsServiceIp "192.168.0.10" `
    -AksPodCidr "172.16.0.0/12" `
    -AksSysNodeSize "Standard_B4ms" `
    -AksSysMinNodeCount 1 `
    -AksSysMaxNodeCount 3 `
    -PrivateLinkZoneResourceGroupId "/subscriptions/6190d2d3-f65d-4f7a-939e-ad9829c27fd5/resourceGroups/rg-awg-hub"
    