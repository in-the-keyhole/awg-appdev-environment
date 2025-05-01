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
    -RootCaCerts "-----BEGIN CERTIFICATE-----
MIIBbzCCARWgAwIBAgIQFhTlZWo+1Xt03/Yt7Z5vFTAKBggqhkjOPQQDAjAWMRQw
EgYDVQQDEwtBV0cgUm9vdCBDQTAeFw0yNTA1MDExNDI5MzNaFw0yNjA1MDEyMDI5
MzNaMBYxFDASBgNVBAMTC0FXRyBSb290IENBMFkwEwYHKoZIzj0CAQYIKoZIzj0D
AQcDQgAEkRC6p/SLzGj3EuMl1snPiFzXRIvokvmYyhEo6QU4ttziq+k7oN0ZgCkb
5X/3ucghkRa6eWkkIAjzMeDRUvHLuKNFMEMwDgYDVR0PAQH/BAQDAgEGMBIGA1Ud
EwEB/wQIMAYBAf8CAQgwHQYDVR0OBBYEFGgntOkALmE1hw7fzsSwK2nyF8LBMAoG
CCqGSM49BAMCA0gAMEUCIQDm+PvSpXXG2DzM7aDj4xj5QcVMfxjUjwnXmbIf7SEl
TAIgChzptgGUi7vBOmwPo8g8hZXX9GmWLIz8BgXR2Y0re4c=
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIBmDCCAT6gAwIBAgIQY3gBBnDS9vtFXZB9w+crNjAKBggqhkjOPQQDAjAWMRQw
EgYDVQQDEwtBV0cgUm9vdCBDQTAeFw0yNTA1MDExNDMwMDhaFw0yNjA1MDEyMDMw
MDVaMB4xHDAaBgNVBAMTE0FXRyBJbnRlcm1lZGlhdGUgQ0EwWTATBgcqhkjOPQIB
BggqhkjOPQMBBwNCAASgRnNo/RlTVeO3MHIO8doZqTUVsbo2DLfE7qdiT9FXGqo6
NH2PtQeoDaOWUG1ayyvjzj44vaqnz+QsA7EAJsCgo2YwZDAOBgNVHQ8BAf8EBAMC
AQYwEgYDVR0TAQH/BAgwBgEB/wIBCDAdBgNVHQ4EFgQUaT/TgAtvXs7pRleoPU/g
YS3SEIEwHwYDVR0jBBgwFoAUaCe06QAuYTWHDt/OxLArafIXwsEwCgYIKoZIzj0E
AwIDSAAwRQIgee7rakn2bIXmwSQatPea/OFoZA+b9JlcPBLKh7N0mPMCIQDM/TW8
BEIEn44KTQTn/jysfsJ6frKWMr/IQBddPLhI6Q==
-----END CERTIFICATE-----
" `
    -AcmeServer "https://acme-v02.api.letsencrypt.org/directory" `
    -AcmeEmail "jhaltom@keyholesoftware.com" `
    -PlatformInternalDnsZoneName "labs.appdev.az.int.awginc.com" `
    -InternalDnsZoneName "dev1.labs.appdev.az.int.awginc.com" `
    -InternalAcmeServer "https://ca.az.int.awginc.com/v1/pki/acme/directory" `
    -InternalAcmeEmail "jhaltom@keyholesoftware.com" `
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
    -AksSysMaxNodeCount 3
    