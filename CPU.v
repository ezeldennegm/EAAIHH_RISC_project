module CPU (
    input  wire       clk,
    input  wire       reset,
    input  wire       interrupt,
    input  wire [7:0] input_port,
    output wire [7:0] OUT
);

    // ===============================
    // FETCH STAGE WIRES
    // ===============================
    wire [7:0] pc_F;
    wire [7:0] instr_F;
    wire [7:0] immediate_F;
    wire       immediate_en_F;
    wire stall_F, stall_D;
    wire flush_F, flush_D, flush_EX;
    wire intr_ack, intr_active, intr_ret;
    wire branch_taken_EX;
    wire [7:0] branch_target_EX;

    Fetch_stage IF (
        .clk(clk),
        .reset(reset),
        .f_stall(stall_F),
        .intr_ack(intr_ack),
        .intr_active(intr_active),
        .instruction(instr_F),
        .immediate(immediate_F),
        .immediate_enabled(immediate_en_F),
        .branch_taken(branch_taken_EX),
        .branch_target(branch_target_EX),
        .pc(pc_F)
    );

    // ===============================
    // IF/ID PIPELINE REGISTER
    // ===============================
    reg [7:0] instr_D, immediate_D, pc_D;
    reg       immediate_en_D;

    always @(posedge clk) begin
        if (reset || flush_D) begin
            instr_D        <= 0;
            immediate_D    <= 0;
            immediate_en_D <= 0;
            pc_D           <= pc_F;
        end else if (!stall_D) begin
            instr_D        <= instr_F;
            immediate_D    <= immediate_F;
            immediate_en_D <= immediate_en_F;
            pc_D           <= pc_F;
        end
    end

    // ===============================
    // DECODE STAGE WIRES
    // ===============================
    wire [7:0] A_D, B_D;
    wire       reg_write_D;
    wire [1:0] mem_read_D, wb_sel_D;
    wire       mem_write_D, read_out_D, store_pc_D, return_flags_D;
    wire [3:0] alu_op_D;
    wire [1:0] flag_change_D;
    wire [2:0] jmp_chk_D;
    // for forwarding
    wire [7:0] alu_out_E;
    
    wire [7:0] wb_data_pre;   // value to write back

    // for write back
    reg       reg_write_W;
    reg  [1:0] wb_sel_W;
    wire [7:0] wb_data;

    decode_stage ID (
        .clk(clk),
        .reset(reset),
        .instr_id(instr_D),
        .immediate(immediate_D),
        .pc_id(pc_D),
        .branch_taken_ex(branch_taken_EX),
        .intr(interrupt),
        .alu_out_ex(alu_out_E),
        .mem_out_mem(wb_data_pre),
        .wb_out(wb_data),
        .input_port(input_port),
        .wb_we(reg_write_W),
        .wb_addr(wb_sel_W),
        .stall_F(stall_F),
        .stall_D(stall_D),
        .flush_F(flush_F),
        .flush_D(flush_D),
        .flush_M(flush_M),
        .flush_EX(flush_EX),
        .intr_ack(intr_ack),
        .intr_active(intr_active),
        .intr_ret(intr_ret),
        .A(A_D),
        .B(B_D),
        .reg_write(reg_write_D),
        .mem_read(mem_read_D),
        .mem_write(mem_write_D),
        .alu_op(alu_op_D),
        .flag_change(flag_change_D),
        .wb_sel(wb_sel_D),
        .read_out(read_out_D),
        .jmp_chk(jmp_chk_D),
        .store_pc(store_pc_D),
        .return_flags(return_flags_D)
    );

    // ===============================
    // ID/EX PIPELINE REGISTER
    // ===============================
    reg [7:0] A_E, B_E, pc_E;
    reg       reg_write_E;
    reg  [1:0] mem_read_E, wb_sel_E;
    reg       mem_write_E, store_pc_E, return_flags_E;
    reg  [3:0] alu_op_E;
    reg  [1:0] flag_change_E;
    reg  [2:0] jmp_chk_E;

    always @(posedge clk) begin
        if (reset || flush_EX) begin
            A_E <= 0; B_E <= 0; pc_E <= pc_D;
            reg_write_E <= 0; mem_read_E <= 0; mem_write_E <= 0;
            alu_op_E <= 0; flag_change_E <= 0; wb_sel_E <= 0;
            jmp_chk_E <= 0; store_pc_E <= 0; return_flags_E <= 0;
        end else begin
            A_E <= A_D;
            B_E <= B_D;
            pc_E <= pc_D;
            reg_write_E <= reg_write_D;
            mem_read_E <= mem_read_D;
            mem_write_E <= mem_write_D;
            alu_op_E <= alu_op_D;
            flag_change_E <= flag_change_D;
            wb_sel_E <= wb_sel_D;
            jmp_chk_E <= jmp_chk_D;
            store_pc_E <= store_pc_D;
            return_flags_E <= return_flags_D;
        end
    end

    // ===============================
    // EXECUTE STAGE WIRES
    // ===============================
    
    wire       branch_taken_E;
    wire [7:0] branch_target_E;
    wire [3:0] flags_out_E;
    wire [3:0] preserved_flags_E;

    EX_stage EX (
        .clk(clk),
        .reset(reset),
        .A(A_E),
        .B(B_E),
        .alu_op(alu_op_E),
        .jump_type(jmp_chk_E),
        .intr_ack(intr_ack),
        .restore_flags(return_flags_E),
        .mem_out(wb_data_pre),
        .alu_out(alu_out_E),
        .branch_taken(branch_taken_E),
        .branch_target(branch_target_E),
        .flags_out(flags_out_E),
        .preserved_flags(preserved_flags_E)
    );

    assign branch_taken_EX = branch_taken_E;
    assign branch_target_EX = branch_target_E;

    // ===============================
    // EX/MEM PIPELINE REGISTER
    // ===============================
    reg [7:0] A_M, B_M, alu_out_M;
    reg       mem_write_M, reg_write_M;
    reg  [1:0] mem_read_M, wb_sel_M;

    always @(posedge clk) begin
        if (reset) begin
            // Datapath (optional but allowed)
            A_M       <= 8'b0;
            B_M       <= 8'b0;
            alu_out_M <= 8'b0;

            // Control (mandatory)
            mem_write_M <= 1'b0;
            mem_read_M  <= 1'b0;
            wb_sel_M    <= 2'b00;
            reg_write_M <= 1'b0;

        end else if (flush_M) begin
            // Bubble injection: kill side effects
            mem_write_M <= 1'b0;
            mem_read_M  <= 1'b0;
            wb_sel_M    <= 2'b00;

            // Datapath can be don't-care; zeroing is fine
            A_M       <= 8'b0;
            B_M       <= 8'b0;
            alu_out_M <= 8'b0;
            reg_write_M <= 1'b0;

        end else begin
            A_M         <= A_E;
            B_M         <= (store_pc_E) ? pc_E:B_E;
            alu_out_M   <= alu_out_E;
            mem_write_M <= (store_pc_E) ? 1:  mem_write_E;
            mem_read_M  <= mem_read_E;
            wb_sel_M    <= wb_sel_E;
            reg_write_M <= reg_write_E;
        end
    end

    // ===============================
    // MEMORY STAGE
    // ===============================
    wire [7:0] mem_data_out;

    Memory MEM_UNIT (
        .clk(clk),
        .rst(reset),
        .we(mem_write_M),
        .intr_ack(intr_ack),
        .data_in(B_M),
        .addr_in(A_M),
        .addr_instr(pc_F),
        .addr_data(A_M),
        .data_out(mem_data_out),
        .instr_out(instr_F),
        .immediate(immediate_F),
        .immediate_enabled(immediate_en_F)
    );

    // ===============================
    // MEM/WB PIPELINE REGISTER
    // ===============================
    // ===============================
    // WB DATA
    // ===============================
    assign wb_data_pre = (mem_read_M) ? mem_data_out : alu_out_M;

    // MEM/WB pipeline register
    reg [7:0] wb_data_reg;

    always @(posedge clk) begin
        if (reset) begin
            wb_data_reg <= 8'b0;
            reg_write_W <= 1'b0;
            wb_sel_W    <= 2'b00;
        end else begin
            wb_data_reg <= wb_data_pre;
            reg_write_W <= reg_write_M;
            wb_sel_W    <= wb_sel_M;
        end
    end


    assign wb_data = wb_data_reg;


endmodule