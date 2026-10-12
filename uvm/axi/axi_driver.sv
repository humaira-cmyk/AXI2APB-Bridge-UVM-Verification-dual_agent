class axi_driver extends uvm_driver #(axi_transaction);

    `uvm_component_utils(axi_driver)

    virtual AXI_BUS axi_vif;

    int bready_delay;
    int rready_delay;


    function new(
        string name = "axi_driver",
        uvm_component parent = null
    );
        super.new(name, parent);
        bready_delay = 0;
        rready_delay = 0;
    endfunction


    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db #(virtual AXI_BUS)::get(
                this, "", "axi_vif", axi_vif
            )) begin
            `uvm_fatal("AXI_DRV", "AXI virtual interface not found")
        end

        if (!uvm_config_db #(int)::get(
                this, "", "bready_delay", bready_delay
            )) begin
            bready_delay = 0;
        end

        if (!uvm_config_db #(int)::get(
                this, "", "rready_delay", rready_delay
            )) begin
            rready_delay = 0;
        end

        `uvm_info(
            "AXI_DRV",
            $sformatf("Configured BREADY delay=%0d RREADY delay=%0d",
                      bready_delay, rready_delay),
            UVM_LOW
        )

    endfunction


    virtual task run_phase(uvm_phase phase);

        axi_transaction req;

        // Initial AXI master outputs.
        axi_vif.aw_valid <= 1'b0;
        axi_vif.w_valid  <= 1'b0;
        axi_vif.ar_valid <= 1'b0;
        axi_vif.b_ready  <= 1'b0;
        axi_vif.r_ready  <= 1'b0;

        axi_vif.aw_id     <= '0;
        axi_vif.aw_addr   <= '0;
        axi_vif.aw_len    <= '0;
        axi_vif.aw_size   <= '0;
        axi_vif.aw_burst  <= '0;
        axi_vif.aw_lock   <= '0;
        axi_vif.aw_cache  <= '0;
        axi_vif.aw_prot   <= '0;
        axi_vif.aw_region <= '0;
        axi_vif.aw_user   <= '0;
        axi_vif.aw_qos    <= '0;

        axi_vif.w_data    <= '0;
        axi_vif.w_strb    <= '0;
        axi_vif.w_last    <= 1'b0;
        axi_vif.w_user    <= '0;

        axi_vif.ar_id     <= '0;
        axi_vif.ar_addr   <= '0;
        axi_vif.ar_len    <= '0;
        axi_vif.ar_size   <= '0;
        axi_vif.ar_burst  <= '0;
        axi_vif.ar_lock   <= '0;
        axi_vif.ar_cache  <= '0;
        axi_vif.ar_prot   <= '0;
        axi_vif.ar_region <= '0;
        axi_vif.ar_user   <= '0;
        axi_vif.ar_qos    <= '0;

        // TB releases reset on the 5th rising edge.
        repeat (10) @(posedge axi_vif.clk);

        forever begin

            seq_item_port.get_next_item(req);

            if (req.simultaneous_rw)
                drive_simultaneous_rw(req);
            else if (req.is_write)
                drive_write(req);
            else
                drive_read(req);

            seq_item_port.item_done();

        end

    endtask


    // =========================================================
    // NORMAL / BACKPRESSURED WRITE
    // =========================================================
    virtual task drive_write(axi_transaction req);

        int i;
        bit [1:0] held_bresp;
        bit [5:0] held_bid;
        bit [5:0] held_buser;

        // AW channel
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
        axi_vif.aw_user   <= req.user;
        axi_vif.aw_qos    <= 4'b0;
        axi_vif.aw_valid  <= 1'b1;

        do @(posedge axi_vif.clk);
        while (axi_vif.aw_ready !== 1'b1);

        axi_vif.aw_valid <= 1'b0;

        // W channel
        axi_vif.w_data  <= req.data;
        axi_vif.w_strb  <= req.strb;
        axi_vif.w_last  <= 1'b1;
        axi_vif.w_user  <= req.user;
        axi_vif.w_valid <= 1'b1;

        do @(posedge axi_vif.clk);
        while (axi_vif.w_ready !== 1'b1);

        axi_vif.w_valid <= 1'b0;

        // B channel - normal response acceptance
        if (bready_delay == 0) begin

            axi_vif.b_ready <= 1'b1;
            `uvm_info("AXI_DRV", "WRITE: waiting for BVALID...", UVM_NONE)

            wait (axi_vif.b_valid === 1'b1);

            req.resp      = axi_vif.b_resp;
            req.resp_id   = axi_vif.b_id;
            req.resp_user = axi_vif.b_user;

            `uvm_info("AXI_DRV", "WRITE: BVALID RECEIVED", UVM_NONE)

            @(posedge axi_vif.clk);
            axi_vif.b_ready <= 1'b0;

        end

        // B channel - directed backpressure
        else begin

            axi_vif.b_ready <= 1'b0;

            `uvm_info(
                "AXI_DRV",
                "WRITE BACKPRESSURE: waiting for BVALID while BREADY=0",
                UVM_LOW
            )

            wait (axi_vif.b_valid === 1'b1);

            held_bresp = axi_vif.b_resp;
            held_bid   = axi_vif.b_id;
            held_buser = axi_vif.b_user;

            for (i = 0; i < bready_delay; i = i + 1) begin

                `uvm_info(
                    "AXI_DRV",
                    $sformatf("BREADY DELAY %0d/%0d: BREADY=0", i+1, bready_delay),
                    UVM_LOW
                )

                @(posedge axi_vif.clk);

                if (axi_vif.b_valid !== 1'b1)
                    `uvm_error("AXI_DRV", "BVALID dropped while BREADY=0")

                if (axi_vif.b_resp !== held_bresp)
                    `uvm_error("AXI_DRV", "BRESP changed while BREADY=0")

                if (axi_vif.b_id !== held_bid)
                    `uvm_error("AXI_DRV", "BID changed while BREADY=0")

                if (axi_vif.b_user !== held_buser)
                    `uvm_error("AXI_DRV", "BUSER changed while BREADY=0")

            end

            axi_vif.b_ready <= 1'b1;
            `uvm_info("AXI_DRV", "WRITE BACKPRESSURE: BREADY=1", UVM_LOW)

            @(posedge axi_vif.clk);

            if (axi_vif.b_valid !== 1'b1)
                `uvm_error("AXI_DRV", "BVALID not asserted on response handshake")

            req.resp      = axi_vif.b_resp;
            req.resp_id   = axi_vif.b_id;
            req.resp_user = axi_vif.b_user;

            axi_vif.b_ready <= 1'b0;

            `uvm_info("AXI_DRV", "WRITE BACKPRESSURE: response accepted", UVM_LOW)

        end

        `uvm_info(
            "AXI_DRIVER",
            $sformatf(
                "WRITE: ID=%0d ADDR=%h DATA=%h RESP=%0d RESP_ID=%0d USER=%0h RESP_USER=%0h",
                req.id, req.addr, req.data, req.resp,
                req.resp_id, req.user, req.resp_user
            ),
            UVM_MEDIUM
        )

    endtask


    // =========================================================
    // NORMAL / BACKPRESSURED READ
    // =========================================================
    virtual task drive_read(axi_transaction req);

        int i;
        bit [31:0] held_rdata;
        bit [1:0]  held_rresp;
        bit [5:0]  held_rid;
        bit [5:0]  held_ruser;

        // AR channel
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
        axi_vif.ar_user   <= req.user;
        axi_vif.ar_qos    <= 4'b0;
        axi_vif.ar_valid  <= 1'b1;

        do @(posedge axi_vif.clk);
        while (axi_vif.ar_ready !== 1'b1);

        axi_vif.ar_valid <= 1'b0;

        // R channel - normal response acceptance
        if (rready_delay == 0) begin

            axi_vif.r_ready <= 1'b1;
            `uvm_info("AXI_DRV", "READ: waiting for RVALID...", UVM_NONE)

            wait (axi_vif.r_valid === 1'b1);

            req.data      = axi_vif.r_data;
            req.resp      = axi_vif.r_resp;
            req.resp_id   = axi_vif.r_id;
            req.resp_user = axi_vif.r_user;

            `uvm_info("AXI_DRV", "READ: RVALID RECEIVED", UVM_NONE)

            @(posedge axi_vif.clk);
            axi_vif.r_ready <= 1'b0;

        end

        // R channel - directed backpressure
        else begin

            axi_vif.r_ready <= 1'b0;

            `uvm_info(
                "AXI_DRV",
                "READ BACKPRESSURE: waiting for RVALID while RREADY=0",
                UVM_LOW
            )

            wait (axi_vif.r_valid === 1'b1);

            held_rdata = axi_vif.r_data;
            held_rresp = axi_vif.r_resp;
            held_rid   = axi_vif.r_id;
            held_ruser = axi_vif.r_user;

            for (i = 0; i < rready_delay; i = i + 1) begin

                `uvm_info(
                    "AXI_DRV",
                    $sformatf("RREADY DELAY %0d/%0d: RREADY=0", i+1, rready_delay),
                    UVM_LOW
                )

                @(posedge axi_vif.clk);

                if (axi_vif.r_valid !== 1'b1)
                    `uvm_error("AXI_DRV", "RVALID dropped while RREADY=0")

                if (axi_vif.r_data !== held_rdata)
                    `uvm_error("AXI_DRV", "RDATA changed while RREADY=0")

                if (axi_vif.r_resp !== held_rresp)
                    `uvm_error("AXI_DRV", "RRESP changed while RREADY=0")

                if (axi_vif.r_id !== held_rid)
                    `uvm_error("AXI_DRV", "RID changed while RREADY=0")

                if (axi_vif.r_user !== held_ruser)
                    `uvm_error("AXI_DRV", "RUSER changed while RREADY=0")

            end

            axi_vif.r_ready <= 1'b1;
            `uvm_info("AXI_DRV", "READ BACKPRESSURE: RREADY=1", UVM_LOW)

            @(posedge axi_vif.clk);

            if (axi_vif.r_valid !== 1'b1)
                `uvm_error("AXI_DRV", "RVALID not asserted on response handshake")

            req.data      = axi_vif.r_data;
            req.resp      = axi_vif.r_resp;
            req.resp_id   = axi_vif.r_id;
            req.resp_user = axi_vif.r_user;

            axi_vif.r_ready <= 1'b0;

            `uvm_info("AXI_DRV", "READ BACKPRESSURE: response accepted", UVM_LOW)

        end

        `uvm_info(
            "AXI_DRIVER",
            $sformatf(
                "READ: ID=%0d ADDR=%h DATA=%h RESP=%0d RESP_ID=%0d USER=%0h RESP_USER=%0h",
                req.id, req.addr, req.data, req.resp,
                req.resp_id, req.user, req.resp_user
            ),
            UVM_MEDIUM
        )

    endtask


    // =========================================================
    // SIMULTANEOUS READ + WRITE
    // =========================================================
    virtual task drive_simultaneous_rw(axi_transaction req);

        bit aw_done;
        bit w_done;
        bit ar_done;
        bit b_done;
        bit r_done;

        aw_done = 1'b0;
        w_done  = 1'b0;
        ar_done = 1'b0;
        b_done  = 1'b0;
        r_done  = 1'b0;

        @(posedge axi_vif.clk);

        // Write request
        axi_vif.aw_id     <= req.id;
        axi_vif.aw_addr   <= req.addr;
        axi_vif.aw_len    <= 8'd0;
        axi_vif.aw_size   <= 3'd2;
        axi_vif.aw_burst  <= 2'b01;
        axi_vif.aw_lock   <= 1'b0;
        axi_vif.aw_cache  <= 4'b0;
        axi_vif.aw_prot   <= 3'b0;
        axi_vif.aw_region <= 4'b0;
        axi_vif.aw_user   <= req.user;
        axi_vif.aw_qos    <= 4'b0;
        axi_vif.aw_valid  <= 1'b1;

        axi_vif.w_data    <= req.data;
        axi_vif.w_strb    <= req.strb;
        axi_vif.w_last    <= 1'b1;
        axi_vif.w_user    <= req.user;
        axi_vif.w_valid   <= 1'b1;

        // Read request at the same time
        axi_vif.ar_id     <= req.read_id;
        axi_vif.ar_addr   <= req.read_addr;
        axi_vif.ar_len    <= 8'd0;
        axi_vif.ar_size   <= 3'd2;
        axi_vif.ar_burst  <= 2'b01;
        axi_vif.ar_lock   <= 1'b0;
        axi_vif.ar_cache  <= 4'b0;
        axi_vif.ar_prot   <= 3'b0;
        axi_vif.ar_region <= 4'b0;
        axi_vif.ar_user   <= req.read_user;
        axi_vif.ar_qos    <= 4'b0;
        axi_vif.ar_valid  <= 1'b1;

        axi_vif.b_ready   <= 1'b1;
        axi_vif.r_ready   <= 1'b1;

        `uvm_info(
            "AXI_DRV",
            $sformatf(
                "SIMULTANEOUS START: WRITE ADDR=%h, READ ADDR=%h",
                req.addr, req.read_addr
            ),
            UVM_LOW
        )

        // Keep each VALID asserted until its own handshake.
        while (!(aw_done && w_done && ar_done && b_done && r_done)) begin

            @(posedge axi_vif.clk);

            if (!aw_done && axi_vif.aw_valid && axi_vif.aw_ready) begin
                aw_done = 1'b1;
                axi_vif.aw_valid <= 1'b0;
            end

            if (!w_done && axi_vif.w_valid && axi_vif.w_ready) begin
                w_done = 1'b1;
                axi_vif.w_valid <= 1'b0;
            end

            if (!ar_done && axi_vif.ar_valid && axi_vif.ar_ready) begin
                ar_done = 1'b1;
                axi_vif.ar_valid <= 1'b0;
            end

            if (!r_done && axi_vif.r_valid && axi_vif.r_ready) begin
                r_done = 1'b1;
                `uvm_info("AXI_DRV", "SIMULTANEOUS: READ RESPONSE ACCEPTED", UVM_LOW)
            end

            if (!b_done && axi_vif.b_valid && axi_vif.b_ready) begin
                b_done = 1'b1;
                `uvm_info("AXI_DRV", "SIMULTANEOUS: WRITE RESPONSE ACCEPTED", UVM_LOW)
            end

        end

        axi_vif.b_ready <= 1'b0;
        axi_vif.r_ready <= 1'b0;

        `uvm_info("AXI_DRV", "SIMULTANEOUS READ + WRITE COMPLETE", UVM_LOW)

    endtask

endclass

