import {
  MsalGuardConfiguration,
  MsalInterceptorConfiguration,
} from '@azure/msal-angular';
import {
  BrowserCacheLocation,
  InteractionType,
  LogLevel,
  PublicClientApplication,
} from '@azure/msal-browser';
import { getAppConfig } from '../config/app-config';

/**
 * MSAL logging callback – only logs warnings and errors.
 */
function loggerCallback(logLevel: LogLevel, message: string): void {
  if (logLevel <= LogLevel.Warning) {
    console.warn(`[MSAL] ${message}`);
  }
}

/**
 * Create the MSAL PublicClientApplication instance.
 *
 * Uses the runtime configuration loaded from `/config.json`.
 */
export function MSALInstanceFactory(): PublicClientApplication {
  const config = getAppConfig();

  return new PublicClientApplication({
    auth: {
      clientId: config.clientId,
      authority: `https://login.microsoftonline.com/${config.tenantId}`,
      redirectUri: window.location.origin,
      postLogoutRedirectUri: window.location.origin,
    },
    cache: {
      cacheLocation: BrowserCacheLocation.LocalStorage,
    },
    system: {
      loggerOptions: {
        loggerCallback,
        logLevel: LogLevel.Warning,
        piiLoggingEnabled: false,
      },
    },
  });
}

/**
 * MSAL Guard configuration – used to protect routes.
 */
export function MSALGuardConfigFactory(): MsalGuardConfiguration {
  const config = getAppConfig();

  return {
    interactionType: InteractionType.Redirect,
    authRequest: {
      scopes: [`api://${config.apiClientId}/.default`],
    },
  };
}

/**
 * MSAL Interceptor configuration – automatically attaches Bearer tokens
 * to outgoing HTTP requests matching the API base URL.
 *
 * We use the `.default` scope because the API relies on App Roles (the
 * `roles` claim) for authorisation, not delegated scopes (`scp` claim).
 * The `.default` scope simply requests a valid access token whose audience
 * (`aud`) matches the API's Application ID.
 */
export function MSALInterceptorConfigFactory(): MsalInterceptorConfiguration {
  const config = getAppConfig();
  const scopes = [`api://${config.apiClientId}/.default`];
  const protectedResourceMap = new Map<string, Array<string> | null>();

  // Public endpoints — do NOT attach a token (pass null to skip)
  protectedResourceMap.set(`${config.apiBaseUrl}/`, null);
  protectedResourceMap.set(`${config.apiBaseUrl}/health`, null);

  // Secured endpoints — request a token with .default scope
  protectedResourceMap.set(`${config.apiBaseUrl}/hello*`, scopes);
  protectedResourceMap.set(`${config.apiBaseUrl}/me`, scopes);

  return {
    interactionType: InteractionType.Redirect,
    protectedResourceMap,
  };
}
