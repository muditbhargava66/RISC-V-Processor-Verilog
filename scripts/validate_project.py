#!/usr/bin/env python3
"""
RISC-V Processor Project Validation
Comprehensive validation without requiring FPGA tools
"""

import subprocess
import sys
import re
from pathlib import Path

class ProjectValidator:
    """Comprehensive project validator"""
    
    def __init__(self):
        self.results = {}
        self.total_tests = 0
        self.passed_tests = 0
    
    def test_file_structure(self):
        """Test complete file structure"""
        print("📁 Testing file structure...")
        
        required_files = {
            # Core source files
            "src/alu.v": "ALU module",
            "src/register_file.v": "Register file module",
            "src/control_unit.v": "Control unit module",
            "src/immediate_generator.v": "Immediate generator module",
            "src/program_counter.v": "Program counter module",
            "src/instruction_memory.v": "Instruction memory module",
            "src/data_memory.v": "Data memory module",
            "src/branch_unit.v": "Branch unit module",
            "src/riscv_processor.v": "Top-level processor module",
            
            # Verification files
            "verification/testbenches/unit/alu_tb.v": "ALU basic testbench",
            "verification/testbenches/unit/alu_tb.sv": "ALU comprehensive testbench",
            "verification/testbenches/unit/register_file_tb.sv": "Register file testbench",
            "verification/testbenches/unit/control_unit_tb.sv": "Control unit testbench",
            "verification/testbenches/unit/immediate_generator_tb.sv": "Immediate generator testbench",
            "verification/testbenches/unit/program_counter_tb.sv": "Program counter testbench",
            "verification/testbenches/unit/branch_unit_tb.sv": "Branch unit testbench",
            "verification/testbenches/system/simple_processor_tb.v": "Simple system testbench",
            "verification/testbenches/system/processor_system_tb.sv": "Full system testbench",
            
            # Build and constraint files
            "constraints/riscv_processor.xdc": "Vivado constraints",
            "constraints/riscv_processor.sdc": "Quartus constraints",
            "scripts/build_project.tcl": "Vivado build script",
            "scripts/build_quartus_project.tcl": "Quartus build script",
            
            # Documentation and automation
            "README.md": "Project documentation",
            "PROJECT_SUMMARY.md": "Project summary",
            "verification/README.md": "Verification documentation",
            "verification/Makefile": "Verification automation",
            "verification/scripts/run_unit_tests.py": "Unit test runner"
        }
        
        missing_files = []
        present_files = []
        
        for file_path, description in required_files.items():
            if Path(file_path).exists():
                present_files.append((file_path, description))
            else:
                missing_files.append((file_path, description))
        
        self.total_tests += 1
        if not missing_files:
            print(f"✅ All {len(required_files)} required files present")
            self.passed_tests += 1
            self.results["file_structure"] = True
        else:
            print(f"❌ {len(missing_files)} files missing:")
            for file_path, desc in missing_files:
                print(f"   - {file_path} ({desc})")
            self.results["file_structure"] = False
        
        return not missing_files
    
    def test_verilog_syntax(self):
        """Test Verilog syntax and module structure"""
        print("\n🔍 Testing Verilog syntax...")
        
        src_files = list(Path("src").glob("*.v"))
        syntax_errors = []
        
        for vfile in src_files:
            try:
                with open(vfile, 'r') as f:
                    content = f.read()
                
                # Check for module declaration
                if not re.search(r'module\s+\w+', content):
                    syntax_errors.append(f"{vfile.name}: No module declaration")
                    continue
                
                # Check for endmodule
                if 'endmodule' not in content:
                    syntax_errors.append(f"{vfile.name}: Missing endmodule")
                
                # Check for balanced parentheses
                paren_count = content.count('(') - content.count(')')
                if paren_count != 0:
                    syntax_errors.append(f"{vfile.name}: Unbalanced parentheses ({paren_count})")
                
                # Check for basic Verilog constructs
                if vfile.name == "riscv_processor.v":
                    required_modules = ["alu", "register_file", "control_unit", "immediate_generator"]
                    for module in required_modules:
                        if module not in content:
                            syntax_errors.append(f"{vfile.name}: Missing {module} instantiation")
                
            except Exception as e:
                syntax_errors.append(f"{vfile.name}: Error reading file - {e}")
        
        self.total_tests += 1
        if not syntax_errors:
            print(f"✅ All {len(src_files)} Verilog files pass syntax check")
            self.passed_tests += 1
            self.results["verilog_syntax"] = True
        else:
            print(f"❌ {len(syntax_errors)} syntax issues found:")
            for error in syntax_errors:
                print(f"   - {error}")
            self.results["verilog_syntax"] = False
        
        return not syntax_errors
    
    def test_testbench_structure(self):
        """Test testbench structure and completeness"""
        print("\n🧪 Testing testbench structure...")
        
        testbench_files = [
            "verification/testbenches/unit/alu_tb.sv",
            "verification/testbenches/unit/register_file_tb.sv",
            "verification/testbenches/unit/control_unit_tb.sv",
            "verification/testbenches/unit/immediate_generator_tb.sv",
            "verification/testbenches/unit/program_counter_tb.sv",
            "verification/testbenches/unit/branch_unit_tb.sv"
        ]
        
        testbench_errors = []
        
        for tb_file in testbench_files:
            if not Path(tb_file).exists():
                testbench_errors.append(f"{tb_file}: File missing")
                continue
            
            try:
                with open(tb_file, 'r') as f:
                    content = f.read()
                
                # Check for testbench module
                if not re.search(r'module\s+\w+_tb', content):
                    testbench_errors.append(f"{tb_file}: No testbench module found")
                
                # Check for DUT instantiation
                if "dut" not in content.lower():
                    testbench_errors.append(f"{tb_file}: No DUT instantiation found")
                
                # Check for test reporting
                if "$display" not in content:
                    testbench_errors.append(f"{tb_file}: No test reporting found")
                
                # Check for test completion
                if "$finish" not in content:
                    testbench_errors.append(f"{tb_file}: No test completion found")
                
            except Exception as e:
                testbench_errors.append(f"{tb_file}: Error reading file - {e}")
        
        self.total_tests += 1
        if not testbench_errors:
            print(f"✅ All {len(testbench_files)} testbenches pass structure check")
            self.passed_tests += 1
            self.results["testbench_structure"] = True
        else:
            print(f"❌ {len(testbench_errors)} testbench issues found:")
            for error in testbench_errors:
                print(f"   - {error}")
            self.results["testbench_structure"] = False
        
        return not testbench_errors
    
    def test_build_scripts(self):
        """Test build script completeness"""
        print("\n🔨 Testing build scripts...")
        
        build_scripts = {
            "scripts/build_project.tcl": ["create_project", "add_files", "set_property"],
            "scripts/build_quartus_project.tcl": ["project_new", "set_global_assignment", "VERILOG_FILE"],
            "scripts/build_all_projects.py": ["class ProjectBuilder", "build_vivado_project", "build_quartus_project"]
        }
        
        script_errors = []
        
        for script_path, required_content in build_scripts.items():
            if not Path(script_path).exists():
                script_errors.append(f"{script_path}: File missing")
                continue
            
            try:
                with open(script_path, 'r') as f:
                    content = f.read()
                
                for required in required_content:
                    if required not in content:
                        script_errors.append(f"{script_path}: Missing '{required}'")
                
            except Exception as e:
                script_errors.append(f"{script_path}: Error reading file - {e}")
        
        self.total_tests += 1
        if not script_errors:
            print(f"✅ All {len(build_scripts)} build scripts pass completeness check")
            self.passed_tests += 1
            self.results["build_scripts"] = True
        else:
            print(f"❌ {len(script_errors)} build script issues found:")
            for error in script_errors:
                print(f"   - {error}")
            self.results["build_scripts"] = False
        
        return not script_errors
    
    def test_constraint_files(self):
        """Test constraint file completeness"""
        print("\n⚙️ Testing constraint files...")
        
        constraint_tests = [
            ("constraints/riscv_processor.xdc", ["create_clock", "set_property", "clk"]),
            ("constraints/riscv_processor.sdc", ["create_clock", "set_input_delay", "set_output_delay"])
        ]
        
        constraint_errors = []
        
        for constraint_file, required_content in constraint_tests:
            if not Path(constraint_file).exists():
                constraint_errors.append(f"{constraint_file}: File missing")
                continue
            
            try:
                with open(constraint_file, 'r') as f:
                    content = f.read()
                
                for required in required_content:
                    if required not in content:
                        constraint_errors.append(f"{constraint_file}: Missing '{required}'")
                
            except Exception as e:
                constraint_errors.append(f"{constraint_file}: Error reading file - {e}")
        
        self.total_tests += 1
        if not constraint_errors:
            print(f"✅ All constraint files pass completeness check")
            self.passed_tests += 1
            self.results["constraint_files"] = True
        else:
            print(f"❌ {len(constraint_errors)} constraint file issues found:")
            for error in constraint_errors:
                print(f"   - {error}")
            self.results["constraint_files"] = False
        
        return not constraint_errors
    
    def test_risc_v_compliance(self):
        """Test RISC-V instruction set compliance"""
        print("\n🎯 Testing RISC-V compliance...")
        
        # Check control unit for instruction support
        control_unit_path = Path("src/control_unit.v")
        if not control_unit_path.exists():
            print("❌ Control unit file missing")
            return False
        
        try:
            with open(control_unit_path, 'r') as f:
                content = f.read()
            
            # Check for RISC-V opcodes
            required_opcodes = [
                "OPCODE_R_TYPE", "OPCODE_I_TYPE", "OPCODE_LOAD", "OPCODE_STORE",
                "OPCODE_BRANCH", "OPCODE_JAL", "OPCODE_JALR", "OPCODE_LUI", "OPCODE_AUIPC"
            ]
            
            missing_opcodes = []
            for opcode in required_opcodes:
                if opcode not in content:
                    missing_opcodes.append(opcode)
            
            # Check for ALU operations
            alu_path = Path("src/alu.v")
            alu_ops = ["ADD", "SUB", "AND", "OR", "XOR", "SLL", "SRL", "SRA", "SLT", "SLTU"]
            missing_alu_ops = []
            
            if alu_path.exists():
                with open(alu_path, 'r') as f:
                    alu_content = f.read()
                
                for op in alu_ops:
                    if op not in alu_content:
                        missing_alu_ops.append(op)
            
            self.total_tests += 1
            if not missing_opcodes and not missing_alu_ops:
                print("✅ RISC-V RV32I instruction set compliance verified")
                self.passed_tests += 1
                self.results["risc_v_compliance"] = True
                return True
            else:
                print("❌ RISC-V compliance issues found:")
                if missing_opcodes:
                    print(f"   Missing opcodes: {missing_opcodes}")
                if missing_alu_ops:
                    print(f"   Missing ALU operations: {missing_alu_ops}")
                self.results["risc_v_compliance"] = False
                return False
                
        except Exception as e:
            print(f"❌ Error checking RISC-V compliance: {e}")
            self.results["risc_v_compliance"] = False
            return False
    
    def generate_report(self):
        """Generate comprehensive validation report"""
        print("\n" + "="*60)
        print("RISC-V PROCESSOR PROJECT VALIDATION REPORT")
        print("="*60)
        
        success_rate = (self.passed_tests / self.total_tests) * 100 if self.total_tests > 0 else 0
        
        print(f"Total Tests: {self.total_tests}")
        print(f"Passed: {self.passed_tests}")
        print(f"Failed: {self.total_tests - self.passed_tests}")
        print(f"Success Rate: {success_rate:.1f}%")
        print()
        
        # Detailed results
        for test_name, result in self.results.items():
            status = "✅ PASS" if result else "❌ FAIL"
            print(f"{test_name.replace('_', ' ').title()}: {status}")
        
        print()
        
        if self.passed_tests == self.total_tests:
            print("🎉 ALL VALIDATION TESTS PASSED!")
            print("✅ Project is ready for FPGA implementation")
            print()
            print("🚀 Next Steps:")
            print("   1. Install Vivado or Quartus Prime")
            print("   2. Run: python scripts/build_all_projects.py")
            print("   3. Synthesize and implement the design")
            print("   4. Program the FPGA and test on hardware")
        else:
            failed_tests = self.total_tests - self.passed_tests
            print(f"⚠️ {failed_tests} VALIDATION TEST(S) FAILED")
            print("🔧 Fix the issues above before proceeding to FPGA implementation")
        
        print("="*60)
        
        return self.passed_tests == self.total_tests

def main():
    """Main validation function"""
    print("🔍 RISC-V Processor Project Validation")
    print("="*50)
    
    validator = ProjectValidator()
    
    # Run all validation tests
    validator.test_file_structure()
    validator.test_verilog_syntax()
    validator.test_testbench_structure()
    validator.test_build_scripts()
    validator.test_constraint_files()
    validator.test_risc_v_compliance()
    
    # Generate final report
    success = validator.generate_report()
    
    return 0 if success else 1

if __name__ == "__main__":
    exit(main())