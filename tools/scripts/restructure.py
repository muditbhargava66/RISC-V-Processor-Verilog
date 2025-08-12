#!/usr/bin/env python3
"""
Production-Ready RISC-V Processor Restructuring Script
Reorganizes the project into a professional directory structure
"""

import os
import shutil
import sys
from pathlib import Path

def create_directory_structure():
    """Create the new production directory structure"""
    
    directories = [
        # Configuration
        "config/synthesis",
        "config/simulation", 
        "config/ci",
        
        # Documentation
        "docs/architecture",
        "docs/user-guide",
        "docs/developer-guide",
        "docs/api",
        
        # Source code restructure
        "src/rtl/core",
        "src/rtl/memory", 
        "src/rtl/peripherals",
        "src/rtl/top",
        "src/constraints/timing",
        "src/constraints/physical",
        "src/constraints/synthesis",
        
        # Verification
        "verification/testbenches/unit",
        "verification/testbenches/integration", 
        "verification/testbenches/system",
        "verification/tests/assembly",
        "verification/tests/c",
        "verification/tests/compliance",
        "verification/models",
        "verification/coverage",
        
        # Tools
        "tools/scripts/build",
        "tools/scripts/simulation",
        "tools/scripts/synthesis", 
        "tools/scripts/utils",
        "tools/generators",
        "tools/analyzers",
        
        # Projects
        "projects/vivado",
        "projects/quartus",
        "projects/libero",
        
        # Examples
        "examples/basic",
        "examples/advanced", 
        "examples/tutorials",
        
        # Build outputs (will be gitignored)
        "build/synthesis",
        "build/implementation",
        "build/simulation",
        "build/reports"
    ]
    
    print("Creating production directory structure...")
    for directory in directories:
        Path(directory).mkdir(parents=True, exist_ok=True)
        print(f"  ✓ Created: {directory}")

def move_existing_files():
    """Move existing files to their new locations"""
    
    moves = [
        # Move RTL files
        ("src/processor_top.v", "src/rtl/top/processor_top.v"),
        ("src/alu.v", "src/rtl/core/alu.v"),
        ("src/ALU_control.v", "src/rtl/core/alu_control.v"),
        ("src/Control_unit.v", "src/rtl/core/control_unit.v"),
        ("src/regfile.v", "src/rtl/core/regfile.v"),
        ("src/shifter.v", "src/rtl/core/shifter.v"),
        ("src/data_mem.v", "src/rtl/memory/data_mem.v"),
        ("src/instr_mem.v", "src/rtl/memory/instr_mem.v"),
        ("src/data_ext.v", "src/rtl/memory/data_ext.v"),
        ("src/PC.v", "src/rtl/core/pc.v"),
        ("src/pc_adder.v", "src/rtl/core/pc_adder.v"),
        ("src/imm_gen.v", "src/rtl/core/imm_gen.v"),
        
        # Move constraints
        ("constraints/processor.xdc", "src/constraints/timing/processor.xdc"),
        
        # Move scripts
        ("scripts/run_synthesis_safe.tcl", "tools/scripts/synthesis/run_synthesis.tcl"),
        ("scripts/run_implementation.tcl", "tools/scripts/synthesis/run_implementation.tcl"),
        ("scripts/run_simulation.tcl", "tools/scripts/simulation/run_simulation.tcl"),
        ("scripts/create_project_simple.tcl", "tools/scripts/build/create_project.tcl"),
        ("scripts/validate_project.tcl", "tools/scripts/utils/validate_project.tcl"),
        ("scripts/run_vivado.py", "tools/scripts/utils/run_vivado.py"),
        ("scripts/vivado_wrapper.py", "tools/scripts/utils/vivado_wrapper.py"),
        ("scripts/syntax_check.py", "tools/scripts/utils/syntax_check.py"),
        ("scripts/run_tests.py", "tools/scripts/utils/run_tests.py"),
        
        # Move testbenches
        ("testbenches/processor_vivado_tb.v", "verification/testbenches/system/processor_system_tb.v"),
        ("testbenches/alu_tb.v", "verification/testbenches/unit/alu_tb.v"),
        ("testbenches/Control_unit_tb.v", "verification/testbenches/unit/control_unit_tb.v"),
        ("testbenches/regfile_tb.v", "verification/testbenches/unit/regfile_tb.v"),
        ("testbenches/data_mem_tb.v", "verification/testbenches/unit/data_mem_tb.v"),
        ("testbenches/program_tb.v", "verification/testbenches/integration/program_tb.v"),
        
        # Move project files
        ("vivado_project", "projects/vivado/riscv_processor"),
        
        # Move documentation
        ("README.md", "docs/README.md"),
        ("VIVADO_IMPROVEMENTS.md", "docs/developer-guide/vivado_improvements.md"),
        ("CROSS_PLATFORM_GUIDE.md", "docs/user-guide/cross_platform_guide.md"),
    ]
    
    print("\nMoving existing files to new structure...")
    for src, dst in moves:
        if os.path.exists(src):
            # Create destination directory if it doesn't exist
            Path(dst).parent.mkdir(parents=True, exist_ok=True)
            
            if os.path.isdir(src):
                if os.path.exists(dst):
                    shutil.rmtree(dst)
                shutil.move(src, dst)
            else:
                shutil.move(src, dst)
            print(f"  ✓ Moved: {src} → {dst}")
        else:
            print(f"  ⚠ Not found: {src}")

def cleanup_old_structure():
    """Remove old directories and files"""
    
    cleanup_items = [
        "src",  # Old src directory (now empty)
        "constraints",  # Old constraints directory
        "scripts",  # Old scripts directory
        "testbenches",  # Old testbenches directory
        "vivado_project",  # Old vivado project (moved)
        
        # Remove scattered documentation
        "HOW_TO_OPEN_IN_VIVADO.md",
        "PROJECT_COMPLETE.md", 
        "SYNTHESIS_SUCCESS.md",
        "TEST_RESULTS.md",
        "RESTRUCTURE_PLAN.md",
        
        # Remove temporary files
        ".Xil",
        "logs",
        "reports",
    ]
    
    print("\nCleaning up old structure...")
    for item in cleanup_items:
        if os.path.exists(item):
            if os.path.isdir(item):
                shutil.rmtree(item)
                print(f"  ✓ Removed directory: {item}")
            else:
                os.remove(item)
                print(f"  ✓ Removed file: {item}")

def main():
    """Main restructuring function"""
    print("🔄 RISC-V Processor Production Restructuring")
    print("=" * 50)
    
    try:
        create_directory_structure()
        move_existing_files()
        cleanup_old_structure()
        
        print("\n" + "=" * 50)
        print("✅ Restructuring completed successfully!")
        print("📁 New production-ready directory structure created")
        print("🚀 Ready for production development")
        
    except Exception as e:
        print(f"\n❌ Error during restructuring: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main())