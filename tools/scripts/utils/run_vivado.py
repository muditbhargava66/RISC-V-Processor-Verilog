#!/usr/bin/env python3
"""
Vivado runner script - handles cross-platform Vivado execution
Usage: python run_vivado.py <script.tcl> [log_file] [journal_file]
"""

import sys
import os
from vivado_wrapper import VivadoWrapper

def main():
    if len(sys.argv) < 2:
        print("Usage: python run_vivado.py <script.tcl> [log_file] [journal_file]")
        return 1
    
    script_path = sys.argv[1]
    log_file = sys.argv[2] if len(sys.argv) > 2 else None
    journal_file = sys.argv[3] if len(sys.argv) > 3 else None
    
    # Check if script exists
    if not os.path.exists(script_path):
        print(f"[ERROR] Script not found: {script_path}")
        return 1
    
    wrapper = VivadoWrapper()
    
    if not wrapper.is_available():
        print("[ERROR] Vivado not found!")
        print("Please ensure Vivado is installed and in your PATH.")
        print("\nCommon installation paths:")
        print("  Windows: C:\\Xilinx\\Vivado\\<version>\\bin\\")
        print("  Linux:   /opt/Xilinx/Vivado/<version>/bin/")
        print("  macOS:   /opt/Xilinx/Vivado/<version>/bin/")
        return 1
    
    print(f"[INFO] Found Vivado: {wrapper.vivado_cmd}")
    version = wrapper.get_version()
    if version:
        print(f"[INFO] Version: {version}")
    
    success = wrapper.run_script(script_path, log_file=log_file, journal_file=journal_file)
    
    if success:
        print("[SUCCESS] Vivado script completed successfully!")
        return 0
    else:
        print("[ERROR] Vivado script failed!")
        return 1

if __name__ == "__main__":
    sys.exit(main())