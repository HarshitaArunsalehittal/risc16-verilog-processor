module control(
    input      [3:0] opcode,
    output reg       reg_write, alu_src, mem_write, mem_to_reg,
    output reg       rt_sel, branch_eq, branch_ne, jump, halt,
    output reg [2:0] alu_ctrl
);
    always @(*) begin
        reg_write = 0; alu_src = 0; mem_write = 0; mem_to_reg = 0;
        rt_sel = 0; branch_eq = 0; branch_ne = 0; jump = 0; halt = 0;
        alu_ctrl = 3'd0;
        case (opcode)
            4'b0000: begin reg_write = 1; alu_ctrl = 3'd0; end // ADD
            4'b0001: begin reg_write = 1; alu_ctrl = 3'd1; end // SUB
            4'b0010: begin reg_write = 1; alu_ctrl = 3'd2; end // AND
            4'b0011: begin reg_write = 1; alu_ctrl = 3'd3; end // OR
            4'b0100: begin reg_write = 1; alu_ctrl = 3'd4; end // XOR
            4'b0101: begin reg_write = 1; alu_ctrl = 3'd5; end // SLT
            4'b0110: begin reg_write = 1; alu_src = 1; end     // ADDI
            4'b0111: begin reg_write = 1; alu_src = 1; mem_to_reg = 1; end // LW
            4'b1000: begin alu_src = 1; mem_write = 1; rt_sel = 1; end     // SW
            4'b1001: begin rt_sel = 1; branch_eq = 1; alu_ctrl = 3'd1; end // BEQ
            4'b1010: begin rt_sel = 1; branch_ne = 1; alu_ctrl = 3'd1; end // BNE
            4'b1011: jump = 1;                                              // JMP
            4'b1111: halt = 1;                                              // HALT
            default: ;
        endcase
    end
endmodule