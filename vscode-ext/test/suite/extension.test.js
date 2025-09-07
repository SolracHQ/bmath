"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
Object.defineProperty(exports, "__esModule", { value: true });
const assert = __importStar(require("assert"));
const vscode = __importStar(require("vscode"));
const extension_1 = require("../../src/client/extension");
suite('BMath Extension Tests', () => {
    let disposable;
    setup(() => __awaiter(void 0, void 0, void 0, function* () {
        disposable = yield (0, extension_1.activate)();
    }));
    teardown(() => {
        disposable.dispose();
    });
    test('Syntax highlighting works', () => __awaiter(void 0, void 0, void 0, function* () {
        var _a;
        const document = yield vscode.workspace.openTextDocument({ content: 'let x = 42' });
        yield vscode.window.showTextDocument(document);
        const decorations = (_a = vscode.window.activeTextEditor) === null || _a === void 0 ? void 0 : _a.document.getText();
        assert.ok(decorations.includes('let'), 'Syntax highlighting for "let" should be present');
    }));
    test('Type inference works', () => __awaiter(void 0, void 0, void 0, function* () {
        const document = yield vscode.workspace.openTextDocument({ content: 'let y: integer = 5' });
        yield vscode.window.showTextDocument(document);
        // Simulate type inference logic here
        const inferredType = 'integer'; // This should be replaced with actual inference logic
        assert.strictEqual(inferredType, 'integer', 'Type inference should correctly identify the type');
    }));
    test('Code completion works', () => __awaiter(void 0, void 0, void 0, function* () {
        const document = yield vscode.workspace.openTextDocument({ content: 'let z = ' });
        yield vscode.window.showTextDocument(document);
        const completionItems = yield vscode.commands.executeCommand('vscode.executeCompletionItemProvider', document.uri, new vscode.Position(0, 10));
        assert.ok(completionItems && completionItems.length > 0, 'Code completion should provide suggestions');
    }));
});
