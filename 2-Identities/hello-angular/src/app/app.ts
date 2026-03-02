import { Component, OnInit, OnDestroy, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';
import { MsalService, MsalBroadcastService } from '@azure/msal-angular';
import { InteractionStatus } from '@azure/msal-browser';
import { Subject, filter, takeUntil } from 'rxjs';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, RouterOutlet, RouterLink, RouterLinkActive],
  templateUrl: './app.html',
  styleUrl: './app.css',
})
export class App implements OnInit, OnDestroy {
  isAuthenticated = signal(false);
  userName = signal<string | null>(null);
  private readonly destroy$ = new Subject<void>();

  constructor(
    private readonly authService: MsalService,
    private readonly broadcastService: MsalBroadcastService
  ) { }

  ngOnInit(): void {
    this.authService.handleRedirectObservable().subscribe();

    this.broadcastService.inProgress$
      .pipe(
        filter(
          (status: InteractionStatus) =>
            status === InteractionStatus.None
        ),
        takeUntil(this.destroy$)
      )
      .subscribe(() => {
        this.checkAuth();
      });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  private checkAuth(): void {
    const accounts = this.authService.instance.getAllAccounts();
    this.isAuthenticated.set(accounts.length > 0);
    if (accounts.length > 0) {
      this.authService.instance.setActiveAccount(accounts[0]);
      this.userName.set(accounts[0].name ?? accounts[0].username);
    }
  }

  login(): void {
    this.authService.loginRedirect();
  }

  logout(): void {
    this.authService.logoutRedirect();
  }
}
