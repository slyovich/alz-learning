---
marp: true
theme: gaia
paginate: true
size: 16:9
style: |
  section {
    background-color: #0f172a;
    color: #f1f5f9;
  }
  h1, h2, h3 {
    color: #38bdf8;
  }
  h2 {
    font-size: 1em;
  }
  pre, code {
    background-color: #1e293b;
    padding: 2px 2px;
    border-radius: 3px;
    font-size: 18px;
  }
  table {
    font-size: 0.85em;
  }
  .columns-1 {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 1rem;
  }
  .emoji-header {
    font-size: 10px;
  }
  ul {
    font-size: 0.7em;
  }

  /* ── Columns helper ── */
  .columns {
    display: grid;
    grid-template-columns: 1fr 2fr;
    gap: 30px;
  }
---

# 🫆 Identity and access management

### Comment sécuriser ses services Azure ?

**Auteur :** Sylvain Riquen, Cloud Technical Architecte  
**Date :** février 2026  
**Audience :** Équipe Développement

---

<style scoped>
  blockquote {
    margin: 70px 0;
    font-size: 26px;
  }
</style>

# 📦 Introduction

## Ce que nous allons voir

- Les différents types d'identités dans Azure (managed vs non-managed)
- Les types d'applications dans Entra ID
- La sécurisation RBAC des services Azure
- La sécurisation Entra ID des communications entre services

> 💡 **Objectif :** Comprendre comment Azure gère les identités pour sécuriser vos services et vos communications.

---

# 📚 Agenda

1. Types d'identités Azure
2. Identités managées (Managed Identities)
3. Identités non-managées (Service Principals & secrets)
4. App Registrations Entra ID
5. RBAC : sécuriser l'accès aux services Azure
6. Entra ID : sécuriser les communications entre services
7. Take Away & Q&A

---

<style scoped>
  table {
    font-size: 21px;
  }
  blockquote {
    font-size: 26px;
  }
</style>

# ⚖️ Types d'identités dans Azure

## Vue d'ensemble

| Type | Gestion des secrets | Cas d'usage | Risque |
|------|---------------------|-------------|--------|
| **User** | MFA / Password | Accès humain | Phishing, credential leak |
| **Managed Identity** | ❌ Aucun secret | Service Azure → Azure | ✅ Minimal |
| **Service Principal** | Secret / Certificat | CI/CD, apps externes | ⚠️ Rotation obligatoire |
| **Workload Identity Federation** | ❌ Aucun secret | GitHub Actions, GCP, AWS | ✅ Minimal |

---

<style scoped>
  ul {
    margin-top: 0px;
    font-size: 18px;
  }
  h2 {
    margin-top: 30px;
    font-size: 24px;
  }
</style>

# ✅ Managed Identities

## System-Assigned

- Liée au cycle de vie de la ressource Azure (App Service, VM, Function App…)
- Créée et supprimée automatiquement avec la ressource
- **1 identité = 1 ressource** (pas partageable)
- Idéal pour : accès simple à un Key Vault, Storage, SQL Database

## User-Assigned

- Créée indépendamment comme ressource Azure
- Peut être assignée à **plusieurs ressources**
- Persiste même si la ressource est supprimée
- Idéal pour : scénarios multi-services avec les mêmes droits

## 🔑 Point clé

- **Aucun secret à gérer** — Azure gère la rotation des tokens automatiquement
- Le token est obtenu via le **Instance Metadata Service (IMDS)** ou le SDK Azure
- S'utilise dans le code via `DefaultAzureCredential()`

---

<style scoped>
  h2 {
    margin-top: 30px;
    font-size: 24px;
  }
</style>

# ✅ Managed Identity : Exemple

## Accès à un Key Vault depuis un App Service

```csharp
// Aucun secret dans le code !
SecretClient client = new SecretClientBuilder()
    .vaultUrl("https://my-keyvault.vault.azure.net/")
    .credential(new DefaultAzureCredential()) // Utilise la Managed Identity
    .buildClient();

KeyVaultSecret secret = await client.GetSecretAsync("my-secret");
```

## Configuration Terraform

```hcl
resource "azurerm_linux_web_app" "app" {
  name = "my-app"
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "kv_access" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.app.identity[0].principal_id
}
```

---

<style scoped>
  ul {
    margin-top: 0px;
    font-size: 20px;
  }
  h2 {
    margin-top: 30px;
    font-size: 24px;
  }
</style>

# ⚠️ Service Principals

## Points clés

- Objet dans Entra ID représentant une identité technique
- Authentification via **secret** (mot de passe) ou **certificat**
- Nécessite une **rotation régulière** des credentials

## Quand les utiliser ?

