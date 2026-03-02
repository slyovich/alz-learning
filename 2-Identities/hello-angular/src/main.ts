import { bootstrapApplication } from '@angular/platform-browser';
import { appConfig } from './app/app.config';
import { App } from './app/app';
import { loadAppConfig } from './app/config/app-config';

/**
 * Load runtime configuration from /config.json BEFORE bootstrapping Angular.
 *
 * This ensures the config is available synchronously to MSAL factory
 * functions (MSALInstanceFactory, MSALInterceptorConfigFactory, etc.).
 */
loadAppConfig()
  .then(() => bootstrapApplication(App, appConfig))
  .catch((err) => {
    console.error('Application startup failed:', err);
    document.body.innerHTML = `
      <div style="font-family: sans-serif; padding: 3rem; text-align: center; color: #f87171;">
        <h1>⚠️ Configuration Error</h1>
        <p>${err.message}</p>
        <p style="color: #888; margin-top: 1rem;">
          Copy <code>public/config.example.json</code> to <code>public/config.json</code>
          and fill in your Entra ID values.
        </p>
      </div>
    `;
  });
