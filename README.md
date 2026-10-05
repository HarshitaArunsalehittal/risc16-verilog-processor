# 16-bit RISC Processor — Verilog RTL Design

A single-cycle 16-bit RISC CPU, designed, simulated, and synthesized from scratch in Verilog HDL. The project covers the full flow from instruction set design through RTL coding, functional verification, synthesis, and FPGA-level timing closure.

---

## Overview

- **ISA width:** 16-bit instructions, 16-bit data
- **Registers:** 8 × 16-bit general-purpose registers (`r0`–`r7`), `r0` hardwired to 0
- **Memory:** 256-word instruction ROM, 256-word data RAM (Harvard architecture)
- **Pipeline:** Single-cycle (one instruction completes every clock)
- **Instructions:** 12 instructions — arithmetic, logic, memory, branch, jump, halt
- **Target device:** Xilinx 7-series (`xc7k70tfbv676-1`); constraints included for Basys3
- **Tool flow:** Xilinx Vivado 2025.2 — simulation, synthesis, implementation
- **Status:** Simulated and functionally verified. Synthesized. Timing closed at 100 MHz.

---

## Why a single-cycle RISC CPU?

This project is a from-the-ground-up exercise in computer architecture: instead of using a pre-built soft-core, every piece of the datapath — the ALU, the register file, the control logic, the memories, and the instruction fetch/decode/execute wiring — is designed, connected, and verified by hand. It demonstrates:

- How an instruction set architecture (ISA) is defined and encoded into bits
- How a datapath is built to execute that ISA, one instruction per clock cycle
- How RTL design, simulation, synthesis, and timing analysis fit together in a real FPGA tool flow

---

## Architecture

The datapath flows as follows on every clock cycle:

1. The **Program Counter (PC)** supplies an address to the **Instruction Memory**, which returns the 16-bit instruction to execute.
2. The **Control Unit** decodes the instruction's opcode (bits `[15:12]`) and generates every control signal used downstream — `reg_write`, `alu_src`, `mem_write`, `mem_to_reg`, `branch_eq`, `branch_ne`, `jump`, and `halt`.
3. The **Register File** is read using the source register fields from the instruction, supplying two operand values.
4. The **ALU** performs the required arithmetic/logic operation, or computes a comparison for branch instructions.
5. The **Data Memory** is read (for `LW`) or written (for `SW`), using the ALU result as the address.
6. The result — either the ALU output or data memory output — is written back into the **Register File** on the next clock edge.
7. The **PC** is updated: sequentially (`PC + 1`), to a branch target, or to a jump target, depending on the instruction just executed.

### Pipeline stages (all completed within one clock cycle)

**Fetch → Decode → Register Read → Execute → Memory Access → Write-Back → PC Update**

---

## Instruction Set Architecture (ISA)

### Instruction formats

| Format | Bit layout | Used by |
|---|---|---|
| R-type | `[15:12]` opcode, `[11:9]` rd, `[8:6]` rs1, `[5:3]` rs2, `[2:0]` unused | ADD, SUB, AND, OR, XOR, SLT |
| I-type | `[15:12]` opcode, `[11:9]` rd/rt, `[8:6]` rs1, `[5:0]` imm6 (sign-extended) | ADDI, LW, SW, BEQ, BNE |
| J-type | `[15:12]` opcode, `[11:0]` target address | JMP |

### Instruction table

| Opcode | Mnemonic | Format | Operation |
|---|---|---|---|
| 0000 | ADD  | R | rd = rs1 + rs2 |
| 0001 | SUB  | R | rd = rs1 − rs2 |
| 0010 | AND  | R | rd = rs1 & rs2 |
| 0011 | OR   | R | rd = rs1 \| rs2 |
| 0100 | XOR  | R | rd = rs1 ^ rs2 |
| 0101 | SLT  | R | rd = (rs1 < rs2) ? 1 : 0, signed |
| 0110 | ADDI | I | rd = rs1 + imm |
| 0111 | LW   | I | rd = mem[rs1 + imm] |
| 1000 | SW   | I | mem[rs1 + imm] = rt |
| 1001 | BEQ  | I | if (rt == rs1) PC = PC + 1 + imm |
| 1010 | BNE  | I | if (rt != rs1) PC = PC + 1 + imm |
| 1011 | JMP  | J | PC = target |
| 1111 | HALT | — | stop execution |

---

## Module breakdown

| File | Role |
|---|---|
| `alu.v` | Performs ADD, SUB, AND, OR, XOR, and signed less-than comparison; flags `zero` for branch decisions |
| `regfile.v` | 8-entry x 16-bit register file; dual read ports, single write port; `r0` always reads as 0 |
| `control.v` | Pure combinational decoder — maps the 4-bit opcode to every control signal in the datapath |
| `instr_mem.v` | 256-word instruction ROM, pre-loaded with the test program |
| `data_mem.v` | 256-word synchronous read/write data RAM |
| `risc16.v` | Top-level CPU — wires together the PC, instruction memory, control, register file, ALU, and data memory |
| `fpga_top.v` | Board-level wrapper — divides the 100 MHz board clock down and drives LEDs with the PC, for on-hardware visibility |
| `tb_risc16.v` | Self-checking testbench — drives the CPU, waits for HALT, and asserts the expected final register/memory state |
| `basys3.xdc` | Pin and clock constraints for the Digilent Basys3 (Artix-7) board |

