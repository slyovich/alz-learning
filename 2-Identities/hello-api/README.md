# 🚀 Hello World API — Secured with Entra ID

A simple Python Web API built with [FastAPI](https://fastapi.tiangolo.com/) and secured with **Microsoft Entra ID** (Azure AD) Bearer token authentication.

## Prerequisites

- **Python 3.10+** — [Download](https://www.python.org/downloads/)
- **An Azure subscription** with access to Entra ID
- **An App Registration** in Entra ID for this API (see [Entra ID Setup](#-entra-id-setup))

## 🔐 Entra ID Setup

### 1. Register the API application

1. Go to the **Azure Portal** → **Microsoft Entra ID** → **App registrations** → **New registration**
2. Set:
   - **Name**: `Hello World API`
   - **Supported account types**: *Accounts in this organizational directory only (Single tenant)*
3. Click **Register** and note the:
   - **Application (client) ID** → this is your `AZURE_CLIENT_ID`
   - **Directory (tenant) ID** → this is your `AZURE_TENANT_ID`

### 2. Use v2 access tokens

1. In your App Registration → **Manifest**
2. Update the manifest to set the `requestedAccessTokenVersion` property to `2`

### 3. Expose an API (optional — for delegated permissions)

1. In your App Registration → **Expose an API**
2. Set the **Application ID URI** (e.g. `api://<client-id>`)
3. Add a scope (e.g. `api://<client-id>/Hello.Read`)

### 4. Register a client application (to obtain tokens)

To call this API, you need a **client** app registration:

1. Create another App Registration (e.g. `Hello API Client`)
2. Under **API permissions** → **Add a permission** → **My APIs** → select `Hello World API`
3. Add the scope you created above
4. Under **Certificates & secrets** → create a **Client secret** (note the value)

### 5. Configure environment variables

```bash
cp .env.example .env
```

Edit `.env` with your values:

```env
AZURE_TENANT_ID=your-tenant-id
AZURE_CLIENT_ID=your-api-client-id
```

## 🏁 Getting Started

### 1. Create a virtual environment

```bash
cd 2-Identities/hello-api
python3 -m venv .venv
source .venv/bin/activate     # macOS / Linux
# .venv\Scripts\activate      # Windows
```

### 2. Install dependencies

```bash
pip install -r requirements.txt
```

### 3. Run the API

```bash
uvicorn main:app --reload
```

The API will be available at **<http://127.0.0.1:8000>**.

## 📡 Endpoints

| Method | Path            | Auth Required | Description                             |
|--------|-----------------|---------------|-----------------------------------------|
| `GET`  | `/`             | ❌ No          | API info & link to documentation        |
| `GET`  | `/health`       | ❌ No          | Health-check endpoint                   |
| `GET`  | `/hello`        | ✅ Yes         | Greets the authenticated user           |
| `GET`  | `/hello/{name}` | ✅ Yes         | Greets a specific person                |
| `GET`  | `/me`           | ✅ Yes         | Returns the authenticated user's claims |

## 🧪 Testing the API

### 1. Obtain a token

Use the **OAuth 2.0 Client Credentials** flow to get a token:

```bash
# Set your variables
TENANT_ID="your-tenant-id"
CLIENT_ID="your-client-app-client-id"
CLIENT_SECRET="your-client-secret"
API_CLIENT_ID="your-api-client-id"

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

### 2. Call secured endpoints

```bash
# Hello (authenticated)
curl -H "Authorization: Bearer ${TOKEN}" http://127.0.0.1:8000/hello

# Hello with a name
curl -H "Authorization: Bearer ${TOKEN}" http://127.0.0.1:8000/hello/Sylvain

# Get identity claims
curl -H "Authorization: Bearer ${TOKEN}" http://127.0.0.1:8000/me
```

### 3. Call public endpoints (no token needed)

```bash
# API root
curl http://127.0.0.1:8000/
# → {"message":"Welcome to the Hello World API","docs":"/docs","auth":"..."}

# Health check
curl http://127.0.0.1:8000/health
# → {"status":"healthy"}
```

### 4. Test without a token (should fail)

```bash
curl http://127.0.0.1:8000/hello
# → 403 Forbidden — {"detail": "Not authenticated"}
```

## 📖 Interactive Documentation (Swagger UI)

FastAPI generates interactive API documentation automatically. The Swagger UI includes an **Authorize** button where you can paste a Bearer token.

| Documentation    | URL                                  |
|------------------|--------------------------------------|
| **Swagger UI**   | <http://127.0.0.1:8000/docs>        |
| **ReDoc**        | <http://127.0.0.1:8000/redoc>       |
| **OpenAPI JSON** | <http://127.0.0.1:8000/openapi.json>|

## 🏗️ Architecture

```
┌─────────────┐     ┌──────────────────┐     ┌──────────────┐
│   Client    │────▶│  Hello World API │────▶│  Entra ID    │
│ (with JWT)  │     │   (FastAPI)      │     │  (JWKS keys) │
└─────────────┘     └──────────────────┘     └──────────────┘
       │                     │                       │
       │  1. Authorization:  │  2. Fetch JWKS keys   │
       │     Bearer <token>  │     (cached)          │
       │                     │◀──────────────────────│
       │                     │  3. Validate JWT       │
       │  4. 200 OK / 401    │     (sig, aud, iss,   │
       │◀────────────────────│      exp)              │
```

## 📁 Project Structure

```
hello-api/
├── main.py              # FastAPI application & route definitions
├── auth.py              # Entra ID JWT authentication module
├── requirements.txt     # Python dependencies
├── .env.example         # Environment variables template
├── .env                 # Local config (git-ignored)
├── README.md            # This file
└── docs/
    └── swagger-ui.png   # Swagger UI screenshot
```

## 🛠️ Tech Stack

- **[FastAPI](https://fastapi.tiangolo.com/)** — Modern, fast web framework for building APIs
- **[Uvicorn](https://www.uvicorn.org/)** — Lightning-fast ASGI server
- **[python-jose](https://python-jose.readthedocs.io/)** — JWT token encoding/decoding
- **[httpx](https://www.python-httpx.org/)** — HTTP client for fetching JWKS keys
- **[Pydantic Settings](https://docs.pydantic.dev/latest/concepts/pydantic_settings/)** — Configuration management via environment variables
