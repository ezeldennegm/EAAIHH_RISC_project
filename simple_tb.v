module cpu_reset_tb;

    // ===============================
    // Clock / Reset
    // ===============================
    reg clk;
    reg reset;

    // ===============================
    // External ports
    // ===============================
    reg  intr;
    wire [7:0] OUT;
    wire [7:0] input_port;

    // ===============================
    // Instantiate CPU
    // ===============================
    CPU DUT (
        .clk   (clk),
        .reset (reset),
        .interrupt  (intr),
        .OUT   (OUT),
        .input_port(input_port)
    );

    // ===============================
    // Clock generation (10 ns period)
    // ===============================
    initial begin
        clk = 0;
        forever begin
           #1 clk = ~clk; 
        end
    end 

    // ===============================
    // Initialization
    // ===============================
    initial begin
        // -------------------------------
        // Load memory and register file
        // -------------------------------
        $readmemh("mem.dat", DUT.MEM_UNIT.mem);
        

        repeat (3) @(negedge clk);
        reset = 1;
        intr = 0;

        // Hold reset for a few cycles
        repeat (3) @(negedge clk);

        // Deassert reset
        reset = 0;

        $readmemh("reg.dat", DUT.ID.RF.R);
        repeat (3) @(negedge clk);
        // Run for a few cycles
        repeat (30) @(negedge clk);

        $display("Reset + initialization test completed.");
        $finish;
    end

    // ===============================
    // Monitor important signals
    // ===============================
    initial begin
        $monitor(
            "time=%0t | reset=%b | PC=%h | OUT=%h",
            $time,
            reset,
            DUT.IF.pc,
            OUT
        );
    end

endmodule