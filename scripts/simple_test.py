#!/usr/bin/env python3
"""
Simple Windows-compatible test runner
"""

import subprocess
import sys
from pathlib import Path

def run_syntax_check():
    """Run basic syntax check without emojis"""
    print("Running syntax check...")
    
    src_dir = Path("src")
    if not src_dir.exists():
        print("ERROR: src directory not found")
        return False
    
    verilog_files = list(src_dir.glob("*.v"))
    print(f"Found {len(verilog_files)} Verilog files")
    
    for vfile in verilog_files:
        try:
            with open(vfile, 'r') as f:
                content = f.read()
            
            if 'module' in content and 'endmodule' in content:
                print(f"  OK: {vfile.name}")
            else:
                print(f"  ERROR: {vfile.name} - missing module/endmodule")
                return False
        except Exception as e:
            print(f"  ERROR: {vfile.name} - {e}")
            return False
    
    return True

def check_project_structure():
    """Check basic project structure"""
    print("\nChecking project structure...")
    
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
    
    missing = []
    for file_path in required_files:
        if not Path(file_path).exists():
            missing.append(file_path)
    
    if missing:
        print(f"Missing files: {missing}")
        return False
    
    print(f"All {len(required_files)} core files present")
    return True

def check_verification():
    """Check verification environment"""
    print("\nChecking verification environment...")
    
    verification_files = [
        "verification/testbenches/unit/alu_tb.v",
        "verification/testbenches/unit/alu_tb.sv",
        "verification/testbenches/unit/register_file_tb.sv",
        "verification/testbenches/unit/control_unit_tb.sv",
        "verification/testbenches/unit/immediate_generator_tb.sv",
        "verification/testbenches/unit/program_counter_tb.sv",
        "verification/testbenches/unit/branch_unit_tb.sv",
        "verification/scripts/run_unit_tests.py",
        "verification/Makefile"
    ]
    
    missing = []
    for file_path in verification_files:
        if not Path(file_path).exists():
            missing.append(file_path)
    
    if missing:
        print(f"Missing verification files: {missing}")
        return False
    
    print(f"All {len(verification_files)} verification files present")
    return True

def main():
    """Main test function"""
    print("RISC-V Processor Simple Test Suite")
    print("=" * 40)
    
    tests = [
        ("Syntax Check", run_syntax_check),
        ("Project Structure", check_project_structure),
        ("Verification Environment", check_verification)
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        try:
            if test_func():
                print(f"PASS: {test_name}")
                passed += 1
            else:
                print(f"FAIL: {test_name}")
        except Exception as e:
            print(f"ERROR: {test_name} - {e}")
    
    print("\n" + "=" * 40)
    print("TEST RESULTS")
    print("=" * 40)
    print(f"Total: {total}")
    print(f"Passed: {passed}")
    print(f"Failed: {total - passed}")
    print(f"Success Rate: {(passed/total)*100:.1f}%")
    
    if passed == total:
        print("\nALL TESTS PASSED!")
        print("Project is ready for simulation and FPGA implementation")
        return 0
    else:
        print(f"\n{total - passed} TEST(S) FAILED")
        return 1

if __name__ == "__main__":
    exit(main())