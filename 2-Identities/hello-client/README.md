# 🖥️ Hello API Console Client — Entra ID Client Credentials

A Python console application that demonstrates the **OAuth 2.0 Client Credentials** flow to obtain an access token from **Microsoft Entra ID** and call the secured endpoints of the [Hello World API](../hello-api/).

## How It Works

```
┌───────────────────┐     ┌──────────────────┐     ┌──────────────┐
│   hello-client    │     │   Entra ID       │     │  hello-api   │
│   (Console App)   │     │   (Azure AD)     │     │  (FastAPI)   │
└───────────────────┘     └──────────────────┘     └──────────────┘
        │                          │                       │
        │ 1. POST /oauth2/v2.0/token                       │
        │    client_id +           │                       │
        │    client_secret +       │                       │
        │    scope=<api>/.default  │                       │
        │─────────────────────────▶│                       │
        │                          │                       │
        │◀─────────────────────────│                       │
        │ 2. Access Token          │                       │
        │    (with roles claim)    │                       │
        │                          │                       │
        │ 3. GET /hello                                    │
        │    Authorization: Bearer <token>                 │
        │─────────────────────────────────────────────────▶│
        │                                                  │
        │◀─────────────────────────────────────────────────│
        │ 4. 200 OK { "message": "Hello, World!" }         │
```

### Key concepts

| Concept | Description |
|---------|-------------|
| **Client Credentials Flow** | OAuth 2.0 grant designed for machine-to-machine / service-to-service communication — no interactive user involved |
| **`.default` scope** | In the client credentials flow, you always request `{api_client_id}/.default`; Entra ID returns all admin-consented Application permissions |
| **App Roles** | The `roles` claim in the token contains the App Roles that have been granted (and admin-consented) to the client application |
| **MSAL** | Microsoft Authentication Library — handles token caching, refresh, and the OAuth protocol details |

## Prerequisites

- **Python 3.10+**
- The **Hello World API** running locally (see [hello-api README](../hello-api/README.md))
- Two App Registrations in Entra ID:
  1. The **API** registration (`Hello World API`) — with App Roles defined
  2. A **Client** registration (`Hello API Client`) — with a client secret and the App Roles granted

### Entra ID Setup for the Client App

1. **Create a client App Registration** (e.g. `Hello API Client`)
2. **Certificates & secrets** → Create a **Client secret** → note the value
3. **API permissions** → **Add a permission** → **My APIs** → `Hello World API` → **Application permissions** → tick `Hello.Read` and `User.Read` → **Add permissions**
4. **Grant admin consent** for the permissions (required for Application permissions)

## 🏁 Getting Started

### 1. Create a virtual environment

```bash
cd 2-Identities/hello-client
python3 -m venv .venv
source .venv/bin/activate     # macOS / Linux
# .venv\Scripts\activate      # Windows
```

### 2. Install dependencies

```bash
pip install -r requirements.txt
```

### 3. Configure environment variables

```bash
cp .env.example .env
```

Edit `.env` with your values:

```env
AZURE_TENANT_ID=your-tenant-id
AZURE_CLIENT_ID=your-client-app-client-id
AZURE_CLIENT_SECRET=your-client-secret
API_CLIENT_ID=your-api-client-id
API_BASE_URL=http://127.0.0.1:8000
```

### 4. Start the Hello World API

In a separate terminal:

```bash
cd ../hello-api
source .venv/bin/activate
uvicorn main:app --reload
```

### 5. Run the client

```bash
python main.py
```

## 📋 Expected Output

The client will:

1. **Display configuration** — shows which tenant/client/API it's targeting
2. **Acquire an access token** — using MSAL's client credentials flow
3. **Call public endpoints** — `GET /`, `GET /health` (no token needed)
4. **Call secured endpoints** — `GET /hello`, `GET /hello/Sylvain`, `GET /me` (with token)
5. **Call a secured endpoint without a token** — demonstrates the expected 403 error

Each response is displayed in a formatted panel with the HTTP status code and response body.

## 📁 Project Structure

```
hello-client/
├── main.py              # Console application entry point
├── requirements.txt     # Python dependencies
├── .env.example         # Environment variables template
├── .env                 # Local config (git-ignored)
└── README.md            # This file
```

## 🛠️ Tech Stack

- **[MSAL](https://learn.microsoft.com/en-us/entra/msal/python/)** — Microsoft Authentication Library for Python
- **[httpx](https://www.python-httpx.org/)** — Modern HTTP client
- **[Rich](https://rich.readthedocs.io/)** — Beautiful terminal formatting
- **[Pydantic Settings](https://docs.pydantic.dev/latest/concepts/pydantic_settings/)** — Configuration management
