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

### Securing an API and configuring Entra ID clients

**Author:** Sylvain Riquen, Cloud Technical Architect  
**Date:** March 2026  
**Audience:** Development Team

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

# 📦 Lab Objective

## What we will do

- **Create an App Registration** to secure a Python API (FastAPI)
- **Create a Service Principal** (client) to test machine-to-machine access
- **Configure a console client** in Python that uses the Client Credentials Flow
- **Create a SPA App Registration** for an Angular application
- Understand **scopes**, **App Roles**, and **pre-authorized applications**

> 💡 **By the end of this lab**, you will have a secured API, a working service-to-service client, and an Angular SPA authenticated via Entra ID.

---

# 📚 Agenda

1. Architecture overview
2. **Part 1** — App Registration for `hello-api`
3. **Part 2** — Service Principal & `hello-client`
4. **Part 3** — SPA App Registration & `hello-angular`
5. Recap & Q&A

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

# 🏗️ Overall Architecture

## Overview of the three projects

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

# 📋 Prerequisites

## Before you begin

- **Python 3.10+** installed
- **Node.js ≥ 20** and npm installed
- **Access to the Azure Portal** with permissions on Entra ID
- **VSCode** or a code editor
- The three projects cloned locally:
  - `2-Identities/hello-api`
  - `2-Identities/hello-client`
  - `2-Identities/hello-angular`

> 💡 Note your **Tenant ID** — you will need it at every step. You can find it under **Azure Portal → Microsoft Entra ID → Overview**.

> The `hello-*` applications were **generated using AI** and are intended solely for use within this lab. They are not designed for production use.

---

<!-- _class: lead -->

# 🔵 Part 1

## Securing the API — `hello-api`

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

# 📝 Step 1.1 — Create the App Registration

## Create the App Registration in Entra ID

1. **Azure Portal** → **Microsoft Entra ID** → **App registrations** → **New registration**
2. Fill in the form:
   - **Name**: `Hello World API`
   - **Supported account types**: *Accounts in this organizational directory only (Single tenant)*
   - **Redirect URI**: leave empty (this is an API, not an interactive app)
3. Click **Register**

## 📌 Values to note

From the **Overview** page of your App Registration:

- **Application (client) ID** → this is your `AZURE_CLIENT_ID`
- **Directory (tenant) ID** → this is your `AZURE_TENANT_ID`

> ⚠️ Keep these values handy; they will be needed throughout the lab.

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

# 📝 Step 1.2 — Configure Access Tokens v2

## Why switch to v2?

- By default, Entra ID issues **v1** tokens (`iss` = `sts.windows.net/...`)
- Version **v2** uses a standard JWT format and an `aud` claim that maps directly to the **Client ID**

## How to do it

1. In your App Registration → **Manifest**
2. Find `requestedAccessTokenVersion` (or `accessTokenAcceptedVersion`)
3. Change the value from `null` to `2`
4. Click **Save**

```json
{
  "accessTokenAcceptedVersion": 2
}
```

> 💡 This step is **essential** for JWT validation in our API to work with the `aud` = `Client ID` claim and the `iss` = `https://login.microsoftonline.com/{tenant-id}/v2.0` claim.

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

# 📝 Step 1.3 — Define App Roles

## Why App Roles?

App Roles control **who** (user, group, or application) is allowed to perform an action. This is an **admin-controlled** model: only an administrator can assign roles.

## Create the roles

1. In the **Hello World API** App Registration → **App roles** → **Create app role**
2. Create the following roles:

| Display Name | Value | Allowed Member Types | Description |
|---|---|---|---|
| **Hello Reader** | `Hello.Read` | Both (Users/Groups + Applications) | Can call the hello endpoints |
| **User Profile Reader** | `User.Read` | Both (Users/Groups + Applications) | Can call the /me endpoint |

## ⚠️ Important

- The **Value** field is what will appear in the `roles` claim of the JWT token
- **Both** allows the role to be assigned to users AND applications (service-to-service)

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

Both appear as claims in the token, but they follow different models:

|                         | **Scopes** (`scp`)                          | **Roles** (`roles`)                                  |
|-------------------------|---------------------------------------------|------------------------------------------------------|
| **Model**               | Delegated permissions                       | Role-based permissions                               |
| **Who receives them**   | Users only (interactive flows)              | Users/groups **and** applications                    |
| **Who decides**         | The **user consents**                       | An **admin assigns**                                 |
| **Typical granularity** | Per-action (e.g. `Hello.Read`)              | Per-profile (e.g. `Admin`, `Reader`)                 |
| **Token claim**         | `scp` (space-separated string)              | `roles` (array of strings)                           |
| **Use case**            | "This app can read my greetings"            | "This user/app is an Admin"                          |

