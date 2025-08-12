#!/usr/bin/env python3
"""
Close any open Vivado projects
"""

import subprocess
import sys
from pathlib import Path

def find_vivado():
    """Find Vivado installation"""
    paths = [
        "C:/Xilinx/Vivado/2022.2/bin/vivado.bat",
        "C:/Xilinx/Vivado/2022.1/bin/vivado.bat",
        "C:/Xilinx/Vivado/2023.1/bin/vivado.bat"
    ]
    
    for path in paths:
        if Path(path).exists():
            return path
    return None

def close_vivado_projects():
    """Close any open Vivado projects"""
    vivado_path = find_vivado()
    if not vivado_path:
        print("❌ Vivado not found")
        return False
    
    print("🔧 Closing any open Vivado projects...")
    
    # Create a script to close projects
    close_script = """
# Close any open projects
catch {close_project -quiet}
puts "All projects closed"
exit
"""
    
    script_path = Path("temp_close.tcl")
    with open(script_path, "w") as f:
        f.write(close_script)
    
    try:
        cmd = [vivado_path, "-mode", "batch", "-source", str(script_path)]
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                 universal_newlines=True, encoding='utf-8', errors='replace')
        
        stdout, stderr = process.communicate(timeout=60)
        
        if script_path.exists():
            script_path.unlink()
        
        print("✅ Vivado projects closed")
        return True
        
    except Exception as e:
        print(f"❌ Error closing projects: {e}")
        return False
    finally:
        if script_path.exists():
            script_path.unlink()

if __name__ == "__main__":
    close_vivado_projects()