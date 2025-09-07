import * as vscode from 'vscode';
import { createServer } from './server';

export function activate(context: vscode.ExtensionContext) {
    const server = createServer();
    context.subscriptions.push(server);
}

export function deactivate() {
    // Clean up resources if needed
}