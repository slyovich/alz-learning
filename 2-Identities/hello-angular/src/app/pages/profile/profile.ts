import { Component, OnInit, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MsalService } from '@azure/msal-angular';
import { AccountInfo } from '@azure/msal-browser';

@Component({
  selector: 'app-profile',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './profile.html',
  styleUrl: './profile.css',
})
export class ProfileComponent implements OnInit {
  account = signal<AccountInfo | null>(null);
  claims = signal<Record<string, unknown>>({});

  constructor(private readonly authService: MsalService) { }

  ngOnInit(): void {
    const accounts = this.authService.instance.getAllAccounts();
    if (accounts.length > 0) {
      const acct = accounts[0];
      this.account.set(acct);
      this.claims.set(acct.idTokenClaims ?? {});
    }
  }

  get claimEntries(): [string, unknown][] {
    return Object.entries(this.claims());
  }

  formatValue(val: unknown): string {
    if (Array.isArray(val)) {
      return val.join(', ');
    }
    if (typeof val === 'object' && val !== null) {
      return JSON.stringify(val, null, 2);
    }
    return String(val ?? '—');
  }
}
