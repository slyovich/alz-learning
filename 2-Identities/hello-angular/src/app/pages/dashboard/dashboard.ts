import { Component, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import {
  HelloApiService,
  HelloResponse,
  MeResponse,
} from '../../services/hello-api.service';

interface ApiCallResult {
  loading: boolean;
  data: unknown | null;
  error: string | null;
  status: number | null;
  duration: number | null;
}

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './dashboard.html',
  styleUrl: './dashboard.css',
})
export class DashboardComponent {
  customName = signal('Angular');

  helloResult = signal<ApiCallResult>({
    loading: false,
    data: null,
    error: null,
    status: null,
    duration: null,
  });

  helloNameResult = signal<ApiCallResult>({
    loading: false,
    data: null,
    error: null,
    status: null,
    duration: null,
  });

  meResult = signal<ApiCallResult>({
    loading: false,
    data: null,
    error: null,
    status: null,
    duration: null,
  });

  constructor(private readonly apiService: HelloApiService) { }

  callHello(): void {
    this.helloResult.set({
      loading: true,
      data: null,
      error: null,
      status: null,
      duration: null,
    });
    const start = performance.now();

    this.apiService.getHello().subscribe({
      next: (data: HelloResponse) => {
        this.helloResult.set({
          loading: false,
          data,
          error: null,
          status: 200,
          duration: Math.round(performance.now() - start),
        });
      },
      error: (err) => {
        this.helloResult.set({
          loading: false,
          data: null,
          error: err.error?.detail || err.message || 'Request failed',
          status: err.status ?? null,
          duration: Math.round(performance.now() - start),
        });
      },
    });
  }

  callHelloName(): void {
    const name = this.customName();
    this.helloNameResult.set({
      loading: true,
      data: null,
      error: null,
      status: null,
      duration: null,
    });
    const start = performance.now();

    this.apiService.getHelloName(name).subscribe({
      next: (data: HelloResponse) => {
        this.helloNameResult.set({
          loading: false,
          data,
          error: null,
          status: 200,
          duration: Math.round(performance.now() - start),
        });
      },
      error: (err) => {
        this.helloNameResult.set({
          loading: false,
          data: null,
          error: err.error?.detail || err.message || 'Request failed',
          status: err.status ?? null,
          duration: Math.round(performance.now() - start),
        });
      },
    });
  }

  callMe(): void {
    this.meResult.set({
      loading: true,
      data: null,
      error: null,
      status: null,
      duration: null,
    });
    const start = performance.now();

    this.apiService.getMe().subscribe({
      next: (data: MeResponse) => {
        this.meResult.set({
          loading: false,
          data,
          error: null,
          status: 200,
          duration: Math.round(performance.now() - start),
        });
      },
      error: (err) => {
        this.meResult.set({
          loading: false,
          data: null,
          error: err.error?.detail || err.message || 'Request failed',
          status: err.status ?? null,
          duration: Math.round(performance.now() - start),
        });
      },
    });
  }

  formatJson(data: unknown): string {
    return JSON.stringify(data, null, 2);
  }

  onNameInput(event: Event): void {
    const input = event.target as HTMLInputElement;
    this.customName.set(input.value);
  }
}
