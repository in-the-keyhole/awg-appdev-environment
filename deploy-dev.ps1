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
    -DefaultName "awg-app" `
    -ReleaseName "1.0.0" `
    -DefaultTags @{} `
    -MetadataLocation "westus" `
    -ResourceLocation "eastus" `
    -DnsZoneName "app.pub.az.awg.ikvm.org" `
    -InternalDnsZoneName "app.int.az.awg.keyholesoftware.com" `
    -VnetAddressPrefix "10.224.0.0/16" `
    -DefaultVnetSubnetAddressPrefix "10.224.0.0/24" `
    -AksSkuName "Base" `
    -AksSkuTier "Free" `
    -AksAadAdminGroupObjectIds @() `
    -AksAvailabilityZones @() `
    -AksVnetSubnetAddressPrefix "10.224.1.0/24" `
    -AksServiceCidr "192.168.0.0/16" `
    -AksDnsServiceIp "192.168.0.10" `
    -AksPodCidr "172.16.0.0/12" `
    -AksSysNodeSize "Standard_B4ms" `
    -AksSysMinNodeCount 1 `
    -AksSysMaxNodeCount 3
