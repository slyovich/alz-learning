"""Hello World Web API built with FastAPI — secured with Entra ID authentication."""

from fastapi import Depends, FastAPI

from auth import TokenClaims, validate_token

app = FastAPI(
    title="Hello World API",
    description=(
        "A simple Hello World API secured with **Microsoft Entra ID** (Azure AD) "
        "Bearer token authentication.\n\n"
        "### 🔒 Authentication\n"
        "All `/hello` endpoints require a valid JWT Bearer token issued by Entra ID.\n\n"
        "Click the **Authorize** button above and paste a valid token to try the "
        "secured endpoints."
    ),
    version="2.0.0",
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
# Secured endpoints – require a valid Entra ID Bearer token
# ---------------------------------------------------------------------------


@app.get("/hello", tags=["Hello"])
async def hello(claims: TokenClaims = Depends(validate_token)):
    """Say hello to the authenticated user.

    Requires a valid Entra ID Bearer token.
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
async def hello_name(name: str, claims: TokenClaims = Depends(validate_token)):
    """Say hello to a specific person.

    Requires a valid Entra ID Bearer token.

    Args:
        name: The name of the person to greet.
    """
    return {
        "message": f"Hello, {name}!",
        "authenticated_as": claims.preferred_username,
    }


@app.get("/me", tags=["Identity"])
async def me(claims: TokenClaims = Depends(validate_token)):
    """Return the full identity of the authenticated user.

    Requires a valid Entra ID Bearer token.
    """
    return {
        "sub": claims.sub,
        "name": claims.name,
        "preferred_username": claims.preferred_username,
        "oid": claims.oid,
        "roles": claims.roles,
        "scopes": claims.scp,
    }
