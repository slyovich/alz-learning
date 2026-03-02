"""Entra ID (Azure AD) authentication module for FastAPI.

This module provides JWT Bearer token validation against Microsoft Entra ID.
It fetches the OpenID Connect metadata and JWKS signing keys automatically,
and validates incoming tokens for issuer, audience, and signature.
"""

import logging
from functools import lru_cache
from typing import Annotated, Any

import httpx
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from pydantic import BaseModel
from pydantic_settings import BaseSettings, SettingsConfigDict

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------


class EntraIDSettings(BaseSettings):
    """Settings loaded from environment variables or .env file."""

    azure_tenant_id: str
    azure_client_id: str

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
    )

    @property
    def authority(self) -> str:
        return f"https://login.microsoftonline.com/{self.azure_tenant_id}"

    @property
    def openid_config_url(self) -> str:
        return f"{self.authority}/v2.0/.well-known/openid-configuration"

    @property
    def issuer(self) -> str:
        return f"https://login.microsoftonline.com/{self.azure_tenant_id}/v2.0"


@lru_cache
def get_settings() -> EntraIDSettings:
    """Cache and return the Entra ID settings (singleton)."""
    return EntraIDSettings()  # type: ignore[call-arg]


# ---------------------------------------------------------------------------
# JWKS key fetching
# ---------------------------------------------------------------------------

_jwks_cache: dict[str, Any] | None = None


def _get_jwks(openid_config_url: str) -> dict[str, Any]:
    """Fetch the JSON Web Key Set from the Entra ID JWKS endpoint.

    Keys are cached in-memory after the first successful fetch.
    """
    global _jwks_cache  # noqa: PLW0603
    if _jwks_cache is not None:
        return _jwks_cache

    # 1. Discover the jwks_uri from the OpenID Connect metadata
    with httpx.Client() as client:
        openid_config = client.get(openid_config_url).json()
        jwks_uri = openid_config["jwks_uri"]

        # 2. Fetch the actual signing keys
        jwks = client.get(jwks_uri).json()

    _jwks_cache = jwks
    logger.info("Fetched %d signing keys from Entra ID", len(jwks.get("keys", [])))
    return jwks


def clear_jwks_cache() -> None:
    """Clear the cached JWKS keys (useful for key rotation)."""
    global _jwks_cache  # noqa: PLW0603
    _jwks_cache = None


# ---------------------------------------------------------------------------
# Token validation
# ---------------------------------------------------------------------------

# FastAPI security scheme – this adds the "Authorize" button in Swagger UI
bearer_scheme = HTTPBearer(
    description="Paste a valid Entra ID Bearer token (JWT).",
)


class TokenClaims(BaseModel):
    """Decoded and validated token claims exposed to route handlers."""

    sub: str
    name: str | None = None
    preferred_username: str | None = None
    oid: str | None = None
    roles: list[str] = []
    scp: str | None = None
    raw: dict[str, Any] = {}


def _find_rsa_key(token: str, jwks: dict[str, Any]) -> dict[str, str] | None:
    """Find the RSA public key matching the token's `kid` header claim."""
    unverified_header = jwt.get_unverified_header(token)
    kid = unverified_header.get("kid")
    for key in jwks.get("keys", []):
        if key["kid"] == kid:
            return key
    return None


async def validate_token(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(bearer_scheme)],
    settings: Annotated[EntraIDSettings, Depends(get_settings)],
) -> TokenClaims:
    """FastAPI dependency that validates an Entra ID JWT Bearer token.

    Usage::

        @app.get("/secure")
        async def secure(claims: TokenClaims = Depends(validate_token)):
            return {"user": claims.preferred_username}
    """
    token = credentials.credentials

    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Invalid or expired token",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        # Fetch JWKS
        jwks = _get_jwks(settings.openid_config_url)
        rsa_key = _find_rsa_key(token, jwks)

        if rsa_key is None:
            # Key might have rotated – clear cache and retry once
            clear_jwks_cache()
            jwks = _get_jwks(settings.openid_config_url)
            rsa_key = _find_rsa_key(token, jwks)

        if rsa_key is None:
            logger.warning("No matching RSA key found for token kid")
            raise credentials_exception

        # Decode and validate the token
        payload = jwt.decode(
            token,
            rsa_key,
            algorithms=["RS256"],
            audience=settings.azure_client_id,
            issuer=settings.issuer,
            options={
                "verify_exp": True,
                "verify_aud": True,
                "verify_iss": True,
            },
        )

        return TokenClaims(
            sub=payload.get("sub", ""),
            name=payload.get("name"),
            preferred_username=payload.get("preferred_username"),
            oid=payload.get("oid"),
            roles=payload.get("roles", []),
            scp=payload.get("scp"),
            raw=payload,
        )

    except JWTError as exc:
        logger.warning("JWT validation failed: %s", exc)
        raise credentials_exception from exc
    except httpx.HTTPError as exc:
        logger.error("Failed to fetch JWKS keys: %s", exc)
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Unable to validate token – identity provider unavailable",
        ) from exc
