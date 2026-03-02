# Hello API Explorer — Angular Client

An Angular SPA (Single Page Application) that consumes the **Hello World API** (`hello-api`), secured with **Microsoft Entra ID** (Azure AD) authentication using MSAL Angular.

## Features

- 🔐 **Entra ID Authentication** — Sign in with Microsoft via MSAL Angular (redirect flow)
- 🔒 **Protected Routes** — Dashboard and Profile pages require authentication (MSAL Guard)
- 📡 **Automatic Token Injection** — MSAL HTTP Interceptor attaches Bearer tokens to API calls
- 🎨 **Premium Dark UI** — Glassmorphism design with smooth animations
- 🧭 **Lazy-Loaded Routes** — Home, Dashboard, Profile pages with code splitting
- ⚙️ **Runtime Configuration** — External `config.json` (no rebuild needed per environment)

## Architecture

```text
                         ┌────────────────────┐
                         │ public/config.json │ ← runtime config (gitignored)
                         └────────┬───────────┘
                                  │ fetch() before bootstrap
                         ┌────────▼─────────┐
         main.ts ───────►│  loadAppConfig() │
                         └────────┬─────────┘
                                  │ getAppConfig()
┌─────────────────────────────────┼──────────────────────────┐
│                  Angular SPA    │                          │
│                                 ▼                          │
│  ┌───────────┐  ┌───────────┐  ┌─────────────┐             │
│  │   Home    │  │ Dashboard │  │  Profile    │             │
│  │ (public)  │  │ (secured) │  │ (secured)   │             │
│  └───────────┘  └─────┬─────┘  └─────────────┘             │
│                       │                                    │
│              ┌────────┴────────┐                           │
│              │ HelloApiService │                           │
│              └────────┬────────┘                           │
│                       │                                    │
│            ┌──────────┴───────────┐                        │
│            │ MSAL HTTP Interceptor│ ← auto Bearer token    │
│            └──────────┬───────────┘   (.default scope)     │
└───────────────────────┼────────────────────────────────────┘
                        │ HTTP + Authorization: Bearer <token>
                        ▼
┌────────────────────────────────────────────────────────────┐
│               Hello World API (FastAPI)                    │
│                                                            │
│  GET /        (public)       GET /hello    (Hello.Read)    │
│  GET /health  (public)       GET /hello/:n (Hello.Read)    │
│                              GET /me       (User.Read)     │
│                                                            │
│  Authorisation: App Roles (roles claim) — NOT scopes       │
└────────────────────────────────────────────────────────────┘
```

## Prerequisites

1. **Node.js** ≥ 20 and npm
2. **hello-api** running locally on `http://127.0.0.1:8000`
3. **Entra ID App Registration** for the SPA (see below)

## Entra ID Setup

### 1. Expose a delegated scope on the API

The API authorises requests using **App Roles** (`roles` claim), not delegated scopes. However, the OAuth 2.0 delegated flow requires at least one **delegated scope** to be configured on the API so that Entra ID can issue an access token for the SPA.

1. **Azure Portal → Entra ID → App registrations → hello-api**
2. **Expose an API** → Set the Application ID URI (e.g. `api://ee6cb38d-...`)
3. **Add a scope**:
   - Scope name: `access_as_user`
   - Who can consent: **Admins and users**
   - Admin consent display name: `Access Hello API`
   - Admin consent description: `Allow the application to access Hello API on behalf of the signed-in user`
   - State: **Enabled**

> This scope acts as a "ticket of entry" — the API does not validate it server‑side.

### 2. Pre-authorise the SPA as a client application

If user consent is **disabled** in your tenant (a common enterprise policy), users will be blocked from signing in unless the SPA is explicitly pre-authorised on the API. This step bypasses the consent prompt entirely.

1. **Azure Portal → Entra ID → App registrations → hello-api**
2. **Expose an API → Authorized client applications → Add a client application**
3. Enter the **Application (client) ID** of the SPA (`hello-angular`)
4. Check the `access_as_user` scope
5. **Add application**

> This tells Entra ID: "The SPA is a trusted client — any user who can sign in may access the API's `access_as_user` scope without being prompted for consent."

### 3. Create the SPA App Registration

1. **Azure Portal → Entra ID → App registrations → New registration**
2. Name: `hello-angular` (or any name)
3. **Redirect URI**: Select **Single-page application (SPA)** and set to `http://localhost:4200`
4. After creation, note the **Application (client) ID** (needed for step 2 above and for `config.json`)

### 4. Add API permissions to the SPA

1. **Azure Portal → Entra ID → App registrations → hello-angular**
2. **API permissions → Add a permission → My APIs → hello-api**
3. **Delegated permissions** → check `access_as_user`
4. **Add permissions**

> **Note:** If the SPA has been pre-authorised (step 2), admin consent is not required. If your tenant allows admin consent, you may still click **Grant admin consent** as an extra safety measure.

### 5. Assign App Roles to users

