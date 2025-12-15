module Fetch_stage(
    input clk,
    input reset,
    input f_stall,
    input intr_ack,
    input intr_active,
    input [7:0] instruction,
    input [7:0] immediate,
    input immediate_enabled,
    input branch_taken,
    input [7:0] branch_target,
    output reg [7:0] pc
);

    always @(posedge clk) begin
        if (reset || intr_ack)
            pc <= instruction;
        else begin
            if (f_stall)
                pc <= pc;
            else begin
                if (branch_taken) begin
                    pc <= branch_target;
                end else begin
                    if (immediate_enabled)
                        pc <= pc + 2;
                    else 
                        pc <= pc + 1;
                end
            end
        end
    end
endmodule