#!/usr/bin/env python3
"""
Simple RISC-V Processor Build Script
Robust build with proper error handling
"""

import subprocess
import sys
import os
from pathlib import Path

def find_vivado():
    """Find Vivado installation"""
    paths = [
        "C:/Xilinx/Vivado/2022.2/bin/vivado.bat",
        "C:/Xilinx/Vivado/2022.1/bin/vivado.bat",
        "C:/Xilinx/Vivado/2023.1/bin/vivado.bat",
        "C:/Xilinx/Vivado/2023.2/bin/vivado.bat"
    ]
    
    for path in paths:
        if Path(path).exists():
            return path
    return None

def find_quartus():
    """Find Quartus installation"""
    paths = [
        "C:/intelFPGA_lite/23.1/quartus/bin64/quartus_sh.exe",
        "C:/intelFPGA_lite/22.1/quartus/bin64/quartus_sh.exe",
        "C:/intelFPGA/23.1/quartus/bin64/quartus_sh.exe"
    ]
    
    for path in paths:
        if Path(path).exists():
            return path
    return None

def build_vivado_project(vivado_path):
    """Build Vivado project"""
    print("🔨 Building Vivado Project...")
    
    # Ensure directories exist
    Path("projects/vivado").mkdir(parents=True, exist_ok=True)
    
    # Create a simple build script that handles existing projects
    build_script = """
# Close any existing projects
catch {close_project -quiet}

# Set project variables
set project_name "riscv_processor"
set project_dir "./projects/vivado"
set part_name "xc7a35tcpg236-1"

puts "Creating RISC-V Processor Vivado Project..."

# Remove existing project
if {[file exists $project_dir/$project_name]} {
    puts "Removing existing project..."
    file delete -force $project_dir/$project_name
}

# Create project
create_project $project_name $project_dir/$project_name -part $part_name -force

# Add source files
puts "Adding source files..."
add_files -norecurse {
    ./src/alu.v
    ./src/register_file.v
    ./src/control_unit.v
    ./src/immediate_generator.v
    ./src/program_counter.v
    ./src/instruction_memory.v
    ./src/data_memory.v
    ./src/branch_unit.v
    ./src/riscv_processor.v
}

# Add constraints
add_files -fileset constrs_1 -norecurse ./constraints/riscv_processor.xdc

# Add testbenches
add_files -fileset sim_1 -norecurse {
    ./verification/testbenches/system/simple_processor_tb.v
}

# Set top modules
set_property top riscv_processor [current_fileset]
set_property top simple_processor_tb [get_filesets sim_1]

# Update compile order
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "SUCCESS: Vivado project created successfully!"
puts "Project location: $project_dir/$project_name/$project_name.xpr"

# Save and close
save_project_as $project_name $project_dir/$project_name -force
close_project
"""
    
    # Write the script
    script_path = Path("temp_vivado_build.tcl")
    with open(script_path, "w", encoding='utf-8') as f:
        f.write(build_script)
    
    try:
        # Run Vivado
        cmd = [vivado_path, "-mode", "batch", "-source", str(script_path)]
        print(f"Running: {' '.join(cmd)}")
        
        # Use a simpler approach to avoid encoding issues
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, 
                                 universal_newlines=True, encoding='utf-8', errors='replace')
        
        stdout, stderr = process.communicate(timeout=300)
        
        # Clean up
        if script_path.exists():
            script_path.unlink()
        
        if process.returncode == 0 and "SUCCESS" in stdout:
            print("✅ Vivado project created successfully!")
            
            # Check if project file exists
            project_file = Path("projects/vivado/riscv_processor/riscv_processor.xpr")
            if project_file.exists():
                print(f"📁 Project file: {project_file}")
                return True
        
        print("❌ Vivado project creation failed")
        if stderr:
            print(f"Error: {stderr}")
        return False
        
    except subprocess.TimeoutExpired:
        print("❌ Vivado build timed out")
        return False
    except Exception as e:
        print(f"❌ Build error: {e}")
        return False
    finally:
        if script_path.exists():
            script_path.unlink()

