#!/usr/bin/env python3
"""
Cross-platform Verilog syntax checker for RISC-V processor
Performs basic syntax validation without requiring external tools
"""

import os
import re
import sys
import glob
from pathlib import Path

class VerilogSyntaxChecker:
    def __init__(self):
        self.errors = []
        self.warnings = []
        self.files_checked = 0
        
    def check_file(self, filepath):
        """Check a single Verilog file for syntax issues"""
        print(f"Checking {filepath}...")
        
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
                lines = content.split('\n')
                
            self.files_checked += 1
            self._check_module_structure(filepath, content, lines)
            self._check_basic_syntax(filepath, lines)
            self._check_common_issues(filepath, lines)
            
        except Exception as e:
            self.errors.append(f"{filepath}: Failed to read file - {e}")
    
    def _check_module_structure(self, filepath, content, lines):
        """Check module declaration and structure"""
        # Check for module declaration
        module_pattern = r'^\s*module\s+(\w+)\s*\('
        endmodule_pattern = r'^\s*endmodule\s*$'
        
        module_count = 0
        endmodule_count = 0
        module_name = None
        
        for i, line in enumerate(lines, 1):
            module_match = re.search(module_pattern, line)
            if module_match:
                module_count += 1
                module_name = module_match.group(1)
                
            if re.search(endmodule_pattern, line):
                endmodule_count += 1
        
        if module_count == 0:
            self.errors.append(f"{filepath}: No module declaration found")
        elif module_count > 1:
            self.warnings.append(f"{filepath}: Multiple module declarations found")
            
        if endmodule_count == 0:
            self.errors.append(f"{filepath}: No endmodule found")
        elif module_count != endmodule_count:
            self.errors.append(f"{filepath}: Mismatched module/endmodule count")
            
        # Check if filename matches module name
        if module_name:
            expected_filename = f"{module_name}.v"
            actual_filename = os.path.basename(filepath)
            if actual_filename != expected_filename:
                self.warnings.append(f"{filepath}: Filename '{actual_filename}' doesn't match module name '{module_name}' (expected '{expected_filename}')")
    
    def _check_basic_syntax(self, filepath, lines):
        """Check basic Verilog syntax"""
        paren_count = 0
        brace_count = 0
        bracket_count = 0
        
        for i, line in enumerate(lines, 1):
            # Skip comments
            line_clean = re.sub(r'//.*$', '', line)
            line_clean = re.sub(r'/\*.*?\*/', '', line_clean)
            
            # Count parentheses, braces, brackets
            paren_count += line_clean.count('(') - line_clean.count(')')
            brace_count += line_clean.count('{') - line_clean.count('}')
            bracket_count += line_clean.count('[') - line_clean.count(']')
            
            # Check for common syntax errors
            if re.search(r';\s*;', line_clean):
                self.warnings.append(f"{filepath}:{i}: Double semicolon found")
                
            if re.search(r'=\s*=(?!=)', line_clean):
                self.warnings.append(f"{filepath}:{i}: Possible assignment operator error (== vs =)")
        
        # Check balanced parentheses/braces/brackets
        if paren_count != 0:
            self.errors.append(f"{filepath}: Unbalanced parentheses (net: {paren_count})")
        if brace_count != 0:
            self.errors.append(f"{filepath}: Unbalanced braces (net: {brace_count})")
        if bracket_count != 0:
            self.errors.append(f"{filepath}: Unbalanced brackets (net: {bracket_count})")
    
    def _check_common_issues(self, filepath, lines):
        """Check for common Verilog issues"""
        for i, line in enumerate(lines, 1):
            line_clean = line.strip()
            
            # Check for missing semicolons (basic heuristic)
            if (re.search(r'^\s*(input|output|wire|reg)\s+.*[^;]\s*$', line) and 
                not re.search(r'^\s*(input|output|wire|reg)\s+.*,\s*$', line)):
                self.warnings.append(f"{filepath}:{i}: Possible missing semicolon")
            
            # Check for undefined signals (basic check)
            if re.search(r'^\s*assign\s+\w+\s*=', line):
                # This is a basic check - a full parser would be needed for complete validation
                pass
            
            # Check for proper timescale
            if i == 1 and not re.search(r'`timescale', line):
                self.warnings.append(f"{filepath}: Missing timescale directive")
    
    def check_all_files(self, src_dir="src"):
        """Check all Verilog files in the source directory"""
        verilog_files = glob.glob(os.path.join(src_dir, "*.v"))
        
        if not verilog_files:
            self.errors.append(f"No Verilog files found in {src_dir} directory")
            return
        
        for filepath in sorted(verilog_files):
            self.check_file(filepath)
    
    def print_results(self):
        """Print the results of the syntax check"""
        print("\n" + "="*60)
        print("VERILOG SYNTAX CHECK RESULTS")
        print("="*60)
        
        print(f"Files checked: {self.files_checked}")
        print(f"Errors: {len(self.errors)}")
        print(f"Warnings: {len(self.warnings)}")
        
        if self.errors:
            print("\nERRORS:")
            for error in self.errors:
                print(f"  [ERROR] {error}")
        
        if self.warnings:
            print("\nWARNINGS:")
            for warning in self.warnings:
                print(f"  [WARN]  {warning}")
        
        if not self.errors and not self.warnings:
            print("\n[PASS] All files passed basic syntax checks!")
        elif not self.errors:
            print(f"\n[PASS] No errors found, but {len(self.warnings)} warnings to review")
        else:
            print(f"\n[FAIL] Found {len(self.errors)} errors that need to be fixed")
        
        return len(self.errors) == 0

def main():
    """Main function"""
    print("RISC-V Processor Verilog Syntax Checker")
    print("=" * 40)
    
    # Check if src directory exists
    if not os.path.exists("src"):
        print("[ERROR] 'src' directory not found!")
        print("Please run this script from the project root directory.")
        return 1
    
    checker = VerilogSyntaxChecker()
    checker.check_all_files()
    
    success = checker.print_results()
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())