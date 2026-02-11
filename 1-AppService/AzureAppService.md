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
    padding: 20px 6px;
    border-radius: 3px;
    font-size: 25px;
  }
  table {
    font-size: 0.85em;
  }
  .columns {
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
---

# 🚀 Déploiement sécurisé Azure App Service

### De Public à Zero Trust

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
- Un parcours de sécurisation progressif d'une Web App
- De l'exposition publique naïve à une architecture Zero Trust
- Les impacts techniques à chaque étape

## Pourquoi ce talk ?
- La sécurité n'est pas une option, c'est une nécessité
- Comprendre les couches de défense en profondeur

> 💡 **Note :** Je ne touche aucune commission sur la vente d'App Services ! 💸😉

---

# 📚 Agenda

1. Architecture globale (5 étapes)
2. **Étape 1** : App Service Public
3. **Étape 2** : IP Restrictions
4. **Étape 3** : Private Endpoint
5. **Étape 4** : Application Gateway + WAF
6. **Étape 5** : Authentification Entra ID + mTLS
7. Matrice décisionnelle
8. Best Practices & Q&A

---

<style scoped>
  pre, code {
    font-size: 16px;
    padding: 10px 10px;
  }
</style>

# 🎯 Architecture globale

```
Étape 1 : Public
  Internet ←→ App Service (Public)

Étape 2 : IP Restrictions
  Internet ←→ [IP Whitelist] → App Service

Étape 3 : Private Endpoint
  VNet ←→ Private Endpoint ←→ App Service (Private)

Étape 3.5 : VNet Integration
  App Service ←→ VNet ←→ Firewall (Outbound control) ß←→ Internet

Étape 4 : Application Gateway + WAF
  Internet ←→ App Gateway (WAF) 
               ↓ Private
            VNet ←→ Private Endpoint ←→ App Service

Étape 5 : Zero Trust + Entra ID
  Internet ←→ App Gateway (WAF + mTLS (optional))
               ↓ Private
            VNet ←→ Private Endpoint ←→ App Service Auth
                        ↓ Authenticated user verification
                      Code applicatif
```

---

<style scoped>
  h2 {
    margin-top: 50px;
  }
</style>

# 🌐 Étape 1 : App Service PUBLIC

## Architecture
```
Internet ←→ App Service (Public IP + Default Domain)
           https://monapp.azurewebsites.net
```

## ✅ Ce qui marche

- ✅ Accès direct via browser depuis n'importe où
- ✅ Custom domain facile
- ✅ Dev/Test rapide

---

<style scoped>
  pre, code {
    font-size: 14px;
    padding: 10px 10px;
  }
</style>

# 🌐 Étape 1 : Limitations

## ❌ Limitations sécurité

- ❌ IP publique exposée (DDoS, scans)
- ❌ Pas de WAF (Web Application Firewall)
- ❌ N'importe qui peut accéder
- ❌ Pas de contrôle les flux sortants (ex. exfiltration de données, exploitation de vulnérabilités)

## Demo
```bash
# Deploy
az webapp create --resource-group myrg --name monapp-demo --runtime "NODE:20-lts"

# Accès public OK
curl https://monapp-demo.azurewebsites.net

# Voir la public IP
nslookup monapp-demo.azurewebsites.net
```

---

<style scoped>
  h2 {
    margin-top: 30px;
  }
</style>

# 🔐 Étape 2 : IP Restrictions

## Architecture
```
Internet ←→ [IP Whitelist] → App Service
            (403 si IP non autorisée)
```

## Changements

```bash
# Portal : Networking → Access Restrictions
# Ajouter règles :
# - Allow Dev Team : 203.0.113.0/24
# - Allow CI/CD : 198.51.100.0/25
# - Deny All (default)
```

---

<style scoped>
  h2 {
    font-size: 32px;
  }
  ul {
    font-size: 24px;
  }
</style>

# 🔐 Étape 2 : Capabilities

## ✅ Ce qui marche toujours

- ✅ Custom domain facile
- ✅ Dev/Test rapide

## ✅ Nouveautés

- ✅ **Contrôle d'accès par IP** Accès direct via browser depuis une IP autorisée
- ✅ Azure DevOps/CLI OK (IP agents connus)

## ❌ Impact applicatif

- ❌ IP publique exposée (DDoS, scans)
- ❌ Pas de WAF (Web Application Firewall)
- ❌ Pas de contrôle les flux sortants (ex. exfiltration de données, exploitation de vulnérabilités)

---

# 🔐 Étape 2 : Demo

```bash
# Restreindre à mon IP
Portal → Access Restrictions → Add Allow Rule → 203.0.113.100/32

# Test depuis IP non autorisée
curl https://monapp-demo.azurewebsites.net
# → 403 Forbidden ❌
```

---

<style scoped>
  h2 {
    margin-top: 60px;
  }
</style>

# 🔒 Étape 3 : Private Endpoint

## Architecture
```
VNet (10.0.0.0/16)
  └─ PE Subnet (10.0.0.0/24)
      └─ Private Endpoint NIC (10.0.0.10)
         ↓ Azure Backbone
        App Service (Disabled Public Access)

Internet ❌ (sauf via VPN/ExpressRoute)
```

<!--
---

# 🔒 Étape 3 : Setup

```bash
# 1. Créer Private DNS Zone
az network private-dns zone create \
  --name privatelink.azurewebsites.net \
  --resource-group myrg

# 2. Créer Private Endpoint
az network private-endpoint create \
  --name monapp-pe \
  --vnet-name myvnet \
  --subnet subnet-1 \
  --private-connection-resource-id \
    /subscriptions/.../monapp \
  --group-id sites

# 3. Désactiver accès public
Portal → Networking → Public Access = Disabled
```
-->
---

<style scoped>
  h2 {
    font-size: 30px;
    margin-top: 35px;
  }
  ul {
    font-size: 18px;
  }
</style>

# 🔒 Étape 3 : Capabilities

## ✅ Ce qui marche

- ✅ Accès depuis une ressource dans le VNet
- ✅ Custom domain (DNS privé)

## ✅ Nouveautés

- ✅ **Trafic inbound 100% privé** Azure backbone
- ✅ **NSG sur endpoint** Contrôle fine des flux entrants
- ✅ Zéro IP publique

## ❌ Impact applicatif

- ❌ Pas de WAF (Web Application Firewall)
- ❌ Pas de contrôle les flux sortants (ex. exfiltration de données, exploitation de vulnérabilités)

---

# 🔒 Étape 3 : Demo

```bash
# Depuis VM dans VNet (via Bastion)
# Test DNS
nslookup monapp.azurewebsites.net
# Result: monapp.privatelink.azurewebsites.net → 10.0.1.10

# Accès OK
curl https://monapp.azurewebsites.net
# ✅ 200 OK

# Depuis Internet
curl https://monapp.azurewebsites.net
# ❌ 403 / Connection Timeout
```

---

<style scoped>
  h2 {
    font-size: 28px;
  }
  ul {
    font-size: 18px;
  }
</style>

# 📤 Étape 3.5 : VNet Integration

## ✅ Concept

- Permet à l'App Service d'accéder aux ressources du VNet (SQL, Storage, On-prem).
- **Route All** : Force tout le trafic sortant (Internet inclus) à passer par le VNet.
- **Firewall** : Permet de forcer le routage du trafic sortant vers un Firewall.
- **Internet access** : Deny par défaut pour rendre l'exploitation d'une faille dans un conteneur plus complexe (ex. évite la création d'un reverse shell qui facilite l'exploitation).

## ⚙️ Configuration

- Subnet dédié avec délégation *Microsoft.Web/serverFarms*.
- Activation de l'option **VNet Route All**.

## 🛡️ Sécurité & Contrôle

- ✅ **Filtrage FQDN** : Sortie via Azure Firewall pour autoriser uniquement certains domaines.
- ✅ **NSG** : Contrôle des flux sortants directement sur le subnet d'intégration.
- ✅ **IP de sortie fixe** : Utilisation d'une NAT Gateway ou de l'IP du Firewall pour l'identification IP.

---

# 📤 Étape 3.5 : Demo

```bash
# Depuis VM dans VNet (via Bastion)
# Test DNS
nslookup monapp.azurewebsites.net
# Result: monapp.privatelink.azurewebsites.net → 10.0.1.10

# Accès en échec
curl https://monapp.azurewebsites.net
# ❌ 500 OK
# L'appel vers l'API publique échoue car le flux sortant du réseau est bloqué par une règle NSG
```

---

# 🛡️ Étape 4 : Application Gateway + WAF

## Architecture complète

```
Internet ←→ App Gateway (Public IP)
            - WAF (OWASP rules)
            - SSL Termination
            ↓ Private (Port 443)
         VNet ←→ PE → App Service
```

<!--
---

# 🛡️ Étape 4 : Setup

```bash
# 1. Créer App Gateway (WAF_v2)
az network application-gateway create \
  --name myappgw \
  --location eastus2 \
  --resource-group myrg \
  --sku WAF_v2

# 2. Backend Pool : Private Endpoint App Service
Portal → Backend Pools → Add
  → Target : FQDN → monapp.privatelink.azurewebsites.net

# 3. HTTP Settings (Port 443)
Portal → HTTP Settings → HTTPS → Port 443

# 4. WAF Policy (OWASP 3.1)
Portal → WAF Policy → Create
  → Rules : SQL Injection, XSS, Command Injection
```
-->

---

# 🛡️ Étape 4 : Capabilities

## ✅ Ce qui marche parfaitement

- ✅ **Custom domain public** (*.contoso.com)
- ✅ **WAF L7** (OWASP Top 10)
- ✅ **URL Path routing** (/api → backend1, /images → backend2)
- ✅ Session affinity
- ✅ Health probes

<!--
---

# 🛡️ Étape 4 : Capacités applicatives

## ✅ Nouveautés applicatives

```csharp
// Récupérer real client IP (pas App GW IP)
var clientIp = HttpContext.Connection.RemoteIpAddress;
// Via X-Forwarded-For header
var realIp = Request.Headers["X-Forwarded-For"];

// Forcer HTTPS (App GW termine SSL)
app.UseHttpsRedirection();

// Rewrites & redirects
app.MapGet("/old-api", () => Results.Redirect("/api/v2"));
```
-->

<!--
---

<style scoped>
  h2 {
    font-size: 32px;
  }
  ul {
    font-size: 24px;
  }
</style>

# 🛡️ Étape 4 : Impact

## ✅ Avantages

- ✅ Sécurité L7 (WAF)
- ✅ DDoS protection intégré
- ✅ Routing intelligent
- ✅ HTTPS global forcé

## ⚠️ Limitations

- ⚠️ Latence +0.1-0.2s (L7 inspection)
- ⚠️ Coût App Gateway (~0.25$/h) + WAF (~0.3$/h)

## ❌ Pas encore d'authentification

- ❌ Pas de vérification utilisateur au niveau infrastructure
-->

<!--
---

# 🛡️ Étape 4 : Demo

```bash
# Deploy App Gateway (template ARM pré-scripté)
# Pointer custom domain
Portal → Custom domains → contoso.com → App GW Public IP

# Test WAF : injection SQL
curl "https://contoso.com/?id=1' OR '1'='1"
# ❌ 403 Forbidden (WAF blocked)

# Test normal
curl https://contoso.com
# ✅ 200 OK

# URL routing
curl https://contoso.com/api
# → Backend pool : monapp-api

curl https://contoso.com/images
# → Backend pool : storage-static
```
-->

---

# 🔑 Étape 5 : Zero Trust + Entra ID

## Architecture finale

```
Internet ←→ App Gateway (WAF + mTLS (optional))
              ↓ Private
          VNet ←→ Private Endpoint ←→ App Service Auth
                      ↓ Authenticated user verification
                    Code applicatif
```
<!--
---

# 🔑 Étape 5 : Setup Entra ID

```bash
# 1. Enregistrer App Service dans Entra ID
Portal → App Service → Authentication → Add identity provider
  → Microsoft → Tenant : Default Tenant
  → Allow public access : No (force login)

# 2. App Gateway → Client Certificate (optionnel)
# Pour mTLS bidirectionnel
```
-->
---

<style scoped>
  ul {
    font-size: 20px;
  }
  pre, code {
    font-size: 12px;
  }
</style>

# 🔑 Étape 5 : Capabilities

## ✅ Ce qui marche parfaitement

- ✅ Accès public sécurisé (WAF + Auth)
- ✅ Custom domain + HTTPS forcé
- ✅ API protection via scopes Entra
- ✅ Audit logs complets (Activity Logs)

## ✅ Nouveautés applicatives

```csharp
// User claims depuis Entra ID
var userId = User.FindFirst("oid")?.Value;
var email = User.FindFirst("preferred_username")?.Value;

// RBAC dans code
if (User.IsInRole("Admin")) {
    // Action admin
}

// Token validation auto
// (middleware appliqué par App Service Auth)
```

<!--
---

# 🔑 Étape 5 : Demo

```bash
# Accès avant login
curl https://contoso.com
# → Redirect vers login Microsoft
# ✅ Popup login Entra ID

# Après login
# Token automatically added to headers
# Request → App Service → Claims extracted

# Code reçoit :
User.Identity.Name = "user@contoso.com"
User.FindFirst("preferred_username").Value = "alice.smith@contoso.com"
User.FindFirst("oid").Value = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```
-->

---

# 📊 Environnement d'entreprise

| Critère | Public | IP Restrict | Private EP | App GW | Zero Trust |
|---------|--------|-------------|------------|--------|------------|
| **Sandbox** | ✅ | ✅ | ⚠️ | ❌ | ❌ |
| **Landing Zone Online** | ✅ | ✅ | ⚠️ | ❌ | ✅✅ |
| **Landing Zone Corp** | ❌ | ❌ | ✅ | ✅ | ✅✅ |
<!--
---

<style scoped>
  h2 {
    font-size: 30px;
  }
  ul {
    font-size: 20px;
  }
  table{
    font-size: 20px;
  }
  blockquote {
    margin: 50px 0;
    font-size: 20px;
  }
</style>

# 💰 Détails coûts (Février 2026)

## App Service Tier

- **B1** (Basic, dev environment) : CHF 12.00/mois
- **P0V3** (Premium, prod environment) : CHF 55.00/mois

## Composants additionnels

| Composant | Coût |
|-----------|------|
| **Private Endpoint** | CHF 6.00/mois (incl. 10GB data transfer) |
| **App Gateway Standard** | CHF 160.00/mois (Standard_v2) |
| **App Gateway WAF** | CHF 275.00/mois (WAF_v2) |
| **Private DNS Zone** | CHF 1.00/mois |

> **Note** les coûts sont estimés en CHF pour la région Switzerland North
-->
<!--
---

# ✅ Best Practices

## Design & Gouvernance

```
✅ Utiliser Private Endpoint
✅ App Gateway + WAF
✅ Entra ID pour authentification (Zero Trust)
✅ Managed Identity (pas de secrets en code)
✅ Activity Logs + NSG Flow Logs monitoring
```

## IaC & Automation

```
✅ Bicep/Terraform modules
✅ Azure Policy : Enforce governance
✅ Azure DevOps : deploy automatisé
```

---

# ✅ Best Practices (suite)

## Sécurité réseau

```
✅ Firewall pour contrôle des flux réseau
✅ NSG sur Private Endpoint subnet (deny except from authorized sources)
```

## Monitoring & Auditing

```
✅ App Service logs → Log Analytics
✅ Application Gateway diagnostics
✅ Activity Logs (qui a changé quoi)
✅ Alertes : Failed requests, high latency
```
-->
---

# 🎓 Résumé

*Illustration du chemin parcouru*

---

# ❓ Questions ?

**Contact :** sriquen@vaudoise.ch

**Teams :** #Cop Dev Azure