def build_quartus_project(quartus_path):
    """Build Quartus project"""
    print("🔨 Building Quartus Project...")
    
    # Ensure directories exist
    Path("projects/quartus").mkdir(parents=True, exist_ok=True)
    
    # Create Quartus build script
    build_script = """
package require ::quartus::project

set project_name "riscv_processor"
set project_dir "./projects/quartus"

puts "Creating RISC-V Processor Quartus Project..."

cd $project_dir

# Remove existing project
if {[project_exists $project_name]} {
    project_close
    file delete -force $project_name.qpf
    file delete -force $project_name.qsf
}

# Create project
project_new $project_name -overwrite

# Set device
set_global_assignment -name FAMILY "Cyclone IV E"
set_global_assignment -name DEVICE "EP4CE22F17C6"
set_global_assignment -name TOP_LEVEL_ENTITY riscv_processor

# Add source files
set_global_assignment -name VERILOG_FILE ../../src/alu.v
set_global_assignment -name VERILOG_FILE ../../src/register_file.v
set_global_assignment -name VERILOG_FILE ../../src/control_unit.v
set_global_assignment -name VERILOG_FILE ../../src/immediate_generator.v
set_global_assignment -name VERILOG_FILE ../../src/program_counter.v
set_global_assignment -name VERILOG_FILE ../../src/instruction_memory.v
set_global_assignment -name VERILOG_FILE ../../src/data_memory.v
set_global_assignment -name VERILOG_FILE ../../src/branch_unit.v
set_global_assignment -name VERILOG_FILE ../../src/riscv_processor.v

# Add constraints
set_global_assignment -name SDC_FILE ../../constraints/riscv_processor.sdc

puts "SUCCESS: Quartus project created successfully!"
puts "Project location: $project_dir/$project_name.qpf"

project_close
"""
    
    # Write the script
    script_path = Path("temp_quartus_build.tcl")
    with open(script_path, "w", encoding='utf-8') as f:
        f.write(build_script)
    
    try:
        # Run Quartus
        cmd = [quartus_path, "-t", str(script_path)]
        print(f"Running: {' '.join(cmd)}")
        
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                 universal_newlines=True, encoding='utf-8', errors='replace')
        
        stdout, stderr = process.communicate(timeout=300)
        
        # Clean up
        if script_path.exists():
            script_path.unlink()
        
        if process.returncode == 0 and "SUCCESS" in stdout:
            print("✅ Quartus project created successfully!")
            
            # Check if project file exists
            project_file = Path("projects/quartus/riscv_processor.qpf")
            if project_file.exists():
                print(f"📁 Project file: {project_file}")
                return True
        
        print("❌ Quartus project creation failed")
        if stderr:
            print(f"Error: {stderr}")
        return False
        
    except subprocess.TimeoutExpired:
        print("❌ Quartus build timed out")
        return False
    except Exception as e:
        print(f"❌ Build error: {e}")
        return False
    finally:
        if script_path.exists():
            script_path.unlink()

def main():
    """Main function"""
    print("🚀 RISC-V Processor Simple Build System")
    print("="*50)
    
    # Find tools
    vivado_path = find_vivado()
    quartus_path = find_quartus()
    
    if vivado_path:
        print(f"✅ Vivado found: {vivado_path}")
    else:
        print("❌ Vivado not found")
    
    if quartus_path:
        print(f"✅ Quartus found: {quartus_path}")
    else:
        print("❌ Quartus not found")
    
    if not vivado_path and not quartus_path:
        print("\n❌ No FPGA tools found!")
        return 1
    
    print()
    
    # Build projects
    success_count = 0
    total_count = 0
    
    if vivado_path:
        total_count += 1
        if build_vivado_project(vivado_path):
            success_count += 1
    
    if quartus_path:
        total_count += 1
        if build_quartus_project(quartus_path):
            success_count += 1
    
    # Report results
    print("\n" + "="*50)
    print("BUILD SUMMARY")
    print("="*50)
    print(f"Projects built: {success_count}/{total_count}")
    
    if success_count > 0:
        print("\n🎉 Success! Projects created:")
        
        if vivado_path and Path("projects/vivado/riscv_processor/riscv_processor.xpr").exists():
            print("   Vivado: projects/vivado/riscv_processor/riscv_processor.xpr")
            print(f"   Open with: {vivado_path.replace('vivado.bat', 'vivado')} projects/vivado/riscv_processor/riscv_processor.xpr")
        
        if quartus_path and Path("projects/quartus/riscv_processor.qpf").exists():
            print("   Quartus: projects/quartus/riscv_processor.qpf")
            print(f"   Open with: {quartus_path.replace('quartus_sh.exe', 'quartus.exe')} projects/quartus/riscv_processor.qpf")
        
        print("\n🚀 Next steps:")
        print("   1. Open the project in your FPGA tool")
        print("   2. Run synthesis to verify the design")
        print("   3. Run implementation (place & route)")
        print("   4. Generate programming file")
        
        return 0
    else:
        print("\n❌ No projects built successfully")
        return 1

if __name__ == "__main__":
    exit(main())