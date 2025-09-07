import * as vscode from 'vscode';

export function getHoverInformation(word: string, document: vscode.TextDocument, position: vscode.Position): vscode.Hover {
  return new vscode.Hover(`Hover info for **${word}**`);
}

export function getCompletionItems(document: vscode.TextDocument, position: vscode.Position): vscode.CompletionItem[] {
  // Simple passthrough to create similar completion items as the completion provider
  return [
    new vscode.CompletionItem('if', vscode.CompletionItemKind.Keyword),
    new vscode.CompletionItem('else', vscode.CompletionItemKind.Keyword),
  ];
}

export function getDiagnostics(document: vscode.TextDocument): vscode.Diagnostic[] {
  const diagnostics: vscode.Diagnostic[] = [];
  const text = document.getText();
  const lines = text.split(/\r?\n/);
  lines.forEach((line, index) => {
    if (line.includes('error')) {
      diagnostics.push(new vscode.Diagnostic(new vscode.Range(index, 0, index, line.length), 'Detected an error in the line.', vscode.DiagnosticSeverity.Error));
    }
  });
  return diagnostics;
}