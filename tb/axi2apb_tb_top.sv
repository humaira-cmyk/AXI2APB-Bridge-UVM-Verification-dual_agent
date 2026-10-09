module axi2apb_tb_top;

    // =========================================================
    // Clock and Reset
    // =========================================================

    logic clk;
    logic rst_n;
    logic test_en;


    // =========================================================
    // Clock Generation
    // =========================================================

    initial begin

        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end

    end


    // =========================================================
    // Reset + Test Enable
    // =========================================================

    initial begin

        rst_n   = 1'b0;
        test_en = 1'b0;

        // Keep DUT in reset
        repeat (5) @(posedge clk);

        // Release reset
        rst_n = 1'b1;

        // Enable AXI buffers / DUT
        test_en = 1'b1;

    end


    // =========================================================
    // AXI and APB Interfaces
    // =========================================================

    AXI_BUS axi();
    APB_BUS apb();


    // =========================================================
    // Connect Clock
    // =========================================================

    assign axi.clk = clk;
    assign apb.clk = clk;


    // =========================================================
    // DUT
    // =========================================================

    axi2apb_wrap dut (

        .clk_i      (clk),
        .rst_ni     (rst_n),
        .test_en_i  (test_en),

        .axi_slave  (axi),
        .apb_master (apb)

    );


    // =========================================================
    // DEBUG MONITOR
    // =========================================================

    initial begin

        forever begin

            @(posedge clk);

            $display(
                "TIME=%0t | AXI: AWV=%b AWR=%b WV=%b WR=%b BV=%b BR=%b ARV=%b ARR=%b RV=%b RR=%b | APB: PSEL=%b PEN=%b PW=%b ADDR=%h DATA=%h READY=%b",
                $time,

                axi.aw_valid,
                axi.aw_ready,

                axi.w_valid,
                axi.w_ready,

                axi.b_valid,
                axi.b_ready,

                axi.ar_valid,
                axi.ar_ready,

                axi.r_valid,
                axi.r_ready,

                apb.psel,
                apb.penable,
                apb.pwrite,
                apb.paddr,
                apb.pwdata,
                apb.pready
            );

        end

    end


    // =========================================================
    // UVM CONFIGURATION + START TEST
    // =========================================================

    initial begin

        // -----------------------------------------------------
        // AXI virtual interface
        // -----------------------------------------------------

        uvm_config_db #(virtual AXI_BUS)::set(
            null,
            "*",
            "axi_vif",
            axi
        );


        // -----------------------------------------------------
        // APB virtual interface
        // -----------------------------------------------------

        uvm_config_db #(virtual APB_BUS)::set(
            null,
            "*",
            "apb_vif",
            apb
        );


        // -----------------------------------------------------
        // Start UVM test
        // -----------------------------------------------------

        run_test("axi2apb_test");

    end

endmodule