- ✅ Applications qui tournent **hors Azure** (on-premise, autre cloud)
- ✅ Pipelines CI/CD (GitHub Actions, Azure DevOps) — **mais préférer Workload Identity Federation**
- ✅ Applications multi-tenant
- ✅ Lorsque les Managed Identities ne sont pas supportées (ex. Kafka Trigger)

## ❌ Risques

- 🔓 Secrets qui expirent → interruption de service
- 🔓 Secrets en clair dans la configuration → fuite possible
- 🔓 Pas de traçabilité fine (qui a utilisé le secret ?)

---

<style scoped>
  h2 {
    font-size: 24px;
  }
</style>

# ⚠️ Service Principals : Exemple

## Accès à un Key Vault depuis une application on-premise

```csharp
ClientSecretCredential clientSecretCredential = new ClientSecretCredentialBuilder()
  .clientId("<your client ID>")
  .clientSecret("<your client secret>") // ⚠️ Arg... il faut protéger ce secret!
  .tenantId("<your tenant ID>")
  .build();
  
SecretClient client = new SecretClientBuilder()
    .vaultUrl("https://my-keyvault.vault.azure.net/")
    .credential(clientSecretCredential)
    .buildClient();

KeyVaultSecret secret = await client.GetSecretAsync("my-secret");
```

## Configuration Terraform

```hcl
data "azuread_service_principal" "app" {
  display_name = "my-awesome-application"
}

resource "azurerm_role_assignment" "kv_access" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = data.azuread_service_principal.app.object_id
}
```

---

<style scoped>
  h2 {
    font-size: 26px;
  }
  p, ul {
    font-size: 20px;
    margin-top: 0px;
  }
  pre, code {
    font-size: 20px;
    padding: 10px 10px;
    margin-top: 0px;
  }
  .columns img {
    margin-top: 3px;
  }
</style>

# ✅ Workload Identity Federation

## Concept

Permet à une identité **externe** (ex. Azure DevOps Pipelines, GitHub Actions workflow, AKS Service Account) d'obtenir un token Azure **sans secret**. Ceci est une feature spécifique à Entra ID.

## Comment ça marche ?

<div class="columns">
<div>

