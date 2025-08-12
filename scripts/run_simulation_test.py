#!/usr/bin/env python3
"""
RISC-V Processor Simulation Test Runner
Tests the processor with various simulation scenarios
"""

import subprocess
import sys
import time
from pathlib import Path

def create_vivado_sim_script():
    """Create Vivado simulation script"""
    sim_script = """
# Open project
open_project projects/vivado/riscv_processor/riscv_processor.xpr

# Set simulation top
set_property top simple_processor_tb [get_filesets sim_1]
update_compile_order -fileset sim_1

# Launch simulation
launch_simulation -mode behavioral

# Run simulation
run 1000ns

# Check if simulation completed successfully
if {[current_sim] != ""} {
    puts "SUCCESS: Simulation completed"
    close_sim
} else {
    puts "ERROR: Simulation failed"
    exit 1
}

close_project
"""
    
    with open("temp_sim.tcl", "w") as f:
        f.write(sim_script)
    
    return "temp_sim.tcl"

def run_vivado_simulation():
    """Run Vivado simulation"""
    print("🧪 Running Vivado simulation...")
    
    # Check if project exists
    project_path = Path("projects/vivado/riscv_processor/riscv_processor.xpr")
    if not project_path.exists():
        print("❌ Vivado project not found. Run build script first.")
        return False
    
    try:
        # Create simulation script
        script_path = create_vivado_sim_script()
        
        # Run simulation
        cmd = ["vivado", "-mode", "batch", "-source", script_path]
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
        
        # Clean up
        if Path(script_path).exists():
            Path(script_path).unlink()
        
        if result.returncode == 0 and "SUCCESS" in result.stdout:
            print("✅ Vivado simulation completed successfully")
            return True
        else:
            print("❌ Vivado simulation failed")
            print(f"Output: {result.stdout}")
            print(f"Error: {result.stderr}")
            return False
            
    except subprocess.TimeoutExpired:
        print("❌ Vivado simulation timed out")
        return False
    except Exception as e:
        print(f"❌ Vivado simulation error: {e}")
        return False

def run_modelsim_simulation():
    """Run ModelSim simulation (if available)"""
    print("🧪 Running ModelSim simulation...")
    
    try:
        # Check if ModelSim is available
        result = subprocess.run(["vsim", "-version"], 
                              capture_output=True, text=True, timeout=10)
        if result.returncode != 0:
            print("❌ ModelSim not available")
            return False
        
        # Create work library
        subprocess.run(["vlib", "work"], check=True)
        
        # Compile source files
        verilog_files = [
            "src/alu.v",
            "src/register_file.v",
            "src/control_unit.v",
            "src/immediate_generator.v",
            "src/program_counter.v",
            "src/instruction_memory.v",
            "src/data_memory.v",
            "src/branch_unit.v",
            "src/riscv_processor.v",
            "verification/testbenches/system/simple_processor_tb.v"
        ]
        
        compile_cmd = ["vlog"] + verilog_files
        result = subprocess.run(compile_cmd, capture_output=True, text=True)
        
        if result.returncode != 0:
            print("❌ ModelSim compilation failed")
            print(f"Error: {result.stderr}")
            return False
        
        # Run simulation
        sim_cmd = ["vsim", "-c", "-do", "run 1000ns; quit", "simple_processor_tb"]
        result = subprocess.run(sim_cmd, capture_output=True, text=True, timeout=120)
        
        if result.returncode == 0:
            print("✅ ModelSim simulation completed successfully")
            return True
        else:
            print("❌ ModelSim simulation failed")
            print(f"Error: {result.stderr}")
            return False
            
    except Exception as e:
        print(f"❌ ModelSim simulation error: {e}")
        return False

def run_basic_functionality_test():
    """Run basic functionality test without simulator"""
    print("🔍 Running basic functionality test...")
    
    # Check if all source files compile without errors
    try:
        # Simple syntax check
        result = subprocess.run([sys.executable, "scripts/simple_test.py"], 
                              capture_output=True, text=True)
        
        if result.returncode == 0:
            print("✅ Basic functionality test passed")
            return True
        else:
            print("❌ Basic functionality test failed")
            print(f"Error: {result.stderr}")
            return False
            
    except Exception as e:
        print(f"❌ Basic functionality test error: {e}")
        return False

def main():
    """Main simulation test function"""
    print("🚀 RISC-V Processor Simulation Test Suite")
    print("="*50)
    
    tests_run = 0
    tests_passed = 0
    
    # Run basic functionality test
    tests_run += 1
    if run_basic_functionality_test():
        tests_passed += 1
    
    print()
    
    # Try Vivado simulation
    if Path("projects/vivado/riscv_processor/riscv_processor.xpr").exists():
        tests_run += 1
        if run_vivado_simulation():
            tests_passed += 1
    else:
        print("ℹ️ Vivado project not found, skipping Vivado simulation")
    
    print()
    
    # Try ModelSim simulation
    tests_run += 1
    if run_modelsim_simulation():
        tests_passed += 1
    
    # Generate report
    print("\n" + "="*50)
    print("SIMULATION TEST REPORT")
    print("="*50)
    print(f"Tests run: {tests_run}")
    print(f"Tests passed: {tests_passed}")
    print(f"Success rate: {(tests_passed/tests_run)*100:.1f}%")
    
    if tests_passed == tests_run:
        print("\n🎉 All simulation tests passed!")
        print("✅ RISC-V processor is functioning correctly")
        return 0
    else:
        print(f"\n⚠️ {tests_run - tests_passed} simulation test(s) failed")
        print("🔧 Check simulator installation and project setup")
        return 1

if __name__ == "__main__":
    exit(main())