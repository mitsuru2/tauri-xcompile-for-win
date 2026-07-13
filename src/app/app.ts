import { Component, signal } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { ButtonDirective } from 'primeng/button';
import { Card } from 'primeng/card';
import { Divider } from 'primeng/divider';
import { Tag } from 'primeng/tag';
import { Bolt } from '@primeicons/angular/bolt';
import { Box } from '@primeicons/angular/box';
import { Desktop } from '@primeicons/angular/desktop';
import { ExternalLink } from '@primeicons/angular/external-link';
import { Palette } from '@primeicons/angular/palette';

@Component({
  selector: 'app-root',
  imports: [
    RouterOutlet,
    ButtonDirective,
    Card,
    Divider,
    Tag,
    Bolt,
    Box,
    Desktop,
    ExternalLink,
    Palette,
  ],
  templateUrl: './app.html',
  styleUrl: './app.scss',
})
export class App {
  protected readonly title = signal('tauri-xcompile-for-win');
}
