# PoSeiDon Core (PSD)
## RV32IMA-Sv32 Microarchitecture Specification
### Version 1.1 — Monolithic Architecture Document

---

# Chapter 1 — Architectural Contract

## 1.1 Design Objectives
The PoSeiDon Core (PSD) is a 32-bit in-order RISC processor implementing RV32IMA with Supervisor support and Sv32 virtual memory. The primary architectural goals are:

- Full compliance with RV32I base integer ISA
- Support for M (integer multiply/divide) and A (atomic) extensions
- Support for Zicsr control and status register instructions
- Machine (M) and Supervisor (S) privilege modes
- Sv32 virtual memory capable of running Linux
- Precise exceptions
- Deterministic 5-stage pipeline

## 1.2 Architectural Scope
The core SHALL:
- Execute one instruction per cycle (single-issue)
- Maintain in-order retirement
- Provide a 32-bit address space
- Support 4 KiB pages under Sv32
- Guarantee precise trap semantics

The core SHALL NOT in v1.1:
- Implement out-of-order execution
- Implement branch prediction
- Implement caches (blocking memory model only)

## 1.3 Compliance Requirements
All architectural behavior must conform to the RISC-V Unprivileged and Privileged specifications for RV32IMA and Sv32. Any implementation-defined behavior must not violate architectural guarantees.

## 1.4 Reset State
Upon reset:
- PC is initialized to RESET_VECTOR
- Processor enters Machine mode
- mstatus is cleared except mandatory reset fields
- satp.MODE = 0 (MMU disabled)

## 1.5 Precise Exception Guarantee
At any trap event:
- All older instructions are retired
- The faulting instruction is not committed
- No younger instruction has modified architectural state

---

---

# Chapter 2 — ISA Compliance

## 2.1 Base Integer (RV32I)
PSD implements all 40 base RV32I instructions including:
- Arithmetic (ADD, SUB, SLT, SLTU)
- Logical (AND, OR, XOR)
- Shifts (SLL, SRL, SRA)
- Immediate variants
- Load and store instructions
- Control transfer (JAL, JALR, branches)
- System instructions (ECALL, EBREAK)

All instructions are 32-bit fixed width.

## 2.2 M Extension
The following are supported:
- MUL, MULH, MULHSU, MULHU
- DIV, DIVU
- REM, REMU

Multiplier/divider may be multi-cycle but must stall pipeline until completion.

## 2.3 A Extension
Supported atomic operations:
- LR.W, SC.W
- AMOADD.W, AMOAND.W, AMOOR.W, AMOXOR.W
- AMOMIN.W, AMOMAX.W, AMOMINU.W, AMOMAXU.W

Atomic operations must appear indivisible.

## 2.4 Zicsr
CSR instructions supported:
- CSRRW, CSRRS, CSRRC
- CSRRWI, CSRRSI, CSRRCI

CSR accesses obey privilege rules.

## 2.5 Privileged Compliance
Machine and Supervisor modes implemented.
Trap delegation via medeleg/mideleg supported.
Sv32 page-based virtual memory supported.

---

---

# Chapter 3 — Register File Architecture

## 3.1 General Purpose Registers
PSD implements 64 x 32-bit general-purpose registers.

- x0 is hardwired to zero.
- x1–x63 are writable.

## 3.2 Port Structure
- 2 read ports
- 1 write port

Read ports:
- rs1_addr[5:0]
- rs2_addr[5:0]
- rs1_data[31:0]
- rs2_data[31:0]

Write port:
- rd_addr[5:0]
- rd_data[31:0]
- rd_we

## 3.3 Write Semantics
- Writes occur on rising clock edge
- If rd_addr == 0, write is ignored

## 3.4 Hazard Considerations
Writeback data must be available for forwarding in the following cycle.

## 3.5 Reset Behavior
All registers except x0 are undefined after reset unless explicitly cleared by software.

---

---

# Chapter 4 — Program Counter Unit

## 4.1 PC Register
32-bit register holding address of current instruction.

## 4.2 Default Update Rule
PC_next = PC_current + 4

