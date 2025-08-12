# RISC-V Memory Operations Test
# Tests load and store instructions

.text
.globl _start

_start:
    # Initialize base address
    addi x1, x0, 0x100   # Base address = 0x100
    
    # Test word operations
    addi x2, x0, 0x12345678  # Test data (would need lui/ori for full 32-bit)
    sw   x2, 0(x1)       # Store word at address 0x100
    lw   x3, 0(x1)       # Load word from address 0x100
    
    # Test halfword operations
    addi x4, x0, 0x1234  # Test halfword data
    sh   x4, 4(x1)       # Store halfword at address 0x104
    lh   x5, 4(x1)       # Load halfword (sign extended)
    lhu  x6, 4(x1)       # Load halfword unsigned
    
    # Test byte operations
    addi x7, x0, 0x56    # Test byte data
    sb   x7, 8(x1)       # Store byte at address 0x108
    lb   x8, 8(x1)       # Load byte (sign extended)
    lbu  x9, 8(x1)       # Load byte unsigned
    
    # Test multiple stores and loads
    addi x10, x0, 1
    addi x11, x0, 2
    addi x12, x0, 3
    
    sw   x10, 12(x1)     # Store at 0x10C
    sw   x11, 16(x1)     # Store at 0x110
    sw   x12, 20(x1)     # Store at 0x114
    
    lw   x13, 12(x1)     # Load from 0x10C
    lw   x14, 16(x1)     # Load from 0x110
    lw   x15, 20(x1)     # Load from 0x114
    
    # Verify data integrity
    beq  x10, x13, test1_pass
    addi x16, x0, 1      # Test 1 failed
    
test1_pass:
    beq  x11, x14, test2_pass
    addi x17, x0, 1      # Test 2 failed
    
test2_pass:
    beq  x12, x15, all_pass
    addi x18, x0, 1      # Test 3 failed
    
all_pass:
    addi x19, x0, 0xFF   # All tests passed
    
    # End program
end:
    beq  x0, x0, end