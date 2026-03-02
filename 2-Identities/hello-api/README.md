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

### 3. Expose an API — Scopes & Delegated Permissions (Optional)

#### Why use scopes?

Without scopes, any client holding a valid token for your API audience has **full access to every endpoint** — it's all-or-nothing. Scopes let you introduce **granular, per-operation access control** based on the *delegated permissions* model.

| Benefit              | Description                                                                     |
|----------------------|---------------------------------------------------------------------------------|
| **Granular access**  | Each scope maps to a specific capability (e.g. read greetings vs. read profile) |
| **Least privilege**  | Client applications only request the permissions they actually need             |
| **User consent**     | When a user logs in, Entra ID shows them exactly what the app is requesting     |
| **Auditability**     | You can trace which scopes were granted in each token                           |

> **Scopes vs. Roles** — Both appear as claims in the token, but they follow different models:
>
> |                         | **Scopes** (`scp`)                          | **Roles** (`roles`)                                  |
> |-------------------------|---------------------------------------------|------------------------------------------------------|
> | **Model**               | Delegated permissions                       | Role-based permissions                               |
> | **Who receives them**   | Users only (interactive flows)              | Users/groups **and** applications                    |
> | **Who decides**         | The **user consents**                       | An **admin assigns**                                 |
> | **Typical granularity** | Per-action (e.g. `Hello.Read`)              | Per-profile (e.g. `Admin`, `Reader`)                 |
> | **Token claim**         | `scp` (space-separated string)              | `roles` (array of strings)                           |
> | **Use case**            | "This app can read my greetings"            | "This user/app is an Admin"                          |
>
> In short: **scopes** = the *user* controls what an app can do on their behalf; **roles** = an *admin* controls who has which role. Both can coexist on the same App Registration.

#### Example scopes for this API

| Scope        | Description       | Grants access to                  |
|--------------|-------------------|-----------------------------------|
| `Hello.Read` | Read greetings    | `GET /hello`, `GET /hello/{name}` |
| `User.Read`  | Read user profile | `GET /me`                         |

#### Configure scopes in Entra ID

1. In your App Registration → **Expose an API**
2. Click **Set** next to *Application ID URI* and accept the default `api://<client-id>` (or choose your own)
3. Click **Add a scope** and create:
   - **Scope name**: `Hello.Read`
   - **Who can consent**: *Admins and users*
   - **Admin consent display name**: *Read greetings*
   - **Admin consent description**: *Allows the app to call the hello endpoints on behalf of the signed-in user.*
4. Repeat to add a `User.Read` scope (for the `/me` endpoint)
5. In the **client** App Registration → **API permissions** → **Add a permission** → **My APIs** → select `Hello World API` → tick the scopes you need → **Add permissions**

#### Enforce scopes in the code

To make scopes effective, you must **verify** the `scp` claim in your endpoints. Add a `require_scope` dependency in `auth.py`:

```python
def require_scope(required: str):
    """FastAPI dependency that enforces a specific delegated scope."""
    def _check(claims: TokenClaims = Depends(validate_token)):
        token_scopes = (claims.scp or "").split()
        if required not in token_scopes:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Missing required scope: {required}",
            )
        return claims
    return _check
```

Then update `main.py` to use it:

```python
from auth import TokenClaims, validate_token, require_scope

@app.get("/hello")
async def hello(claims: TokenClaims = Depends(require_scope("Hello.Read"))):
    ...

@app.get("/hello/{name}")
async def hello_name(name: str, claims: TokenClaims = Depends(require_scope("Hello.Read"))):
    ...

@app.get("/me")
async def me(claims: TokenClaims = Depends(require_scope("User.Read"))):
    ...
```

With this in place, the access model becomes:

```text
Without scopes:  Valid token?  → ✅ Full access to all endpoints
With scopes:     Valid token?  → Which scopes? → ✅ Access only to matching endpoints
```

### 3.5 Define App Roles — Role-based Authorisation

#### Why use App Roles?

While **scopes** control what an app can do *on behalf of a user*, **App Roles** control *who* (user, group, or application) is allowed to perform an action at all. They follow an **admin-assigned** model, meaning a tenant admin decides which principals receive which roles.

| Benefit                | Description                                                                                   |
|------------------------|-----------------------------------------------------------------------------------------------|
| **Admin-controlled**   | Only a tenant admin can assign roles — users cannot self-grant access                         |
| **Works for apps too** | App Roles appear in the `roles` claim for *both* interactive users and client-credentials apps |
| **Coarse-grained**     | Ideal for profile-level access (Reader, Writer, Admin) rather than per-action                 |
| **Group-assignable**   | A role can be assigned to an Entra ID group, automatically granting it to all group members   |

