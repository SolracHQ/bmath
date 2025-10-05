#!/usr/bin/env python3
"""
Generate BMath Standard Library Documentation from JSON.

This script reads the stdlib.json file and generates
comprehensive Markdown documentation for all standard library functions and constants.
"""

import json
import os
from pathlib import Path
from typing import Dict, List, Any


def format_type(type_spec: Any) -> str:
    """Format a type specification into a readable string."""
    if isinstance(type_spec, str):
        return type_spec
    elif isinstance(type_spec, list):
        return " | ".join(type_spec)
    return "Any"


def format_param(param: Dict[str, Any]) -> str:
    """Format a parameter specification into a readable string."""
    name = param["name"]
    param_type = format_type(param["type"])
    
    parts = [f"`{name}: {param_type}`"]
    
    if param.get("optional", False):
        parts.append("(optional)")
    if param.get("variadic", False):
        parts.append("(variadic)")
    
    return " ".join(parts)


def format_signature(sig: Dict[str, Any]) -> str:
    """Format a function signature into readable text."""
    params = sig.get("params", [])
    returns = format_type(sig.get("returns", "Any"))
    
    if not params:
        return f"|| -> {returns}"
    
    param_strs = []
    for param in params:
        name = param["name"]
        param_type = format_type(param["type"])
        
        if param.get("variadic", False):
            # Variadic parameters: ...name: Type
            param_strs.append(f"...{name}: {param_type}")
        elif param.get("optional", False):
            # Optional parameters: name?: Type if no default, or name: Type = default if default provided
            if "default" in param:
                default_val = param["default"]
                param_strs.append(f"{name}: {param_type} = {default_val}")
            else:
                param_strs.append(f"{name}?: {param_type}")
        else:
            param_strs.append(f"{name}: {param_type}")
    
    return f"|{', '.join(param_strs)}| -> {returns}"


def generate_function_doc(func_name: str, func_data: Dict[str, Any]) -> str:
    """Generate documentation for a single function."""
    lines = []
    
    # Function header
    lines.append(f"### `{func_name}`")
    lines.append("")
    
    # Description
    description = func_data.get("description", "No description available.")
    lines.append(description)
    lines.append("")
    
    # Signatures
    signatures = func_data.get("signatures", [])
    if signatures:
        if len(signatures) == 1:
            lines.append("**Signature:**")
        else:
            lines.append("**Signatures:**")
        lines.append("")
        
        for sig in signatures:
            lines.append(f"```bmath")
            lines.append(format_signature(sig))
            lines.append(f"```")
            lines.append("")
            
            # Parameter descriptions (if available)
            params = sig.get("params", [])
            if params and any(p.get("description") for p in params):
                lines.append("**Parameters:**")
                lines.append("")
                for param in params:
                    desc = param.get("description", "")
                    if desc:
                        param_spec = format_param(param)
                        lines.append(f"- {param_spec}: {desc}")
                lines.append("")
            
            # Return type description (if available)
            returns = format_type(sig.get("returns", "Any"))
            lines.append(f"**Returns:** `{returns}`")
            lines.append("")
    
    # Examples
    examples = func_data.get("examples", [])
    if examples:
        lines.append("**Examples:**")
        lines.append("")
        for example in examples:
            lines.append(f"```bm")
            lines.append(example)
            lines.append(f"```")
            lines.append("")
    
    lines.append("---")
    lines.append("")
    
    return "\n".join(lines)


def categorize_functions(functions: Dict[str, Dict[str, Any]]) -> Dict[str, List[str]]:
    """Categorize functions based on their 'category' field in JSON."""
    # Category display name mapping
    CATEGORY_NAMES = {
        "core": "Core Functions",
        "arithmetic": "Arithmetic",
        "trigonometric": "Trigonometric",
        "vector": "Vector Operations",
        "sequence": "Sequence Operations",
        "functional": "Functional",
        "comparison": "Comparison",
        "assertions": "Assertions",
        "type-system": "Type System",
    }
    
    categories: Dict[str, List[str]] = {}
    
    # Group functions by their category field
    for func_name, func_data in functions.items():
        category = func_data.get("category", "other")
        display_name = CATEGORY_NAMES.get(category, "Other")
        
        if display_name not in categories:
            categories[display_name] = []
        categories[display_name].append(func_name)
    
    # Sort functions within each category
    for func_list in categories.values():
        func_list.sort()
    
    return categories


