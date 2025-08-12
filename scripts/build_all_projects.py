#!/usr/bin/env python3
"""
RISC-V Processor Multi-Platform Build Script
Builds projects for both Vivado and Quartus
"""

import subprocess
import sys
import time
import os
from pathlib import Path

class ProjectBuilder:
    """Multi-platform FPGA project builder"""
    
    def __init__(self):
        self.project_root = Path(".").resolve()
        self.results = {}
    
    def check_tool_availability(self):
        """Check which FPGA tools are available"""
        tools = {}
        
        # Check Vivado
        try:
            result = subprocess.run(["vivado", "-version"], 
                                  capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                tools["vivado"] = True
                print("✅ Vivado found")
            else:
                tools["vivado"] = False
                print("❌ Vivado not found or not working")
        except:
            tools["vivado"] = False
            print("❌ Vivado not available")
        
        # Check Quartus
        try:
            result = subprocess.run(["quartus_sh", "--version"], 
                                  capture_output=True, text=True, timeout=10)
            if result.returncode == 0:
                tools["quartus"] = True
                print("✅ Quartus found")
            else:
                tools["quartus"] = False
                print("❌ Quartus not found or not working")
        except:
            tools["quartus"] = False
            print("❌ Quartus not available")
        
        return tools
    
    def build_vivado_project(self):
        """Build Vivado project"""
        print("\n🔨 Building Vivado project...")
        
        try:
            # Run Vivado in batch mode
            cmd = ["vivado", "-mode", "batch", "-source", "scripts/build_project.tcl"]
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
            
            if result.returncode == 0:
                print("✅ Vivado project built successfully")
                self.results["vivado"] = {"success": True, "message": "Project created"}
                return True
            else:
                print("❌ Vivado project build failed")
                print(f"Error: {result.stderr}")
                self.results["vivado"] = {"success": False, "message": result.stderr}
                return False
                
        except subprocess.TimeoutExpired:
            print("❌ Vivado build timed out")
            self.results["vivado"] = {"success": False, "message": "Build timeout"}
            return False
        except Exception as e:
            print(f"❌ Vivado build error: {e}")
            self.results["vivado"] = {"success": False, "message": str(e)}
            return False
    
    def build_quartus_project(self):
        """Build Quartus project"""
        print("\n🔨 Building Quartus project...")
        
        try:
            # Run Quartus in shell mode
            cmd = ["quartus_sh", "-t", "scripts/build_quartus_project.tcl"]
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
            
            if result.returncode == 0:
                print("✅ Quartus project built successfully")
                self.results["quartus"] = {"success": True, "message": "Project created"}
                return True
            else:
                print("❌ Quartus project build failed")
                print(f"Error: {result.stderr}")
                self.results["quartus"] = {"success": False, "message": result.stderr}
                return False
                
        except subprocess.TimeoutExpired:
            print("❌ Quartus build timed out")
            self.results["quartus"] = {"success": False, "message": "Build timeout"}
            return False
        except Exception as e:
            print(f"❌ Quartus build error: {e}")
            self.results["quartus"] = {"success": False, "message": str(e)}
            return False
    
    def run_vivado_synthesis(self):
        """Run Vivado synthesis"""
        print("\n⚙️ Running Vivado synthesis...")
        
        project_path = "projects/vivado/riscv_processor/riscv_processor.xpr"
        if not Path(project_path).exists():
            print("❌ Vivado project not found")
            return False
        
        try:
            # Create synthesis TCL script
            synth_script = """
open_project projects/vivado/riscv_processor/riscv_processor.xpr
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "ERROR: Synthesis failed"
    exit 1
}
puts "SUCCESS: Synthesis completed"
close_project
"""
            
            with open("temp_synth.tcl", "w") as f:
                f.write(synth_script)
            
            cmd = ["vivado", "-mode", "batch", "-source", "temp_synth.tcl"]
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
            
            # Clean up
            if Path("temp_synth.tcl").exists():
                Path("temp_synth.tcl").unlink()
            
            if result.returncode == 0 and "SUCCESS" in result.stdout:
                print("✅ Vivado synthesis completed successfully")
                return True
            else:
                print("❌ Vivado synthesis failed")
                print(f"Output: {result.stdout}")
                return False
                
        except Exception as e:
            print(f"❌ Vivado synthesis error: {e}")
            return False
    
    def run_quartus_compilation(self):
        """Run Quartus compilation"""
        print("\n⚙️ Running Quartus compilation...")
        
        project_path = "projects/quartus/riscv_processor.qpf"
        if not Path(project_path).exists():
            print("❌ Quartus project not found")
            return False
        
        try:
            # Change to project directory
            original_dir = os.getcwd()
            os.chdir("projects/quartus")
            
            cmd = ["quartus_sh", "--flow", "compile", "riscv_processor"]
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
            
            # Return to original directory
            os.chdir(original_dir)
            
            if result.returncode == 0:
                print("✅ Quartus compilation completed successfully")
                return True
            else:
                print("❌ Quartus compilation failed")
                print(f"Error: {result.stderr}")
                return False
                
        except Exception as e:
            print(f"❌ Quartus compilation error: {e}")
            return False
    
    def generate_report(self):
        """Generate build report"""
        print("\n" + "="*50)
        print("BUILD REPORT")
        print("="*50)
        
        total_builds = len(self.results)
        successful_builds = sum(1 for r in self.results.values() if r["success"])
        
        for tool, result in self.results.items():
            status = "✅ SUCCESS" if result["success"] else "❌ FAILED"
            print(f"{tool.upper()}: {status}")
            if not result["success"]:
                print(f"  Error: {result['message']}")
        
        print(f"\nSummary: {successful_builds}/{total_builds} builds successful")
        
        if successful_builds == total_builds:
            print("🎉 All builds completed successfully!")
            return True
        else:
            print("⚠️ Some builds failed")
            return False

def main():
    """Main build function"""
    print("🚀 RISC-V Processor Multi-Platform Builder")
    print("="*50)
    
    builder = ProjectBuilder()
    
    # Check tool availability
    print("Checking FPGA tool availability...")
    tools = builder.check_tool_availability()
    
    if not any(tools.values()):
        print("\n❌ No FPGA tools found!")
        print("Please install Vivado and/or Quartus Prime")
        return 1
    
    # Build projects
    build_success = True
    
    if tools.get("vivado", False):
        if not builder.build_vivado_project():
            build_success = False
        # Optionally run synthesis
        # builder.run_vivado_synthesis()
    
    if tools.get("quartus", False):
        if not builder.build_quartus_project():
            build_success = False
        # Optionally run compilation
        # builder.run_quartus_compilation()
    
    # Generate report
    overall_success = builder.generate_report()
    
    return 0 if overall_success else 1

if __name__ == "__main__":
    exit(main())