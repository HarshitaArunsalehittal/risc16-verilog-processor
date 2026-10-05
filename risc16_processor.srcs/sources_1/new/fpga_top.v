module fpga_top(
    input         clk,      // 100 MHz
    input         btnC,     // reset
    output [15:0] led
);
    reg [25:0] cnt = 0;
    always @(posedge clk) cnt <= cnt + 1;
    wire slow_clk = cnt[25];

    wire [15:0] pc;
    wire halted;
    risc16 cpu (.clk(slow_clk), .rst(btnC), .pc_out(pc), .halted(halted));

    assign led = pc;   // watch the PC step through the program
endmodule