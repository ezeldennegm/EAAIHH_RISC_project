module Memory (
    input  wire       clk,
    input  wire       rst,
    input  wire       we,
    input  wire       intr_ack,
    input  wire [7:0] data_in,
    input  wire [7:0] addr_in,
    input  wire [7:0] addr_instr,
    input  wire [7:0] addr_data,
    output wire  [7:0] data_out,
    output wire  [7:0] instr_out,
    output wire  [7:0] immediate,
    output wire        immediate_enabled
);
    reg [7:0] mem [0:255];

    always @(posedge clk) begin
        if (we) begin
            mem[addr_in] <= data_in;
        end
    end
    // Fetch stage
    assign instr_out = (rst) ? mem[0] :(intr_ack) ? mem[1]: mem[addr_instr];
    assign immediate_enabled = (instr_out[7:4] == 12) ? 1 : 0;
    assign immediate = (immediate_enabled) ? mem[addr_instr+1] : 0;

    // Memory stage
    assign data_out = (rst) ? 0 : mem[addr_data];
endmodule