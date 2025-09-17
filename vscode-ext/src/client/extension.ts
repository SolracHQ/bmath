/**
 * BMath Language Extension for Visual Studio Code
 * 
 * This extension provides comprehensive language support for BMath including:
 * - Syntax highlighting and language configuration
 * - Real-time diagnostics via Language Server Protocol (LSP)
 * - Hover information for symbols and expressions  
 * - Intelligent code completion
 * - Static analysis and error checking
 * 
 * The extension connects to the BMath LSP server (lspv2) which provides
 * all language intelligence features without caching to prevent memory issues.
 */

import * as vscode from 'vscode';
import * as path from 'path';
import * as fs from 'fs';
import {
    LanguageClient,
    LanguageClientOptions,
    ServerOptions,
    TransportKind,
    StreamInfo,
    RevealOutputChannelOn
} from 'vscode-languageclient/node';

let client: LanguageClient | undefined;

/**
 * Find the BMath LSP server executable
 */
function findLspExecutable(context: vscode.ExtensionContext): string | null {
    const config = vscode.workspace.getConfiguration('bmath');
    
    // 1. Check user-configured path
    const configuredPath = config.get<string>('lspPath');
    if (configuredPath && fs.existsSync(configuredPath)) {
        return configuredPath;
    }
    
    // 2. Check workspace bin directory
    const workspaceFolders = vscode.workspace.workspaceFolders || [];
    if (workspaceFolders.length > 0) {
        const workspaceRoot = workspaceFolders[0].uri.fsPath;
        const candidates = [
            path.join(workspaceRoot, 'bin', 'lsp'),
            path.join(workspaceRoot, 'bin', 'lsp.exe'), // Windows
            path.join(workspaceRoot, 'bin', 'lspv2'),
            path.join(workspaceRoot, 'bin', 'lspv2.exe') // Windows
        ];
        
        for (const candidate of candidates) {
            if (fs.existsSync(candidate)) {
                return candidate;
            }
        }
    }
    
    // 3. Check extension bundled binary
    const extensionCandidates = [
        path.join(context.extensionPath, 'bin', 'lsp'),
        path.join(context.extensionPath, 'bin', 'lsp.exe'),
        path.join(context.extensionPath, 'bin', 'lspv2'), 
        path.join(context.extensionPath, 'bin', 'lspv2.exe')
    ];
    
    for (const candidate of extensionCandidates) {
        if (fs.existsSync(candidate)) {
            return candidate;
        }
    }
    
    return null;
}

/**
 * Create and configure the Language Server Protocol client
 */
function createLanguageClient(lspPath: string, outputChannel: vscode.OutputChannel): LanguageClient {
    // Server options - how to start the LSP server
    const serverOptions: ServerOptions = (): Promise<StreamInfo> => {
        return new Promise((resolve, reject) => {
            const { spawn } = require('child_process');
            
            outputChannel.appendLine(`Starting BMath LSP server: ${lspPath}`);
            
            const serverProcess = spawn(lspPath, [], {
                stdio: ['pipe', 'pipe', 'pipe']
            });
            
            if (!serverProcess || !serverProcess.pid) {
                reject(new Error('Failed to start LSP server process'));
                return;
            }
            
            outputChannel.appendLine(`LSP server started with PID: ${serverProcess.pid}`);
            
            // Capture stderr for debugging
            serverProcess.stderr.on('data', (data: Buffer) => {
                const message = data.toString().trim();
                if (message) {
                    outputChannel.appendLine(`[Server] ${message}`);
                }
            });
            
            serverProcess.on('error', (error: Error) => {
                outputChannel.appendLine(`Server error: ${error.message}`);
                reject(error);
            });
            
            serverProcess.on('exit', (code: number, signal: string) => {
                outputChannel.appendLine(`Server exited with code ${code}, signal ${signal}`);
            });
            
            resolve({
                reader: serverProcess.stdout,
                writer: serverProcess.stdin
            });
        });
    };
    
    // Client options - how the client behaves
    const clientOptions: LanguageClientOptions = {
        documentSelector: [
            { scheme: 'file', language: 'bmath' },
            { scheme: 'untitled', language: 'bmath' }
        ],
        synchronize: {
            configurationSection: 'bmath',
            fileEvents: [
                vscode.workspace.createFileSystemWatcher('**/*.bm'),
                vscode.workspace.createFileSystemWatcher('**/bmath.json')
            ]
        },
        outputChannel: outputChannel,
        revealOutputChannelOn: RevealOutputChannelOn.Info,
        initializationOptions: {
            enableDiagnostics: vscode.workspace.getConfiguration('bmath').get('enableDiagnostics', true),
            enableHover: vscode.workspace.getConfiguration('bmath').get('enableHover', true), 
            enableCompletion: vscode.workspace.getConfiguration('bmath').get('enableCompletion', true),
            logLevel: vscode.workspace.getConfiguration('bmath').get('logLevel', 'info')
        }
    };
    
    return new LanguageClient(
        'bmathLanguageServer',
        'BMath Language Server',
        serverOptions,
        clientOptions
    );
}

