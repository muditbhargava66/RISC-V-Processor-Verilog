# RISC-V Processor Cleanup Script
# Removes all generated files, logs, and temporary directories

param(
    [switch]$Deep,
    [switch]$LogsOnly
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "RISC-V Processor Cleanup Script" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

function Remove-SafelyIfExists {
    param([string]$Path, [string]$Description)
    
    if (Test-Path $Path) {
        try {
            Remove-Item $Path -Recurse -Force -ErrorAction Stop
            Write-Host "Removed: $Description" -ForegroundColor Green
        }
        catch {
            Write-Host "Warning: Could not remove $Description" -ForegroundColor Yellow
        }
    }
}

function Remove-FilePattern {
    param([string]$Pattern, [string]$Description)
    
    $files = Get-ChildItem -Path . -Name $Pattern -Recurse -ErrorAction SilentlyContinue
    if ($files) {
        $files | ForEach-Object {
            try {
                Remove-Item $_ -Force -ErrorAction Stop
            }
            catch {
                # Silently continue
            }
        }
        Write-Host "Cleaned: $Description" -ForegroundColor Green
    }
}

# Clean log files
Write-Host "Cleaning log and journal files..." -ForegroundColor Yellow
Remove-FilePattern "*.log" "Log files"
Remove-FilePattern "*.jou" "Journal files"
Remove-FilePattern "*.backup.log" "Backup log files"
Remove-FilePattern "*.backup.jou" "Backup journal files"
Remove-FilePattern "vivado*.log" "Vivado log files"
Remove-FilePattern "vivado*.jou" "Vivado journal files"

if ($LogsOnly) {
    Write-Host "Log cleanup completed!" -ForegroundColor Green
    exit 0
}

# Clean generated files
Write-Host "Cleaning generated files..." -ForegroundColor Yellow
Remove-SafelyIfExists ".Xil" "Xilinx temporary directory"
Remove-SafelyIfExists "xsim.dir" "XSim directory"

# Clean simulation files
Remove-FilePattern "*.wdb" "Waveform database files"
Remove-FilePattern "*.wcfg" "Waveform configuration files"
Remove-FilePattern "*.vcd" "VCD files"
Remove-FilePattern "*.pb" "Protocol buffer files"

# Clean synthesis files
Remove-FilePattern "*.dcp" "Design checkpoint files"
Remove-FilePattern "*.bit" "Bitstream files"
Remove-FilePattern "*.ltx" "Logic analyzer files"
Remove-FilePattern "*.mmi" "Memory map files"

if ($Deep) {
    Write-Host "Performing deep clean..." -ForegroundColor Yellow
    Remove-SafelyIfExists "projects" "Project directories"
    Remove-SafelyIfExists "test_project" "Test project directory"
    
    # Clean any remaining Vivado generated directories
    Get-ChildItem -Directory | Where-Object { $_.Name -match ".*\.cache$|.*\.hw$|.*\.ip_user_files$|.*\.sim$|.*\.runs$|.*\.gen$|.*\.srcs$" } | ForEach-Object {
        Remove-SafelyIfExists $_.FullName $_.Name
    }
}

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Cleanup completed successfully!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan