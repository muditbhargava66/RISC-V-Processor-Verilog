#!/usr/bin/env python3
"""
RISC-V Processor Unit Test Runner
Production-ready test automation script
"""

import os
import sys
import subprocess
import time
import json
from pathlib import Path
from typing import Dict, List, Tuple
import argparse

class UnitTestRunner:
    """Professional unit test runner for RISC-V processor verification"""
    
    def __init__(self, project_root: str = "."):
        self.project_root = Path(project_root).resolve()
        self.verification_dir = self.project_root / "verification"
        self.testbench_dir = self.verification_dir / "testbenches" / "unit"
        self.results_dir = self.verification_dir / "results"
        self.coverage_dir = self.verification_dir / "coverage"
        
        # Test configuration
        self.unit_tests = [
            "alu_tb",
            "register_file_tb", 
            "control_unit_tb",
            "immediate_generator_tb",
            "program_counter_tb",
            "branch_unit_tb"
        ]
        
        # Results tracking
        self.test_results = {}
        self.overall_success = True
        
        # Create output directories
        self.results_dir.mkdir(parents=True, exist_ok=True)
        self.coverage_dir.mkdir(parents=True, exist_ok=True)
    
    def run_single_test(self, test_name: str, simulator: str = "xsim") -> Tuple[bool, Dict]:
        """Run a single unit test and return results"""
        print(f"🧪 Running {test_name}...")
        
        # Try both .sv and .v extensions
        test_file_sv = self.testbench_dir / f"{test_name}.sv"
        test_file_v = self.testbench_dir / f"{test_name}.v"
        
        if test_file_sv.exists():
            test_file = test_file_sv
        elif test_file_v.exists():
            test_file = test_file_v
        else:
            print(f"❌ Test file not found: {test_file_sv} or {test_file_v}")
            return False, {"error": "Test file not found"}
        
        # Prepare simulation command based on simulator
        if simulator == "xsim":
            return self._run_xsim_test(test_name)
        elif simulator == "modelsim":
            return self._run_modelsim_test(test_name)
        else:
            print(f"❌ Unsupported simulator: {simulator}")
            return False, {"error": f"Unsupported simulator: {simulator}"}
    
    def _run_xsim_test(self, test_name: str) -> Tuple[bool, Dict]:
        """Run test using Xilinx Vivado XSim"""
        try:
            # Create temporary TCL script for simulation
            tcl_script = self._create_xsim_tcl(test_name)
            
            # Run simulation
            start_time = time.time()
            result = subprocess.run([
                "vivado", "-mode", "batch", "-source", str(tcl_script)
            ], capture_output=True, text=True, timeout=300)
            
            end_time = time.time()
            duration = end_time - start_time
            
            # Parse results
            success = result.returncode == 0
            log_content = result.stdout + result.stderr
            
            # Extract test statistics from log
            stats = self._parse_test_log(log_content)
            stats["duration"] = duration
            stats["simulator"] = "xsim"
            
            if success:
                print(f"✅ {test_name} completed successfully ({duration:.2f}s)")
            else:
                print(f"❌ {test_name} failed ({duration:.2f}s)")
                print(f"Error: {result.stderr}")
            
            # Save detailed log
            log_file = self.results_dir / f"{test_name}_xsim.log"
            with open(log_file, 'w') as f:
                f.write(log_content)
            
            return success, stats
            
        except subprocess.TimeoutExpired:
            print(f"❌ {test_name} timed out")
            return False, {"error": "Test timed out", "duration": 300}
        except Exception as e:
            print(f"❌ {test_name} failed with exception: {e}")
            return False, {"error": str(e)}
    
    def _create_xsim_tcl(self, test_name: str) -> Path:
        """Create TCL script for XSim simulation"""
        tcl_content = f"""
# XSim simulation script for {test_name}
create_project -force temp_proj ./temp_proj -part xc7a35tcpg236-1

# Add source files
add_files -norecurse {{
    ../src/alu.v
    ../src/register_file.v
    ../src/control_unit.v
    ../src/immediate_generator.v
}}

# Add testbench
add_files -fileset sim_1 -norecurse {{
    {self.testbench_dir}/{test_name}.sv
}}

# Set top module
set_property top {test_name} [get_filesets sim_1]

# Launch simulation
launch_simulation -mode behavioral

# Run simulation
run all

# Close project
close_project
"""
        
        tcl_file = self.results_dir / f"{test_name}_sim.tcl"
        with open(tcl_file, 'w') as f:
            f.write(tcl_content)
        
        return tcl_file
    
    def _run_modelsim_test(self, test_name: str) -> Tuple[bool, Dict]:
        """Run test using ModelSim/QuestaSim"""
        try:
            # Create work library
            subprocess.run(["vlib", "work"], check=True)
            
            # Compile source files
            compile_cmd = [
                "vlog", "-sv",
                str(self.project_root / "src" / "*.v"),
                str(self.testbench_dir / f"{test_name}.sv")
            ]
            
            result = subprocess.run(compile_cmd, capture_output=True, text=True)
            if result.returncode != 0:
                return False, {"error": "Compilation failed", "log": result.stderr}
            
            # Run simulation
            start_time = time.time()
            sim_cmd = ["vsim", "-c", "-do", f"run -all; quit", test_name]
            result = subprocess.run(sim_cmd, capture_output=True, text=True, timeout=300)
            
            end_time = time.time()
            duration = end_time - start_time
            
            success = result.returncode == 0
            log_content = result.stdout + result.stderr
            
            stats = self._parse_test_log(log_content)
            stats["duration"] = duration
            stats["simulator"] = "modelsim"
            
            # Save log
            log_file = self.results_dir / f"{test_name}_modelsim.log"
            with open(log_file, 'w') as f:
                f.write(log_content)
            
            return success, stats
            
        except Exception as e:
            return False, {"error": str(e)}
    
    def _parse_test_log(self, log_content: str) -> Dict:
        """Parse test log to extract statistics"""
        stats = {
            "total_tests": 0,
            "passed": 0,
            "failed": 0,
            "success_rate": 0.0,
            "errors": []
        }
        
        lines = log_content.split('\n')
        for line in lines:
            if "Total Tests:" in line:
                try:
                    stats["total_tests"] = int(line.split(':')[1].strip())
                except:
                    pass
            elif "Passed:" in line:
                try:
                    stats["passed"] = int(line.split(':')[1].strip())
                except:
                    pass
            elif "Failed:" in line:
                try:
                    stats["failed"] = int(line.split(':')[1].strip())
                except:
                    pass
            elif "Success Rate:" in line:
                try:
                    rate_str = line.split(':')[1].strip().replace('%', '')
                    stats["success_rate"] = float(rate_str)
                except:
                    pass
            elif "❌" in line or "ERROR" in line:
                stats["errors"].append(line.strip())
        
        return stats   
 
    def run_all_tests(self, simulator: str = "xsim", parallel: bool = False) -> bool:
        """Run all unit tests"""
        print("========================================")
        print("🚀 RISC-V Processor Unit Test Suite")
        print("========================================")
        print(f"Simulator: {simulator}")
        print(f"Test Directory: {self.testbench_dir}")
        print(f"Results Directory: {self.results_dir}")
        print("")
        
        start_time = time.time()
        
        if parallel and len(self.unit_tests) > 1:
            # Run tests in parallel (simplified version)
            print("🔄 Running tests in parallel...")
            success = self._run_tests_parallel(simulator)
        else:
            # Run tests sequentially
            print("🔄 Running tests sequentially...")
            success = self._run_tests_sequential(simulator)
        
        end_time = time.time()
        total_duration = end_time - start_time
        
        # Generate comprehensive report
        self._generate_final_report(total_duration)
        
        return success
    
    def _run_tests_sequential(self, simulator: str) -> bool:
        """Run tests one by one"""
        overall_success = True
        
        for test_name in self.unit_tests:
            success, stats = self.run_single_test(test_name, simulator)
            self.test_results[test_name] = {
                "success": success,
                "stats": stats
            }
            
            if not success:
                overall_success = False
            
            print("")  # Add spacing between tests
        
        return overall_success
    
    def _run_tests_parallel(self, simulator: str) -> bool:
        """Run tests in parallel (basic implementation)"""
        import concurrent.futures
        
        overall_success = True
        
        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as executor:
            # Submit all tests
            future_to_test = {
                executor.submit(self.run_single_test, test_name, simulator): test_name
                for test_name in self.unit_tests
            }
            
            # Collect results
            for future in concurrent.futures.as_completed(future_to_test):
                test_name = future_to_test[future]
                try:
                    success, stats = future.result()
                    self.test_results[test_name] = {
                        "success": success,
                        "stats": stats
                    }
                    
                    if not success:
                        overall_success = False
                        
                except Exception as e:
                    print(f"❌ {test_name} generated an exception: {e}")
                    self.test_results[test_name] = {
                        "success": False,
                        "stats": {"error": str(e)}
                    }
                    overall_success = False
        
        return overall_success
    
    def _generate_final_report(self, total_duration: float):
        """Generate comprehensive test report"""
        print("========================================")
        print("📊 UNIT TEST SUITE REPORT")
        print("========================================")
        
        total_tests = 0
        total_passed = 0
        total_failed = 0
        successful_modules = 0
        
        # Per-module summary
        for test_name, result in self.test_results.items():
            success = result["success"]
            stats = result["stats"]
            
            print(f"\n📋 {test_name.upper()}:")
            print(f"   Status: {'✅ PASS' if success else '❌ FAIL'}")
            
            if "total_tests" in stats:
                print(f"   Tests: {stats['passed']}/{stats['total_tests']} passed")
                print(f"   Success Rate: {stats['success_rate']:.1f}%")
                total_tests += stats["total_tests"]
                total_passed += stats["passed"]
                total_failed += stats["failed"]
            
            if "duration" in stats:
                print(f"   Duration: {stats['duration']:.2f}s")
            
            if success:
                successful_modules += 1
            
            if "errors" in stats and stats["errors"]:
                print(f"   Errors: {len(stats['errors'])}")
        
        # Overall summary
        print("\n" + "="*40)
        print("🎯 OVERALL SUMMARY")
        print("="*40)
        print(f"Modules Tested: {len(self.unit_tests)}")
        print(f"Modules Passed: {successful_modules}")
        print(f"Modules Failed: {len(self.unit_tests) - successful_modules}")
        
        if total_tests > 0:
            overall_success_rate = (total_passed / total_tests) * 100
            print(f"Total Test Cases: {total_tests}")
            print(f"Total Passed: {total_passed}")
            print(f"Total Failed: {total_failed}")
            print(f"Overall Success Rate: {overall_success_rate:.2f}%")
        
        print(f"Total Duration: {total_duration:.2f}s")
        
        # Final verdict
        print("\n" + "="*40)
        if successful_modules == len(self.unit_tests):
            print("🎉 ALL UNIT TESTS PASSED!")
            print("✅ RISC-V processor units are ready for integration")
        else:
            failed_count = len(self.unit_tests) - successful_modules
            print(f"❌ {failed_count} UNIT TEST(S) FAILED")
            print("🔧 Fix failing modules before proceeding to integration")
        print("="*40)
        
        # Save JSON report
        self._save_json_report(total_duration)
    
    def _save_json_report(self, total_duration: float):
        """Save detailed results in JSON format"""
        report = {
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
            "total_duration": total_duration,
            "summary": {
                "modules_tested": len(self.unit_tests),
                "modules_passed": sum(1 for r in self.test_results.values() if r["success"]),
                "modules_failed": sum(1 for r in self.test_results.values() if not r["success"])
            },
            "results": self.test_results
        }
        
        report_file = self.results_dir / "unit_test_report.json"
        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2)
        
        print(f"\n📄 Detailed report saved: {report_file}")
    
    def generate_coverage_report(self):
        """Generate code coverage report (placeholder)"""
        print("\n📈 Generating coverage report...")
        
        # This would integrate with coverage tools
        coverage_file = self.coverage_dir / "unit_coverage.html"
        
        # Placeholder coverage report
        html_content = """
        <html><head><title>Unit Test Coverage</title></head>
        <body>
        <h1>RISC-V Processor Unit Test Coverage</h1>
        <p>Coverage analysis would be generated here by tools like:</p>
        <ul>
        <li>Vivado Code Coverage</li>
        <li>VCS Coverage</li>
        <li>QuestaSim Coverage</li>
        </ul>
        </body></html>
        """
        
        with open(coverage_file, 'w') as f:
            f.write(html_content)
        
        print(f"📊 Coverage report placeholder: {coverage_file}")

def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(description="RISC-V Processor Unit Test Runner")
    parser.add_argument("--simulator", choices=["xsim", "modelsim"], default="xsim",
                       help="Simulation tool to use")
    parser.add_argument("--parallel", action="store_true",
                       help="Run tests in parallel")
    parser.add_argument("--coverage", action="store_true",
                       help="Generate coverage report")
    parser.add_argument("--test", type=str,
                       help="Run specific test only")
    parser.add_argument("--project-root", type=str, default=".",
                       help="Project root directory")
    
    args = parser.parse_args()
    
    # Create test runner
    runner = UnitTestRunner(args.project_root)
    
    try:
        if args.test:
            # Run single test
            print(f"🎯 Running single test: {args.test}")
            success, stats = runner.run_single_test(args.test, args.simulator)
            
            if success:
                print("✅ Test completed successfully")
                sys.exit(0)
            else:
                print("❌ Test failed")
                sys.exit(1)
        else:
            # Run all tests
            success = runner.run_all_tests(args.simulator, args.parallel)
            
            if args.coverage:
                runner.generate_coverage_report()
            
            sys.exit(0 if success else 1)
            
    except KeyboardInterrupt:
        print("\n⚠️  Test run interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n💥 Test runner failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()