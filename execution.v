module EX_stage (
    input  clk,
    input  reset,

    // ----------- Operands -----------
    input  [7:0] A,
    input  [7:0] B,

    // ----------- Control -----------
    input  [3:0] alu_op,
    input  [2:0] jump_type,

    // ----------- Interrupt Control -----------
    input        intr_ack,
    input        restore_flags,

    // ----------- MEM input (RET / RTI target) -----------
    input  [7:0] mem_out,

    // ----------- Outputs -----------
    output [7:0] alu_out,
    output       branch_taken,
    output [7:0] branch_target,
    output [3:0] flags_out,
    output [3:0] preserved_flags
);

    // ==================================================
    //                    FLAGS
    // ==================================================
    reg C, V, N, Z;
    reg pC, pV, pN, pZ;
    wire aluC, aluV, aluN, aluZ;

    // ==================================================
    //                    ALU
    // ==================================================
    ALU alu (
        .A(A),
        .B(B),
        .opcode(alu_op),
        .oldC(C),
        .oldV(V),
        .oldN(N),
        .oldZ(Z),
        .out(alu_out),
        .C(aluC),
        .V(aluV),
        .N(aluN),
        .Z(aluZ)
    );

    // ==================================================
    //           FLAG WRITE ENABLE (PER OPCODE)
    // ==================================================
    reg we_C, we_V, we_N, we_Z;

    always @(*) begin
        we_C = 0; we_V = 0; we_N = 0; we_Z = 0;

        case (alu_op)
            4'd2,  // ADD
            4'd3,  // SUB
            4'd6,  // DEC
            4'd7:  // INC
                begin we_C = 1; we_V = 1; we_N = 1; we_Z = 1; end

            4'd4,  // AND
            4'd5,  // OR
            4'd8,  // NEG
            4'd9:  // NOT
                begin we_N = 1; we_Z = 1; end

            4'd10, // RLC
            4'd11, // RRC
            4'd12, // SETC
            4'd13: // CLRC
                begin we_C = 1; end

            default: ; // MOV, DEC_A → no flags
        endcase
    end

    // ==================================================
    //                FLAGS REGISTER
    // ==================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            C <= 0; V <= 0; N <= 0; Z <= 0;
            pC <= 0; pV <= 0; pN <= 0; pZ <= 0;
        end else begin
            // Interrupt acknowledge → save flags
            if (intr_ack) begin
                pC <= C;
                pV <= V;
                pN <= N;
                pZ <= Z;
            end

            // Restore flags (RET / RTI)
            if (restore_flags) begin
                C <= pC;
                V <= pV;
                N <= pN;
                Z <= pZ;
            end else begin
                if (we_C) C <= aluC;
                if (we_V) V <= aluV;
                if (we_N) N <= aluN;
                if (we_Z) Z <= aluZ;
            end
        end
    end

    // ==================================================
    //             RET / RTI MICRO-FSM
    // ==================================================
    localparam RET_IDLE = 1'b0;
    localparam RET_WAIT = 1'b1;
    reg ret_state;

    always @(posedge clk or posedge reset) begin
        if (reset)
            ret_state <= RET_IDLE;
        else begin
            case (ret_state)
                RET_IDLE:
                    if (jump_type == 3'd6)
                        ret_state <= RET_WAIT;
                RET_WAIT:
                    ret_state <= RET_IDLE;
            endcase
        end
    end

    // ==================================================
    //                 BRANCH LOGIC
    // ==================================================
    reg bt;
    reg [7:0] btgt;
    wire loop_taken = ((A - 8'd1) != 8'd0);

    always @(*) begin
        bt   = 1'b0;
        btgt = B;  // default branch target

        case (ret_state)

            // ---------- NORMAL EXECUTION ----------
            RET_IDLE: begin
                case (jump_type)
                    3'd1: bt = Z;            // JZ
                    3'd2: bt = N;            // JN
                    3'd3: bt = C;            // JC
                    3'd4: bt = V;            // JV
                    3'd5: bt = 1'b1;         // JMP
                    3'd7: bt = loop_taken;   // LOOP
                    3'd6: begin              // RET / RTI
                        bt   = 1'b0;         // delay, not taken yet
                        btgt = B;             // placeholder, ignored
                    end
                    default: bt = 1'b0;
                endcase
            end

            // ---------- DELAY CYCLE ----------
            RET_WAIT: begin
                bt   = 1'b1;                 // taken now
                btgt = mem_out;              // return address
            end

        endcase
    end

    // ==================================================
    //                  OUTPUTS
    // ==================================================
    assign branch_taken  = bt;
    assign branch_target = btgt;
    assign flags_out        = {C, V, N, Z};
    assign preserved_flags = {pC, pV, pN, pZ};

endmodule