#!/usr/bin/env python3
"""
Generate VS Code snippets from centralized snippets data.

This script reads data/snippets.json and generates the VS Code
snippets file for the BMath extension.
"""

import json
import sys
from pathlib import Path


def load_snippets_data(data_path: Path) -> dict:
    """Load snippets from JSON file."""
    snippets_file = data_path / "snippets.json"
    
    if not snippets_file.exists():
        print(f"Error: {snippets_file} not found", file=sys.stderr)
        sys.exit(1)
    
    with open(snippets_file, "r", encoding="utf-8") as f:
        return json.load(f)


def generate_vscode_snippets(snippets_data: dict) -> dict:
    """Convert snippets data to VS Code snippet format."""
    vscode_snippets = {}
    
    for snippet in snippets_data["snippets"]:
        vscode_snippets[snippet["name"]] = {
            "prefix": snippet["prefix"],
            "body": snippet["body"],
            "description": snippet["description"]
        }
    
    return vscode_snippets


def main():
    # Determine paths
    script_dir = Path(__file__).parent
    project_root = script_dir.parent
    data_dir = project_root / "data"
    vscode_snippets_dir = project_root / "vscode-ext" / "snippets"
    
    # Load snippets data
    print(f"Loading snippets from {data_dir / 'snippets.json'}...")
    snippets_data = load_snippets_data(data_dir)
    
    print(f"Found {len(snippets_data['snippets'])} snippets")
    
    # Generate VS Code snippets
    vscode_snippets = generate_vscode_snippets(snippets_data)
    
    # Write output file
    output_file = vscode_snippets_dir / "bmath.code-snippets"
    print(f"Writing VS Code snippets to {output_file}...")
    
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(vscode_snippets, f, indent=2, ensure_ascii=False)
    
    print("✓ Successfully generated VS Code snippets")
    print(f"  Version: {snippets_data['version']}")
    print(f"  Snippets: {len(vscode_snippets)}")


if __name__ == "__main__":
    main()