def generate_category_doc(category: str, func_names: List[str], functions: Dict[str, Dict[str, Any]]) -> str:
    """Generate documentation for a category of functions."""
    lines = []
    
    # Category header
    lines.append(f"## {category}")
    lines.append("")
    
    # Generate docs for each function in the category
    for func_name in func_names:
        if func_name in functions:
            lines.append(generate_function_doc(func_name, functions[func_name]))
    
    return "\n".join(lines)


def generate_index(categories: Dict[str, List[str]]) -> str:
    """Generate the index/table of contents."""
    lines = []
    
    lines.append("# BMath Standard Library Reference")
    lines.append("")
    lines.append("Complete reference documentation for all BMath standard library functions.")
    lines.append("")
    lines.append("## Table of Contents")
    lines.append("")
    
    for category in categories.keys():
        # Create anchor link (lowercase, spaces to hyphens)
        anchor = category.lower().replace(" ", "-")
        lines.append(f"- [{category}](#{anchor})")
    
    lines.append("")
    lines.append("---")
    lines.append("")
    
    return "\n".join(lines)


def main():
    """Main function to generate documentation."""
    # Paths
    script_dir = Path(__file__).parent
    project_dir = script_dir.parent
    json_path = project_dir / "data" / "stdlib.json"
    output_dir = project_dir / "docs" / "stdlib"
    
    # Ensure output directory exists
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Load JSON data
    print(f"Loading signatures from: {json_path}")
    with open(json_path, "r") as f:
        data = json.load(f)
    
    functions = data.get("functions", {})
    version = data.get("version", "unknown")
    
    print(f"Loaded {len(functions)} functions (version {version})")
    
    # Categorize functions
    categories = categorize_functions(functions)
    
    # Generate complete reference document
    output_path = output_dir / "reference.md"
    print(f"Generating complete reference: {output_path}")
    
    with open(output_path, "w") as f:
        # Write header
        f.write(f"<!-- Auto-generated from stdlib.json - DO NOT EDIT MANUALLY -->\n")
        f.write(f"<!-- Version: {version} -->\n\n")
        
        # Write index
        f.write(generate_index(categories))
        
        # Write each category
        for category, func_names in categories.items():
            f.write(generate_category_doc(category, func_names, functions))
            f.write("\n")
    
    # Generate individual category files (optional)
    print("\nGenerating category-specific files:")
    for category, func_names in categories.items():
        # Create filename from category name
        filename = category.lower().replace(" ", "-") + ".md"
        category_path = output_dir / filename
        
        print(f"  - {filename}")
        with open(category_path, "w") as f:
            f.write(f"<!-- Auto-generated from stdlib.json - DO NOT EDIT MANUALLY -->\n")
            f.write(f"<!-- Version: {version} -->\n\n")
            f.write(generate_category_doc(category, func_names, functions))
    
    # Generate index.md
    index_path = output_dir / "index.md"
    print(f"\nGenerating index: {index_path}")
    with open(index_path, "w") as f:
        f.write(f"<!-- Auto-generated from stdlib.json - DO NOT EDIT MANUALLY -->\n")
        f.write(f"<!-- Version: {version} -->\n\n")
        f.write("# BMath Standard Library Documentation\n\n")
        f.write(f"Version: {version}\n\n")
        f.write("## Function Categories\n\n")
        
        for category, func_names in categories.items():
            filename = category.lower().replace(" ", "-") + ".md"
            f.write(f"### [{category}]({filename})\n\n")
            f.write(f"{len(func_names)} functions: ")
            f.write(", ".join(f"`{name}`" for name in func_names))
            f.write("\n\n")
        
        f.write("## Complete Reference\n\n")
        f.write("See [reference.md](reference.md) for the complete function reference.\n")
    
    print("\n✅ Documentation generation complete!")


if __name__ == "__main__":
    main()