---

## Functional verification

The CPU was verified in Vivado's behavioral simulator against a hand-written test program that computes **5 + 4 + 3 + 2 + 1** using a decrementing loop, stores the result to memory, reads it back, and halts:

```
ADDI r1, r0, 5      ; r1 = 5          (loop counter)
ADDI r2, r0, 0      ; r2 = 0          (accumulator)
loop:
ADD  r2, r2, r1     ; r2 += r1
ADDI r1, r1, -1     ; r1 -= 1
BNE  r1, r0, loop   ; loop while r1 != 0
SW   r2, 0(r0)      ; mem[0] = r2
LW   r3, 0(r0)      ; r3 = mem[0]
HALT
```

**Testbench result:**

```
r1=0 r2=15 r3=15 mem[0]=15
TEST PASSED
$finish called at time: 225 ns
```

This confirms the ALU, register file, branching logic, memory read/write, and the PC's sequential/branch update logic are all functioning correctly together.

*(Screenshot: `docs/test_passed.png`)*
*(Screenshot: `docs/waveform.png`)*

---

## Synthesis results

Synthesized for a Xilinx 7-series part (`xc7k70tfbv676-1`) targeting the CPU core (`risc16`):

| Resource | Used | Available | Utilization |
|---|---|---|---|
| Slice LUTs | 234 | 41,000 | 0.57% |
| Slice Registers | 16 | 82,000 | 0.02% |
| F7 Muxes | 32 | 20,500 | 0.16% |
| F8 Muxes | 16 | 10,250 | 0.16% |
| Bonded IOB | 19 | 300 | 6.33% |
| BUFGCTRL | 1 | 32 | 3.13% |

Per-module breakdown: ALU — 79 LUTs. Data Memory — 66 LUTs, 32 registers. Register File — 87 LUTs.

The design is extremely lightweight, as expected for an 8-register, single-cycle, 16-bit CPU with no pipelining or caching.

*(Screenshot: `docs/utilization.png`)*

---

## Timing closure

Timing constraint: **100 MHz** (10 ns clock period), defined in `basys3.xdc`.

| Metric | Result |
|---|---|
| Worst Negative Slack (WNS) | +3.149 ns |
| Worst Hold Slack (WHS) | +0.184 ns |
| Worst Pulse Width Slack (WPWS) | +4.090 ns |
| Failing endpoints | 0 / 848 |

All user-specified timing constraints are met. With 3.149 ns of slack at a 10 ns period, the critical path is approximately 6.85 ns, implying a theoretical maximum frequency of roughly 145 MHz for this design on this part.

*(Screenshot: `docs/timing_summary.png`)*

---

## How to run this project

### Prerequisites
- Xilinx Vivado 2025.2 (or compatible version) — Vivado ML Edition, not Vitis Unified IDE
- (Optional) A Digilent Basys3 board if you want to program real hardware

### Simulation (no hardware needed)
1. Clone this repo and open `risc16_processor.xpr` in Vivado, or create a new RTL project and add every file under `risc16_processor.srcs/sources_1/new/` as a design source, and `tb_risc16.v` as a simulation source.
2. In the Sources panel, right-click `risc16.v` and select Set as Top (design top), and `tb_risc16.v` and select Set as Top (simulation top).
3. Flow Navigator → SIMULATION → Run Simulation → Run Behavioral Simulation.
4. In the Tcl Console, run `run -all` if it doesn't auto-complete.
5. Confirm `TEST PASSED` in the Tcl Console.

### Synthesis and implementation (for utilization and timing numbers)
1. Flow Navigator → SYNTHESIS → Run Synthesis.
2. Once complete: Reports → Report Utilization, and Reports → Report Timing Summary.

### Programming real hardware (optional)
1. Set `fpga_top.v` as the top module (instead of `risc16.v`) and ensure `basys3.xdc` is added under Constraints.
2. Run Synthesis → Run Implementation → Generate Bitstream.
3. Open Hardware Manager, connect the board, and program the device. The 16 LEDs will display the live program counter (PC) as the CPU executes.

---

## Future improvements

- Extend the ISA with shift instructions (SLL, SRL), JAL/JR for subroutine calls, and additional ALU operations.
- Convert to a classic 5-stage pipeline (IF / ID / EX / MEM / WB) with hazard detection and forwarding.
- Add a UART or simple memory-mapped I/O peripheral for interactive hardware demos.
- Expand the testbench into a suite covering every instruction and edge cases (overflow, zero-register writes, back-to-back branches).

---

## Tools and concepts used

Verilog HDL, Xilinx Vivado, RTL Design, Behavioral Simulation, Synthesis, Static Timing Analysis, FPGA Implementation, Computer Architecture, Instruction Set Design, Digital Logic Design.

---

## Author

**Harshita**
2026 ECE Graduate, VTU — interested in VLSI (Functional Verification, Physical Design) and embedded/software roles.
