# resource helm_release "crossplane" {
#   name = "crossplane"
#   namespace = "crossplane-system"
#   repository = "https://charts.crossplane.io/stable"
#   chart = "crossplane"
#   version = "1.19.1"
#   create_namespace = true
#   atomic = true

#   # wait for the Crossplan CRDs to have been created
#   provisioner local-exec {
#     when = create
#     command = "kubectl wait --for=condition=Established crd configurations.pkg.crossplane.io"
#   }
# }

# # resource "kubernetes_manifest" "crossplane-configuration-awg-app-init" {
# #   manifest = {
# #     apiVersion = "pkg.crossplane.io/v1"
# #     kind = "Configuration"
# #     metadata = {
# #       name = "awg-configuration-app-init"
# #     apply -
# #     spec = {
# #       package = "${azurerm_container_registry.devops.login_server}/awg/app-init:123"
# #     }
# #   }

# #   depends_on = [ helm_release.crossplane ]
# # }

# resource "kubernetes_service_account" "crossplane-azure" {
#   metadata {
#     namespace = helm_release.crossplane.namespace
#     name = "azure"
#   }
# }

# # resource "kubernetes_manifest" "crossplane-provider-azure-family-config" {
# #   manifest = {
# #     apiVersion = "pkg.crossplane.io/v1beta1"
# #     kind = "DeploymentRuntimeConfig"
# #     metadata = {
# #       name = "provider-azure-family-config"
# #     }
# #     spec = {
# #       deploymentTemplate = {
# #         spec = {
# #           selector = {}
# #           template = {
# #             metadata = {
# #               labels = {
# #                 "azure.workload.identity/use" = "true"
# #               }
# #             }
# #             spec = {
# #               serviceAccountName = kubernetes_service_account.crossplane-azure.metadata[0].name
# #               containers = [
# #                 {
# #                   name = "package-runtime"
# #                   args = [
# #                     "--enable-external-secret-stores",
# #                     "--enable-management-policies"
# #                   ]
# #                 }
# #               ]
# #             }
# #           }
# #         }
# #       }
# #     }
# #   }
  
# #   depends_on = [
# #     helm_release.crossplane,
# #     kubernetes_manifest.crossplane-configuration-awg-app-init
# #   ]
# # }

# # resource "kubernetes_manifest" "crossplane-workload-identity-provider-config" {
# #   manifest = {
# #     apiVersion = "aws.crossplane.io/v1beta1"
# #     kind = "ProviderConfig"
# #     metadata = {
# #       name = "workload-identity-provider-config"
# #     }
# #     spec = {
# #       credentials = {
# #         source = "OIDCTokenFile"
# #       }
# #       oidcTokenFilePath = "/var/run/secrets/azure/tokens/azure-identity-token"
# #       clientID = azurerm_user_assigned_identity.crossplane.client_id
# #       subscriptionID = data.azurerm_client_config.current.subscription_id
# #       tenantID = azurerm_user_assigned_identity.crossplane.tenant_id
# #     }
# #   }
  
# #   depends_on = [
# #     helm_release.crossplane
# #   ]
# # }

# # locals {
# #   provider-family-azure-items = [
# #     { service = "managedidentity" },
# #     { service = "storage" },
# #     { service = "sql" },
# #     { service = "compute" },
# #     { service = "cosmosdb" },
# #     { service = "databricks" },
# #     { service = "dbformysql" },
# #     { service = "dbforpostgresql" },
# #     { service = "eventgrid" },
# #     { service = "insights" },
# #     { service = "keyvault" },
# #     { service = "logic" },
# #     { service = "maintenance" },
# #     { service = "network" },
# #     { service = "resources" },
# #     { service = "search" },
# #     { service = "servicebus" },
# #     { service = "signalrservice" },
# #     { service = "web" }
# #   ]
# # }

# # resource "kubernetes_manifest" "crossplane-provider-azure-items" {
# #   count = length(local.provider-family-azure-items)
# #   manifest = {
# #     apiVersion = "pkg.crossplane.io/v1"
# #     kind = "Provider"
# #     metadata = {
# #       name = "provider-azure-${local.provider-family-azure-items[count.index].service}"
# #     }
# #     spec = {
# #       package = "xpkg.upbound.io/upbound/provider-azure-${local.provider-family-azure-items[count.index].service}:v1"
# #       runtimeConfigRef = {
# #         name = "provider-azure-family-config"
# #       }
# #     }
# #   }

# #   depends_on = [
# #     helm_release.crossplane,
# #     kubernetes_manifest.crossplane-provider-family-azure
# #   ]
# # }

# # resource "kubernetes_manifest" "crossplane-conf-azure-network" {
# #   manifest = {
# #     apiVersion = "pkg.crossplane.io/v1"
# #     kind = "Configuration"
# #     metadata = {
# #       name = "configuration-azure-network"
# #     }
# #     spec = {
# #       package = "xpkg.upbound.io/upbound/configuration-azure-network:v0.15.0"
# #     }
# #   }

# #   depends_on = [
# #     helm_release.crossplane,
# #     kubernetes_manifest.crossplane-provider-family-azure
# #   ]
# # }

# # resource "kubernetes_manifest" "crossplane-conf-azure-database" {
# #   manifest = {
# #     apiVersion = "pkg.crossplane.io/v1"
# #     kind = "Configuration"
# #     metadata = {
# #       name = "configuration-azure-database"
# #     }
# #     spec = {
# #       package = "xpkg.upbound.io/upbound/configuration-azure-database:v0.15.0"
# #     }
# #   }

# #   depends_on = [
# #     helm_release.crossplane,
# #     kubernetes_manifest.crossplane-provider-family-azure
# #   ]
# # }

# # resource "kubernetes_manifest" "crossplane-conf-azure-platform-ref" {
# #   manifest = {
# #     apiVersion = "pkg.crossplane.io/v1"
# #     kind = "Configuration"
# #     metadata = {
# #       name = "configuration-azure-platform-ref"
# #     }
# #     spec = {
# #       package = "xpkg.upbound.io/upbound/platform-ref-azure:v0.13.0"
# #     }
# #   }

# #   depends_on = [
# #     helm_release.crossplane,
# #     kubernetes_manifest.crossplane-provider-family-azure
# #   ]
# # }
