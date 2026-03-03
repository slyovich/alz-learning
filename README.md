# 🎓 ALZ Learning — Azure Landing Zone Education

This repository is an **educational resource** for hands-on learning of Azure Landing Zone concepts, application security, and identity management in Azure.

It accompanies a series of presentations ([MARP](https://marp.app/) format) and hands-on labs designed to build skills on Azure fundamentals.

---

## 🎯 Purpose

Provide a progressive, structured learning environment covering:

- **Bootstrapping** an Azure Landing Zone with Infrastructure as Code (Bicep)
- **Securing applications** on Azure App Service (from public exposure to Zero Trust)
- **Identity and access management** with Microsoft Entra ID (RBAC, Managed Identities, App Registrations)

Each module contains runnable code, deployment scripts, and presentations to facilitate understanding.

---

## 📁 Repository Structure

```
alz-learning/
├── 0-bootstrap/          # Landing Zone bootstrapping
├── 1-AppService/         # Progressive App Service security
├── 2-Identities/         # Identities, access & secure communications
└── README.md
```

---

### 📦 `0-bootstrap/` — Landing Zone Bootstrapping

Infrastructure initialization using **Azure Bicep** and [Azure Verified Modules (AVM)](https://azure.github.io/Azure-Verified-Modules/).

| Module | Description |
|--------|-------------|
| `main.bicep` | Main deployment orchestrator |
| `modules/lz-vending.bicep` | Network configuration (VNet, subnets, NSG) and managed identity |
| `modules/dns-zones.bicep` | Private DNS zones for Private Links |
| `modules/resourcegroups.bicep` | Resource Group creation |
| `modules/storage.bicep` | Secure Storage Account for Terraform state |
| `modules/virtualmachine.bicep` | Ubuntu jumpbox VM + Azure Bastion |

---

### 🌐 `1-AppService/` — Securing Azure App Service

A progressive security journey for a Web App in **5 steps**, illustrated with a MARP presentation and Azure CLI scripts.

| Step | Topic | Script |
|------|-------|--------|
| 1 | Public App Service | `infra/0-default.sh` |
| 2 | IP Restrictions | `infra/1a-iprestrictions.sh`, `infra/1b-iprestrictions.sh` |
| 3 | Private Endpoint | `infra/2-privateendpoint.sh` |
| 3.5 | VNet Integration | `infra/3-vnetintegration.sh` |
| 4 | Application Gateway + WAF | — |
| 5 | Zero Trust + Entra ID (EasyAuth) | `infra/4-easyauth.sh` |

**Additional content:**

- `AzureAppService.md` — Full MARP presentation (from public to Zero Trust)
- `api/` — Demo Node.js API

---

### 🔐 `2-Identities/` — Identity & Access Management

Module dedicated to understanding **Azure identities** and **securing service-to-service communications** with Microsoft Entra ID.

| Content | Description |
|---------|-------------|
| `Identities and Access Management.md` | MARP presentation covering identity types, RBAC, App Registrations, and Workload Identity Federation |
| `hello-api/` | Python API (FastAPI) secured with Entra ID — token validation, scopes, and app roles |
| `hello-client/` | Python console app demonstrating service-to-service authentication (Client Credentials Flow) |
| `hello-angular/` | Angular application with MSAL authentication (Authorization Code Flow) |

---

## 🚀 Getting Started

### Prerequisites

- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed
- [Bicep CLI](https://learn.microsoft.com/azure/azure-resource-manager/bicep/install) installed (`az bicep install`)
- An Azure subscription with appropriate permissions
- Python 3.x (for the Identities module projects)
- Node.js (for the App Service module API and the Angular app)

### Quick Start

```sh
# Clone the repository
git clone <your-fork-url>
cd alz-learning

# Log in to Azure
az login
```

Each module can be explored independently — refer to the `README.md` in each subfolder for specific instructions.

---

## 📖 Additional Resources

- [Azure Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Azure Landing Zones](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/landing-zone/)
- [Microsoft Entra ID Documentation](https://learn.microsoft.com/entra/identity/)
- [Azure App Service Security Best Practices](https://learn.microsoft.com/azure/app-service/overview-security)
- [MSAL.js Documentation](https://learn.microsoft.com/entra/msal/js/)

---

## 📝 License

This repository is for educational use.
