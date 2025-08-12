# Simple RISC-V Assembly Program
# Demonstrates basic arithmetic operations

.text
.globl _start

_start:
    # Initialize registers
    addi x1, x0, 10      # x1 = 10
    addi x2, x0, 5       # x2 = 5
    
    # Arithmetic operations
    add  x3, x1, x2      # x3 = x1 + x2 = 15
    sub  x4, x1, x2      # x4 = x1 - x2 = 5
    
    # Logical operations
    and  x5, x1, x2      # x5 = x1 & x2
    or   x6, x1, x2      # x6 = x1 | x2
    xor  x7, x1, x2      # x7 = x1 ^ x2
    
    # Shift operations
    sll  x8, x1, x2      # x8 = x1 << x2
    srl  x9, x1, x2      # x9 = x1 >> x2
    
    # Comparison
    slt  x10, x2, x1     # x10 = (x2 < x1) ? 1 : 0
    
    # Branch test
    beq  x1, x1, equal   # Branch if x1 == x1 (always true)
    addi x11, x0, 99     # Should not execute
    
equal:
    addi x11, x0, 1      # x11 = 1 (branch taken)
    
    # Simple loop
    addi x12, x0, 0      # Counter
    addi x13, x0, 3      # Loop limit
    
loop:
    addi x12, x12, 1     # Increment counter
    blt  x12, x13, loop  # Branch if counter < limit
    
    # End program
    addi x14, x0, 42     # Final result
    
    # Infinite loop to stop execution
end:
    beq  x0, x0, end