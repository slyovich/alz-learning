import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterLink } from '@angular/router';
import { MsalService } from '@azure/msal-angular';
import { HelloApiService, RootResponse, HealthResponse } from '../../services/hello-api.service';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule, RouterLink],
  templateUrl: './home.html',
  styleUrl: './home.css',
})
export class HomeComponent implements OnInit {
  isAuthenticated = signal(false);
  userName = signal<string | null>(null);
  rootInfo = signal<RootResponse | null>(null);
  healthStatus = signal<HealthResponse | null>(null);
  loading = signal(true);

  constructor(
    private readonly authService: MsalService,
    private readonly apiService: HelloApiService
  ) { }

  ngOnInit(): void {
    const accounts = this.authService.instance.getAllAccounts();
    this.isAuthenticated.set(accounts.length > 0);
    if (accounts.length > 0) {
      this.userName.set(accounts[0].name ?? accounts[0].username);
    }

    // Fetch public endpoints
    this.apiService.getRoot().subscribe({
      next: (data) => this.rootInfo.set(data),
      error: (err) => console.error('Root API error:', err),
    });

    this.apiService.getHealth().subscribe({
      next: (data) => {
        this.healthStatus.set(data);
        this.loading.set(false);
      },
      error: (err) => {
        console.error('Health API error:', err);
        this.loading.set(false);
      },
    });
  }

  login(): void {
    this.authService.loginRedirect();
  }
}
