module risc16(
    input         clk, rst,
    output [15:0] pc_out,
    output        halted
);
    reg  [15:0] pc;
    wire [15:0] instr, rd1, rd2, alu_b, alu_y, dmem_rd, wb_data, imm, pc_plus1, pc_next;
    wire        reg_write, alu_src, mem_write, mem_to_reg, rt_sel;
    wire        branch_eq, branch_ne, jump, halt, zero, take_branch;
    wire [2:0]  alu_ctrl;

    instr_mem im (.addr(pc[7:0]), .instr(instr));

    control ctrl (
        .opcode(instr[15:12]),
        .reg_write(reg_write), .alu_src(alu_src), .mem_write(mem_write),
        .mem_to_reg(mem_to_reg), .rt_sel(rt_sel), .branch_eq(branch_eq),
        .branch_ne(branch_ne), .jump(jump), .halt(halt), .alu_ctrl(alu_ctrl)
    );

    regfile rf (
        .clk(clk), .we(reg_write),
        .ra1(instr[8:6]),
        .ra2(rt_sel ? instr[11:9] : instr[5:3]),
        .wa(instr[11:9]), .wd(wb_data),
        .rd1(rd1), .rd2(rd2)
    );

    assign imm   = {{10{instr[5]}}, instr[5:0]};
    assign alu_b = alu_src ? imm : rd2;

    alu alu0 (.a(rd1), .b(alu_b), .alu_ctrl(alu_ctrl), .y(alu_y), .zero(zero));

    data_mem dm (.clk(clk), .we(mem_write), .addr(alu_y[7:0]), .wd(rd2), .rd(dmem_rd));

    assign wb_data = mem_to_reg ? dmem_rd : alu_y;

    assign pc_plus1    = pc + 16'd1;
    assign take_branch = (branch_eq & zero) | (branch_ne & ~zero);
    assign pc_next     = halt        ? pc :
                         jump        ? {4'b0000, instr[11:0]} :
                         take_branch ? pc_plus1 + imm :
                                       pc_plus1;

    always @(posedge clk)
        if (rst) pc <= 16'd0;
        else     pc <= pc_next;

    assign pc_out = pc;
    assign halted = halt;
endmodule