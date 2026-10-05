module regfile(
    input         clk, we,
    input  [2:0]  ra1, ra2, wa,
    input  [15:0] wd,
    output [15:0] rd1, rd2
);
    reg [15:0] regs [0:7];
    integer i;
    initial for (i = 0; i < 8; i = i + 1) regs[i] = 16'd0;

    assign rd1 = (ra1 == 3'd0) ? 16'd0 : regs[ra1];
    assign rd2 = (ra2 == 3'd0) ? 16'd0 : regs[ra2];

    always @(posedge clk)
        if (we && wa != 3'd0) regs[wa] <= wd;
endmodule