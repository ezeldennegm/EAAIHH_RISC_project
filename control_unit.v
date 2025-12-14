module control_unit (
    // ----------- Inputs -----------
    input clk,
    input reset,
    input [7:0] instr,         // from IF/ID pipeline register
    input branch_taken,        // EX stage branch resolution
    input intr,                // interrupt signal

    // ----------- Outputs to Pipeline Control -----------
    output reg stall_F,
    output reg stall_D,
    output reg flush_D,
    output reg flush_F,
    output reg flush_EX,
    output reg flush_M,
    output reg intr_ack,
    output reg intr_active,
    output reg intr_ret,

    // ----------- Outputs to Datapath (decoder signals) -----------
    output reg       reg_write,
    output reg [1:0] mem_read, // 0 -> Alu out, 1 -> mem out, 2 -> R[reg_1], 
    output reg       mem_write,
    output reg [3:0] alu_op,
    output reg [1:0] flag_change, // 0 -> no change, 1 -> change Z, N only, 2 -> change all,
    output reg [1:0] reg_1,
    output reg [1:0] reg_2,
    output reg [1:0] alu_src_a, // 0 -> Reg[reg_1], 1 -> immediate, 2 -> forward, 3 -> input port
    output reg [1:0] alu_src_b, // 0 -> Reg[reg_2], 1 -> PC       , 2 -> forward
    output reg [1:0] forward_src_a,
    output reg [1:0] forward_src_b,
    output reg [1:0] wb_sel,       // ALU/MEM/IMM/IN
    output reg       sp_inc,
    output reg       sp_dec,
    output reg       read_out,
    output reg [2:0] jmp_chk, // 0 -> nothing, 1 -> JZ, 2-> JN, 3 -> JC, 4 -> JV, 5 -> JMP, 6 -> RET or RTI, 7-> loop
    output reg       store_pc,
    output reg       return_flags
);

    wire [3:0] opcode = instr[7:4];
    wire [1:0] ra = instr[3:2];
    wire [1:0] rb = instr[1:0];

    reg reg_write_source; // 0 -> ALU out, 1 -> Mem out
    reg stall;

    // for hazard checking
    reg [3:0]   rt_ex, rt_mem, rt_wb; // Destination and whether it will write and source
    wire [3:0] rt_dc =  {reg_write_source, reg_write, wb_sel};
    always @(*) begin
        // defaults
        reg_write = 0;
        mem_read  = 0;
        mem_write = 0;
        alu_op    = 4'b0000;
        flag_change = 2'd0;
        reg_1     = 2'b00;
        reg_2     = 2'b00;
        alu_src_a = 2'b01;    // Immediate
        alu_src_b = 2'b01;    // Immediate
        wb_sel    = 2'b00;    // ALU
        sp_inc    = 0;
        sp_dec    = 0;
        read_out  = 0;
        jmp_chk   = 0;
        store_pc  = 0;
        return_flags = 0;
        store_flags = 0;

        reg_write_source = 0;
        if (intr_ack) begin
                alu_src_a = 2'b00;    // R[ra]
                alu_src_b = 2'b10;    // PC
                reg_1 = 3;
                sp_dec = 1;
                mem_write = 1;
        end else 
        case (opcode)
            4'd0: ; // NOP
            4'd1: begin // MOV
                alu_op = 4'd1; // OP_MOV_B
                alu_src_b = 2'b00;    // R[rb]
                reg_2 = rb;
                wb_sel = ra;
                reg_write = 1;
            end
            4'd2: begin // ADD
                alu_op = 4'd2; // OP_ADD
                alu_src_a = 2'b00;    // R[ra]
                alu_src_b = 2'b00;    // R[rb]
                reg_1 = ra;
                reg_2 = rb;
                wb_sel = ra;
                reg_write = 1;
                flag_change = 2'd2;
            end
            4'd3: begin // SUB
                alu_op = 4'd3; // OP_SUB
                alu_src_a = 2'b00;    // R[ra]
                alu_src_b = 2'b00;    // R[rb]
                reg_1 = ra;
                reg_2 = rb;
                wb_sel = ra;
                reg_write = 1;
                flag_change = 2'd2;
            end
            4'd4: begin // AND
                alu_op = 4'd4; // OP_AND
                alu_src_a = 2'b00;    // R[ra]
                alu_src_b = 2'b00;    // R[rb]
                reg_1 = ra;
                reg_2 = rb;
                wb_sel = ra;
                reg_write = 1;
                flag_change = 2'd1;
            end
            4'd5: begin // OR
                alu_op = 4'd5; // OP_OR
                alu_src_a = 2'b00;    // R[ra]
                alu_src_b = 2'b00;    // R[rb]
                reg_1 = ra;
                reg_2 = rb;
                wb_sel = ra;
                reg_write = 1;
                flag_change = 2'd1;
            end
            4'd6: begin // RLC, RRC CLRC SETC
                case (ra)
                    2'd0: begin // RLC
                        alu_op = 4'd10; // OP_RLC
                        alu_src_b = 2'b00;
                        reg_2 = rb;
                        wb_sel = rb;
                        reg_write = 1;
                    end
                    2'd1: begin // RRC
                        alu_op = 4'd11; // OP_RRC
                        alu_src_b = 2'b00;
                        reg_2 = rb;
                        wb_sel = rb;
                        reg_write = 1;
                    end
                    2'd2: begin //SETC
                        alu_op = 4'd12; // OP_SETC
                    end
                    2'd3: begin //CLRC
                        alu_op = 4'd13; // OP_CLRC
                    end
                endcase
            end
            4'd7: begin // PUSH, POP, OUT, IN    
                case (ra)
                    2'd0: begin // PUSH
                        alu_op = 4'd0; // not important
                        alu_src_a = 2'b00;    // R[ra]
                        alu_src_b = 2'b00;    // R[rb]
                        reg_1 = 3;
                        reg_2 = rb;
                        mem_write = 1;
                        sp_dec = 1;
                    end
                    2'd1: begin // POP
                        alu_op = 4'd0; // not important
                        alu_src_a = 2'b00;    // R[ra]
                        reg_1 = 3; // important
                        wb_sel = rb;
                        mem_read = 1; // read mem_out
                        reg_write = 1;
                        sp_inc = 1;

                        reg_write_source = 1;
                    end
                    2'd2: begin // OUT
                        alu_op = 4'd1; // OP_MOV_B
                        alu_src_b = 2'b00;    // R[rb]
                        reg_2 = rb;
                        read_out = 1;
                    end
                    2'd3: begin // IN
                        alu_op = 4'd0; // OP_MOV_A
                        alu_src_a = 2'd3; // Input
                        wb_sel = rb;
                        reg_write = 1;
                    end
                endcase
            end
            4'd8: begin // NOT, NEG, INC, DEC
                case (ra)
                    2'd0: begin // NOT
                        alu_op = 4'd9; // OP_NOT
                        alu_src_b = 2'b00;    // R[rb]
                        reg_2 = rb;
                        wb_sel = rb;
                        reg_write = 1;
                        flag_change = 2'd1;
                    end
                    2'd1: begin // NEG
                        alu_op = 4'd8; // OP_NEG
                        alu_src_b = 2'b00;    // R[rb]
                        reg_2 = rb;
                        wb_sel = rb;
                        reg_write = 1;
                        flag_change = 2'd1;
                    end
                    2'd2: begin // INC
                        alu_op = 4'd7; // OP_INC
                        alu_src_b = 2'b00;    // R[rb]
                        reg_2 = rb;
                        wb_sel = rb;
                        reg_write = 1;
                        flag_change = 2'd2;
                    end
                    2'd3: begin // DEC
                        alu_op = 4'd6; // OP_DEC
                        alu_src_b = 2'b00;    // R[rb]
                        reg_2 = rb;
                        wb_sel = rb;
                        reg_write = 1;
                        flag_change = 2'd2;
                    end
                endcase
            end
            // B - Format
            4'd9: begin // COND-JUMB
                case (ra)
                    2'd0: begin // JZ
                        jmp_chk = 1;
                        alu_src_b = 2'b00;    // R[rb]
                        reg_2 = rb;
                    end
                    2'd1: begin // JN
                        jmp_chk = 2;
                        alu_src_b = 2'b00;    // R[rb]
                        reg_2 = rb;
                    end
                    2'd2: begin // JC
                        jmp_chk = 3;
                        alu_src_b = 2'b00;    // R[rb]
                        reg_2 = rb;
                    end 
                    2'd3: begin // JV
                        jmp_chk = 4;
                        alu_src_b = 2'b00;    // R[rb]
                        reg_2 = rb;
                    end
                endcase
            end
            4'd10: begin // LOOP
                alu_op = 4'd14; // OP_DEC_A
                alu_src_a = 2'b00;    // R[ra]
                alu_src_b = 2'b00;    // R[rb]
                reg_1 = ra;
                reg_2 = rb;
                jmp_chk = 7;
                wb_sel = ra;
                reg_write = 1;
            end
            4'd11: begin // JMP, CALL, RET, RTI
                case (ra)
                    2'd0: begin // JMP
                        jmp_chk = 5;
                        alu_src_b = 2'b00;    // R[rb]
                        reg_2 = rb;
                    end
                    2'd1: begin // CALL
                        jmp_chk = 5;
                        alu_src_a = 2'b00;    // R[ra]
                        alu_src_b = 2'b00;    // R[rb]
                        reg_1 = 3;
                        reg_2 = rb;
                        sp_dec = 1;
                        mem_write = 1;
                        store_pc = 1; // needs modification
                    end
                    2'd2: begin // RET
                        jmp_chk = 6;
                        alu_src_a = 2'b00;    // R[ra]
                        reg_1 = 3;
                        sp_inc = 1;
                    end 
                    2'd3: begin // RTI
                        jmp_chk = 6;
                        alu_src_a = 2'b00;    // R[ra]
                        reg_1 = 3;
                        sp_inc = 1;
                        return_flags = 1;
                    end
                endcase
            end
            // L - Format
            4'd12: begin // 2 byte INSTRUCTIONS
                case (ra)
                    2'd0: begin
                        alu_src_a = 1;
                        wb_sel = rb;
                        reg_write = 1;
                    end
                    2'd1: begin
                        mem_read = 1;
                        alu_src_a = 1;
                        wb_sel = rb;
                        reg_write = 1;

                        reg_write_source = 1;
                    end
                    2'd2: begin
                        mem_write = 1;
                        alu_src_a = 1;
                        reg_2 = rb;
                    end
                endcase
            end
            4'd13: begin
                mem_read = 1;
                reg_write = 1;
                wb_sel = rb;
                reg_1 = ra;

                reg_write_source = 1;
            end
            4'd14: begin
                mem_write = 1;
                reg_1 = ra;
                reg_2 = rb;
            end
        endcase
        // Forwarding Decoding
        begin
            if (alu_src_a == 0 /* Source is chosen reg from register file*/) begin
                case ({1'b1,reg_1})
                    rt_ex: begin
                        if (rt_ex[3] == 1) begin // Source is memory
                            stall = 1;
                        end else begin
                            forward_src_a = 2'b00; // Source is ALU OUT
                        end
                    end
                    rt_mem: begin
                        forward_src_a = 2'b01; // Source is mem OUT
                    end
                    rt_wb: begin
                        forward_src_a = 2'b10; // Source is wb OUT
                    end
                endcase
            end
        end
        begin
            if (alu_src_b == 0 /* Source is chosen reg from register file*/) begin
                case ({1'b1,reg_2})
                    rt_ex: begin
                        if (rt_ex[3] == 1) begin // Source is memory
                            stall = 1;
                        end else begin
                            forward_src_a = 2'b00; // Source is ALU OUT
                        end
                    end
                    rt_mem: begin
                        forward_src_a = 2'b01; // Source is mem OUT
                    end
                    rt_wb: begin
                        forward_src_a = 2'b10; // Source is wb OUT
                    end
                endcase
            end
        end
    end

    // ============================================================
    //                   Hazard Checking
    // ============================================================


    always @(posedge clk) begin
        if (reset) begin
            rt_ex   <=0;
            rt_mem  <=0;
            rt_wb   <=0;
        end else begin
            rt_ex   <= (stall_D) ? 0:rt_dc;
            rt_mem  <= rt_ex;
            rt_wb   <= rt_mem;
        end
    end
    // ============================================================
    //                   Stall (only one type of stall happens)
    // ============================================================
    always @(*) begin
        stall_D = stall;
        stall_F = stall;
    end
    
    // ============================================================
    //                   FSM INT
    // ============================================================

    // State encoding For Interrupts
    parameter I_NORMAL = 2'd0;
    parameter I_RISE   = 2'd1;
    parameter I_ACTIVE = 2'd2;
    parameter I_FALL   = 2'd3;

    reg [1:0] i_state, i_next_state;


    always @(*) begin
        i_next_state = i_state;

        case (i_state)

            I_NORMAL: begin
                if (intr)
                    i_next_state = I_RISE;
            end

            I_RISE: begin
                i_next_state = I_ACTIVE; // after rising edge detected, go to active
            end

            I_ACTIVE: begin
                if (~intr)
                    i_next_state = I_FALL;
            end

            I_FALL: begin
                i_next_state = I_NORMAL; // back to normal after falling edge
            end

            default: i_next_state = I_NORMAL;
        endcase
    end

    always @(*) begin
        intr_ack = 0; // default
        intr_active = 0;
        intr_ret = 0;

        case (i_state)
            I_RISE: intr_ack = 1; // single-cycle ack on rising edge
            I_ACTIVE: intr_active = 1; // interrupt still active, do nothing
            I_FALL: intr_ret = 1; // tell fetch to output rti
            default: ;
        endcase
    end

    // ============================================================
    //                   FSM Flush
    // ============================================================

    parameter J_NORMAL  = 3'b000;
    parameter J_UNCOND  = 3'b001; // unconditional, undelayed
    parameter J_DELAY1  = 3'b010; // delayed jump: wait cycle
    parameter J_DELAY2  = 3'b011; // delayed jump: execute
    parameter J_COND    = 3'b100; // conditional jump

    reg [2:0] j_state, j_next_state;


    always @(posedge clk or posedge reset) begin
        if (reset)
            j_state <= J_NORMAL;
        else
            j_state <= j_next_state;
    end


    wire is_cond =
        (jmp_chk == 3'd1 || jmp_chk == 3'd2 || jmp_chk == 3'd3 ||
        jmp_chk == 3'd4 || jmp_chk == 3'd7);

    wire is_uncond  = (jmp_chk == 3'd5);
    wire is_delayed = (jmp_chk == 3'd6);


    always @(*) begin
        j_next_state = j_state;

        case (j_state)

            // --------------------------------------------------
            // NORMAL
            // --------------------------------------------------
            J_NORMAL: begin
                if (is_delayed)
                    j_next_state = J_DELAY1;
                else if (is_uncond)
                    j_next_state = J_UNCOND;
                else if (is_cond)
                    j_next_state = J_COND;
            end

            // --------------------------------------------------
            // UNCONDITIONAL, NO DELAY
            // --------------------------------------------------
            J_UNCOND: begin
                j_next_state = J_NORMAL; // executes immediately
            end

            // --------------------------------------------------
            // DELAYED JUMP – WAIT CYCLE
            // --------------------------------------------------
            J_DELAY1: begin
                j_next_state = J_DELAY2;
            end

            // --------------------------------------------------
            // DELAYED JUMP – EXECUTION CYCLE
            // --------------------------------------------------
            J_DELAY2: begin
                j_next_state = J_NORMAL;
            end

            // --------------------------------------------------
            // CONDITIONAL JUMP
            // --------------------------------------------------
            J_COND: begin
                if (branch_taken)
                    j_next_state = J_NORMAL; // jump taken
                else
                    j_next_state = J_NORMAL; // jump not taken
            end

            default: begin
                j_next_state = J_NORMAL;
            end

        endcase
    end

    always @(*) begin
        flush_F = 0;
        flush_D = 0;
        flush_EX = 0;

        case (j_state)

            // Immediate unconditional jump
            J_UNCOND: begin
                flush_F = 1;
                flush_D = 1;
            end

            // Delayed jump executes HERE (second delayed state)
            J_DELAY2: begin
                flush_F = 1;
                flush_D = 1;
                flush_EX = 1;
            end

            // Conditional jump (only if condition true)
            J_COND: begin
                if (branch_taken) begin
                    flush_F = 1;
                    flush_D = 1;
                end
            end

        endcase
    end
endmodule