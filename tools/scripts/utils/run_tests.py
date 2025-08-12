#!/usr/bin/env python3
"""
Cross-platform test runner for RISC-V processor
Runs various tests and checks without requiring Vivado
"""

import os
import sys
import subprocess
import platform
from pathlib import Path

class TestRunner:
    def __init__(self):
        self.tests_run = 0
        self.tests_passed = 0
        self.tests_failed = 0
        self.os_type = platform.system()
        
    def run_command(self, command, description=""):
        """Run a command and return success status"""
        print(f"\n{'='*50}")
        print(f"Running: {description or command}")
        print('='*50)
        
        try:
            if self.os_type == "Windows":
                result = subprocess.run(command, shell=True, capture_output=True, text=True)
            else:
                result = subprocess.run(command, shell=True, capture_output=True, text=True, executable='/bin/bash')
            
            if result.stdout:
                print("STDOUT:")
                print(result.stdout)
            
            if result.stderr:
                print("STDERR:")
                print(result.stderr)
            
            return result.returncode == 0
            
        except Exception as e:
            print(f"Error running command: {e}")
            return False
    
    def test_file_structure(self):
        """Test that all required files exist"""
        print("\n[TEST] Testing file structure...")
        self.tests_run += 1
        
        required_files = [
            "src/processor_top.v",
            "src/alu.v",
            "src/ALU_control.v",
            "src/Control_unit.v",
            "src/data_ext.v",
            "src/data_mem.v",
            "src/imm_gen.v",
            "src/instr_mem.v",
            "src/PC.v",
            "src/pc_adder.v",
            "src/regfile.v",
            "src/shifter.v",
            "constraints/processor.xdc",
            "testbenches/processor_vivado_tb.v"
        ]
        
        missing_files = []
        for file_path in required_files:
            if not os.path.exists(file_path):
                missing_files.append(file_path)
        
        if missing_files:
            print("[FAIL] Missing files:")
            for file_path in missing_files:
                print(f"   - {file_path}")
            self.tests_failed += 1
            return False
        else:
            print("[PASS] All required files present")
            self.tests_passed += 1
            return True
    
    def test_syntax_check(self):
        """Run Python-based syntax checker"""
        print("\n[TEST] Testing Verilog syntax...")
        self.tests_run += 1
        
        if self.os_type == "Windows":
            command = "python scripts/syntax_check.py"
        else:
            command = "python3 scripts/syntax_check.py"
        
        success = self.run_command(command, "Python syntax checker")
        
        if success:
            print("[PASS] Syntax check passed")
            self.tests_passed += 1
        else:
            print("[FAIL] Syntax check failed")
            self.tests_failed += 1
        
        return success
    
    def test_iverilog_syntax(self):
        """Test with iverilog if available"""
        print("\n[TEST] Testing with iverilog (if available)...")
        self.tests_run += 1
        
        # Check if iverilog is available
        try:
            if self.os_type == "Windows":
                result = subprocess.run("where iverilog", shell=True, capture_output=True)
            else:
                result = subprocess.run("which iverilog", shell=True, capture_output=True)
            
            if result.returncode != 0:
                print("[SKIP] iverilog not found - skipping this test")
                self.tests_run -= 1  # Don't count this as a test
                return True
        except:
            print("[SKIP] iverilog not available - skipping this test")
            self.tests_run -= 1  # Don't count this as a test
            return True
        
        # Test each Verilog file
        verilog_files = [
            "src/processor_top.v",
            "src/alu.v",
            "src/ALU_control.v",
            "src/Control_unit.v",
            "src/data_ext.v",
            "src/data_mem.v",
            "src/imm_gen.v",
            "src/instr_mem.v",
            "src/PC.v",
            "src/pc_adder.v",
            "src/regfile.v",
            "src/shifter.v"
        ]
        
        all_passed = True
        for vfile in verilog_files:
            command = f"iverilog -t null -Wall {vfile}"
            if not self.run_command(command, f"iverilog check for {vfile}"):
                all_passed = False
        
        if all_passed:
            print("[PASS] iverilog syntax check passed")
            self.tests_passed += 1
        else:
            print("[FAIL] iverilog syntax check failed")
            self.tests_failed += 1
        
        return all_passed
    
    def test_directory_structure(self):
        """Test that directories are properly set up"""
        print("\n[TEST] Testing directory structure...")
        self.tests_run += 1
        
        required_dirs = ["src", "testbenches", "constraints", "scripts"]
        optional_dirs = ["reports", "logs", "vivado_project"]
        
        missing_dirs = []
        for dir_path in required_dirs:
            if not os.path.exists(dir_path):
                missing_dirs.append(dir_path)
        
        if missing_dirs:
            print("[FAIL] Missing required directories:")
            for dir_path in missing_dirs:
                print(f"   - {dir_path}")
            self.tests_failed += 1
            return False
        else:
            print("[PASS] All required directories present")
            
            # Check optional directories
            for dir_path in optional_dirs:
                if os.path.exists(dir_path):
                    print(f"[INFO] Optional directory present: {dir_path}")
                else:
                    print(f"[INFO] Optional directory missing: {dir_path} (will be created when needed)")
            
            self.tests_passed += 1
            return True
    
    def test_makefile_targets(self):
        """Test that Makefile targets work"""
        print("\n[TEST] Testing Makefile targets...")
        self.tests_run += 1
        
        # Test help target
        if self.os_type == "Windows":
            # On Windows, we might not have make, so skip this test
            try:
                result = subprocess.run("where make", shell=True, capture_output=True)
                if result.returncode != 0:
                    print("[SKIP] make not found on Windows - skipping Makefile test")
                    self.tests_run -= 1
                    return True
            except:
                print("[SKIP] make not available - skipping Makefile test")
                self.tests_run -= 1
                return True
        
        success = self.run_command("make help", "Makefile help target")
        
        if success:
            print("[PASS] Makefile targets accessible")
            self.tests_passed += 1
        else:
            print("[FAIL] Makefile targets failed")
            self.tests_failed += 1
        
        return success
    
    def run_all_tests(self):
        """Run all available tests"""
        print("RISC-V Processor Test Suite")
        print("=" * 50)
        print(f"Platform: {platform.system()} {platform.release()}")
        print(f"Python: {sys.version}")
        
        # Run tests
        self.test_file_structure()
        self.test_directory_structure()
        self.test_syntax_check()
        self.test_iverilog_syntax()
        self.test_makefile_targets()
        
        # Print summary
        print("\n" + "="*60)
        print("TEST SUMMARY")
        print("="*60)
        print(f"Tests run: {self.tests_run}")
        print(f"Passed: {self.tests_passed}")
        print(f"Failed: {self.tests_failed}")
        
        if self.tests_failed == 0:
            print("\n[SUCCESS] ALL TESTS PASSED!")
            print("Your RISC-V processor project is ready for Vivado!")
        else:
            print(f"\n[FAIL] {self.tests_failed} tests failed")
            print("Please fix the issues before proceeding with Vivado synthesis.")
        
        return self.tests_failed == 0

def main():
    """Main function"""
    runner = TestRunner()
    success = runner.run_all_tests()
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())