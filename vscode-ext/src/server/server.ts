import * as vscode from 'vscode';
import { createServer } from 'vscode-languageserver';

const server = createServer();

server.onInitialize(() => {
    return {
        capabilities: {
            textDocumentSync: vscode.TextDocumentSyncKind.Incremental,
            hoverProvider: true,
            completionProvider: {
                resolveProvider: true,
                triggerCharacters: ['.']
            },
            definitionProvider: true,
            typeDefinitionProvider: true,
            documentSymbolProvider: true,
            workspaceSymbolProvider: true,
            signatureHelpProvider: {
                triggerCharacters: ['(']
            },
            codeActionProvider: true,
            documentFormattingProvider: true,
            documentRangeFormattingProvider: true,
            renameProvider: true,
            referencesProvider: true,
            diagnosticsProvider: true,
        }
    };
});

// Add additional handlers and features as needed

server.listen();