In short:

- **scopes** = the *user* controls what an app can do on their behalf;
- **roles** = an *admin* controls who has which role.

Both can coexist on the same App Registration.

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

# 📝 Step 1.4 — Create a Service Principal

## Create an App Registration to test the API

1. **Azure Portal** → **Microsoft Entra ID** → **App registrations** → **New registration**
2. Fill in:
   - **Name**: `Hello API Client`
   - **Supported account types**: *Single tenant*
3. Click **Register**
4. Note the **Application (client) ID** → this is the client's `AZURE_CLIENT_ID`

## Create a Client Secret

1. In the **Hello API Client** App Registration → **Certificates & secrets**
2. **New client secret**
   - **Description**: `Lab secret`
   - **Expires**: 6 months (or your preferred duration)
3. Click **Add**

> ⚠️ **Copy the secret value immediately!** It will no longer be visible after you leave the page.

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

# 📝 Step 1.5 — Assign App Roles to the Client

## Add application permissions

1. In the **Hello API Client** App Registration → **API permissions**
2. **Add a permission** → **APIs my organisation uses** → select **Hello World API**
3. Choose **Application permissions** (not Delegated)
4. Check `Hello.Read` and `User.Read`
5. Click **Add permissions**

## Grant admin consent

1. Back in **API permissions**, click **Grant admin consent for \<your tenant\>**
2. Confirm

> 💡 **Why admin consent?** Application permissions (client credentials flow) **always** require admin consent because there is no interactive user to consent.

> 🔑 **What happens in the token:** During authentication, Entra ID inserts the consented roles into the JWT's `roles` claim: `["Hello.Read", "User.Read"]`.

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

# 📝 Step 1.6 — Obtain a token

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

