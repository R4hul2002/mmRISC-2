// t34_cbozero : cbo.zero (Zicboz)
//
// The whole 64 byte block around rs1 becomes zero, from any byte of it;
// the blocks around it stay. On memory that is not cached (the peripheral
// window below MEM_BASE) it is a store access fault. Below M it is there
// only as menvcfg.CBZE lets it (and in U senvcfg.CBZE too); otherwise it
// is an illegal instruction. The other cache block operations (Zicbom:
// cbo.clean / flush / inval) are not there. menvcfg / senvcfg keep CBZE
// (bit 7) and nothing else of what the core does not have.
//
//   x29 / x28 / x27 / x26 : a trap happened, its cause, tval, epc
//   x24 : where the handler resumes (0 : behind the instruction)
//   x23 : if not zero, the handler sets MPP to x23[1:0] before MRET
#include "test.h"

// cbo.zero (rs) : MISC-MEM, funct3 2, rd 0, imm 4 (written out, so that the
// test does not need an assembler that knows Zicboz)
#define CBO_ZERO(rs)   .insn i 0x0F, 2, x0, rs, 4
#define CBO_INVAL(rs)  .insn i 0x0F, 2, x0, rs, 0
#define CBO_CLEAN(rs)  .insn i 0x0F, 2, x0, rs, 1
#define CBO_FLUSH(rs)  .insn i 0x0F, 2, x0, rs, 2

#define CSR_SENVCFG 0x10A
#define CSR_MENVCFG 0x30A
#define CBZE        0x80

#define CAUSE_ILLEGAL 2
#define CAUSE_SFAULT  7

    .section .text.init
    .globl _start
_start:
    TEST_INIT
    INIT_PMP
    la   t0, m_trap
    csrw mtvec, t0
    li   x29, 0
    li   x24, 0
    li   x23, 0

    //-----------------------------------------------------------------
    // three blocks of known values
    //-----------------------------------------------------------------
    la   x10, blocks
    li   x11, 24
    li   x12, 0x1111
1:  sd   x12, 0(x10)
    addi x12, x12, 1
    addi x10, x10, 8
    addi x11, x11, -1
    bnez x11, 1b

    // ---- machine mode : the middle block, from an odd byte of it ----
    la   x10, blocks
    addi x13, x10, 64 + 0x13
    CBO_ZERO(x13)
    TEST_EQ(1, x29, 0)
    li   x14, 0                           // the sum of the middle block
    addi x15, x10, 64
    li   x11, 8
1:  ld   x16, 0(x15)
    or   x14, x14, x16
    addi x15, x15, 8
    addi x11, x11, -1
    bnez x11, 1b
    TEST_EQ(2, x14, 0)
    ld   x16, 56(x10)                     // the last word before it
    TEST_EQ(3, x16, 0x1118)
    ld   x16, 128(x10)                    // the first word after it
    TEST_EQ(4, x16, 0x1121)

    // ---- the peripheral window: a store access fault ----
    li   x29, 0
    li   x13, 0x02000000                  // CLINT
    CBO_ZERO(x13)
    TEST_EQ(5, x29, 1)
    TEST_EQ(6, x28, CAUSE_SFAULT)
    TEST_EQ_REG(7, x27, x13)              // mtval is the address

    // ---- Zicbom is not there ----
    li   x29, 0
    CBO_CLEAN(x10)
    TEST_EQ(8, x28, CAUSE_ILLEGAL)
    li   x29, 0
    CBO_FLUSH(x10)
    TEST_EQ(9, x28, CAUSE_ILLEGAL)
    li   x29, 0
    CBO_INVAL(x10)
    TEST_EQ(10, x28, CAUSE_ILLEGAL)
    TEST_EQ(11, x29, 1)

    // ---- menvcfg / senvcfg keep CBZE and nothing new ----
    li   t0, 0xFF
    csrw CSR_MENVCFG, t0
    csrr x14, CSR_MENVCFG
    TEST_EQ(12, x14, CBZE)
    csrw CSR_SENVCFG, t0
    csrr x14, CSR_SENVCFG
    TEST_EQ(13, x14, CBZE)
    csrw CSR_MENVCFG, x0
    csrw CSR_SENVCFG, x0

    // ---- supervisor mode, menvcfg.CBZE clear: illegal ----
    la   x24, back_1
    li   t0, 3 << 11
    csrc mstatus, t0
    li   t0, 1 << 11
    csrs mstatus, t0                      // MPP = S
    la   t0, in_s_1
    csrw mepc, t0
    li   x29, 0
    mret
in_s_1:
    addi x13, x10, 128
    CBO_ZERO(x13)                         // traps; the handler goes on at back_1
    j    fail
back_1:
    TEST_EQ(14, x29, 1)
    TEST_EQ(15, x28, CAUSE_ILLEGAL)
    ld   x16, 128(x10)
    TEST_EQ(16, x16, 0x1121)              // nothing was written

    // ---- supervisor mode with menvcfg.CBZE: it works ----
    li   t0, CBZE
    csrs CSR_MENVCFG, t0
    la   x24, back_2
    li   t0, 3 << 11
    csrc mstatus, t0
    li   t0, 1 << 11
    csrs mstatus, t0
    la   t0, in_s_2
    csrw mepc, t0
    li   x29, 0
    mret
in_s_2:
    addi x13, x10, 128 + 8
    CBO_ZERO(x13)
    ecall                                 // back to M (x24 : back_2)
back_2:
    TEST_EQ(17, x28, 9)                   // the ecall from S, no other trap
    ld   x16, 128(x10)
    TEST_EQ(18, x16, 0)
    ld   x16, 184(x10)
    TEST_EQ(19, x16, 0)

    // ---- user mode: senvcfg.CBZE clear is illegal, set it works ----
    la   x24, back_3
    li   t0, 3 << 11
    csrc mstatus, t0                      // MPP = U
    la   t0, in_u_1
    csrw mepc, t0
    li   x29, 0
    mret
in_u_1:
    CBO_ZERO(x10)
    j    fail
back_3:
    TEST_EQ(20, x28, CAUSE_ILLEGAL)
    ld   x16, 0(x10)
    TEST_EQ(21, x16, 0x1111)
    li   t0, CBZE
    csrs CSR_SENVCFG, t0
    la   x24, back_4
    li   t0, 3 << 11
    csrc mstatus, t0
    la   t0, in_u_2
    csrw mepc, t0
    li   x29, 0
    mret
in_u_2:
    CBO_ZERO(x10)
    ecall
back_4:
    TEST_EQ(22, x28, 8)                   // the ecall from U, no other trap
    ld   x16, 0(x10)
    TEST_EQ(23, x16, 0)
    ld   x16, 56(x10)
    TEST_EQ(24, x16, 0)

    la   t0, default_trap
    csrw mtvec, t0
    TEST_DONE

    //-----------------------------------------------------------------
    .align 2
m_trap:
    csrr x28, mcause
    csrr x27, mtval
    csrr x26, mepc
    li   x29, 1
    beq  x23, x0, 1f
    li   t0, 3 << 11
    csrc mstatus, t0
    andi t0, x23, 3
    slli t0, t0, 11
    csrs mstatus, t0
    li   x23, 0
1:
    bne  x24, x0, 2f
    csrr t0, mepc
    addi t0, t0, 4
    csrw mepc, t0
    mret
2:
    // back to machine mode at x24
    li   t0, 3 << 11
    csrs mstatus, t0                      // MPP = M
    csrw mepc, x24
    li   x24, 0
    mret

    TEST_FAIL_HANDLER

    .section .data
    .align 6
blocks:
    .space 3 * 64

    TOHOST_SECTION
