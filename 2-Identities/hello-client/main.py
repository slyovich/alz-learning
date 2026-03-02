"""Hello API Console Client — Entra ID Client Credentials Flow.

This console application demonstrates how to:
1. Obtain an access token from Microsoft Entra ID using the Client Credentials
   flow (client_id + client_secret).
2. Call the secured endpoints of the Hello World API with the obtained token.

The client credentials flow is designed for **service-to-service** communication
where no interactive user is involved. The token is issued directly to the
application itself, and the ``roles`` claim contains the App Roles that were
granted to the client application by an administrator.
"""

import sys

import httpx
import msal
from dotenv import load_dotenv
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict
from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from rich.text import Text

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

load_dotenv()

console = Console()


class ClientSettings(BaseSettings):
    """Settings loaded from environment variables or .env file."""

    azure_tenant_id: str
    azure_client_id: str
    azure_client_secret: str
    api_client_id: str
    api_base_url: str = Field(default="http://127.0.0.1:8000")

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
    )

    @property
    def authority(self) -> str:
        return f"https://login.microsoftonline.com/{self.azure_tenant_id}"

    @property
    def scope(self) -> list[str]:
        """The scope for the client credentials flow.

        In the client credentials flow you must request the ``.default`` scope
        of the target API. Entra ID will return all the *Application permissions*
        (App Roles) that have been granted (and admin-consented) to the client.
        """
        return [f"{self.api_client_id}/.default"]


# ---------------------------------------------------------------------------
# Token acquisition
# ---------------------------------------------------------------------------


def acquire_token(settings: ClientSettings) -> str:
    """Acquire an access token using MSAL's client credentials flow.

    Returns the access token string, or exits the program on failure.
    """
    app = msal.ConfidentialClientApplication(
        client_id=settings.azure_client_id,
        client_credential=settings.azure_client_secret,
        authority=settings.authority,
    )

    # Try to get a cached token first, then acquire a new one
    result = app.acquire_token_silent(settings.scope, account=None)
    if not result:
        result = app.acquire_token_for_client(scopes=settings.scope)

    if "access_token" not in result:
        console.print(
            Panel(
                f"[bold red]Failed to acquire token[/bold red]\n\n"
                f"Error: {result.get('error', 'unknown')}\n"
                f"Description: {result.get('error_description', 'N/A')}",
                title="❌ Authentication Error",
                border_style="red",
            )
        )
        sys.exit(1)

    return result["access_token"]


# ---------------------------------------------------------------------------
# API calls
# ---------------------------------------------------------------------------


def call_api(
    client: httpx.Client,
    method: str,
    url: str,
    token: str | None = None,
    label: str = "",
) -> httpx.Response:
    """Call an API endpoint and return the response."""
    headers = {}
    if token:
        headers["Authorization"] = f"Bearer {token}"

    response = client.request(method, url, headers=headers)
    return response


def display_response(response: httpx.Response, label: str) -> None:
    """Display an API response in a rich panel."""
    status = response.status_code
    if 200 <= status < 300:
        style = "green"
        icon = "✅"
    elif 400 <= status < 500:
        style = "yellow"
        icon = "⚠️"
    else:
        style = "red"
        icon = "❌"

    try:
        import json
        body = json.dumps(response.json(), indent=2, ensure_ascii=False)
    except Exception:
        body = response.text

    console.print(
        Panel(
            f"[dim]Status:[/dim] [{style} bold]{status}[/{style} bold]\n\n{body}",
            title=f"{icon} {label}",
            border_style=style,
            padding=(1, 2),
        )
    )


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------


def main() -> None:
    """Run the console client demo."""

    # ── Header ──────────────────────────────────────────────────────────
    console.print()
    console.print(
        Panel(
            Text.from_markup(
                "[bold]Hello API Console Client[/bold]\n"
                "[dim]Entra ID Client Credentials Flow Demo[/dim]"
            ),
            border_style="bright_blue",
            padding=(1, 2),
        )
    )

    # ── Load configuration ──────────────────────────────────────────────
    try:
        settings = ClientSettings()  # type: ignore[call-arg]
    except Exception as exc:
        console.print(f"[bold red]Configuration error:[/bold red] {exc}")
        console.print(
            "\n[dim]Make sure you have a .env file with the required variables. "
            "See .env.example for reference.[/dim]"
        )
        sys.exit(1)

    # Show configuration summary
    config_table = Table(
        title="⚙️  Configuration",
        show_header=True,
        header_style="bold cyan",
    )
    config_table.add_column("Setting", style="bold")
    config_table.add_column("Value")
    config_table.add_row("Tenant ID", settings.azure_tenant_id)
    config_table.add_row("Client ID", settings.azure_client_id)
    config_table.add_row("Client Secret", f"{settings.azure_client_secret[:4]}{'*' * 20}")
    config_table.add_row("API Client ID", settings.api_client_id)
    config_table.add_row("API Base URL", settings.api_base_url)
    config_table.add_row("Scope", settings.scope[0])
    console.print(config_table)
    console.print()

    # ── Acquire token ───────────────────────────────────────────────────
    console.print("[bold cyan]🔑 Acquiring access token…[/bold cyan]")
    token = acquire_token(settings)
    console.print("[green]✅ Token acquired successfully![/green]")

    # Show a preview of the token
    console.print(
        Panel(
            f"[dim]{token[:40]}…{token[-20:]}[/dim]",
            title="🎫 Access Token (preview)",
            border_style="dim",
        )
    )
    console.print()

    # ── Call API endpoints ──────────────────────────────────────────────
    base = settings.api_base_url.rstrip("/")

    with httpx.Client(timeout=10.0) as client:

        # 1. Public endpoints (no token needed)
        console.rule("[bold]Public Endpoints[/bold]", style="bright_blue")
        console.print()

        resp = call_api(client, "GET", f"{base}/", label="Root")
        display_response(resp, "GET /")

        resp = call_api(client, "GET", f"{base}/health", label="Health")
        display_response(resp, "GET /health")

        # 2. Secured endpoints (with token)
        console.rule("[bold]Secured Endpoints (with token)[/bold]", style="bright_blue")
        console.print()

        resp = call_api(client, "GET", f"{base}/hello", token=token)
        display_response(resp, "GET /hello")

        resp = call_api(client, "GET", f"{base}/hello/Sylvain", token=token)
        display_response(resp, "GET /hello/Sylvain")

        resp = call_api(client, "GET", f"{base}/me", token=token)
        display_response(resp, "GET /me")

        # 3. Secured endpoint WITHOUT token (should fail with 403)
        console.rule(
            "[bold]Secured Endpoint WITHOUT token (expected failure)[/bold]",
            style="yellow",
        )
        console.print()

        resp = call_api(client, "GET", f"{base}/hello")
        display_response(resp, "GET /hello (no token)")

    # ── Done ────────────────────────────────────────────────────────────
    console.print()
    console.print("[bold green]🎉 Demo complete![/bold green]")
    console.print()


if __name__ == "__main__":
    main()