## 4.3 Redirect Sources
PC may be updated from:
- Branch target (EX stage)
- JAL/JALR target
- Trap vector (mtvec/stvec)
- MRET/SRET return address

## 4.4 Alignment
PC[1:0] must always be 2'b00.
Misaligned instruction fetch raises instruction-address-misaligned exception.

## 4.5 Trap Vector Handling
Trap entry sets PC = BASE + (cause << 2) if vectored mode enabled.
Otherwise PC = BASE.

---

---

# Chapter 5 — Instruction Fetch (IF)

## 5.1 Responsibilities
- Provide instruction to decode stage
- Manage PC sequencing
- Handle control-flow redirects
- Interface with instruction memory

## 5.2 Instruction Memory Interface
Signals:
- imem_addr[31:0]
- imem_rdata[31:0]
- imem_req
- imem_ready

Handshake protocol:
- imem_req asserted when valid fetch requested
- Instruction captured when imem_ready asserted

## 5.3 IF/ID Pipeline Register
Fields:
- pc
- instruction
- valid

## 5.4 Control Hazard Handling
On branch taken or trap:
- Invalidate IF/ID register
- Redirect PC

## 5.5 Stall Conditions
IF stage stalls when:
- Downstream stage asserts stall
- Instruction memory not ready

## 5.6 Exception Detection
Instruction access fault and page fault detected prior to decode when MMU enabled.

---

---

# Chapter 6 — Instruction Decode (ID)

## 6.1 Responsibilities
- Decode opcode, funct3, funct7
- Generate control bundle
- Read register operands
- Generate immediates (I/S/B/U/J)
- Detect illegal instructions

## 6.2 ID/EX Pipeline Register Fields
- pc
- rs1_val[31:0]
- rs2_val[31:0]
- rd_addr[5:0]
- imm[31:0]
- control_bundle
- valid

