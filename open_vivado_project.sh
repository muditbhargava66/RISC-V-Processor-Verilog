#!/bin/bash
# Linux/macOS script to open the Vivado project directly
# Run: ./open_vivado_project.sh

echo "Opening RISC-V Processor project in Vivado..."
echo

# Check if project file exists
if [ ! -f "vivado_project/riscv_processor.xpr" ]; then
    echo "Error: Project file not found!"
    echo "Please run: make create-project"
    echo "Or: python3 scripts/run_vivado.py scripts/create_vivado_project.tcl"
    exit 1
fi

# Try to find Vivado
VIVADO_PATH=""

# Check if vivado is in PATH
if command -v vivado >/dev/null 2>&1; then
    VIVADO_PATH="vivado"
else
    # Check common installation paths
    for path in \
        "/opt/Xilinx/Vivado/2023.1/bin/vivado" \
        "/opt/Xilinx/Vivado/2022.2/bin/vivado" \
        "/opt/Xilinx/Vivado/2022.1/bin/vivado" \
        "/opt/Xilinx/Vivado/2021.2/bin/vivado" \
        "/tools/Xilinx/Vivado/2023.1/bin/vivado" \
        "/tools/Xilinx/Vivado/2022.2/bin/vivado"
    do
        if [ -x "$path" ]; then
            VIVADO_PATH="$path"
            break
        fi
    done
fi

if [ -z "$VIVADO_PATH" ]; then
    echo "Error: Vivado not found!"
    echo "Please ensure Vivado is installed and in your PATH"
    echo "Or modify this script to point to your Vivado installation"
    exit 1
fi

echo "Found Vivado: $VIVADO_PATH"
echo "Opening project: vivado_project/riscv_processor.xpr"
echo

# Launch Vivado with the project file
"$VIVADO_PATH" "vivado_project/riscv_processor.xpr" &

echo "Vivado launched in background"