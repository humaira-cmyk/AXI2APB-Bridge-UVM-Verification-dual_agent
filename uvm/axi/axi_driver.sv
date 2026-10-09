class axi_driver extends uvm_driver #(axi_transaction);

    `uvm_component_utils(axi_driver)

    virtual AXI_BUS axi_vif;


    function new(
        string name = "axi_driver",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction


    // ------------------------------------------------
    // BUILD PHASE
    // ------------------------------------------------

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db #(virtual AXI_BUS)::get(
                this,
                "",
                "axi_vif",
                axi_vif
            )) begin

            `uvm_fatal(
                "AXI_DRV",
                "AXI virtual interface not found"
            )

        end

    endfunction


    // ------------------------------------------------
    // RUN PHASE
    // ------------------------------------------------

    virtual task run_phase(uvm_phase phase);

        axi_transaction req;

        // Initialize AXI outputs
        axi_vif.aw_valid <= 1'b0;
        axi_vif.w_valid  <= 1'b0;
        axi_vif.ar_valid <= 1'b0;

        axi_vif.b_ready  <= 1'b0;
        axi_vif.r_ready  <= 1'b0;

        axi_vif.aw_id    <= '0;
        axi_vif.aw_addr  <= '0;
        axi_vif.aw_len   <= '0;
        axi_vif.aw_size  <= '0;
        axi_vif.aw_burst <= '0;
        axi_vif.aw_lock  <= '0;
        axi_vif.aw_cache <= '0;
        axi_vif.aw_prot  <= '0;
        axi_vif.aw_region<= '0;
        axi_vif.aw_user  <= '0;
        axi_vif.aw_qos   <= '0;

        axi_vif.w_data   <= '0;
        axi_vif.w_strb   <= '0;
        axi_vif.w_last   <= 1'b0;
        axi_vif.w_user   <= '0;

        axi_vif.ar_id    <= '0;
        axi_vif.ar_addr  <= '0;
        axi_vif.ar_len   <= '0;
        axi_vif.ar_size  <= '0;
        axi_vif.ar_burst <= '0;
        axi_vif.ar_lock  <= '0;
        axi_vif.ar_cache <= '0;
        axi_vif.ar_prot  <= '0;
        axi_vif.ar_region<= '0;
        axi_vif.ar_user  <= '0;
        axi_vif.ar_qos   <= '0;


        // Wait out reset (tb releases rst_n at the 5th clock edge).
        // Without this, ready=1 during reset made the driver drop valid
        // and the transfer was lost -> hang waiting for BVALID/RVALID.
        repeat (10) @(posedge axi_vif.clk);

        forever begin

            seq_item_port.get_next_item(req);

            if (req.is_write)
                drive_write(req);
            else
                drive_read(req);

            seq_item_port.item_done();

        end

    endtask


    // =================================================
    // WRITE
    // =================================================

    virtual task drive_write(axi_transaction req);

        // -------------------------
        // AW CHANNEL
        // -------------------------

        @(posedge axi_vif.clk);

        axi_vif.aw_id     <= req.id;
        axi_vif.aw_addr   <= req.addr;
        axi_vif.aw_len    <= 8'd0;
        axi_vif.aw_size   <= 3'd2;
        axi_vif.aw_burst  <= 2'b01;
        axi_vif.aw_lock   <= 1'b0;
        axi_vif.aw_cache  <= 4'b0;
        axi_vif.aw_prot   <= 3'b0;
        axi_vif.aw_region <= 4'b0;
        axi_vif.aw_user   <= '0;
        axi_vif.aw_qos    <= 4'b0;

        axi_vif.aw_valid  <= 1'b1;


        do @(posedge axi_vif.clk); while (axi_vif.aw_ready !== 1'b1);

        axi_vif.aw_valid <= 1'b0;


        // -------------------------
        // W CHANNEL
        // -------------------------

        axi_vif.w_data  <= req.data;
        axi_vif.w_strb  <= req.strb;
        axi_vif.w_last  <= 1'b1;
        axi_vif.w_user  <= '0;

        axi_vif.w_valid <= 1'b1;


        do @(posedge axi_vif.clk); while (axi_vif.w_ready !== 1'b1);

        axi_vif.w_valid <= 1'b0;


        // -------------------------
        // B CHANNEL
        // -------------------------

        axi_vif.b_ready <= 1'b1;

        `uvm_info(
            "AXI_DRV",
            "WRITE: waiting for BVALID...",
            UVM_NONE
        )

        wait (axi_vif.b_valid === 1'b1);

        req.resp = axi_vif.b_resp;

        `uvm_info(
            "AXI_DRV",
            "WRITE: BVALID RECEIVED",
            UVM_NONE
        )

        @(posedge axi_vif.clk);

        axi_vif.b_ready <= 1'b0;


        `uvm_info(
            "AXI_DRIVER",
            $sformatf(
                "WRITE: ADDR=%h DATA=%h RESP=%0d",
                req.addr,
                req.data,
                req.resp
            ),
            UVM_MEDIUM
        )

    endtask


    // =================================================
    // READ
    // =================================================

    virtual task drive_read(axi_transaction req);

        // -------------------------
        // AR CHANNEL
        // -------------------------

        @(posedge axi_vif.clk);

        axi_vif.ar_id     <= req.id;
        axi_vif.ar_addr   <= req.addr;
        axi_vif.ar_len    <= 8'd0;
        axi_vif.ar_size   <= 3'd2;
        axi_vif.ar_burst  <= 2'b01;
        axi_vif.ar_lock   <= 1'b0;
        axi_vif.ar_cache  <= 4'b0;
        axi_vif.ar_prot   <= 3'b0;
        axi_vif.ar_region <= 4'b0;
        axi_vif.ar_user   <= '0;
        axi_vif.ar_qos    <= 4'b0;

        axi_vif.ar_valid  <= 1'b1;


        do @(posedge axi_vif.clk); while (axi_vif.ar_ready !== 1'b1);

        axi_vif.ar_valid <= 1'b0;


        // -------------------------
        // R CHANNEL
        // -------------------------

        axi_vif.r_ready <= 1'b1;

        `uvm_info(
            "AXI_DRV",
            "READ: waiting for RVALID...",
            UVM_NONE
        )

        wait (axi_vif.r_valid === 1'b1);

        req.data = axi_vif.r_data;
        req.resp = axi_vif.r_resp;


        `uvm_info(
            "AXI_DRV",
            "READ: RVALID RECEIVED",
            UVM_NONE
        )

        @(posedge axi_vif.clk);

        axi_vif.r_ready <= 1'b0;


        `uvm_info(
            "AXI_DRIVER",
            $sformatf(
                "READ: ADDR=%h DATA=%h RESP=%0d",
                req.addr,
                req.data,
                req.resp
            ),
            UVM_MEDIUM
        )

    endtask

endclass