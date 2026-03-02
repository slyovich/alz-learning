/**
 * Runtime configuration loaded from `/config.json` at application startup.
 *
 * This allows the same Angular build to run in any environment — only
 * the `config.json` file needs to change (no rebuild required).
 *
 * The config is loaded BEFORE the Angular app bootstraps (see `main.ts`),
 * so it's available synchronously to MSAL factory functions.
 */

export interface AppConfig {
  /** Application (client) ID of the SPA App Registration */
  clientId: string;
  /** Entra ID Tenant ID */
  tenantId: string;
  /** Application (client) ID of the API App Registration */
  apiClientId: string;
  /** Base URL of the Hello World API */
  apiBaseUrl: string;
}

let _config: AppConfig | null = null;

/**
 * Fetch the runtime configuration from `/config.json`.
 *
 * This must be called BEFORE `bootstrapApplication()` in `main.ts`.
 */
export async function loadAppConfig(): Promise<AppConfig> {
  const response = await fetch('/config.json');
  if (!response.ok) {
    throw new Error(
      `Failed to load /config.json (${response.status}). ` +
      `Copy config.example.json to config.json and fill in your values.`
    );
  }
  _config = await response.json();
  return _config!;
}

/**
 * Get the loaded runtime configuration.
 *
 * @throws if called before `loadAppConfig()` has completed.
 */
export function getAppConfig(): AppConfig {
  if (!_config) {
    throw new Error(
      'AppConfig not loaded. Ensure loadAppConfig() is called before bootstrapApplication().'
    );
  }
  return _config;
}