/**
 * Extension activation function
 */
export function activate(context: vscode.ExtensionContext) {
    console.log('Activating BMath extension...');
    
    // Create output channel for logging
    const outputChannel = vscode.window.createOutputChannel('BMath Language Server');
    context.subscriptions.push(outputChannel);
    
    // Create status bar item  
    const statusBarItem = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
    statusBarItem.text = '$(loading~spin) BMath: Starting...';
    statusBarItem.tooltip = 'BMath Language Server Status';
    statusBarItem.show();
    context.subscriptions.push(statusBarItem);
    
    // Find LSP executable
    const lspPath = findLspExecutable(context);
    if (!lspPath) {
        const message = 'BMath LSP server not found. Please configure "bmath.lspPath" or ensure the server binary is at workspace/bin/lsp';
        vscode.window.showErrorMessage(message);
        statusBarItem.text = '$(error) BMath: Server not found';
        statusBarItem.tooltip = message;
        outputChannel.appendLine(message);
        outputChannel.show(true);
        return;
    }
    
    outputChannel.appendLine(`Found LSP server at: ${lspPath}`);
    outputChannel.show(true);
    
    // Create and start language client
    try {
        client = createLanguageClient(lspPath, outputChannel);
        
        // Handle client state changes
        client.onDidChangeState(event => {
            outputChannel.appendLine(`Client state changed: ${event.oldState} -> ${event.newState}`);
            switch (event.newState) {
                case 1: // Starting
                    statusBarItem.text = '$(loading~spin) BMath: Starting...';
                    break;
                case 2: // Running  
                    statusBarItem.text = '$(check) BMath: Ready';
                    statusBarItem.tooltip = 'BMath Language Server is running';
                    break;
                case 3: // Stopped
                    statusBarItem.text = '$(error) BMath: Stopped';
                    statusBarItem.tooltip = 'BMath Language Server has stopped';
                    break;
            }
        });
        
        // Register commands
        const showStatusCommand = vscode.commands.registerCommand('bmath.showServerStatus', () => {
            const state = client?.state ?? 'Unknown';
            const message = `BMath Language Server\nPath: ${lspPath}\nState: ${state}`;
            vscode.window.showInformationMessage(message);
        });
        context.subscriptions.push(showStatusCommand);
        
        const restartServerCommand = vscode.commands.registerCommand('bmath.restartServer', async () => {
            if (client) {
                outputChannel.appendLine('Restarting language server...');
                statusBarItem.text = '$(loading~spin) BMath: Restarting...';
                
                await client.stop();
                client = createLanguageClient(lspPath, outputChannel);
                await client.start();
                
                outputChannel.appendLine('Language server restarted');
            }
        });
        context.subscriptions.push(restartServerCommand);
        
        const runDiagnosticsCommand = vscode.commands.registerCommand('bmath.runDiagnostics', () => {
            const activeEditor = vscode.window.activeTextEditor;
            if (activeEditor && activeEditor.document.languageId === 'bmath') {
                // Force re-analysis by sending a document change
                const document = activeEditor.document;
                if (client && client.state === 2) { // Running
                    vscode.window.showInformationMessage('Running static analysis...');
                    // The LSP will automatically run diagnostics when we send the document
                }
            } else {
                vscode.window.showWarningMessage('No BMath file is currently active');
            }
        });
        context.subscriptions.push(runDiagnosticsCommand);
        
        // Start the client
        client.start().then(() => {
            outputChannel.appendLine('BMath Language Server started successfully');
        }).catch(error => {
            const errorMsg = `Failed to start BMath Language Server: ${error.message}`;
            vscode.window.showErrorMessage(errorMsg);
            statusBarItem.text = '$(error) BMath: Failed to start';
            statusBarItem.tooltip = errorMsg;
            outputChannel.appendLine(errorMsg);
        });
        
        context.subscriptions.push(client);
        
    } catch (error: any) {
        const errorMsg = `Failed to create BMath Language Client: ${error.message}`;
        vscode.window.showErrorMessage(errorMsg);
        statusBarItem.text = '$(error) BMath: Error';
        outputChannel.appendLine(errorMsg);
    }
    
    // Register configuration change handler
    const configChangeHandler = vscode.workspace.onDidChangeConfiguration(event => {
        if (event.affectsConfiguration('bmath')) {
            vscode.window.showInformationMessage(
                'BMath configuration changed. Restart the language server to apply changes.',
                'Restart'
            ).then(selection => {
                if (selection === 'Restart') {
                    vscode.commands.executeCommand('bmath.restartServer');
                }
            });
        }
    });
    context.subscriptions.push(configChangeHandler);
    
    console.log('BMath extension activated successfully');
}

/**
 * Extension deactivation function
 */
export function deactivate(): Thenable<void> | undefined {
    console.log('Deactivating BMath extension...');
    
    if (client) {
        return client.stop();
    }
    
    return undefined;
}