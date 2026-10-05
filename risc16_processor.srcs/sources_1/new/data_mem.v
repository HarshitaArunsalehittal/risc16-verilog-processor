module data_mem(
    input         clk, we,
    input  [7:0]  addr,
    input  [15:0] wd,
    output [15:0] rd
);
    reg [15:0] mem [0:255];
    integer i;
    initial for (i = 0; i < 256; i = i + 1) mem[i] = 16'd0;
    assign rd = mem[addr];
    always @(posedge clk) if (we) mem[addr] <= wd;
endmodule