1. **Azure Portal → Entra ID → Enterprise Applications → hello-api**
2. **Users and groups → Add user/group**
3. Select the user(s) and assign the roles `Hello.Read` and/or `User.Read`

### How scopes, pre-authorisation and App Roles work together

The SPA requests a token using the `.default` scope (`api://{apiClientId}/.default`). Because the SPA is a pre-authorised client, Entra ID skips the consent prompt, includes the `access_as_user` scope in the token, and adds the App Roles assigned to the user:

```text
                    SPA requests: api://{apiClientId}/.default
                                │
                                ▼
                    ┌───────────────────────────────┐
                    │          Entra ID             │
                    │                               │
                    │  Pre-authorised client?       │
                    │  → hello-angular ✅            │  ← consent is skipped
                    │                               │
                    │  Delegated permission         │
                    │  → access_as_user ✅           │  ← required for the flow
                    │                               │
                    │  App Roles assigned to user   │
                    │  → Hello.Read ✅               │  ← controls authorisation
                    │  → User.Read  ✅               │
                    └───────────────┬───────────────┘
                                    │
                            Token contains:
                            • aud   = API client ID
                            • scp   = "access_as_user"   (not validated by the API)
                            • roles = ["Hello.Read", …]   (validated by the API ✅)
```

> **In short:** The delegated scope (`access_as_user`) is the "ticket of entry" that lets the SPA obtain a token for the API. Pre-authorising the SPA on the API bypasses user consent. The actual authorisation is enforced by the API based on the **App Roles** in the `roles` claim.

## Configuration

The application loads its configuration at runtime from `public/config.json` — **no rebuild is needed** when changing environments.

### 1. Create the config file

```bash
cp public/config.example.json public/config.json
```

### 2. Edit `public/config.json`

```json
{
  "clientId": "YOUR_SPA_CLIENT_ID",
  "tenantId": "0b46db74-ba99-4cd2-a723-264e5251f35a",
  "apiClientId": "ee6cb38d-15ed-4083-8629-2ced2ada4536",
  "apiBaseUrl": "http://127.0.0.1:8000"
}
```

| Key | Description |
| --- | --- |
| `clientId` | Application (client) ID of the **SPA** App Registration |
| `tenantId` | Your Entra ID tenant ID |
| `apiClientId` | Application (client) ID of the **API** App Registration |
| `apiBaseUrl` | Base URL of the Hello World API |

> `config.json` is **gitignored** (like a `.env` file). Only `config.example.json` is committed.

### How it works

```text
main.ts                        app bootstrap
   │                                │
   ├─ fetch('/config.json') ───────►│
   │    ▼                           │
   ├─ loadAppConfig()               │
   │    stores config in memory     │
   │                                │
   ├─ bootstrapApplication() ──────►│
   │                                ├─ MSALInstanceFactory()   ─► getAppConfig()
   │                                ├─ MSALGuardConfigFactory() ─► getAppConfig()
   │                                ├─ MSALInterceptorConfig() ─► getAppConfig()
   │                                └─ HelloApiService          ─► getAppConfig()
```

The configuration is loaded **before** Angular bootstraps, so it's available synchronously to all MSAL factory functions and services. If the config file is missing, the app displays a clear error message.

## CORS Configuration

The hello-api needs to allow requests from the Angular SPA. CORS middleware has been added to `hello-api/main.py`:

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:4200"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

## Running

```bash
# Install dependencies
npm install

# Start the dev server
npm start
# → http://localhost:4200
```

## Pages

| Route | Auth Required | Description |
| --- | --- | --- |
| `/` | ❌ | Home page with API status and health check |
| `/dashboard` | ✅ | Interactive API explorer — call secured endpoints |
| `/profile` | ✅ | View your Entra ID identity and token claims |

## Project Structure

```text
hello-angular/
├── public/
│   ├── config.json              ← runtime config (gitignored)
│   └── config.example.json      ← template (committed)
├── src/
│   ├── app/
│   │   ├── auth/
│   │   │   └── auth-config.ts   ← MSAL factories (instance, guard, interceptor)
│   │   ├── config/
│   │   │   └── app-config.ts    ← loadAppConfig() / getAppConfig()
│   │   ├── pages/
│   │   │   ├── home/            ← public landing page
│   │   │   ├── dashboard/       ← secured API explorer
│   │   │   └── profile/         ← secured user identity view
│   │   ├── services/
│   │   │   └── hello-api.service.ts
│   │   ├── app.config.ts        ← providers (MSAL, Router, HttpClient)
│   │   ├── app.routes.ts        ← routes with MsalGuard
│   │   ├── app.ts               ← shell with navbar + auth handling
│   │   └── app.html / app.css
│   ├── styles.css               ← global dark theme
│   └── main.ts                  ← loads config.json, then bootstraps
└── README.md
```

## Technology Stack

- **Angular** 21 with standalone components
- **MSAL Angular** v5 (`@azure/msal-angular` + `@azure/msal-browser`)
- **RxJS** for reactive data flow
- **TypeScript** with strict mode
