module reg_file(
    input        clk,
    input        rst,        // synchronous reset
    input        we,         // write enable
    input  [1:0] ra_addr,    // read port A address
    input  [1:0] rb_addr,    // read port B address
    input  [1:0] wr_addr,    // write address
    input  [7:0] wr_data,
    input        sp_inc,
    input        sp_dec,
    output reg [7:0] ra_data,
    output reg [7:0] rb_data
);

    reg [7:0] R [0:3];

    // asynchronous readports
    always @(*) begin // For ra
        if (ra_addr == 3 && sp_inc ) begin
            ra_data = R[3] + 1;
        end else begin
            ra_data = R[ra_addr];
        end
    end

    always @(*) begin // for rb
        rb_data = R[rb_addr];
    end
    // synchronous write + synchronous reset
    always @(posedge clk) begin
        if (rst) begin
            R[0] <= 8'h00;
            R[1] <= 8'h00;
            R[2] <= 8'h00;
            R[3] <= 8'hFF;    // SP = 255 on reset (required by ISA)
        end else if (we) begin
            R[wr_addr] <= wr_data;
        end
        if (sp_inc) begin
            R[3] <= R[3] + 1;
        end else if (sp_dec) begin
            R[3] <= R[3] - 1;
        end
    end
endmodule