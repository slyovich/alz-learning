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
  h1 {
    font-size: 1.3em;
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

# 🧪 Lab — Identities & App Registrations

### Sécuriser une API et configurer les clients Entra ID

**Auteur :** Sylvain Riquen, Cloud Technical Architecte  
**Date :** mars 2026  
**Audience :** Équipe Développement

---

<style scoped>
  blockquote {
    margin: 40px 0;
    font-size: 26px;
  }
  ul {
    font-size: 22px;
  }
</style>

# 📦 Objectif du Lab

## Ce que nous allons faire

- **Créer une App Registration** pour sécuriser une API Python (FastAPI)
- **Créer un Service Principal** (client) pour tester l'accès machine-to-machine
- **Configurer un client console** Python qui utilise le Client Credentials Flow
- **Créer une App Registration SPA** pour une application Angular
- Comprendre les **scopes**, **App Roles** et les **pre-authorized applications**

> 💡 **À la fin du lab**, vous aurez une API sécurisée, un client service-to-service fonctionnel, et une SPA Angular authentifiée via Entra ID.

---

# 📚 Agenda

1. Présentation de l'architecture
2. **Partie 1** — App Registration pour `hello-api`
3. **Partie 2** — Service Principal & `hello-client`
4. **Partie 3** — App Registration SPA & `hello-angular`
5. Récapitulatif & Q&A

---

<style scoped>
  pre, code {
    font-size: 14px;
    padding: 10px 10px;
  }
  h2 {
    font-size: 24px;
    margin-top: 20px;
  }
</style>

# 🏗️ Architecture Globale

## Vue d'ensemble des trois projets

```text
                       ┌───────────────────────────────────────┐
                       │            Microsoft Entra ID         │
                       │                                       │
                       │   ┌───────────────────────────────┐   │
                       │   │ App Registration: Hello API   │   │
                       │   │  • Scopes: access_as_user     │   │
                       │   │  • App Roles: Hello.Read,     │   │
          ┌────────────│───│    User.Read                  │   │
          │            │   │  • Pre-auth: hello-angular    │   │
          │            │   └───────────────────────────────┘   │
          │            │                                       │
          │            │   ┌────────────────────┐  ┌────────┐  │
          │            │   │ Hello API Client   │  │  SPA   │  │
          │            │   │ (Service Principal)│  │ hello- │  │
          │            │   │  client_secret     │  │ angular│  │
          │            │   └────────────────────┘  └────────┘  │
          │            └───────────────────────────────────────┘
          ▼                      ▼                       ▼
 ┌──────────────────┐    ┌──────────────┐        ┌──────────────┐
 │    hello-api     │    │ hello-client │        │ hello-angular│
 │   (FastAPI)      │    │ (Python CLI) │        │  (Angular)   │
 │  :8000           │    └──────────────┘        │  :4200       │
 └──────────────────┘                            └──────────────┘
```

---

<style scoped>
  ul {
    font-size: 22px;
    margin-top: 0px;
  }
  h2 {
    font-size: 30px;
    margin-top: 30px;
  }
  blockquote {
    font-size: 20px;
    margin-top: 30px;
    border-left: 5px solid #38bdf8;
  }
</style>

# 📋 Prérequis

## Avant de commencer

- **Python 3.10+** installé
- **Node.js ≥ 20** et npm installés
- **Accès au portail Azure** avec droits sur Entra ID
- **VSCode** ou un éditeur de code
- Les trois projets clonés localement :
  - `2-Identities/hello-api`
  - `2-Identities/hello-client`
  - `2-Identities/hello-angular`

> 💡 Notez votre **Tenant ID** — vous en aurez besoin à chaque étape. Vous le trouverez dans **Azure Portal → Microsoft Entra ID → Overview**.

> Les applications hello-* ont été **générées à l'aide de l'IA** et ne sont destinées qu'à être utilisées dans le cadre de ce lab. Elles ne sont pas conçues pour un usage en production.

---

<!-- _class: lead -->

# 🔵 Partie 1

## Sécuriser l'API — `hello-api`

---

<style scoped>
  ul {
    font-size: 20px;
    margin-top: 0px;
  }
  h2 {
    font-size: 26px;
    margin-top: 20px;
  }
  p, ol {
    font-size: 20px;
    margin-top: 0px;
  }
</style>

# 📝 Étape 1.1 — Créer l'App Registration

## Créer l'App Registration dans Entra ID

1. **Azure Portal** → **Microsoft Entra ID** → **App registrations** → **New registration**
2. Remplir le formulaire :
   - **Name** : `Hello World API`
   - **Supported account types** : *Accounts in this organizational directory only (Single tenant)*
   - **Redirect URI** : laisser vide (c'est une API, pas une app interactive)
3. Cliquer **Register**

## 📌 Valeurs à noter

Depuis la page **Overview** de votre App Registration :

- **Application (client) ID** → c'est votre `AZURE_CLIENT_ID`
- **Directory (tenant) ID** → c'est votre `AZURE_TENANT_ID`

> ⚠️ Gardez ces valeurs à portée de main, elles seront nécessaires tout au long du lab.

---

<style scoped>
  ul, ol {
    font-size: 20px;
    margin-top: 0px;
  }
  h2 {
    font-size: 26px;
    margin-top: 15px;
  }
  pre, code {
    font-size: 16px;
    margin-top: 0px;
  }
  blockquote {
    font-size: 20px;
    margin-top: 60px;
  }
</style>

# 📝 Étape 1.2 — Configurer les Access Tokens v2

## Pourquoi passer en v2 ?

- Par défaut, Entra ID émet des tokens **v1** (`iss` = `sts.windows.net/...`)
- La version **v2** utilise un format JWT standard et un claim `aud` qui correspond directement au **Client ID**

## Comment faire ?

1. Dans votre App Registration → **Manifest**
2. Chercher `requestedAccessTokenVersion` (ou `accessTokenAcceptedVersion`)
3. Changer la valeur de `null` à `2`
4. Cliquer **Save**

```json
{
  "accessTokenAcceptedVersion": 2
}
```

> 💡 Cette étape est **indispensable** pour que la validation JWT dans notre API fonctionne avec le claim `aud` = `Client ID` et le claim `iss`= `https://login.microsoftonline.com/{tenant-id}/v2.0`.

---

<style scoped>
  p {
    font-size: 20px;
    margin-top: 0px;
  }
  ul, ol {
    font-size: 18px;
    margin-top: 0px;
  }
  h2 {
    font-size: 26px;
    margin-top: 15px;
  }
  table {
    font-size: 16px;
    margin-bottom: 50px;
  }
</style>

# 📝 Étape 1.3 — Définir les App Roles

## Pourquoi des App Roles ?

Les App Roles contrôlent **qui** (utilisateur, groupe ou application) est autorisé à effectuer une action. C'est un modèle **admin-controlled** : seul un administrateur peut assigner les rôles.

## Créer les rôles

1. Dans l'App Registration **Hello World API** → **App roles** → **Create app role**
2. Créer les rôles suivants :

| Display Name | Value | Allowed Member Types | Description |
|---|---|---|---|
| **Hello Reader** | `Hello.Read` | Both (Users/Groups + Applications) | Can call the hello endpoints |
| **User Profile Reader** | `User.Read` | Both (Users/Groups + Applications) | Can call the /me endpoint |

## ⚠️ Important

- Le champ **Value** est ce qui apparaîtra dans le claim `roles` du token JWT
- **Both** permet d'assigner le rôle à des utilisateurs ET à des applications (service-to-service)

---

<style scoped>
  p {
    font-size: 20px;
  }
  ul, ol {
    font-size: 18px;
    margin-top: 0px;
  }
  h2 {
    font-size: 26px;
    margin-top: 15px;
  }
  table {
    font-size: 16px;
    margin-top: 50px;
    margin-bottom: 50px;
  }
</style>

# 💡 Scopes vs Roles

Les deux apparaissent comme des claims dans le token, mais suivent des modèles différents :

|                         | **Scopes** (`scp`)                          | **Roles** (`roles`)                                  |
|-------------------------|---------------------------------------------|------------------------------------------------------|
| **Model**               | Delegated permissions                       | Role-based permissions                               |
| **Who receives them**   | Users only (interactive flows)              | Users/groups **and** applications                    |
| **Who decides**         | The **user consents**                       | An **admin assigns**                                 |
| **Typical granularity** | Per-action (e.g. `Hello.Read`)              | Per-profile (e.g. `Admin`, `Reader`)                 |
| **Token claim**         | `scp` (space-separated string)              | `roles` (array of strings)                           |
| **Use case**            | "This app can read my greetings"            | "This user/app is an Admin"                          |

En résumé :

- **scopes** = l'*utilisateur* contrôle ce qu'une application peut faire en son nom ;
- **roles** = un *administrateur* contrôle qui a quel rôle.

Les deux peuvent coexister dans la même App Registration.

---

<style scoped>
  ul, ol {
    font-size: 20px;
    margin-top: 0px;
  }
  h2 {
    font-size: 26px;
    margin-top: 15px;
  }
  blockquote {
    font-size: 18px;
    margin-top: 50px;
  }
</style>

# 📝 Étape 1.4 — Créer un Service Principal

## Créer une App Registration pour tester l'API

1. **Azure Portal** → **Microsoft Entra ID** → **App registrations** → **New registration**
2. Remplir :
   - **Name** : `Hello API Client`
   - **Supported account types** : *Single tenant*
3. Cliquer **Register**
4. Noter le **Application (client) ID** → c'est le `AZURE_CLIENT_ID` du client

## Créer un Client Secret

1. Dans l'App Registration **Hello API Client** → **Certificates & secrets**
2. **New client secret**
   - **Description** : `Lab secret`
   - **Expires** : 6 months (ou la durée de votre choix)
3. Cliquer **Add**

> ⚠️ **Copiez immédiatement la valeur du secret !** Elle ne sera plus visible après avoir quitté la page.

---

<style scoped>
  ul, ol {
    font-size: 19px;
    margin-top: 0px;
  }
  h2 {
    font-size: 26px;
    margin-top: 15px;
  }
  blockquote {
    font-size: 18px;
    margin-top: 40px;
  }
</style>

# 📝 Étape 1.5 — Assigner les App Roles au Client

## Ajouter les permissions applicatives

1. Dans l'App Registration **Hello API Client** → **API permissions**
2. **Add a permission** → **APIs my organisation uses** → sélectionner **Hello World API**
3. Choisir **Application permissions** (et non Delegated)
4. Cocher `Hello.Read` et `User.Read`
5. Cliquer **Add permissions**

## Accorder le consentement admin

1. De retour dans **API permissions**, cliquer **Grant admin consent for \<votre tenant\>**
2. Confirmer

> 💡 **Pourquoi le consentement admin ?** Les Application permissions (client credentials flow) nécessitent **toujours** un consentement admin car il n'y a pas d'utilisateur interactif pour consentir.

> 🔑 **Ce qui se passe dans le token :** Lors de l'authentification, Entra ID insère les rôles consentis dans le claim `roles` du JWT : `["Hello.Read", "User.Read"]`.

---

<style scoped>
  pre {
    font-size: 24px;
    margin-top: 50px;
  }
  p {
    font-size: 24px;
    margin-top: 50px;
  }
</style>

# 📝 Étape 1.6 — Obtenir un token

```bash
TENANT_ID="<YOUR_TENANT_ID>"
CLIENT_ID="<YOUR_CLIENT_ID>"
CLIENT_SECRET="<YOUR_CLIENT_SECRET>"
API_CLIENT_ID="<YOUR_API_CLIENT_ID>"

# Request a token
TOKEN=$(curl -s -X POST \
  "https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=${CLIENT_ID}" \
  -d "client_secret=${CLIENT_SECRET}" \
  -d "scope=${API_CLIENT_ID}/.default" \
  -d "grant_type=client_credentials" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

echo $TOKEN
```

💡 Collez le token sur [jwt.ms](https://jwt.ms) pour visualiser les claims, notamment le claim `roles`

---

<style scoped>
  ul, ol {
    font-size: 18px;
    margin-top: 0px;
    margin-bottom: 10px;
  }
  h2 {
    font-size: 26px;
    margin-top: 15px;
  }
  p {
    font-size: 16px;
    margin-top: 0px;
  }
  pre {
    font-size: 18px;
    margin-top: 0px;
    margin-bottom: 20px;
  }
</style>

# 📝 Étape 1.7 — Lancer l'API

## Installer et démarrer `hello-api`

1. Ouvrir un terminal dans le dossier `2-Identities/hello-api`

2. Créer un environnement virtuel et installer les dépendances :

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

1. Configurer les variables d'environnement :

```bash
cp .env.example .env
```

1. Éditer `.env` avec les valeurs de l'étape 1.1 :

```env
AZURE_TENANT_ID=your-tenant-id
AZURE_CLIENT_ID=your-api-client-id
```

1. Démarrer l'API :

```bash
uvicorn main:app --reload
```

> ✅ L'API est accessible sur **<http://127.0.0.1:8000>** — testez `GET /` et `GET /health` dans votre navigateur. La doc Swagger est accessible sur **<http://127.0.0.1:8000/docs>**.

---

<style scoped>
  table {
    font-size: 16px;
    margin-top: 10px;
  }
  code {
    font-size: 16px;
  }
  h2 {
    font-size: 26px;
    margin-top: 20px;
  }
  ul {
    font-size: 18px;
    margin-top: 0px;
  }
</style>

# 📝 Étape 1.7 — Vérifier les endpoints

## Endpoints exposés par `hello-api`

| Méthode | Path | Auth | Rôle requis | Description |
|---|---|---|---|---|
| `GET` | `/` | ❌ | — | Info API & lien vers la doc |
| `GET` | `/health` | ❌ | — | Health-check |
| `GET` | `/hello` | ✅ | `Hello.Read` | Salue l'utilisateur authentifié |
| `GET` | `/hello/{name}` | ✅ | `Hello.Read` | Salue une personne spécifique |
| `GET` | `/me` | ✅ | `User.Read` | Retourne les claims de l'utilisateur |

## Tester avec token

```bash
# Hello (authenticated)
curl -H "Authorization: Bearer ${TOKEN}" http://127.0.0.1:8000/hello
```

## Tester sans token

```bash
curl http://127.0.0.1:8000/hello
# → 403 Forbidden
```

---

<!-- _class: lead -->

# 🟢 Partie 2

## Service-to-Service — `hello-client`

---

<style scoped>
  h1 {
    font-size: 1.2em;
  }
  h2 {
    font-size: 26px;
    margin-top: 15px;
  }
  pre, code {
    font-size: 14px;
    padding: 10px 10px;
  }
  blockquote {
    font-size: 16px;
    margin-top: 30px;
  }
</style>

# 📝 Étape 2.1 — Comprendre le Client Credentials Flow

## Séquence d'authentification

```text
┌───────────────────┐       ┌──────────────────┐       ┌──────────────┐
│   hello-client    │       │    Entra ID      │       │  hello-api   │
│   (Console App)   │       │    (Azure AD)    │       │  (FastAPI)   │
└───────────────────┘       └──────────────────┘       └──────────────┘
        │                            │                          │
        │ 1. POST /oauth2/v2.0/token                            │
        │    client_id +             │                          │
        │    client_secret +         │                          │
        │    scope=<api>/.default    │                          │
        │──────────────────────────▶│                          │
        │                            │                          │
        │◀──────────────────────────│                          │
        │ 2. Access Token            │                          │
        │    (avec claim roles)      │                          │
        │                            │                          │
        │ 3. GET /hello                                         │
        │    Authorization: Bearer <token>                      │
        │─────────────────────────────────────────────────────▶│
        │                                                       │
        │◀─────────────────────────────────────────────────────│
        │ 4. 200 OK { "message": "Hello, World!" }              │
```

> Le scope demandé est toujours `{api_client_id}/.default` — Entra ID retourne **tous** les App Roles consentis

---

<style scoped>
  h2 {
    font-size: 26px;
    margin-top: 15px;
  }
  pre {
    font-size: 16px;
    margin-top: 0px;
    margin-bottom: 20px;
  }
  ol {
    font-size: 20px;
    margin-top: 0px;
    margin-bottom: 10px;
  }
</style>

# 📝 Étape 2.2 — Configurer et lancer `hello-client`

## Installer et configurer

1. Ouvrir un **nouveau terminal** dans `2-Identities/hello-client`

2. Créer l'environnement et installer :

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

1. Configurer l'environnement :

```bash
cp .env.example .env
```

1. Éditer `.env` avec vos valeurs :

```env
AZURE_TENANT_ID=your-tenant-id
AZURE_CLIENT_ID=your-client-app-client-id      ← Hello API Client
AZURE_CLIENT_SECRET=your-client-secret          ← le secret copié à l'étape 1.4
API_CLIENT_ID=your-api-client-id                ← Hello World API
API_BASE_URL=http://127.0.0.1:8000
```

1. Lancer le client (assurez-vous que `hello-api` est toujours en cours d'exécution) :

```bash
python main.py
```

---

<style scoped>
  ul, ol {
    margin-top: 10px;
  }
  p, li {
    font-size: 18px;
    margin-top: 0px;
  }
  h2 {
    font-size: 26px;
    margin-top: 15px;
  }
  pre, code {
    font-size: 14px;
    margin-top: 0px;
  }
  blockquote > p {
    font-size: 24px;
    margin-top: 100px;
  }
</style>

# 📝 Étape 2.3 — Résultat attendu

## Ce que fait `hello-client`

Le client console exécute automatiquement les étapes suivantes :

1. **Affiche la configuration** — tenant, client ID, API cible
2. **Acquiert un access token** via MSAL (client credentials flow)
3. **Appelle les endpoints publics** — `GET /`, `GET /health` (sans token)
4. **Appelle les endpoints sécurisés** — `GET /hello`, `GET /hello/Sylvain`, `GET /me` (avec token)
5. **Appelle un endpoint sécurisé sans token** — pour démontrer l'erreur 403

## Vérification

- ✅ Les endpoints publics retournent **200 OK**
- ✅ Les endpoints sécurisés avec token retournent **200 OK** + les données
- ✅ L'endpoint sécurisé sans token retourne **403 Forbidden**

> 🎉 Si tout est vert, vous avez un flow **service-to-service** fonctionnel !

---

<!-- _class: lead -->

# 🟣 Partie 3

## Application Angular — `hello-angular`

---

<style scoped>
  p, ul, ol {
    font-size: 18px;
    margin-top: 0px;
  }
  h2 {
    font-size: 24px;
    margin-top: 15px;
  }
  blockquote {
    font-size: 16px;
    margin-top: 50px;
  }
</style>

# 📝 Étape 3.1 — Exposer un scope délégué sur l'API

## Pourquoi un scope si l'API utilise des App Roles ?

L'API autorise les requêtes via les **App Roles** (claim `roles`), pas les scopes délégués. Cependant, le flow OAuth 2.0 délégué (Authorization Code) **exige** au moins un scope délégué pour qu'Entra ID puisse émettre un access token pour la SPA.

## Configurer le scope

1. **Azure Portal → Entra ID → App registrations → Hello World API**
2. **Expose an API** → Cliquer **Add** à côté de *Application ID URI*
   - Accepter le format par défaut : `api://<client-id>`
3. **Add a scope** :
   - **Scope name** : `access_as_user`
   - **Who can consent** : *Admins and users*
   - **Admin consent display name** : `Access Hello API`
   - **Admin consent description** : `Allow the application to access Hello API on behalf of the signed-in user`
   - **State** : Enabled

> 💡 Ce scope agit comme un **"ticket d'entrée"** — l'API ne le valide pas côté serveur. L'autorisation réelle se fait via les App Roles.

---

<style scoped>
  ul, ol {
    font-size: 18px;
    margin-top: 0px;
  }
  h2 {
    font-size: 24px;
    margin-top: 15px;
  }
</style>

# 📝 Étape 3.2 — Créer l'App Registration SPA

## Enregistrer l'application Angular

1. **Azure Portal → Entra ID → App registrations → New registration**
2. Remplir :
   - **Name** : `hello-angular`
   - **Supported account types** : *Single tenant*
   - **Redirect URI** :
     - **Type** : *Single-page application (SPA)*
     - **URI** : `http://localhost:4200`
3. Cliquer **Register**
4. Noter le **Application (client) ID** — c'est le `clientId` pour `config.json`

## ⚠️ Points importants

- Le type de Redirect URI doit être **SPA** (et non Web) — cela active le **PKCE flow** approprié pour les applications côté client
- Pas besoin de client secret pour une SPA — MSAL utilise le **Authorization Code Flow avec PKCE**

---

<style scoped>
  ul, ol {
    font-size: 19px;
    margin-top: 0px;
  }
  h2 {
    font-size: 24px;
    margin-top: 15px;
  }
  table {
    font-size: 18px;
    margin-top: 10px;
  }
  blockquote {
    font-size: 17px;
    margin-top: 70px;
  }
</style>

# 📝 Étape 3.3 — Ajouter les API Permissions à la SPA

## Configurer les permissions déléguées

1. **Azure Portal → Entra ID → App registrations → hello-angular**
2. **API permissions** → **Add a permission** → **My APIs** → sélectionner **Hello World API**
3. Choisir **Delegated permissions** (et non Application)
4. Cocher `access_as_user`
5. Cliquer **Add permissions**

## Pourquoi Delegated et non Application ?

| Type | Contexte | Utilisé par |
|---|---|---|
| **Delegated** | L'app agit **au nom de l'utilisateur** connecté | SPA, Web Apps |
| **Application** | L'app agit **en son propre nom**, sans utilisateur | Services, Daemons |

> 💡 Une SPA Angular utilise le flow **Authorization Code + PKCE** — c'est un flow *interactif* qui implique un utilisateur. On utilise donc des **Delegated permissions**.

---

<style scoped>
  p, ul, ol {
    font-size: 18px;
    margin-top: 0px;
  }
  h2 {
    font-size: 24px;
    margin-top: 15px;
  }
  blockquote {
    font-size: 16px;
    margin-top: 50px;
  }
</style>

# 📝 Étape 3.4 — Pre-authoriser la SPA

## Pourquoi pré-autoriser ?

Si le **consent utilisateur est désactivé** dans votre tenant (politique courante en entreprise), les utilisateurs seront bloqués à la connexion. La pré-autorisation **bypass le prompt de consentement**.

## Configurer la pré-autorisation

1. **Azure Portal → Entra ID → App registrations → Hello World API**
2. **Expose an API** → **Authorized client applications** → **Add a client application**
3. Entrer le **Application (client) ID** de la SPA (`hello-angular`)
4. Cocher le scope `access_as_user`
5. Cliquer **Add application**

> 🔑 **Ce que cela signifie :** Entra ID considère la SPA comme un client de confiance — tout utilisateur qui peut se connecter peut accéder au scope `access_as_user` de l'API **sans être invité à consentir**.

> ⚠️ **Sans cette étape**, les utilisateurs dans un tenant où le consent est désactivé verront une erreur `AADSTS65001` ("The user or administrator has not consented to use the application").

---

<style scoped>
  h2 {
    font-size: 24px;
    margin-top: 15px;
  }
  pre, code {
    font-size: 12px;
    padding: 5px 5px;
    margin-top: 0px;
  }
  ul {
    font-size: 14px;
    margin-top: 40px;
  }
</style>

# 📝 Étape 3.5 — Comment tout s'articule

## Flow complet : SPA → Entra ID → API

```text
                    SPA demande : api://{apiClientId}/.default
                                │
                                ▼
                    ┌───────────────────────────────┐
                    │          Entra ID             │
                    │                               │
                    │  Client pré-autorisé ?        │
                    │  → hello-angular ✅           │  ← consent est bypassed
                    │                               │
                    │  Permission déléguée          │
                    │  → access_as_user ✅          │  ← requis pour le flow
                    │                               │
                    │  App Roles assignés au user   │
                    │  → Hello.Read ✅              │  ← contrôle l'autorisation
                    │  → User.Read  ✅              │
                    └───────────────┬───────────────┘
                                    │
                            Token contient :
                            • aud   = API client ID
                            • scp   = "access_as_user"   (non validé par l'API)
                            • roles = ["Hello.Read", …]   (validé par l'API ✅)
```

- Le **scope délégué** (`access_as_user`) est le ticket d'entrée pour obtenir un token
- La **pré-autorisation** supprime le prompt de consent
- L'**autorisation réelle** est faite par l'API sur le claim **`roles`**

---

<style scoped>
  h1 {
    font-size: 1.2em;
  }
  p, ul, ol {
    font-size: 18px;
    margin-top: 0px;
  }
  h2 {
    font-size: 24px;
    margin-top: 10px;
  }
</style>

# 📝 Étape 3.6 — Assigner les App Roles aux utilisateurs

## Donner les rôles aux utilisateurs de test

Pour que les utilisateurs puissent accéder aux endpoints sécurisés de l'API depuis la SPA, ils doivent avoir les **App Roles** assignés.

1. **Azure Portal → Entra ID → Enterprise Applications** → rechercher et sélectionner **Hello World API**
2. **Users and groups** → **Add user/group**
3. Sélectionner l'utilisateur (ou le groupe) de test
4. Choisir le rôle **Hello Reader** (`Hello.Read`)
5. Cliquer **Assign**
6. Répéter pour le rôle **User Profile Reader** (`User.Read`)

## ⚠️ Attention

- ❗ C'est dans **Enterprise Applications** (et non App registrations) qu'on assigne les rôles
- Les rôles sont visibles dans le token dans le claim `roles`
- Un utilisateur sans rôle assigné recevra un token **sans** claim `roles` → l'API retournera **403**

---

<style scoped>
  h2 {
    font-size: 24px;
    margin-top: 15px;
  }
  pre {
    font-size: 18px;
    margin-top: 0px;
    margin-bottom: 10px;
  }
  ol {
    font-size: 16px;
    margin-top: 0px;
  }
  blockquote {
    font-size: 16px;
    margin-top: 30px;
  }
</style>

# 📝 Étape 3.7 — Configurer et lancer `hello-angular`

## Installer et configurer

1. Ouvrir un terminal dans `2-Identities/hello-angular`

2. Installer les dépendances :

```bash
npm install
```

1. Créer le fichier de configuration :

```bash
cp public/config.example.json public/config.json
```

1. Éditer `public/config.json` :

```json
{
  "clientId": "YOUR_SPA_CLIENT_ID",
  "tenantId": "YOUR_TENANT_ID",
  "apiClientId": "YOUR_API_CLIENT_ID",
  "apiBaseUrl": "http://127.0.0.1:8000"
}
```

1. Lancer l'application (assurez-vous que `hello-api` tourne toujours) :

```bash
npm start
```

> ✅ L'application est accessible sur **<http://localhost:4200>**

---

<style scoped>
  table {
    font-size: 18px;
    margin-top: 10px;
  }
  h2 {
    font-size: 24px;
    margin-top: 20px;
  }
  ul, ol {
    font-size: 18px;
    margin-top: 0px;
  }
</style>

# 📝 Étape 3.8 — Tester l'application Angular

## Pages disponibles

| Route | Auth | Description |
|---|---|---|
| `/` | ❌ | Page d'accueil — status de l'API et health check |
| `/dashboard` | ✅ | Explorateur d'API interactif — appels aux endpoints sécurisés |
| `/profile` | ✅ | Visualisation de l'identité Entra ID et des claims du token |

## Parcours de test

1. Accéder à **<http://localhost:4200>** — vous devriez voir la page d'accueil
2. Cliquer sur **Login** — vous êtes redirigé vers Entra ID
3. Se connecter avec un utilisateur ayant les App Roles assignés
4. Naviguer vers **/dashboard** — tester les appels API :
   - `GET /hello` → devrait retourner un message de bienvenue
   - `GET /me` → devrait retourner les claims de votre identité
5. Naviguer vers **/profile** — visualiser les informations du token

## ✅ Vérifications

- Le token est automatiquement attaché par **MSAL Interceptor** (pas de gestion manuelle)
- Les endpoints publics ne reçoivent **pas** de token (configuré via `protectedResourceMap`)

---

<style scoped>
  h2 {
    font-size: 28px;
    margin-top: 20px;
  }
  pre, code {
    font-size: 12px;
    padding: 10px 10px;
    margin-top: 0px;
  }
  ul {
    font-size: 15px;
    margin-top: 50px;
  }
</style>

# 🧩 Récapitulatif — Les 3 App Registrations

## Vue d'ensemble

```text
 ┌────────────────────────────────────────────────────────────────────────┐
 │                         Microsoft Entra ID                             │
 ├────────────────────┬─────────────────────┬─────────────────────────────┤
 │ Hello World API    │ Hello API Client    │ hello-angular               │
 │ (App Registration) │ (Service Principal) │ (SPA App Registration)      │
 ├────────────────────┼─────────────────────┼─────────────────────────────┤
 │ • App Roles:       │ • Client secret     │ • Redirect URI: SPA         │
 │   Hello.Read       │ • Application perms │   http://localhost:4200     │
 │   User.Read        │   Hello.Read ✅     │ • Delegated perms           │
 │                    │   User.Read  ✅     │   access_as_user ✅         │
 │ • Scope:           │ • Admin consent ✅  │ • Pre-authorized ✅         │
 │   access_as_user   │                     │ • No secret needed          │
 │                    │                     │                             │
 │ • Token version: 2 │ • Flow:             │ • Flow:                     │
 │                    │   Client Credentials│   Auth Code + PKCE          │
 └────────────────────┴─────────────────────┴─────────────────────────────┘
```

- **Partie 1** : L'API définit les rôles et les scopes — c'est la **ressource protégée**
- **Partie 2** : Le client service utilise un secret — flow **machine-to-machine**
- **Partie 3** : La SPA utilise PKCE — flow **interactif** avec **consent bypassed**

---

<style scoped>
  table {
    font-size: 20px;
    margin-top: 40px;
  }
  h2 {
    font-size: 24px;
    margin-top: 15px;
  }
  h1 {
    font-size: 40px;
  }
  code {
    font-size: 20px;
  }
</style>

# 🔑 Comparaison des Flows

## Client Credentials vs Authorization Code + PKCE

| | **Client Credentials** (`hello-client`) | **Auth Code + PKCE** (`hello-angular`) |
|---|---|---|
| **Utilisateur** | ❌ Aucun — machine-to-machine | ✅ Utilisateur interactif |
| **Secret** | Client secret requis | ❌ Pas de secret (PKCE) |
| **Token claim** | `roles` (App Roles) | `roles` + `scp` (App Roles + Scopes) |
| **Scope demandé** | `{api}/.default` | `api://{api}/.default` |
| **Permissions** | Application permissions | Delegated permissions |
| **Consent** | Admin consent obligatoire | User consent (ou pré-auth) |
| **Cas d'usage** | Daemons, services, CI/CD | SPA, Web Apps, Mobile Apps |

---

<style scoped>
  p, ul {
    font-size: 20px;
    margin-top: 0px;
  }
  h2 {
    font-size: 26px;
    margin-top: 10px;
  }
  table {
    font-size: 18px;
    margin-top: 5px;
  }
  blockquote {
    font-size: 16px;
    margin-top: 20px;
  }
</style>

# 💡 Une seule App Registration pour tout ?

## Pourrait-on utiliser une seule App Reg pour la SPA et l'API ?

**Techniquement oui**, mais c'est **déconseillé**. Le SPA demanderait un token dont l'audience serait son propre `clientId`, et l'API validerait ce même ID. Ça fonctionne, mais…

## Pourquoi séparer ?

| Problème avec une seule App Reg | Impact |
|---|---|
| 🔐 **Mélange des responsabilités** | Un client public (SPA, sans secret) et une ressource protégée (API) partagent la même identité |
| 🎯 **Perte de sémantique de l'audience** | Le claim `aud` devrait identifier la *ressource cible*, pas le client lui-même |
| 🔀 **Pollution de la configuration** | Les redirect URIs (SPA), les scopes exposés (API) et les App Roles se retrouvent tous sur le même objet — la maintenance devient confuse |
| 📋 **Pas de pré-autorisation** | Le mécanisme *pre-authorized client* n'a de sens qu'entre entités distinctes. Dès lors, le consentement utilisateur serait requis pour chaque client. |
| 🔒 **Pas de contrôle granulaire** | On ne peut pas différencier les permissions par application cliente (via l'utilisation des scopes) |

> ✅ **Bonne pratique Microsoft :** **1 App Registration = 1 identité = 1 responsabilité**. Le SPA est un *client* qui demande des tokens pour une *ressource* (l'API) — deux entités, deux App Registrations.

---

<style scoped>
  ul {
    font-size: 22px;
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
  }
</style>

# 🎯 Take Away

## 🔐 App Registrations

- ✅ **Une App Registration par ressource** (API) — définit les rôles et scopes
- ✅ **Une App Registration par client** — chaque client a ses propres permissions
- ⚠️ Toujours utiliser **token v2** pour les nouvelles applications

## 🛡️ Bonnes pratiques

- ✅ **App Roles** pour l'autorisation côté API — contrôle admin
- ✅ **Scopes délégués** comme ticket d'entrée pour les flows interactifs
- ✅ **Pré-autoriser les SPA** pour bypasser le consent en entreprise
- ✅ **Principe du moindre privilège** — n'assigner que les rôles nécessaires

> 🏆 **Résumé :** L'App Registration est le template, le Service Principal est une identité technique. Les App Roles contrôlent l'autorisation, les scopes permettent le flow.

---

# ❓ Questions ?

**Contact :** <sriquen@vaudoise.ch>

**Teams :** #Cop Dev Azure
