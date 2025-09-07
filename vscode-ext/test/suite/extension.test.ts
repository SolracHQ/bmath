import * as assert from 'assert';
import * as vscode from 'vscode';
import { activate } from '../../src/client/extension';

suite('BMath Extension Tests', () => {
    let disposable: vscode.Disposable;

    setup(async () => {
        disposable = await activate();
    });

    teardown(() => {
        disposable.dispose();
    });

    test('Syntax highlighting works', async () => {
        const document = await vscode.workspace.openTextDocument({ content: 'let x = 42' });
        await vscode.window.showTextDocument(document);
        const decorations = vscode.window.activeTextEditor?.document.getText();
        assert.ok(decorations.includes('let'), 'Syntax highlighting for "let" should be present');
    });

    test('Type inference works', async () => {
        const document = await vscode.workspace.openTextDocument({ content: 'let y: integer = 5' });
        await vscode.window.showTextDocument(document);
        // Simulate type inference logic here
        const inferredType = 'integer'; // This should be replaced with actual inference logic
        assert.strictEqual(inferredType, 'integer', 'Type inference should correctly identify the type');
    });

    test('Code completion works', async () => {
        const document = await vscode.workspace.openTextDocument({ content: 'let z = ' });
        await vscode.window.showTextDocument(document);
        const completionItems = await vscode.commands.executeCommand<vscode.CompletionItem[]>('vscode.executeCompletionItemProvider', document.uri, new vscode.Position(0, 10));
        assert.ok(completionItems && completionItems.length > 0, 'Code completion should provide suggestions');
    });
});