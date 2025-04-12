# AWG Application Development Environment

The AWG AppDev Environment is a reusable deployment artifact that is to be used as the base of a category of Applications. Within one Environment, multiple Applications can be created. And Application Environment must be deployed into an existing Application Platform.

One common pattern where this might make sense is in combining pre-prod environments:

+ AppDevPlat #1 (Labs)
  + AppDevEnv #1 (dev1)
    + Application A (dev1)
    + Application B (dev1)
    + Application C (dev1)
  + AppDevEnv #2 (sit1)
    + Application A (sit1)
    + Application B (sit1)
    + Application C (sit1)
  + AppDevEnv #3 (uat1)
    + Application A (uat1)
    + Application B (uat1)
    + Application C (uat1)
+ AppDevPlat #2 (Prod)
  + AppDevEnv #4 (prod)
    + Application A
    + Application B
    + Application C

In an example like the above two Azure subscriptions are used, with one AppDev environment instance per, to segment pre-production from production. Multiple AppDev environments are deployed into the Labs platform, with multiple applications in each of those.

+ AppDevPlat #1 (dev)
  + AppDevEnv #1 (dev1)
    + Application A (dev1)
    + Application B (dev1)
    + Application C (dev1)
  + AppDevEnv #2 (dev2)
    + Application A (dev2)
    + Application B (dev2)
    + Application C (dev2)
+ AppDevPlat #2 (sit)
  + AppDevEnv #3 (sit1)
    + Application A (sit1)
    + Application B (sit1)
    + Application C (sit1)
+ AppDevPlat #3 (uat)
  + AppDevEnv #4 (uat1)
    + Application A (uat1)
    + Application B (uat1)
    + Application C (uat1)
  + AppDevEnv #5 (uat2)
    + Application A (uat2)
    + Application B (uat2)
    + Application C (uat2)
+ AppDevPlat #4
  + AppDevEnv #6
    + Application A
    + Application B
    + Application C

In an example like the above, four Azure subscriptions are used to separate various types of pre-production applications: dev, sit and uat, but multiple environments with multiple applications exist in each.

An Application Development Environment contains unique:

+ Delegated Internal DNS Zone (dev1.labs.int.az.company.com)
+ Delegated Public DNS Zone (dev1.labs.az.company.com)
+ Azure Kubernetes Cluster

These resources are used to serve the various applications deployed within the environment. For instance, multiple applications deployed in the same Environment will be running on the same Kubernetes cluster.

# Usage

Deployment is driven by a PowerShell script named `deploy.ps1`. Arguments passed to this script configure its operation.

| Argument                          | Description
| ---                               | ---
| TfStateResourceGroupName          | Name of the resource group to hold the .tfstate file.
| TfStateStorageAccountName         | Name of the storage account to hold the .tfstate file.
| DefaultName                       | DefaultName should be a soft-globally unique identifier.
| ReleaseName                       | Represents the name of the specific release. Usually a version number.
| DefaultTags                       | Additional tags to place on resources.
| MetadataLocation                  | Location of ARM metadata: resource groups.
| ResourceLocation                  | Primary location of Azure resources.
| DnsZoneName                       | DNS zone name of the delegated public zone. Delegation is not handled.
| InternalDnsZoneName               | DNS zone name of the delegated private zone.
| VnetId                            | Full ARM ID of the virtual network to install into.
| AksVnetSubnetAddressPrefix        | Address prefix of the 'aks' subnet.
