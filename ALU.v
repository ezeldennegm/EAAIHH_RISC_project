module ALU (
    input  [7:0] A,
    input  [7:0] B,
    input  [3:0] opcode,  
    input        oldC,    
    input        oldV,
    input        oldN,
    input        oldZ,
    output reg [7:0] out,   
    output reg       C,
    output reg       V,
    output reg       N,
    output reg       Z
);

    reg [7:0] temp;
    reg       carry_bit;

    localparam OP_MOV_A = 4'd0;
    localparam OP_MOV_B = 4'd1;
    localparam OP_ADD   = 4'd2;
    localparam OP_SUB   = 4'd3;
    localparam OP_AND   = 4'd4;
    localparam OP_OR    = 4'd5;
    localparam OP_DEC   = 4'd6;
    localparam OP_INC   = 4'd7;
    localparam OP_NEG   = 4'd8;
    localparam OP_NOT   = 4'd9;
    localparam OP_RLC   = 4'd10;
    localparam OP_RRC   = 4'd11;
    localparam OP_SETC  = 4'd12;
    localparam OP_CLRC  = 4'd13;
    localparam OP_DEC_A = 4'd14;

    always @(*) begin
        temp      = 8'b0;
        carry_bit = 1'b0;

        C = oldC;
        V = oldV;
        N = oldN;
        Z = oldZ;

        case (opcode)
            OP_MOV_A: temp = A;

            OP_MOV_B: temp = B;

            OP_ADD: begin
                {carry_bit, temp} = {1'b0, A} + {1'b0, B};
                C = carry_bit;
                V = (A[7] & B[7] & ~temp[7]) |
                    (~A[7] & ~B[7] &  temp[7]);
                N = temp[7];
                Z = (temp == 8'b0);
            end

            OP_SUB: begin
                {carry_bit, temp} = {1'b0, A} - {1'b0, B};
                C = carry_bit;
                V = (A[7] & ~B[7] & ~temp[7]) |
                    (~A[7] &  B[7] &  temp[7]);
                N = temp[7];
                Z = (temp == 8'b0);
            end

            OP_AND: begin
                temp = A & B;
                N = temp[7];
                Z = (temp == 8'b0);
            end

            OP_OR: begin
                temp = A | B;
                N = temp[7];
                Z = (temp == 8'b0);
            end

            OP_DEC: begin
                {carry_bit, temp} = {1'b0, B} - 9'd1;
                C = carry_bit;
                V = (B[7] & ~temp[7]);
                N = temp[7];
                Z = (temp == 8'b0);
            end

            OP_INC: begin
                {carry_bit, temp} = {1'b0, B} + 9'd1;
                C = carry_bit;
                V = (~B[7] & temp[7]);
                N = temp[7];
                Z = (temp == 8'b0);
            end

            OP_NEG: begin
                temp = (~B) + 8'b00000001;
                N = temp[7];
                Z = (temp == 8'b0);
            end

            OP_NOT: begin
                temp = ~B;
                N = temp[7];
                Z = (temp == 8'b0);
            end

            OP_RLC: begin
                C    = B[7];
                temp = {B[6:0], C};
                N    = temp[7];
                Z    = (temp == 8'b0);
             	V = 1'b0;
            end

            OP_RRC: begin
                C    = B[0];
                temp = {C, B[7:1]};
                N    = temp[7];
                Z    = (temp == 8'b0);
				V = 1'b0;
            end

            OP_SETC: begin
                C    = 1'b1;
                temp = B;
            end

            OP_CLRC: begin
                C    = 1'b0;
                temp = B;
            end
            
            OP_DEC_A: begin
                temp = A - 1;
            end

            default: temp = 8'b0;
        endcase

        out = temp;
    end

endmodule