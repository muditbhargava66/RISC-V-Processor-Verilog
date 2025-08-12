#!/usr/bin/env python3
"""
RISC-V Processor Build Script with Full Tool Paths
Works with installed tools using their full installation paths
"""

import subprocess
import sys
import time
import os
from pathlib import Path

class FullPathProjectBuilder:
    """Project builder using full tool paths"""
    
    def __init__(self):
        self.project_root = Path(".").resolve()
        self.results = {}
        self.vivado_path = None
        self.quartus_path = None
    
    def find_tool_paths(self):
        """Find full paths to installed tools"""
        print("🔍 Locating FPGA tools...")
        
        # Common Vivado installation paths
        vivado_paths = [
            "C:/Xilinx/Vivado/2022.2/bin/vivado.bat",
            "C:/Xilinx/Vivado/2022.1/bin/vivado.bat", 
            "C:/Xilinx/Vivado/2023.1/bin/vivado.bat",
            "C:/Xilinx/Vivado/2023.2/bin/vivado.bat",
            "C:/Xilinx/Vivado/2021.2/bin/vivado.bat",
            "C:/Xilinx/Vivado/2024.1/bin/vivado.bat"
        ]
        
        # Common Quartus installation paths
        quartus_paths = [
            "C:/intelFPGA_lite/23.1/quartus/bin64/quartus_sh.exe",
            "C:/intelFPGA_lite/22.1/quartus/bin64/quartus_sh.exe",
            "C:/intelFPGA_lite/21.1/quartus/bin64/quartus_sh.exe",
            "C:/intelFPGA/23.1/quartus/bin64/quartus_sh.exe",
            "C:/intelFPGA/22.1/quartus/bin64/quartus_sh.exe",
            "C:/altera/quartus/bin64/quartus_sh.exe"
        ]
        
        # Find Vivado
        for path in vivado_paths:
            if Path(path).exists():
                self.vivado_path = path
                print(f"✅ Vivado found: {path}")
                break
        
        if not self.vivado_path:
            print("❌ Vivado not found in common locations")
        
        # Find Quartus
        for path in quartus_paths:
            if Path(path).exists():
                self.quartus_path = path
                print(f"✅ Quartus found: {path}")
                break
        
        if not self.quartus_path:
            print("❌ Quartus not found in common locations")
        
        return self.vivado_path is not None or self.quartus_path is not None
    
    def test_tool_execution(self):
        """Test if tools can be executed"""
        print("\n🧪 Testing tool execution...")
        
        if self.vivado_path:
            try:
                result = subprocess.run([self.vivado_path, "-version"], 
                                      capture_output=True, text=True, timeout=30)
                if result.returncode == 0:
                    print("✅ Vivado execution test passed")
                    # Extract version info
                    for line in result.stdout.split('\n'):
                        if 'Vivado' in line and 'v' in line:
                            print(f"   Version: {line.strip()}")
                            break
                else:
                    print("❌ Vivado execution test failed")
                    print(f"   Error: {result.stderr}")
            except Exception as e:
                print(f"❌ Vivado execution error: {e}")
        
        if self.quartus_path:
            try:
                result = subprocess.run([self.quartus_path, "--version"], 
                                      capture_output=True, text=True, timeout=30)
                if result.returncode == 0:
                    print("✅ Quartus execution test passed")
                    # Extract version info
                    for line in result.stdout.split('\n'):
                        if 'Quartus' in line and 'Version' in line:
                            print(f"   Version: {line.strip()}")
                            break
                else:
                    print("❌ Quartus execution test failed")
                    print(f"   Error: {result.stderr}")
            except Exception as e:
                print(f"❌ Quartus execution error: {e}")
    
    def build_vivado_project(self):
        """Build Vivado project using full path"""
        if not self.vivado_path:
            print("❌ Vivado path not found")
            return False
        
        print("\n🔨 Building Vivado Project...")
        print("-" * 40)
        
        try:
            # Ensure project directory exists
            project_dir = Path("projects/vivado")
            project_dir.mkdir(parents=True, exist_ok=True)
            
            # Create the build command with full path
            script_path = Path("scripts/build_project.tcl").resolve()
            cmd = [self.vivado_path, "-mode", "batch", "-source", str(script_path)]
            
            print(f"Executing: {' '.join(cmd)}")
            print("This may take a few minutes...")
            
            # Run the command
            result = subprocess.run(cmd, capture_output=True, text=True, 
                                  timeout=600, cwd=self.project_root)
            
            if result.returncode == 0:
                print("✅ Vivado project created successfully!")
                
                # Check if project file was created
                project_file = project_dir / "riscv_processor" / "riscv_processor.xpr"
                if project_file.exists():
                    print(f"📁 Project file: {project_file}")
                    print(f"🚀 To open: {self.vivado_path.replace('vivado.bat', 'vivado')} {project_file}")
                
                # Show some output for verification
                if "Project created successfully" in result.stdout or "create_project" in result.stdout:
                    print("📊 Build output indicates success")
                
                self.results["vivado"] = {"success": True, "message": "Project created"}
                return True
            else:
                print("❌ Vivado project creation failed")
                print("Return code:", result.returncode)
                if result.stdout:
                    print("STDOUT (last 500 chars):")
                    print(result.stdout[-500:])
                if result.stderr:
                    print("STDERR:")
                    print(result.stderr)
                
                self.results["vivado"] = {"success": False, "message": result.stderr or "Unknown error"}
                return False
                
        except subprocess.TimeoutExpired:
            print("❌ Vivado build timed out (10 minutes)")
            self.results["vivado"] = {"success": False, "message": "Build timeout"}
            return False
        except Exception as e:
            print(f"❌ Vivado build error: {e}")
            self.results["vivado"] = {"success": False, "message": str(e)}
            return False
    
    def build_quartus_project(self):
        """Build Quartus project using full path"""
        if not self.quartus_path:
            print("❌ Quartus path not found")
            return False
        
        print("\n🔨 Building Quartus Project...")
        print("-" * 40)
        
        try:
            # Ensure project directory exists
            project_dir = Path("projects/quartus")
            project_dir.mkdir(parents=True, exist_ok=True)
            
            # Create the build command with full path
            script_path = Path("scripts/build_quartus_project.tcl").resolve()
            cmd = [self.quartus_path, "-t", str(script_path)]
            
            print(f"Executing: {' '.join(cmd)}")
            print("This may take a few minutes...")
            
            # Run the command
            result = subprocess.run(cmd, capture_output=True, text=True, 
                                  timeout=600, cwd=self.project_root)
            
            if result.returncode == 0:
                print("✅ Quartus project created successfully!")
                
                # Check if project file was created
                project_file = project_dir / "riscv_processor.qpf"
                if project_file.exists():
                    print(f"📁 Project file: {project_file}")
                    quartus_gui = self.quartus_path.replace("quartus_sh.exe", "quartus.exe")
                    print(f"🚀 To open: {quartus_gui} {project_file}")
                
                # Show some output for verification
                if "project created successfully" in result.stdout.lower() or "project_new" in result.stdout:
                    print("📊 Build output indicates success")
                
                self.results["quartus"] = {"success": True, "message": "Project created"}
                return True
            else:
                print("❌ Quartus project creation failed")
                print("Return code:", result.returncode)
                if result.stdout:
                    print("STDOUT (last 500 chars):")
                    print(result.stdout[-500:])
                if result.stderr:
                    print("STDERR:")
                    print(result.stderr)
                
                self.results["quartus"] = {"success": False, "message": result.stderr or "Unknown error"}
                return False
                
        except subprocess.TimeoutExpired:
            print("❌ Quartus build timed out (10 minutes)")
            self.results["quartus"] = {"success": False, "message": "Build timeout"}
            return False
        except Exception as e:
            print(f"❌ Quartus build error: {e}")
            self.results["quartus"] = {"success": False, "message": str(e)}
            return False
    
    def run_quick_synthesis_test(self):
        """Run a quick synthesis test if projects were created"""
        print("\n⚡ Running Quick Synthesis Tests...")
        
        if "vivado" in self.results and self.results["vivado"]["success"]:
            print("\n🔧 Testing Vivado Synthesis...")
            project_file = Path("projects/vivado/riscv_processor/riscv_processor.xpr")
            
            if project_file.exists():
                try:
                    # Create synthesis test script
                    synth_script = f"""
open_project {project_file}
reset_run synth_1
launch_runs synth_1 -jobs 2
wait_on_run synth_1
set progress [get_property PROGRESS [get_runs synth_1]]
puts "Synthesis progress: $progress"
if {{$progress == "100%"}} {{
    puts "SUCCESS: Synthesis completed"
}} else {{
    puts "INFO: Synthesis progress: $progress"
}}
close_project
"""
                    
                    script_path = Path("temp_synth_test.tcl")
                    with open(script_path, "w") as f:
                        f.write(synth_script)
                    
                    cmd = [self.vivado_path, "-mode", "batch", "-source", str(script_path)]
                    result = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
                    
                    # Clean up
                    if script_path.exists():
                        script_path.unlink()
                    
                    if "SUCCESS" in result.stdout:
                        print("✅ Vivado synthesis test completed successfully")
                    elif "100%" in result.stdout:
                        print("✅ Vivado synthesis completed")
                    else:
                        print("⚠️ Vivado synthesis test incomplete (may need more time)")
                        
                except Exception as e:
                    print(f"⚠️ Synthesis test error: {e}")
    
    def generate_comprehensive_report(self):
        """Generate comprehensive build report"""
        print("\n" + "="*70)
        print("RISC-V PROCESSOR BUILD REPORT - FULL PATH METHOD")
        print("="*70)
        
        print("Tool Locations:")
        print(f"  Vivado: {self.vivado_path or 'Not found'}")
        print(f"  Quartus: {self.quartus_path or 'Not found'}")
        print()
        
        if self.results:
            total_builds = len(self.results)
            successful_builds = sum(1 for r in self.results.values() if r["success"])
            
            print("Build Results:")
            for tool, result in self.results.items():
                status = "✅ SUCCESS" if result["success"] else "❌ FAILED"
                print(f"  {tool.upper()}: {status}")
                if not result["success"]:
                    print(f"    Error: {result['message'][:100]}...")
            
            print(f"\nBuild Summary: {successful_builds}/{total_builds} successful")
            
            if successful_builds > 0:
                print("\n🎉 Project(s) built successfully!")
                print("\n🚀 Next Steps:")
                
                if "vivado" in self.results and self.results["vivado"]["success"]:
                    project_path = "projects/vivado/riscv_processor/riscv_processor.xpr"
                    vivado_gui = self.vivado_path.replace("vivado.bat", "vivado")
                    print(f"   Open Vivado: {vivado_gui} {project_path}")
                    print("   Or double-click the .xpr file")
                
                if "quartus" in self.results and self.results["quartus"]["success"]:
                    project_path = "projects/quartus/riscv_processor.qpf"
                    quartus_gui = self.quartus_path.replace("quartus_sh.exe", "quartus.exe")
                    print(f"   Open Quartus: {quartus_gui} {project_path}")
                    print("   Or double-click the .qpf file")
                
                print("\n📋 What you can do next:")
                print("   1. Open the project in the FPGA tool")
                print("   2. Run synthesis to check for errors")
                print("   3. Run implementation (place & route)")
                print("   4. Generate bitstream for FPGA programming")
                print("   5. Run simulations to verify functionality")
                
            else:
                print("\n❌ No projects built successfully")
                print("Check error messages above")
        else:
            print("No build attempts made")
        
        print("="*70)
        
        return len(self.results) > 0 and any(r["success"] for r in self.results.values())

def main():
    """Main build function"""
    print("🚀 RISC-V Processor Build System - Full Path Method")
    print("="*60)
    print("This script locates and uses full paths to FPGA tools")
    print()
    
    builder = FullPathProjectBuilder()
    
    # Find tool paths
    if not builder.find_tool_paths():
        print("\n❌ No FPGA tools found!")
        print("Please ensure Vivado and/or Quartus are installed")
        print("Common locations checked:")
        print("  Vivado: C:/Xilinx/Vivado/*/bin/vivado.bat")
        print("  Quartus: C:/intelFPGA*/*/quartus/bin64/quartus_sh.exe")
        return 1
    
    # Test tool execution
    builder.test_tool_execution()
    
    # Build projects
    if builder.vivado_path:
        builder.build_vivado_project()
    
    if builder.quartus_path:
        builder.build_quartus_project()
    
    # Optional: Run synthesis test
    # builder.run_quick_synthesis_test()
    
    # Generate comprehensive report
    success = builder.generate_comprehensive_report()
    
    return 0 if success else 1

if __name__ == "__main__":
    exit(main())