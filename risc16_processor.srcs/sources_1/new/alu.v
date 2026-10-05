module alu(
    input      [15:0] a, b,
    input      [2:0]  alu_ctrl,
    output reg [15:0] y,
    output            zero
);
    always @(*) begin
        case (alu_ctrl)
            3'd0: y = a + b;
            3'd1: y = a - b;
            3'd2: y = a & b;
            3'd3: y = a | b;
            3'd4: y = a ^ b;
            3'd5: y = ($signed(a) < $signed(b)) ? 16'd1 : 16'd0;
            default: y = 16'd0;
        endcase
    end
    assign zero = (y == 16'd0);
endmodule