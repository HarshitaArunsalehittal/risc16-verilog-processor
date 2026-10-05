module instr_mem(
    input  [7:0]  addr,
    output [15:0] instr
);
    reg [15:0] mem [0:255];
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) mem[i] = 16'h0000; // NOP
        // Program: sum = 5+4+3+2+1
        mem[0] = 16'h6205; // ADDI r1, r0, 5
        mem[1] = 16'h6400; // ADDI r2, r0, 0
        mem[2] = 16'h0488; // loop: ADD  r2, r2, r1
        mem[3] = 16'h627F; //       ADDI r1, r1, -1
        mem[4] = 16'hA23D; //       BNE  r1, r0, loop (-3)
        mem[5] = 16'h8400; // SW r2, 0(r0)
        mem[6] = 16'h7600; // LW r3, 0(r0)
        mem[7] = 16'hF000; // HALT
    end
    assign instr = mem[addr];
endmodule