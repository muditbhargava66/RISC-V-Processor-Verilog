#!/usr/bin/env python3
"""
Simple syntax checker for Verilog files
Verifies basic module structure and syntax
"""

import os
import re
from pathlib import Path

def check_verilog_syntax(file_path):
    """Basic Verilog syntax checking"""
    errors = []
    warnings = []
    
    try:
        with open(file_path, 'r') as f:
            content = f.read()
        
        # Check for module declaration
        module_match = re.search(r'module\s+(\w+)', content)
        if not module_match:
            errors.append("No module declaration found")
            return errors, warnings
        
        module_name = module_match.group(1)
        
        # Check for endmodule
        if 'endmodule' not in content:
            errors.append("Missing endmodule")
        
        # Check for balanced parentheses
        paren_count = content.count('(') - content.count(')')
        if paren_count != 0:
            errors.append(f"Unbalanced parentheses: {paren_count}")
        
        # Check for balanced begin/end
        begin_count = len(re.findall(r'\bbegin\b', content))
        end_count = len(re.findall(r'\bend\b', content))
        if begin_count != end_count:
            warnings.append(f"Unbalanced begin/end: {begin_count} begin, {end_count} end")
        
        # Check for common syntax issues
        if re.search(r';\s*;', content):
            warnings.append("Double semicolons found")
        
        if re.search(r'=\s*=\s*[^=]', content):
            warnings.append("Possible assignment instead of comparison")
        
        print(f"OK {file_path.name}: Module '{module_name}'")
        
    except Exception as e:
        errors.append(f"Error reading file: {e}")
    
    return errors, warnings

def check_project_structure():
    """Check if all required files exist"""
    project_root = Path(".")
    required_files = [
        "src/alu.v",
        "src/register_file.v", 
        "src/control_unit.v",
        "src/immediate_generator.v",
        "src/program_counter.v",
        "src/instruction_memory.v",
        "src/data_memory.v",
        "src/branch_unit.v",
        "src/riscv_processor.v"
    ]
    
    missing_files = []
    existing_files = []
    
    for file_path in required_files:
        full_path = project_root / file_path
        if full_path.exists():
            existing_files.append(file_path)
        else:
            missing_files.append(file_path)
    
    print("Project Structure Check:")
    print(f"Found {len(existing_files)} source files")
    
    if missing_files:
        print(f"Missing {len(missing_files)} files:")
        for file in missing_files:
            print(f"   - {file}")
    
    return len(missing_files) == 0

def main():
    print("RISC-V Processor Syntax Checker")
    print("=" * 40)
    
    # Check project structure
    structure_ok = check_project_structure()
    print()
    
    if not structure_ok:
        print("Project structure incomplete")
        return 1
    
    # Check syntax of all Verilog files
    src_dir = Path("src")
    total_errors = 0
    total_warnings = 0
    
    print("Checking Verilog syntax:")
    
    for verilog_file in src_dir.glob("*.v"):
        errors, warnings = check_verilog_syntax(verilog_file)
        
        if errors:
            print(f"ERROR {verilog_file.name}: {len(errors)} errors")
            for error in errors:
                print(f"   ERROR: {error}")
            total_errors += len(errors)
        
        if warnings:
            print(f"WARNING {verilog_file.name}: {len(warnings)} warnings")
            for warning in warnings:
                print(f"   WARNING: {warning}")
            total_warnings += len(warnings)
    
    print()
    print("Summary:")
    print(f"   Total errors: {total_errors}")
    print(f"   Total warnings: {total_warnings}")
    
    if total_errors == 0:
        print("All syntax checks passed!")
        return 0
    else:
        print("Syntax errors found")
        return 1

if __name__ == "__main__":
    exit(main())