#!/usr/bin/env python3
"""
RISC-V Processor Build Script with Enhanced Tool Detection
Works with installed Vivado and Quartus tools
"""

import subprocess
import sys
import time
import os
import shutil
from pathlib import Path

class EnhancedProjectBuilder:
    """Enhanced project builder with proper tool detection"""
    
    def __init__(self):
        self.project_root = Path(".").resolve()
        self.results = {}
        self.vivado_version = None
        self.quartus_version = None
    
    def detect_tools(self):
        """Enhanced tool detection with proper PATH handling"""
        print("🔍 Detecting FPGA tools...")
        tools = {}
        
        # Check Vivado with multiple methods
        vivado_found = False
        try:
            # Method 1: Direct command
            result = subprocess.run(["vivado", "-version"], 
                                  capture_output=True, text=True, timeout=15,
                                  shell=True)  # Use shell=True for Windows
            if result.returncode == 0 and "Vivado" in result.stdout:
                vivado_found = True
                # Extract version
                for line in result.stdout.split('\n'):
                    if 'Vivado' in line and 'v' in line:
                        self.vivado_version = line.strip()
                        break
                print(f"✅ Vivado found: {self.vivado_version}")
            
        except Exception as e:
            print(f"   Vivado detection method 1 failed: {e}")
        
        if not vivado_found:
            # Method 2: Check common installation paths
            common_vivado_paths = [
                "C:/Xilinx/Vivado/2022.2/bin/vivado.bat",
                "C:/Xilinx/Vivado/2022.1/bin/vivado.bat",
                "C:/Xilinx/Vivado/2023.1/bin/vivado.bat",
                "C:/Xilinx/Vivado/2023.2/bin/vivado.bat"
            ]
            
            for path in common_vivado_paths:
                if Path(path).exists():
                    vivado_found = True
                    self.vivado_version = f"Found at {path}"
                    print(f"✅ Vivado found at: {path}")
                    break
        
        tools["vivado"] = vivado_found
        
        # Check Quartus with multiple methods
        quartus_found = False
        try:
            # Method 1: Direct command
            result = subprocess.run(["quartus_sh", "--version"], 
                                  capture_output=True, text=True, timeout=15,
                                  shell=True)  # Use shell=True for Windows
            if result.returncode == 0 and "Quartus" in result.stdout:
                quartus_found = True
                # Extract version
                for line in result.stdout.split('\n'):
                    if 'Quartus' in line and 'Version' in line:
                        self.quartus_version = line.strip()
                        break
                print(f"✅ Quartus found: {self.quartus_version}")
            
        except Exception as e:
            print(f"   Quartus detection method 1 failed: {e}")
        
        if not quartus_found:
            # Method 2: Check common installation paths
            common_quartus_paths = [
                "C:/intelFPGA_lite/23.1/quartus/bin64/quartus_sh.exe",
                "C:/intelFPGA_lite/22.1/quartus/bin64/quartus_sh.exe",
                "C:/intelFPGA/23.1/quartus/bin64/quartus_sh.exe",
                "C:/altera/quartus/bin64/quartus_sh.exe"
            ]
            
            for path in common_quartus_paths:
                if Path(path).exists():
                    quartus_found = True
                    self.quartus_version = f"Found at {path}"
                    print(f"✅ Quartus found at: {path}")
                    break
        
        tools["quartus"] = quartus_found
        
        print(f"\nTool Detection Summary:")
        print(f"  Vivado: {'✅ Available' if tools['vivado'] else '❌ Not found'}")
        print(f"  Quartus: {'✅ Available' if tools['quartus'] else '❌ Not found'}")
        
        return tools
    
    def build_vivado_project(self):
        """Build Vivado project with enhanced error handling"""
        print("\n🔨 Building Vivado Project...")
        print("-" * 40)
        
        try:
            # Ensure project directory exists
            project_dir = Path("projects/vivado")
            project_dir.mkdir(parents=True, exist_ok=True)
            
            # Run Vivado build script
            print("Running Vivado build script...")
            cmd = ["vivado", "-mode", "batch", "-source", "scripts/build_project.tcl"]
            
            # Use shell=True for Windows compatibility
            result = subprocess.run(cmd, capture_output=True, text=True, 
                                  timeout=300, shell=True, cwd=self.project_root)
            
            if result.returncode == 0:
                print("✅ Vivado project created successfully!")
                
                # Check if project file was created
                project_file = project_dir / "riscv_processor" / "riscv_processor.xpr"
                if project_file.exists():
                    print(f"📁 Project file: {project_file}")
                    print("🚀 To open: vivado projects/vivado/riscv_processor/riscv_processor.xpr")
                else:
                    print("⚠️ Project file not found, but build completed")
                
                self.results["vivado"] = {"success": True, "message": "Project created"}
                return True
            else:
                print("❌ Vivado project creation failed")
                print("STDOUT:", result.stdout)
                print("STDERR:", result.stderr)
                self.results["vivado"] = {"success": False, "message": result.stderr}
                return False
                
        except subprocess.TimeoutExpired:
            print("❌ Vivado build timed out (5 minutes)")
            self.results["vivado"] = {"success": False, "message": "Build timeout"}
            return False
        except Exception as e:
            print(f"❌ Vivado build error: {e}")
            self.results["vivado"] = {"success": False, "message": str(e)}
            return False
    
    def build_quartus_project(self):
        """Build Quartus project with enhanced error handling"""
        print("\n🔨 Building Quartus Project...")
        print("-" * 40)
        
        try:
            # Ensure project directory exists
            project_dir = Path("projects/quartus")
            project_dir.mkdir(parents=True, exist_ok=True)
            
            # Run Quartus build script
            print("Running Quartus build script...")
            cmd = ["quartus_sh", "-t", "scripts/build_quartus_project.tcl"]
            
            # Use shell=True for Windows compatibility
            result = subprocess.run(cmd, capture_output=True, text=True, 
                                  timeout=300, shell=True, cwd=self.project_root)
            
            if result.returncode == 0:
                print("✅ Quartus project created successfully!")
                
                # Check if project file was created
                project_file = project_dir / "riscv_processor.qpf"
                if project_file.exists():
                    print(f"📁 Project file: {project_file}")
                    print("🚀 To open: quartus projects/quartus/riscv_processor.qpf")
                else:
                    print("⚠️ Project file not found, but build completed")
                
                self.results["quartus"] = {"success": True, "message": "Project created"}
                return True
            else:
                print("❌ Quartus project creation failed")
                print("STDOUT:", result.stdout)
                print("STDERR:", result.stderr)
                self.results["quartus"] = {"success": False, "message": result.stderr}
                return False
                
        except subprocess.TimeoutExpired:
            print("❌ Quartus build timed out (5 minutes)")
            self.results["quartus"] = {"success": False, "message": "Build timeout"}
            return False
        except Exception as e:
            print(f"❌ Quartus build error: {e}")
            self.results["quartus"] = {"success": False, "message": str(e)}
            return False
    
    def run_vivado_simulation(self):
        """Run a quick Vivado simulation test"""
        print("\n🧪 Testing Vivado Simulation...")
        
        project_path = Path("projects/vivado/riscv_processor/riscv_processor.xpr")
        if not project_path.exists():
            print("❌ Vivado project not found")
            return False
        
        try:
            # Create a simple simulation script
            sim_script = f"""
open_project {project_path}
set_property top simple_processor_tb [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation -mode behavioral
run 100ns
if {{[current_sim] != ""}} {{
    puts "SUCCESS: Simulation running"
    close_sim
}} else {{
    puts "ERROR: Simulation failed"
    exit 1
}}
close_project
"""
            
            script_path = Path("temp_sim_test.tcl")
            with open(script_path, "w") as f:
                f.write(sim_script)
            
            print("Running simulation test...")
            cmd = ["vivado", "-mode", "batch", "-source", str(script_path)]
            result = subprocess.run(cmd, capture_output=True, text=True, 
                                  timeout=180, shell=True)
            
            # Clean up
            if script_path.exists():
                script_path.unlink()
            
            if result.returncode == 0 and "SUCCESS" in result.stdout:
                print("✅ Vivado simulation test passed")
                return True
            else:
                print("❌ Vivado simulation test failed")
                print("Output:", result.stdout[-500:])  # Last 500 chars
                return False
                
        except Exception as e:
            print(f"❌ Simulation test error: {e}")
            return False
    
    def generate_report(self):
        """Generate comprehensive build report"""
        print("\n" + "="*60)
        print("RISC-V PROCESSOR BUILD REPORT")
        print("="*60)
        
        print(f"Vivado Version: {self.vivado_version or 'Not detected'}")
        print(f"Quartus Version: {self.quartus_version or 'Not detected'}")
        print()
        
        total_builds = len(self.results)
        successful_builds = sum(1 for r in self.results.values() if r["success"])
        
        for tool, result in self.results.items():
            status = "✅ SUCCESS" if result["success"] else "❌ FAILED"
            print(f"{tool.upper()} Build: {status}")
            if not result["success"]:
                print(f"  Error: {result['message'][:100]}...")
        
        print(f"\nBuild Summary: {successful_builds}/{total_builds} successful")
        
        if successful_builds > 0:
            print("\n🎉 Project(s) built successfully!")
            print("\n🚀 Next Steps:")
            if "vivado" in self.results and self.results["vivado"]["success"]:
                print("   Vivado: vivado projects/vivado/riscv_processor/riscv_processor.xpr")
            if "quartus" in self.results and self.results["quartus"]["success"]:
                print("   Quartus: quartus projects/quartus/riscv_processor.qpf")
        else:
            print("\n❌ No projects built successfully")
            print("Check error messages above and ensure tools are properly installed")
        
        print("="*60)
        
        return successful_builds > 0

def main():
    """Main build function"""
    print("🚀 RISC-V Processor Enhanced Build System")
    print("="*50)
    
    builder = EnhancedProjectBuilder()
    
    # Detect tools
    tools = builder.detect_tools()
    
    if not any(tools.values()):
        print("\n❌ No FPGA tools detected!")
        print("Please ensure Vivado and/or Quartus are installed and in PATH")
        return 1
    
    # Build projects
    build_success = False
    
    if tools.get("vivado", False):
        if builder.build_vivado_project():
            build_success = True
            # Optionally test simulation
            # builder.run_vivado_simulation()
    
    if tools.get("quartus", False):
        if builder.build_quartus_project():
            build_success = True
    
    # Generate report
    overall_success = builder.generate_report()
    
    return 0 if overall_success else 1

if __name__ == "__main__":
    exit(main())