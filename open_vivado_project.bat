@echo off
REM Windows batch script to open the Vivado project directly
REM Double-click this file to open the project in Vivado

echo Opening RISC-V Processor project in Vivado...
echo.

REM Check if project file exists
if not exist "vivado_project\riscv_processor.xpr" (
    echo Error: Project file not found!
    echo Please run: make create-project
    echo Or: python scripts/run_vivado.py scripts/create_vivado_project.tcl
    pause
    exit /b 1
)

REM Try to find and launch Vivado
set VIVADO_PATH=
for %%i in (vivado.bat vivado.exe) do (
    for %%j in (%%i) do (
        if not "%%~$PATH:j"=="" (
            set VIVADO_PATH=%%~$PATH:j
            goto :found
        )
    )
)

REM Check common installation paths
if exist "C:\Xilinx\Vivado\2023.1\bin\vivado.bat" set VIVADO_PATH=C:\Xilinx\Vivado\2023.1\bin\vivado.bat
if exist "C:\Xilinx\Vivado\2022.2\bin\vivado.bat" set VIVADO_PATH=C:\Xilinx\Vivado\2022.2\bin\vivado.bat
if exist "C:\Xilinx\Vivado\2022.1\bin\vivado.bat" set VIVADO_PATH=C:\Xilinx\Vivado\2022.1\bin\vivado.bat
if exist "C:\Xilinx\Vivado\2021.2\bin\vivado.bat" set VIVADO_PATH=C:\Xilinx\Vivado\2021.2\bin\vivado.bat

:found
if "%VIVADO_PATH%"=="" (
    echo Error: Vivado not found!
    echo Please ensure Vivado is installed and in your PATH
    echo Or modify this script to point to your Vivado installation
    pause
    exit /b 1
)

echo Found Vivado: %VIVADO_PATH%
echo Opening project: vivado_project\riscv_processor.xpr
echo.

REM Launch Vivado with the project file
"%VIVADO_PATH%" "vivado_project\riscv_processor.xpr"