#!/usr/bin/env python3
"""
Cross-platform Vivado wrapper script
Handles different OS-specific Vivado invocations and paths
"""

import os
import sys
import subprocess
import platform
from pathlib import Path

class VivadoWrapper:
    def __init__(self):
        self.os_type = platform.system()
        self.vivado_cmd = self._find_vivado()
        
    def _find_vivado(self):
        """Find Vivado executable on different platforms"""
        possible_commands = []
        
        if self.os_type == "Windows":
            # Common Windows Vivado paths
            possible_commands = [
                "vivado.bat",
                "vivado",
                r"C:\Xilinx\Vivado\2023.1\bin\vivado.bat",
                r"C:\Xilinx\Vivado\2022.2\bin\vivado.bat",
                r"C:\Xilinx\Vivado\2022.1\bin\vivado.bat",
                r"C:\Xilinx\Vivado\2021.2\bin\vivado.bat",
            ]
        else:
            # Linux/macOS paths
            possible_commands = [
                "vivado",
                "/opt/Xilinx/Vivado/2023.1/bin/vivado",
                "/opt/Xilinx/Vivado/2022.2/bin/vivado",
                "/opt/Xilinx/Vivado/2022.1/bin/vivado",
                "/opt/Xilinx/Vivado/2021.2/bin/vivado",
                "/tools/Xilinx/Vivado/2023.1/bin/vivado",
                "/tools/Xilinx/Vivado/2022.2/bin/vivado",
            ]
        
        # Check each possible command
        for cmd in possible_commands:
            try:
                if os.path.exists(cmd):
                    return cmd
                
                # Try to run the command to see if it's in PATH
                if self.os_type == "Windows":
                    result = subprocess.run(f"where {cmd}", shell=True, capture_output=True)
                else:
                    result = subprocess.run(f"which {cmd}", shell=True, capture_output=True)
                
                if result.returncode == 0:
                    return cmd
                    
            except Exception:
                continue
        
        return None
    
    def is_available(self):
        """Check if Vivado is available"""
        return self.vivado_cmd is not None
    
    def run_script(self, script_path, mode="batch", log_file=None, journal_file=None):
        """Run a Vivado TCL script"""
        if not self.is_available():
            print("❌ Vivado not found!")
            print("Please ensure Vivado is installed and in your PATH.")
            return False
        
        # Build command
        cmd_parts = [self.vivado_cmd, "-mode", mode, "-source", script_path]
        
        if log_file:
            cmd_parts.extend(["-log", log_file])
        
        if journal_file:
            cmd_parts.extend(["-journal", journal_file])
        
        command = " ".join(cmd_parts)
        
        print(f"Running: {command}")
        
        try:
            result = subprocess.run(command, shell=True)
            return result.returncode == 0
        except Exception as e:
            print(f"Error running Vivado: {e}")
            return False
    
    def get_version(self):
        """Get Vivado version"""
        if not self.is_available():
            return None
        
        try:
            result = subprocess.run(f"{self.vivado_cmd} -version", 
                                  shell=True, capture_output=True, text=True)
            if result.returncode == 0:
                # Extract version from output
                for line in result.stdout.split('\n'):
                    if 'Vivado' in line and 'v' in line:
                        return line.strip()
            return "Unknown version"
        except Exception:
            return None

def main():
    """Main function for testing the wrapper"""
    wrapper = VivadoWrapper()
    
    print("Vivado Wrapper Test")
    print("=" * 30)
    print(f"OS: {platform.system()}")
    print(f"Vivado available: {wrapper.is_available()}")
    
    if wrapper.is_available():
        print(f"Vivado command: {wrapper.vivado_cmd}")
        version = wrapper.get_version()
        if version:
            print(f"Vivado version: {version}")
    else:
        print("Vivado not found in common locations.")
        print("Please ensure Vivado is installed and accessible.")

if __name__ == "__main__":
    main()