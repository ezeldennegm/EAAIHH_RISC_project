module decode_stage (
    // ============================================================
    // Clock / Reset
    // ============================================================
    input         clk,
    input         reset,

    // ============================================================
    // IF/ID inputs
    // ============================================================
    input  [7:0]  instr_id,
    input  [7:0]  immediate,
    input  [7:0]  pc_id,
    input         branch_taken_ex,
    input         intr,

    // ============================================================
    // Forwarding inputs
    // ============================================================
    input  [7:0]  alu_out_ex,
    input  [7:0]  mem_out_mem,
    input  [7:0]  wb_out,
    input  [7:0]  input_port,

    // ============================================================
    // WB inputs
    // ============================================================
    input         wb_we,
    input  [1:0]  wb_addr,

    // ============================================================
    // Outputs to pipeline control
    // ============================================================
    output        stall_F,
    output        stall_D,
    output        flush_F,
    output        flush_D,
    output        flush_EX,
    output        flush_M,

    output        intr_ack,
    output        intr_active,
    output        intr_ret,

    // ============================================================
    // Outputs to EX stage
    // ============================================================
    output reg [7:0]  A,
    output reg [7:0]  B,

    // ============================================================
    // Control outputs (latched in ID/EX)
    // ============================================================
    output        reg_write,
    output [1:0]  mem_read,
    output        mem_write,
    output [3:0]  alu_op,
    output [1:0]  flag_change,
    output [1:0]  wb_sel,
    output        read_out,
    output [2:0]  jmp_chk,
    output        store_pc,
    output        return_flags
);

    // ============================================================
    // Internal wires
    // ============================================================
    wire [1:0] reg_1, reg_2;
    wire [1:0] alu_src_a, alu_src_b;
    wire [1:0] forward_src_a, forward_src_b;
    wire       sp_inc, sp_dec;

    wire [7:0] ra_data, rb_data;
    reg  [7:0] fwd_a, fwd_b;

    // ============================================================
    // Control Unit
    // ============================================================
    control_unit CU (
        .clk(clk),
        .reset(reset),
        .instr(instr_id),
        .branch_taken(branch_taken_ex),
        .intr(intr),

        .stall_F(stall_F),
        .stall_D(stall_D),
        .flush_D(flush_D),
        .flush_F(flush_F),
        .flush_EX(flush_EX),
        .flush_M(flush_M),
        .intr_ack(intr_ack),
        .intr_active(intr_active),
        .intr_ret(intr_ret),

        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .alu_op(alu_op),
        .flag_change(flag_change),
        .reg_1(reg_1),
        .reg_2(reg_2),
        .alu_src_a(alu_src_a),
        .alu_src_b(alu_src_b),
        .forward_src_a(forward_src_a),
        .forward_src_b(forward_src_b),
        .wb_sel(wb_sel),
        .sp_inc(sp_inc),
        .sp_dec(sp_dec),
        .read_out(read_out),
        .jmp_chk(jmp_chk),
        .store_pc(store_pc),
        .return_flags(return_flags)
    );

    // ============================================================
    // Register File
    // ============================================================
    reg_file RF (
        .clk(clk),
        .rst(reset),
        .we(wb_we),
        .ra_addr(reg_1),
        .rb_addr(reg_2),
        .wr_addr(wb_addr),
        .wr_data(wb_out),
        .sp_inc(sp_inc),
        .sp_dec(sp_dec),
        .ra_data(ra_data),
        .rb_data(rb_data)
    );

    // ============================================================
    // Forwarding MUXes
    // ============================================================
    always @(*) begin
        case (forward_src_a)
            2'd0: fwd_a = alu_out_ex;
            2'd1: fwd_a = mem_out_mem;
            2'd2: fwd_a = wb_out;
            default: fwd_a = 8'b0;
        endcase

        case (forward_src_b)
            2'd0: fwd_b = alu_out_ex;
            2'd1: fwd_b = mem_out_mem;
            2'd2: fwd_b = wb_out;
            default: fwd_b = 8'b0;
        endcase
    end

    // ============================================================
    // Final Operand Selection
    // ============================================================
    always @(*) begin
        // ---------- A ----------
        case (alu_src_a)
            2'd0: A = ra_data;
            2'd1: A = immediate;
            2'd2: A = fwd_a;
            2'd3: A = input_port;
            default: A = 8'b0;
        endcase

        // ---------- B ----------
        case (alu_src_b)
            2'd0: B = rb_data;
            2'd1: B = pc_id;
            2'd2: B = fwd_b;
            2'd3: B = input_port;
            default: B = 8'b0;
        endcase
    end

endmodule