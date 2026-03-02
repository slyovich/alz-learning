import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { getAppConfig } from '../config/app-config';

// ---------------------------------------------------------------------------
// Response interfaces matching hello-api endpoints
// ---------------------------------------------------------------------------

export interface RootResponse {
  message: string;
  docs: string;
  auth: string;
}

export interface HealthResponse {
  status: string;
}

export interface HelloResponse {
  message: string;
  user?: {
    sub: string;
    name: string | null;
    preferred_username: string | null;
  };
  authenticated_as?: string;
}

export interface MeResponse {
  sub: string;
  name: string | null;
  preferred_username: string | null;
  oid: string | null;
  roles: string[];
  scopes: string | null;
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

@Injectable({ providedIn: 'root' })
export class HelloApiService {
  private readonly baseUrl = getAppConfig().apiBaseUrl;

  constructor(private readonly http: HttpClient) { }

  /** GET / — public root endpoint */
  getRoot(): Observable<RootResponse> {
    return this.http.get<RootResponse>(`${this.baseUrl}/`);
  }

  /** GET /health — public health check */
  getHealth(): Observable<HealthResponse> {
    return this.http.get<HealthResponse>(`${this.baseUrl}/health`);
  }

  /** GET /hello — secured, requires Hello.Read role */
  getHello(): Observable<HelloResponse> {
    return this.http.get<HelloResponse>(`${this.baseUrl}/hello`);
  }

  /** GET /hello/:name — secured, requires Hello.Read role */
  getHelloName(name: string): Observable<HelloResponse> {
    return this.http.get<HelloResponse>(
      `${this.baseUrl}/hello/${encodeURIComponent(name)}`
    );
  }

  /** GET /me — secured, requires User.Read role */
  getMe(): Observable<MeResponse> {
    return this.http.get<MeResponse>(`${this.baseUrl}/me`);
  }
}
