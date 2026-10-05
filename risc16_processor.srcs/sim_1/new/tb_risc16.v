
module tb_risc16;
    reg clk = 0, rst = 1;
    wire [15:0] pc_out;
    wire halted;

    risc16 dut (.clk(clk), .rst(rst), .pc_out(pc_out), .halted(halted));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("risc16.vcd");
        $dumpvars(0, tb_risc16);
        #22 rst = 0;
        wait (halted);
        #20;
        $display("r1=%0d r2=%0d r3=%0d mem[0]=%0d",
                 dut.rf.regs[1], dut.rf.regs[2], dut.rf.regs[3], dut.dm.mem[0]);
        if (dut.rf.regs[2] == 16'd15 && dut.rf.regs[3] == 16'd15)
            $display("TEST PASSED");
        else
            $display("TEST FAILED");
        $finish;
    end

    initial begin #5000; $display("TIMEOUT"); $finish; end
endmodule