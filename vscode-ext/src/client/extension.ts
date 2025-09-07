import * as vscode from 'vscode';
import * as path from 'path';
import * as fs from 'fs';
// Intentionally do not import local feature providers (hover/completion/typeInference/diagnostics).
// This extension relies solely on the external Language Server Protocol (LSP) for features.
import {
    LanguageClient,
    LanguageClientOptions,
    ServerOptions,
    TransportKind,
    StreamInfo
} from 'vscode-languageclient/node';
import { RevealOutputChannelOn, Trace } from 'vscode-languageclient';
import { spawn } from 'child_process';

function findLspExecutable(context: vscode.ExtensionContext): string | null {
    // 1) user-configured path
    const cfg = vscode.workspace.getConfiguration('bmath');
    const configured = cfg.get<string>('lspPath');
    if (configured && fs.existsSync(configured)) return configured;

    // 2) workspace/bin/lsp (common during development)
    const folders = vscode.workspace.workspaceFolders || [];
    if (folders.length > 0) {
        const candidate = path.join(folders[0].uri.fsPath, 'bin', 'lsp');
        if (fs.existsSync(candidate)) return candidate;
        // Windows executable
        if (process.platform === 'win32') {
            const winCandidate = candidate + '.exe';
            if (fs.existsSync(winCandidate)) return winCandidate;
        }
    }

    // 3) extension bundled bin (if you package the binary inside the extension)
    const extCandidate = path.join(context.extensionPath, 'bin', 'lsp');
    if (fs.existsSync(extCandidate)) return extCandidate;
    if (process.platform === 'win32') {
        const winExt = extCandidate + '.exe';
        if (fs.existsSync(winExt)) return winExt;
    }

    return null;
}

export function activate(context: vscode.ExtensionContext) {

    // Try to find the LSP executable and start a LanguageClient to connect to it
    const lspExec = findLspExecutable(context);
    if (!lspExec) {
        vscode.window.showWarningMessage('BMath LSP binary not found. Configure "bmath.lspPath" or place the binary at workspace/bin/lsp');
        return;
    }

    // status bar item to make server state visible
    const status = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 100);
    status.text = 'BMath: starting...';
    status.tooltip = 'BMath language server status';
    status.show();
    context.subscriptions.push(status);

    // ensure an Output channel exists (explicitly created so user can open it)
    const outChannel = vscode.window.createOutputChannel('BMath LSP');
    context.subscriptions.push(outChannel);
    outChannel.appendLine(`BMath extension: will try to start LSP at: ${lspExec}`);
    // show the output channel briefly so user sees startup messages
    outChannel.show(true);

    // Server logs are written to stderr by default; this extension captures stderr
    outChannel.appendLine('Note: BMath LSP logs are captured from the server stderr.');

    // register a helpful command to show server status/path
    const statusCmd = vscode.commands.registerCommand('bmath.showServerStatus', () => {
        const msg = `LSP exec: ${lspExec}\nStatus: ${status.text}`;
        vscode.window.showInformationMessage(msg);
    });
    context.subscriptions.push(statusCmd);

    try {
        // Basic check: executable exists
        // We spawn the process manually so we can capture stderr into the OutputChannel
        const serverOptions: ServerOptions = () : Promise<StreamInfo> => {
            return new Promise((resolve, _reject) => {
                const cwd = (vscode.workspace.workspaceFolders && vscode.workspace.workspaceFolders[0].uri.fsPath) || undefined;
                const child = spawn(lspExec, [], { cwd });
                child.stderr.on('data', (chunk: Buffer) => {
                    outChannel.append(chunk.toString());
                });
                child.on('exit', (code, signal) => {
                    outChannel.appendLine(`LSP process exited with code=${code} signal=${signal}`);
                    status.text = 'BMath: stopped';
                });
                const stream: StreamInfo = { writer: child.stdin as any, reader: child.stdout as any };
                child.stdout.on('data', (chunk: Buffer) => {
                    outChannel.append(chunk.toString());
                });
                resolve(stream);
            });
        };

        const clientOptions: LanguageClientOptions = {
            documentSelector: [{ scheme: 'file', language: 'bmath' }],
            synchronize: {
                // synchronize the setting section 'bmath' to the server
                configurationSection: 'bmath'
            }
            ,
            // Reveal the output channel when the server logs useful information
            revealOutputChannelOn: RevealOutputChannelOn.Info,
            // pass the explicit channel so it is always present
            outputChannel: outChannel
        };

    const client = new LanguageClient('bmathLanguageServer', 'BMath Language Server', serverOptions, clientOptions);
    // push the client (it has dispose()) and start it
    context.subscriptions.push(client);
    // enable verbose protocol tracing so the Output channel shows requests/responses
    (client as any).trace = Trace.Verbose;
        try {
            outChannel.appendLine('Starting language client...');
            client.start();
            status.text = 'BMath: running';
            status.tooltip = 'BMath LSP is running';
            outChannel.appendLine('Language client started.');
        } catch (err: any) {
            status.text = 'BMath: error';
            outChannel.appendLine('Error starting language client: ' + String(err));
            vscode.window.showErrorMessage('BMath LSP failed to start: ' + String(err));
        }
    } catch (e) {
        outChannel.appendLine('Failed to start BMath language server: ' + (e && (e as Error).message || String(e)));
        vscode.window.showErrorMessage('Failed to start BMath language server: ' + (e && (e as Error).message || String(e)));
    }
}

export function deactivate() {}