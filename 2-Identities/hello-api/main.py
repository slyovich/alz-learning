"""Hello World Web API built with FastAPI — secured with Entra ID authentication
and App Role–based authorisation."""

from fastapi import Depends, FastAPI

from auth import TokenClaims, require_role

app = FastAPI(
    title="Hello World API",
    description=(
        "A simple Hello World API secured with **Microsoft Entra ID** (Azure AD) "
        "Bearer token authentication and **App Role–based** authorisation.\n\n"
        "### 🔒 Authentication & Authorisation\n"
        "All `/hello` endpoints require a valid JWT Bearer token **and** the "
        "appropriate App Role (`Hello.Read` or `User.Read`).\n\n"
        "Click the **Authorize** button above and paste a valid token to try the "
        "secured endpoints."
    ),
    version="3.0.0",
)


# ---------------------------------------------------------------------------
# Public endpoints
# ---------------------------------------------------------------------------


@app.get("/", tags=["Root"])
async def root():
    """Root endpoint returning API information (public — no auth required)."""
    return {
        "message": "Welcome to the Hello World API",
        "docs": "/docs",
        "auth": "Entra ID (Azure AD) Bearer token required on /hello endpoints",
    }


@app.get("/health", tags=["Root"])
async def health():
    """Health-check endpoint (public — no auth required)."""
    return {"status": "healthy"}


# ---------------------------------------------------------------------------
# Secured endpoints – require a valid Entra ID Bearer token + App Role
# ---------------------------------------------------------------------------


@app.get("/hello", tags=["Hello"])
async def hello(claims: TokenClaims = Depends(require_role("Hello.Read"))):
    """Say hello to the authenticated user.

    Requires a valid Entra ID Bearer token **and** the `Hello.Read` App Role.
    """
    name = claims.name or claims.preferred_username or "World"
    return {
        "message": f"Hello, {name}!",
        "user": {
            "sub": claims.sub,
            "name": claims.name,
            "preferred_username": claims.preferred_username,
        },
    }


@app.get("/hello/{name}", tags=["Hello"])
async def hello_name(name: str, claims: TokenClaims = Depends(require_role("Hello.Read"))):
    """Say hello to a specific person.

    Requires a valid Entra ID Bearer token **and** the `Hello.Read` App Role.

    Args:
        name: The name of the person to greet.
    """
    return {
        "message": f"Hello, {name}!",
        "authenticated_as": claims.preferred_username,
    }


@app.get("/me", tags=["Identity"])
async def me(claims: TokenClaims = Depends(require_role("User.Read"))):
    """Return the full identity of the authenticated user.

    Requires a valid Entra ID Bearer token **and** the `User.Read` App Role.
    """
    return {
        "sub": claims.sub,
        "name": claims.name,
        "preferred_username": claims.preferred_username,
        "oid": claims.oid,
        "roles": claims.roles,
        "scopes": claims.scp,
    }
