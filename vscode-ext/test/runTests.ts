import * as assert from 'assert';
import * as path from 'path';
import * as vscode from 'vscode';
import { runTests } from 'vscode-test';

async function main() {
    try {
        // The path to the extension being tested
        const extensionPath = path.resolve(__dirname, '../..');

        // The path to the test runner
        const testRunnerPath = path.resolve(__dirname, './suite');

        // Run the tests
        await runTests({ extensionDevelopmentPath: extensionPath, extensionTestsPath: testRunnerPath });
    } catch (err) {
        console.error('Failed to run tests: ' + err);
        process.exit(1);
    }
}

main();