![](https://learn.microsoft.com/fr-ch/entra/workload-id/media/workload-identity-federation/workflow.svg)

</div>
<div>

```
Le workload externe (ex. GitHub Actions workflow) demande et obtient un jeton auprès du fournisseur d'identité externe (GitHub)
    ↓ Présente le jeton à Entra ID
Entra ID vérifie le jeton ainsi que la relation de trust avec le fournisseur d'identité externe
    ↓ Emet un access token
Le workload externe utilise ce token pour accéder aux ressources
    ↓ Accède aux ressources
Storage / Key Vault / SQL / ...
```

</div>
</div>

## Avantages

- ✅ Aucun secret stocké dans Azure DevOps / CI
- ✅ Token éphémère (courte durée de vie)
- ✅ Granularité : restriction par projet, pipeline, environnement
- ✅ Audit complet dans Entra ID

---

<style scoped>
  h1 {
    font-size: 55px;
  }
  h2 {
    font-size: 20px;
  }
  pre, code {
    font-size: 12px;
    margin-top: 0px;
  }
</style>

# ✅ Workload Identity Federation : Exemple

## Accès à un Key Vault depuis un container AKS

```csharp
SecretClient client = new SecretClientBuilder()
    .vaultUrl("https://my-keyvault.vault.azure.net/")
    .credential(new DefaultAzureCredential())
    .buildClient();

KeyVaultSecret secret = await client.GetSecretAsync("my-secret");
```

## Configuration Terraform

```hcl
resource "azurerm_user_assigned_identity" "this" {
  location            = var.region.name
  name                = "id-aks-${var.region.shortname}-${var.environment}-001"
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_federated_identity_credential" "this" {
  name                = "fc-aks-${var.region.shortname}-${var.environment}"
  resource_group_name = azurerm_resource_group.this.name
  audience            = "api://AzureADTokenExchange"
  parent_id           = azurerm_user_assigned_identity.this.id
  issuer              = var.issuer
  subject             = "system:serviceaccount:dci:myserviceaccountname"
}

resource "azurerm_role_assignment" "kv_access" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.this.principal_id
}
```

---

<style scoped>
  table {
    font-size: 18px;
  }
  h2 {
    font-size: 24px;
    margin-top: 20px;
  }
  ul {
    font-size: 14px;
    margin-top: 0px;
    margin-left: 0px;
  }
  blockquote {
    font-size: 16px;
    margin-top: 40px;
    margin-left: 0px;
    border-left: 5px solid #38bdf8;
  }
</style>

# 🧑‍💻 App Registrations

## Application Object

- Une application doit être enregistrée auprès d’un Tenant Microsoft Entra pour pouvoir utiliser les fonctions de gestion des identités et des accès de Microsoft Entra ID.
- Cet objet agit comme le template où sont configurées diverses choses comme les API permissions, les secrets, le branding, les app roles, etc.
- L’Application Object décrit trois aspects d’une application:
  - comment Entra ID peut émettre des jetons pour accéder à l’application
  - les ressources auxquelles l’application peut avoir besoin d’accéder
  - les actions que l’application peut prendre.

## Service Principal Object

- Chaque Application Object peut être associé à un service principal object (Enterprise Application).
- Un Service Principal est une instance concrète créée à partir de l'Application Object et hérite de certaines propriétés de cet objet d’application.
- Un Service Principal est créé dans chaque Tenant où l’application est utilisée et fait référence à l’Application Object unique à l’échelle mondiale.
- L’objet Service Principal définit
  - ce que l’application peut réellement faire dans le Tenant spécifique,
  - qui peut accéder à l’application,
  - à quelles ressources l’application peut accéder.

> 💡 Semblable à une classe en programmation orientée objet, l’Application Object possède des propriétés statiques qui sont appliquées à tous les Service Principals créés.

---

<style scoped>
  ul {
    font-size: 0.65em;
    margin-top: 0px;
  }
  h2 {
    margin-top: 20px;
    font-size: 28px;
  }
  blockquote {
    font-size: 20px;
    margin-top: 10px;
    margin-left: 0px;
    border-left: 5px solid #38bdf8;
  }
  pre, code {
    font-size: 1em;
  }
</style>

# 🔐 API Permissions Entra ID

## Delegated vs Application Permissions

- **Delegated** : l'application agit **au nom de l'utilisateur** connecté
  - Exemple : lire les mails de l'utilisateur (`Mail.Read`)
  - Soumis au consentement de l'utilisateur ou de l'admin
- **Application** : l'application agit **en son propre nom** (sans utilisateur)
  - Exemple : lire tous les mails du tenant (`Mail.Read` application)
  - Requiert le **consentement admin** obligatoirement

## Scopes et rôles applicatifs

- **Scopes (OAuth2)** : permissions fines exposées par une API (ex. `api://my-app/Data.Read`)
- **App Roles** : rôles définis dans l'App Registration, assignés à des utilisateurs/groupes/apps
  - Idéal pour RBAC applicatif (ex. `Admin`, `Reader`, `Contributor`)

## ⚠️ Principe du moindre privilège

> Ne jamais donner plus de permissions que nécessaire. Préférer les **Delegated** quand possible.

---

<style scoped>
  ul, table {
    font-size: 18px;
    margin-top: 10px;
  }
  h2 {
    font-size: 28px;
    margin-top: 25px;
  }
  table {
    font-size: 16px;
  }
</style>

# 🛡️ RBAC : Sécuriser les services Azure

## Concept

- **RBAC (Role-Based Access Control)** = Qui (**principal**) peut faire quoi (**rôle**) sur quoi (**scope**)
- Hiérarchie des scopes : **Subscription → Resource Group → Resource**

## Rôles Built-in courants

| Rôle | Description |
|------|-------------|
| **Owner** | Accès total + gestion RBAC |
| **Contributor** | Accès total **sauf** gestion RBAC |
| **Reader** | Lecture seule |
| **Key Vault Secrets User** | Lire les secrets Key Vault |
| **Storage Blob Data Reader** | Lire les blobs Storage |

## ⚠️ Bonnes pratiques

- ✅ Assigner les rôles au **plus petit scope** possible (ex. Storage Account plutôt que Resource Group)
- ✅ Utiliser les **groupes Entra ID** plutôt que les assignations individuelles (enforcer par Azure Policies)

---

<style scoped>
  pre, code {
    font-size: 14px;
    padding: 10px 10px;
  }
</style>

# 🛡️ RBAC : Exemple Terraform

## Assigner un rôle à une Managed Identity

```hcl
# L'App Service accède au Storage Account en lecture
resource "azurerm_role_assignment" "app_to_storage" {
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_linux_web_app.app.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

# L'App Service accède au Key Vault
resource "azurerm_role_assignment" "app_to_kv" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.app.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

# Un groupe Entra ID a le rôle Reader sur le Resource Group
resource "azurerm_role_assignment" "group_reader" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Reader"
  principal_id         = data.azuread_group.dev_team.object_id
  principal_type       = "Group"
}
```

<!--
---

<style scoped>
  pre, code {
    font-size: 15px;
    padding: 10px 10px;
  }
  h1 {
    font-size: 40px;
  }
  h2 {
    font-size: 30px;
    margin-top: 35px;
  }
  h3 {
    font-size: 26px;
    margin-top: 45px;
  }
  ol {
    margin-top: 0px;
    margin-left: 0px;
    font-size: 20px;
  }
  p {
    font-size: 18px;
  }
</style>

# 🔄 Entra ID : sécuriser les communications entre services

## Use Cases

<div class="columns-1">
<div>

### Authentification utilisateur

Un utilisateur se connecte à une application web qui consomme une API protégée par Entra ID.

```
Utilisateur
    ↓ Token request (Authorization Code Flow)
Entra ID
    ↓ ID Token + Access Token (audience = target API)
API Backend
    ↓ Valide le token (issuer + audience + claims)
Réponse
```

</div>
<div>

### Authentification service-à-service

Un service client (ex. eFNOL backend) accède à une API protégée par Entra ID.

```
Service client (ex. Managed Identity)
    ↓ Token request (Client Credentials Flow)
Entra ID
    ↓ Access Token (audience = target API)
API Backend
    ↓ Valide le token (issuer + audience + claims)
Réponse
```

</div>
</div>

---

- Configurer l'app registration pour la Web API
- Configurer l'app registration pour le service client
- Faire une demo avec Postman
- Faire une demo avec un service client (ex. console app)

---

<style scoped>
  h1 {
    font-size: 34px;
  }
  h2 {
    font-size: 28px;
  }
  pre, code {
    font-size: 14px;
    padding: 10px 10px;
  }
</style>

# 🔄 Entra ID : sécuriser les communications entre services : Exemple

## App Service → API protégée par Entra ID

```csharp
// Service A : Obtenir un token pour appeler Service B
var credential = new DefaultAzureCredential();
var token = await credential.GetTokenAsync(
    new TokenRequestContext(new[] { "api://service-b/.default" })
);

// Appeler Service B avec le token
var httpClient = new HttpClient();
httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token.Token);

var response = await httpClient.GetAsync("https://service-b.azurewebsites.net/api/data");
```

```csharp
// Service B : Valider le token (Program.cs)
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddMicrosoftIdentityWebApi(builder.Configuration.GetSection("AzureAd"));

// Seules les identités autorisées peuvent accéder
builder.Services.AddAuthorization(options => {
    options.AddPolicy("ServiceOnly", policy =>
        policy.RequireClaim("oid", "<service-a-object-id>"));
});
```

---

<style scoped>
  ul {
    font-size: 0.6em;
  }
  h2 {
    margin-top: 20px;
    font-size: 0.9em;
  }
</style>

# 🔐 Rôle de chaque couche

## 🧑 Utilisateur / Browser

- Initie la connexion et fournit les credentials (MFA)
- Reçoit le contenu de la page après authentification

## 🌐 App Service (Backend)

- Redirige l'utilisateur non-authentifié vers Entra ID
- Échange le **code d'autorisation** contre les tokens (id, access, refresh)
- Stocke les tokens en session côté serveur (**confidential client**)
- Utilise le **access token** pour appeler les API backend

## 🔑 Entra ID (Identity Provider)

- Authentifie l'utilisateur (password + MFA)
- Émet les tokens (id_token, access_token, refresh_token)
- Valide les scopes et le consentement
- Point central de **SSO** et de gestion des sessions

## 🗄️ API Backend

- Valide le **Bearer token** (signature, audience, expiration)
- Applique l'autorisation basée sur les **claims** et **rôles** du token

-->
---

<style scoped>
  ul {
    font-size: 24px;
    margin-top: 10px;
  }
  h2 {
    font-size: 36px;
    margin-top: 40px;
  }
  blockquote {
    font-size: 20px;
    margin-top: 50px;
    margin-left: 0px;
    border-left: 5px solid #38bdf8;
  }
</style>

# 🎯 Take Away

## 🔑 Identités

- ✅ **Toujours préférer les Managed Identities** — aucun secret à gérer
- ✅ Utiliser **Workload Identity Federation** pour AKS
- ⚠️ Service Principal uniquement si pas d'alternative (apps multi-cloud, on-prem)

## 🛡️ RBAC & Sécurité

- ✅ Appliquer le **principe du moindre privilège**
- ✅ Assigner les rôles via des **groupes Entra ID**
- ✅ Assigner les rôles au plus petit scope possible

<!-- ## 🔄 Service-à-service

- ✅ Le token remplace le secret — **Zero credentials dans le code**
- ✅ Chaque service a **sa propre identité** et ses **permissions minimales**
- ✅ Valider le token côté récepteur (audience, issuer, claims) -->

> 🏆 **Résumé en une phrase :** Pas de secrets, des identités managées, du RBAC au moindre privilège.

---

# ❓ Questions ?

**Contact :** <sriquen@vaudoise.ch>

**Teams :** #Cop Dev Azure
