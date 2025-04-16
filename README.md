# AWG Application Development Environment

The AWG AppDev Environment is a reusable deployment artifact that is to be used as the base of a category of Applications. Within one Environment multiple Applications can be created. An Application Environment must be deployed into an existing Application Platform.

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

+ Delegated Internal DNS Zone (dev1.labs.az.int.company.com)
+ Delegated Public DNS Zone (dev1.labs.az.company.com)
+ Virtual Network Subnet
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

# Operation

The AWG Application Environment can be deployed multiple times into an Azure Subscription with each installation specifying a different `DefaultName` value of the form `awg-appdev-{name}`, and various variables associated with the hosting AWG Application Platform. Upon deployment by execution of the `deploy.ps1` script Terraform is used to begin the process. The user executing the deployment process needs full control over the target Azure subscription as well as mostly-full control over the referenced Platform subscription. They are likely to be the same subscription.

The following resources are created:

* A resource group for the resources associated with this deployment.
* A public DNS zone that is delegated within the specified `Platform` DNS zone. This delegation is handled automatically through Terraform.
* A private DNS Zone that is delegated within the specified private `Platform` DNS zone. A virtual network link is created automatically to the `Platform` virtual network.
* A virtual network subnet for the AKS cluster.
* A network security group for the AKS subnet.
* A public key resource to hold the public key for the AKS cluster. The key pair is generated automatically but the private key is forgotten.
* A user assigned managed identity for the AKS cluster.
  * This identity is assigned permission to resources that must be accessed by the AKS cluster:
    * `Network Contributor` to the AKS subnet for deployment of the internal load balancer.
    * `Private DNS Zone Contributor` to the private DNS zone specifically for the AKS cluster.
* An Azure Kubernetes Cluster.
  * In private mode.
  * Local accounts are disabled.
  * Workload Identity is enabled.
  * Automatic upgrade is enabled.
  * Image cleaner is enabled.
  * The previously mentioned user assigned identity is assigned as the kubelet identity.
  * Azure CNI with Cillium is used as the network plane. This reduces the number of IP addresses that is required.
  * The built-in Azure Istio package is enabled.
  * The built-in Azure KEDA package is enabled.
  * The built-in Azure VPA package is enabled.
  * The maintenance window is set to Sunday at midnight (CST).
  * A Crossplane user assigned identity is created.
    * Federated for upbound-provider-helm.
    * Federated for upbound-provider-azure.
* The AKS cluster is bootstrapped:
  * `runCommand` is used to install the Crossplane Helm chart.
  * `runCommand` is used to execute a series of Kubernetes manifests in `aks-bootstrap.yaml.tftpl`.
    * The Crossplane Helm provider is configured with a custom service account which has cluster-admin.
    * The Crossplane Helm provider is installed.
    * A Helm release is scheduled with Crossplane for the `awg-appdev-init` chart. This chart kicks off a process that no longer relies on Terraform.
    * The Crossplane Azure provider is configured to support Workload Identity.
    * The Crossplane Azure provider is installed.
    * A fixed list of additional Crossplane Azure provider(s) is installed. This is required since these require a custom `DeploymentRuntimeConfig` which cannot be done as a dependency or as a Helm chart.
* The Terraform script is over, and the remaining process is handled by `awg-appdev-init`. Consule `awg-appdev-modules` for a full explanation on its operation.