💡 Paste the token on [jwt.ms](https://jwt.ms) to view the claims, especially the `roles` claim

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

# 📝 Step 1.7 — Start the API

## Install and start `hello-api`

1. Open a terminal in the `2-Identities/hello-api` folder

2. Create a virtual environment and install dependencies:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

1. Set up environment variables:

```bash
cp .env.example .env
```

1. Edit `.env` with the values from Step 1.1:

```env
AZURE_TENANT_ID=your-tenant-id
AZURE_CLIENT_ID=your-api-client-id
```

1. Start the API:

```bash
uvicorn main:app --reload
```

> ✅ The API is accessible at **<http://127.0.0.1:8000>** — test `GET /` and `GET /health` in your browser. The Swagger docs are available at **<http://127.0.0.1:8000/docs>**.

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

# 📝 Step 1.7 — Verify the endpoints

## Endpoints exposed by `hello-api`

| Method | Path | Auth | Required Role | Description |
|---|---|---|---|---|
| `GET` | `/` | ❌ | — | API info & link to docs |
| `GET` | `/health` | ❌ | — | Health-check |
| `GET` | `/hello` | ✅ | `Hello.Read` | Greets the authenticated user |
| `GET` | `/hello/{name}` | ✅ | `Hello.Read` | Greets a specific person |
| `GET` | `/me` | ✅ | `User.Read` | Returns the user's claims |

## Test with a token

```bash
# Hello (authenticated)
curl -H "Authorization: Bearer ${TOKEN}" http://127.0.0.1:8000/hello
```

## Test without a token

```bash
curl http://127.0.0.1:8000/hello
# → 403 Forbidden
```

---

<!-- _class: lead -->

# 🟢 Part 2

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

# 📝 Step 2.1 — Understanding the Client Credentials Flow

## Authentication sequence

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
        │    (with roles claim)      │                          │
        │                            │                          │
        │ 3. GET /hello                                         │
        │    Authorization: Bearer <token>                      │
        │─────────────────────────────────────────────────────▶│
        │                                                       │
        │◀─────────────────────────────────────────────────────│
        │ 4. 200 OK { "message": "Hello, World!" }              │
```

> The requested scope is always `{api_client_id}/.default` — Entra ID returns **all** consented App Roles

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

# 📝 Step 2.2 — Configure and run `hello-client`

## Install and configure

1. Open a **new terminal** in `2-Identities/hello-client`

2. Create the environment and install:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

1. Set up the environment:

```bash
cp .env.example .env
```

1. Edit `.env` with your values:

```env
AZURE_TENANT_ID=your-tenant-id
AZURE_CLIENT_ID=your-client-app-client-id      ← Hello API Client
AZURE_CLIENT_SECRET=your-client-secret          ← the secret copied at Step 1.4
API_CLIENT_ID=your-api-client-id                ← Hello World API
API_BASE_URL=http://127.0.0.1:8000
```

1. Run the client (make sure `hello-api` is still running):

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

# 📝 Step 2.3 — Expected result

## What `hello-client` does

The console client automatically performs the following steps:

1. **Displays the configuration** — tenant, client ID, target API
2. **Acquires an access token** via MSAL (client credentials flow)
3. **Calls the public endpoints** — `GET /`, `GET /health` (without a token)
4. **Calls the secured endpoints** — `GET /hello`, `GET /hello/Sylvain`, `GET /me` (with a token)
5. **Calls a secured endpoint without a token** — to demonstrate the 403 error

## Verification

- ✅ Public endpoints return **200 OK**
- ✅ Secured endpoints with a token return **200 OK** + data
- ✅ The secured endpoint without a token returns **403 Forbidden**

> 🎉 If everything is green, you have a working **service-to-service** flow!

---

<!-- _class: lead -->

# 🟣 Part 3

## Angular Application — `hello-angular`

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

# 📝 Step 3.1 — Expose a delegated scope on the API

## Why a scope if the API uses App Roles?

The API authorizes requests via **App Roles** (`roles` claim), not delegated scopes. However, the delegated OAuth 2.0 flow (Authorization Code) **requires** at least one delegated scope for Entra ID to be able to issue an access token for the SPA.

## Configure the scope

1. **Azure Portal → Entra ID → App registrations → Hello World API**
2. **Expose an API** → Click **Add** next to *Application ID URI*
   - Accept the default format: `api://<client-id>`
3. **Add a scope**:
   - **Scope name**: `access_as_user`
   - **Who can consent**: *Admins and users*
   - **Admin consent display name**: `Access Hello API`
   - **Admin consent description**: `Allow the application to access Hello API on behalf of the signed-in user`
   - **State**: Enabled

> 💡 This scope acts as an **"entry ticket"** — the API does not validate it server-side. The actual authorization is handled via App Roles.

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

# 📝 Step 3.2 — Create the SPA App Registration

## Register the Angular application

1. **Azure Portal → Entra ID → App registrations → New registration**
2. Fill in:
   - **Name**: `hello-angular`
   - **Supported account types**: *Single tenant*
   - **Redirect URI**:
     - **Type**: *Single-page application (SPA)*
     - **URI**: `http://localhost:4200`
3. Click **Register**
4. Note the **Application (client) ID** — this is the `clientId` for `config.json`

## ⚠️ Important points

- The Redirect URI type must be **SPA** (not Web) — this enables the appropriate **PKCE flow** for client-side applications
- No client secret is needed for a SPA — MSAL uses the **Authorization Code Flow with PKCE**

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

# 📝 Step 3.3 — Add API Permissions to the SPA

## Configure delegated permissions

1. **Azure Portal → Entra ID → App registrations → hello-angular**
2. **API permissions** → **Add a permission** → **My APIs** → select **Hello World API**
3. Choose **Delegated permissions** (not Application)
4. Check `access_as_user`
5. Click **Add permissions**

## Why Delegated and not Application?

| Type | Context | Used by |
|---|---|---|
| **Delegated** | The app acts **on behalf of the signed-in user** | SPA, Web Apps |
| **Application** | The app acts **on its own behalf**, without a user | Services, Daemons |

> 💡 An Angular SPA uses the **Authorization Code + PKCE** flow — this is an *interactive* flow that involves a user. Therefore, we use **Delegated permissions**.

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

# 📝 Step 3.4 — Pre-authorize the SPA

## Why pre-authorize?

If **user consent is disabled** in your tenant (a common enterprise policy), users will be blocked at sign-in. Pre-authorization **bypasses the consent prompt**.

## Configure pre-authorization

1. **Azure Portal → Entra ID → App registrations → Hello World API**
2. **Expose an API** → **Authorized client applications** → **Add a client application**
3. Enter the **Application (client) ID** of the SPA (`hello-angular`)
4. Check the `access_as_user` scope
5. Click **Add application**

> 🔑 **What this means:** Entra ID considers the SPA a trusted client — any user who can sign in can access the API's `access_as_user` scope **without being prompted to consent**.

> ⚠️ **Without this step**, users in a tenant where consent is disabled will see an `AADSTS65001` error ("The user or administrator has not consented to use the application").

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

# 📝 Step 3.5 — How everything fits together

## Complete flow: SPA → Entra ID → API

```text
                    SPA requests: api://{apiClientId}/.default
                                │
                                ▼
                    ┌───────────────────────────────┐
                    │          Entra ID             │
                    │                               │
                    │  Pre-authorized client?       │
                    │  → hello-angular ✅           │  ← consent is bypassed
                    │                               │
                    │  Delegated permission          │
                    │  → access_as_user ✅          │  ← required for the flow
                    │                               │
                    │  App Roles assigned to user   │
                    │  → Hello.Read ✅              │  ← controls authorization
                    │  → User.Read  ✅              │
                    └───────────────┬───────────────┘
                                    │
                            Token contains:
                            • aud   = API client ID
                            • scp   = "access_as_user"   (not validated by the API)
                            • roles = ["Hello.Read", …]   (validated by the API ✅)
```

- The **delegated scope** (`access_as_user`) is the entry ticket to obtain a token
- **Pre-authorization** removes the consent prompt
- The **actual authorization** is performed by the API on the **`roles`** claim

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

# 📝 Step 3.6 — Assign App Roles to users

## Grant roles to test users

For users to access the API's secured endpoints from the SPA, they must have the **App Roles** assigned.

1. **Azure Portal → Entra ID → Enterprise Applications** → search for and select **Hello World API**
2. **Users and groups** → **Add user/group**
3. Select the test user (or group)
4. Choose the **Hello Reader** role (`Hello.Read`)
5. Click **Assign**
6. Repeat for the **User Profile Reader** role (`User.Read`)

## ⚠️ Important

- ❗ Roles are assigned in **Enterprise Applications** (not App registrations)
- Roles are visible in the token under the `roles` claim
- A user without assigned roles will receive a token **without** a `roles` claim → the API will return **403**

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

# 📝 Step 3.7 — Configure and run `hello-angular`

## Install and configure

1. Open a terminal in `2-Identities/hello-angular`

2. Install dependencies:

```bash
npm install
```

1. Create the configuration file:

```bash
cp public/config.example.json public/config.json
```

1. Edit `public/config.json`:

```json
{
  "clientId": "YOUR_SPA_CLIENT_ID",
  "tenantId": "YOUR_TENANT_ID",
  "apiClientId": "YOUR_API_CLIENT_ID",
  "apiBaseUrl": "http://127.0.0.1:8000"
}
```

1. Run the application (make sure `hello-api` is still running):

```bash
npm start
```

> ✅ The application is accessible at **<http://localhost:4200>**

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

# 📝 Step 3.8 — Test the Angular application

## Available pages

| Route | Auth | Description |
|---|---|---|
| `/` | ❌ | Home page — API status and health check |
| `/dashboard` | ✅ | Interactive API explorer — calls to secured endpoints |
| `/profile` | ✅ | Entra ID identity and token claims viewer |

## Test walkthrough

1. Go to **<http://localhost:4200>** — you should see the home page
2. Click **Login** — you are redirected to Entra ID
3. Sign in with a user who has the App Roles assigned
4. Navigate to **/dashboard** — test the API calls:
   - `GET /hello` → should return a welcome message
   - `GET /me` → should return your identity claims
5. Navigate to **/profile** — view the token information

## ✅ Checks

- The token is automatically attached by **MSAL Interceptor** (no manual handling)
- Public endpoints do **not** receive a token (configured via `protectedResourceMap`)

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

# 🧩 Summary — The 3 App Registrations

## Overview

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

- **Part 1**: The API defines roles and scopes — it is the **protected resource**
- **Part 2**: The service client uses a secret — **machine-to-machine** flow
- **Part 3**: The SPA uses PKCE — **interactive** flow with **consent bypassed**

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

# 🔑 Flow Comparison

## Client Credentials vs Authorization Code + PKCE

| | **Client Credentials** (`hello-client`) | **Auth Code + PKCE** (`hello-angular`) |
|---|---|---|
| **User** | ❌ None — machine-to-machine | ✅ Interactive user |
| **Secret** | Client secret required | ❌ No secret (PKCE) |
| **Token claim** | `roles` (App Roles) | `roles` + `scp` (App Roles + Scopes) |
| **Requested scope** | `{api}/.default` | `api://{api}/.default` |
| **Permissions** | Application permissions | Delegated permissions |
| **Consent** | Admin consent required | User consent (or pre-auth) |
| **Use case** | Daemons, services, CI/CD | SPA, Web Apps, Mobile Apps |

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

- ✅ **One App Registration per resource** (API) — defines roles and scopes
- ✅ **One App Registration per client** — each client has its own permissions
- ⚠️ Always use **token v2** for new applications

## 🛡️ Best Practices

- ✅ **App Roles** for API-side authorization — admin-controlled
- ✅ **Delegated scopes** as an entry ticket for interactive flows
- ✅ **Pre-authorize SPAs** to bypass consent in enterprise settings
- ✅ **Principle of least privilege** — assign only the necessary roles

> 🏆 **Summary:** The App Registration is the template, the Service Principal is a technical identity. App Roles control authorization, scopes enable the flow.

---

# ❓ Questions?

**Contact:** <sriquen@vaudoise.ch>

**Teams:** #Cop Dev Azure