#### Example App Roles for this API

| Role Value   | Display Name        | Allowed Member Types       | Grants access to                  |
|--------------|---------------------|----------------------------|-----------------------------------|
| `Hello.Read` | Hello Reader        | Users/Groups, Applications | `GET /hello`, `GET /hello/{name}` |
| `User.Read`  | User Profile Reader | Users/Groups, Applications | `GET /me`                         |

#### Configure App Roles in Entra ID

1. In the **API** App Registration → **App roles** → **Create app role**
2. For each role fill in:
   - **Display name**: e.g. *Hello Reader*
   - **Allowed member types**: *Both (Users/Groups + Applications)*
   - **Value**: `Hello.Read`
   - **Description**: *Can call the hello endpoints*
3. Repeat for `User.Read`

Alternatively, edit the **Manifest** directly and add an `appRoles` array:

```json
"appRoles": [
  {
    "allowedMemberTypes": ["User", "Application"],
    "displayName": "Hello Reader",
    "id": "<generate-a-unique-guid>",
    "isEnabled": true,
    "description": "Can call the hello endpoints",
    "value": "Hello.Read"
  },
  {
    "allowedMemberTypes": ["User", "Application"],
    "displayName": "User Profile Reader",
    "id": "<generate-a-unique-guid>",
    "isEnabled": true,
    "description": "Can call the /me endpoint",
    "value": "User.Read"
  }
]
```

#### Assign App Roles

**For users / groups** (interactive flows):

1. Go to **Enterprise Applications** → select `Hello World API`
2. **Users and groups** → **Add user/group**
3. Select the user or group, then pick the role (`Hello.Read`, `User.Read`, or both)

**For client applications** (client-credentials flow):

1. In the **client** App Registration → **API permissions** → **Add a permission**
2. Select **My APIs** → `Hello World API` → **Application permissions**
3. Tick the role(s) you need → **Add permissions**
4. Click **Grant admin consent** (required because Application permissions always need admin consent)

#### Enforce App Roles in the code

The `require_role` dependency in `auth.py` verifies the `roles` claim:

```python
def require_role(required: str):
    """FastAPI dependency that enforces a specific App Role."""
    def _check(claims: TokenClaims = Depends(validate_token)):
        if required not in (claims.roles or []):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Missing required role: {required}",
            )
        return claims
    return _check
```

Then use it in `main.py`:

```python
from auth import TokenClaims, require_role

@app.get("/hello")
async def hello(claims: TokenClaims = Depends(require_role("Hello.Read"))):
    ...

@app.get("/hello/{name}")
async def hello_name(name: str, claims: TokenClaims = Depends(require_role("Hello.Read"))):
    ...

@app.get("/me")
async def me(claims: TokenClaims = Depends(require_role("User.Read"))):
    ...
```

The complete access model:

```text
No auth:       → ✅ Public endpoints only (/  /health)
Valid token:   → ❌ 403 if missing required role
Token + role:  → ✅ Access to role-matched endpoints
```

### 4. Register a client application (to obtain tokens)

To call this API, you need a **client** app registration:

1. Create another App Registration (e.g. `Hello API Client`)
2. Optional: Under **API permissions** → **Add a permission** → **My APIs** → select `Hello World API`
3. Optional: Add the scope you created above
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

| Method | Path            | Auth Required | Role Required | Description                              |
|--------|-----------------|---------------|---------------|------------------------------------------|
| `GET`  | `/`             | ❌ No         | —             | API info & link to documentation         |
| `GET`  | `/health`       | ❌ No         | —             | Health-check endpoint                    |
| `GET`  | `/hello`        | ✅ Yes        | `Hello.Read`  | Greets the authenticated user            |
| `GET`  | `/hello/{name}` | ✅ Yes        | `Hello.Read`  | Greets a specific person                 |
| `GET`  | `/me`           | ✅ Yes        | `User.Read`   | Returns the authenticated user's claims  |

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
       │                     │  3. Validate JWT      │
       │                     │     (sig, aud, iss,   │
       │                     │      exp)             │
       │                     │  4. Check App Role    │
       │                     │     (roles claim)     │
       │  5. 200 / 401 / 403 │                       │
       │◀────────────────────│                       │
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