## 6.3 Immediate Generation
I-type: sign-extend inst[31:20]
S-type: sign-extend {inst[31:25], inst[11:7]}
B-type: sign-extend {inst[31], inst[7], inst[30:25], inst[11:8], 0}
U-type: {inst[31:12], 12'b0}
J-type: sign-extend {inst[31], inst[19:12], inst[20], inst[30:21], 0}

## 6.4 Illegal Instruction Detection
If opcode/funct combination unsupported, raise illegal instruction exception.

---

# Chapter 7 — Execute Stage (EX)

## 7.1 Responsibilities
- Perform ALU operations
- Evaluate branches
- Compute memory addresses
- Execute multiply/divide

## 7.2 ALU Operations
Inputs: rs1_val, rs2_val/imm
Operations:
- ADD/SUB
- AND/OR/XOR
- SLL/SRL/SRA
- SLT/SLTU

## 7.3 Branch Evaluation
Comparison performed in EX stage.
If branch_taken:
- Signal pipeline flush
- Provide redirect PC

## 7.4 Multiplier/Divider
Iterative unit.
Pipeline stalls while busy.
DIV by zero returns defined architectural result per spec.

## 7.5 EX/MEM Register
- alu_result
- rs2_val
- rd_addr
- mem_control
- reg_write
- valid

---

# Chapter 8 — Memory Stage (MEM)

## 8.1 Responsibilities
- Perform loads and stores
- Enforce alignment
- Perform sign/zero extension
- Interface with MMU and DTLB

## 8.2 Memory Interface Signals
- dmem_addr[31:0]
- dmem_wdata[31:0]
- dmem_rdata[31:0]
- dmem_we
- dmem_be[3:0]
- dmem_req
- dmem_ready

## 8.3 Load Semantics
On load completion:
- Apply sign/zero extension
- Forward result to WB

## 8.4 Store Semantics
Store considered architecturally committed at WB stage.

## 8.5 Alignment Rules
Word: addr[1:0] == 00
Halfword: addr[0] == 0
Else: raise misaligned exception.

## 8.6 MEM/WB Register
- write_data
- rd_addr
- reg_write
- valid

---

# Chapter 9 — Writeback Stage (WB)

## 9.1 Responsibilities
- Commit result to register file
- Finalize architectural state update

## 9.2 Writeback Sources
- ALU result
- Load result
- CSR result
- Atomic result

## 9.3 Commit Rules
If exception_valid:
- Suppress register write

If rd_addr != 0 and reg_write == 1:
- Write result on rising edge

WB stage defines precise retirement boundary.

---

# Chapter 10 — Pipeline Architecture

## 10.1 Stage Order
IF → ID → EX → MEM → WB

## 10.2 Pipeline Registers
- IF/ID
- ID/EX
- EX/MEM
- MEM/WB

Each register contains valid bit.

## 10.3 Stall Mechanism
When stall asserted:
- Freeze upstream stages
- Maintain register state

## 10.4 Flush Mechanism
On branch or exception:
- Invalidate younger stage valid bits

---

# Chapter 11 — Hazard Detection Unit

## 11.1 Data Hazards
Forwarding paths:
- EX→EX
- MEM→EX
- WB→EX

## 11.2 Load-Use Hazard
If load in EX and next instruction uses result:
- Insert single-cycle stall

## 11.3 Structural Hazards
No structural hazards in v1.1 (single memory port assumption).

---

# Chapter 12 — Control Unit

## 12.1 Central Control Logic
Generates control signals based on opcode decode.

## 12.2 Exception Priority
Highest to lowest:
1. Instruction access fault
2. Illegal instruction
3. Breakpoint
4. Load/store faults
5. ECALL

## 12.3 Stall/Flush Arbitration
Exceptions override branch redirects.

---

# Chapter 13 — CSR Architecture

## 13.1 Mandatory CSRs
- mstatus
- misa
- mtvec
- mepc
- mcause
- mtval
- medeleg
- mideleg
- satp

## 13.2 CSR Access Rules
- Accessible per privilege level
- Writes masked according to spec

## 13.3 satp Format (Sv32)
- MODE[31:30]
- ASID[29:22]
- PPN[21:0]

MODE=1 enables Sv32.

---

# Chapter 14 — Privileged Modes

## 14.1 Machine Mode (M)
- Full access to CSRs
- Handles all traps unless delegated

## 14.2 Supervisor Mode (S)
- Controlled by mstatus and medeleg
- Access to stvec, sepc, scause

## 14.3 Trap Delegation
medeleg/mideleg determine routing of traps.

## 14.4 Return Instructions
- MRET restores privilege from mstatus.MPP
- SRET restores from sstatus.SPP

---

# Chapter 15 — Exception Model

## 15.1 Precise Exceptions
- All older instructions committed
- Faulting instruction not committed
- Younger instructions flushed

## 15.2 Exception Types
- Instruction address misaligned
- Instruction access fault
- Illegal instruction
- Breakpoint
- Load/store misaligned
- Load/store access fault
- ECALL (U/S/M)
- Page faults (if MMU enabled)

## 15.3 Trap Entry Sequence
1. Save PC to mepc/sepc
2. Write mcause/scause
3. Write mtval/stval if required
4. Update privilege mode
5. Redirect PC to trap vector

---

# Chapter 16 — Interrupt Architecture

## 16.1 Supported Interrupt Sources
- Machine external interrupt (MEI)
- Machine timer interrupt (MTI)
- Machine software interrupt (MSI)
- Supervisor external interrupt (SEI)
- Supervisor timer interrupt (STI)
- Supervisor software interrupt (SSI)

Interrupt pending bits reflected in mip CSR.
Interrupt enable bits controlled by mie CSR.

## 16.2 Global Interrupt Enable
- mstatus.MIE controls global M-mode interrupts
- mstatus.SIE controls global S-mode interrupts

Interrupt is taken only if:
- Global enable bit set
- Corresponding enable bit in mie set
- Pending bit in mip set

## 16.3 Interrupt Priority
Machine-mode interrupts have higher priority than Supervisor interrupts.
Within a privilege level, priority order:
1. External
2. Timer
3. Software

## 16.4 Interrupt Entry
On interrupt:
- Save PC to mepc/sepc
- Write mcause/scause with interrupt bit set
- Update mstatus.MPP/SPP and MPIE/SPIE
- Redirect to mtvec/stvec

Interrupts are precise and taken between instructions.

---

# Chapter 17 — Atomic Unit

## 17.1 LR/SC Reservation Model
LR.W establishes reservation on a naturally aligned 32-bit word.
Reservation is cleared on:
- Any successful SC.W
- Any conflicting store (implementation-defined for single-core)
- Trap entry

SC.W writes only if reservation valid.
If successful: rd = 0
If failed: rd = 1

## 17.2 AMO Operations
AMO sequence:
1. Read memory
2. Compute ALU operation
3. Write result back
4. Return original value to rd

AMO must appear indivisible relative to other bus masters.

## 17.3 Atomicity Guarantee
PSD assumes single-core in v1.1.
Atomicity relative to external masters must be enforced at interconnect level.

---

# Chapter 18 — Memory Management Unit (MMU)

## 18.1 Address Translation Mode
When satp.MODE = 1, Sv32 translation enabled.
When MODE = 0, translation disabled.

## 18.2 Virtual Address Format
Virtual Address (32-bit):
- VPN[1] = VA[31:22]
- VPN[0] = VA[21:12]
- Offset = VA[11:0]

## 18.3 Physical Address Format
Physical address formed from PPN and page offset.

## 18.4 Permission Checks
PTE fields:
- V (valid)
- R (read)
- W (write)
- X (execute)
- U (user)

Access fault generated if permissions violated.

## 18.5 Fault Types
- Instruction page fault
- Load page fault
- Store page fault

---

# Chapter 19 — TLB Architecture

## 19.1 Structure
Separate ITLB and DTLB.
Initial implementation: fully associative.

## 19.2 Entry Fields
- VPN
- PPN
- Permission bits
- Valid bit

## 19.3 Lookup
Parallel compare of VPN against entries.
On hit:
- Provide PPN and permissions.
On miss:
- Stall pipeline
- Invoke page table walker

## 19.4 SFENCE.VMA
Invalidates matching or all TLB entries.
Executed in Supervisor or Machine mode.

---

# Chapter 20 — Page Table Walker

## 20.1 Two-Level Walk
Level 1 index: VPN[1]
Level 0 index: VPN[0]

## 20.2 Walk Procedure
1. Read level-1 PTE
2. Validate PTE
3. If leaf, compute physical address
4. Else read next-level PTE

## 20.3 Fault Handling
If PTE invalid or permission mismatch:
- Raise page fault
- Populate mtval/stval with faulting VA

## 20.4 Pipeline Interaction
During walk:
- Stall IF or MEM stage
- Resume on completion

---

# Chapter 21 — Linux Boot Flow

## 21.1 Reset to Machine Mode
Processor resets in M-mode at RESET_VECTOR.

## 21.2 SBI or Direct Boot
Option A: OpenSBI in M-mode initializes platform.
Option B: Direct jump to kernel entry in S-mode.

## 21.3 MMU Enable Sequence
1. Setup page tables
2. Write satp with MODE=1
3. Execute SFENCE.VMA
4. Continue execution with virtual addressing

## 21.4 Supervisor Entry
mstatus.MPP set to S
Execute MRET to enter S-mode.

## 21.5 BusyBox Userland
Requires functional:
- Timer interrupt
- Page faults
- Syscall handling (ECALL from U-mode)

---

# Chapter 22 — Memory System Interface

## 22.1 Bus Model
Blocking request/ready handshake.
Single outstanding transaction.

## 22.2 Instruction Port
Read-only.
32-bit aligned fetches.

## 22.3 Data Port
Supports byte-enable writes.
Read and write transactions serialized.

## 22.4 Future Cache Integration
Cache insertion point between core and external memory.
Must preserve precise exception semantics.

---

# Chapter 23 — Debug & Trace

## 23.1 Debug Halt
Optional external halt input.
Freezes pipeline at instruction boundary.

## 23.2 PC Trace
Optional export of committed PC values.
Useful for FPGA validation.

## 23.3 Future Debug Spec
Planned compliance with RISC-V Debug Specification.

---

# Chapter 24 — Verification Strategy

## 24.1 Unit Testing
- ALU directed tests
- CSR access tests
- TLB and MMU tests

## 24.2 Integration Testing
- Random instruction streams
- Exception stress tests
- Atomic stress tests

## 24.3 Linux Validation
Boot Linux kernel to shell.
Run BusyBox utilities.

## 24.4 Formal Properties
- x0 always zero
- No instruction commits after exception
- Correct privilege transitions

---

# Chapter 25 — Physical Implementation Notes

## 25.1 RTL Guidelines
- Fully synthesizable Verilog/SystemVerilog
- No latches
- Synchronous reset preferred

## 25.2 FPGA Target
Initial validation on mid-range FPGA.
Target frequency: 75–150 MHz.

## 25.3 ASIC Considerations
- Separate clock/reset trees
- Scan insertion compatibility
- Replace inferred memories with SRAM macros

## 25.4 Timing Closure Strategy
- Short combinational paths per stage
- Register-heavy control signals
- No combinational loops

---

# Appendix A — Complete CSR Bitfield Definitions

## A.1 mstatus (Machine Status Register)
Bits (RV32):
- [3] MIE — Machine Interrupt Enable
- [7] MPIE — Machine Previous Interrupt Enable
- [12:11] MPP — Machine Previous Privilege (00=U, 01=S, 11=M)
- [1] SIE — Supervisor Interrupt Enable
- [5] SPIE — Supervisor Previous Interrupt Enable
- [8] SPP — Supervisor Previous Privilege
- [18] SUM — Permit Supervisor User Memory access
- [19] MXR — Make Executable Readable

Reserved bits read as zero unless otherwise required by spec.

## A.2 mie/mip
Bit positions:
- [11] MEIE
- [7] MTIE
- [3] MSIE
- [9] SEIE
- [5] STIE
- [1] SSIE

## A.3 mtvec
- [31:2] BASE
- [1:0] MODE (0=Direct, 1=Vectored)

## A.4 mcause Encoding
MSB indicates interrupt (1=interrupt, 0=exception).
Lower bits encode cause per RISC-V Privileged Spec.

## A.5 satp (Sv32)
- [31:30] MODE (0=Bare, 1=Sv32)
- [29:22] ASID
- [21:0] PPN

---

# Appendix B — Trap Timing (Cycle-Level Contract)

Assuming 5-stage pipeline:

Cycle N:
- Fault detected in EX or MEM

Cycle N+1:
- Younger stages flushed
- mepc/sepc written
- mcause/scause written

Cycle N+2:
- PC redirected to trap vector

No instruction after the faulting instruction commits.

---

# Appendix C — Memory Ordering Model

PSD follows RVWMO baseline.

Rules:
- In-order issue and retirement.
- No store buffer in v1.1.
- FENCE instruction stalls pipeline until all prior memory ops complete.
- SC.W must guarantee forward progress if no conflicting store occurs.

---

# Appendix D — MMU Corner Cases

- If W=1 and R=0 in PTE: raise page fault.
- A/D bits assumed hardware-set in v1.1.
- SUM=0 prevents S-mode access to U pages.
- MXR=1 allows execute-only pages to be read.

---

# Appendix E — External SoC Interface Contract

## E.1 Reset
- Active-high synchronous reset.
- RESET_VECTOR externally parameterized.

## E.2 Clock
- Single clock domain in v1.1.

## E.3 Required Memory Map (Linux Minimal)
- RAM at 0x80000000
- CLINT-compatible timer region
- External interrupt controller line

---

# Appendix F — Microarchitectural State Inventory

State Elements:
- PC register
- 64 x 32 GPRs
- CSR register file
- IF/ID, ID/EX, EX/MEM, MEM/WB registers
- TLB arrays
- Reservation register (LR/SC)
- Multiplier/divider FSM state

---

# Appendix G — Formal Invariants

- x0 always reads as zero.
- Only one instruction may commit per cycle.
- No architectural state update when valid=0.
- Trap entry atomic with respect to architectural state.
- satp change requires SFENCE.VMA before use.

---

# Finalization Statement

This document constitutes the authoritative architectural specification for PoSeiDon Core (PSD) v1.1. All RTL implementations must conform strictly to the behavioral and timing guarantees described herein. Any deviation must result in version increment.

---

*End of Document — PSD v1.1 Finalized*

