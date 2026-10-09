class axi_monitor extends uvm_monitor;

    `uvm_component_utils(axi_monitor)

    virtual AXI_BUS axi_vif;

    uvm_analysis_port #(axi_transaction) analysis_port;


    // ------------------------------------------------
    // Pending write information
    // ------------------------------------------------

    bit        aw_pending;
    bit [5:0]  pending_aw_id;
    bit [31:0] pending_aw_addr;

    bit        w_pending;
    bit [31:0] pending_w_data;
    bit [3:0]  pending_w_strb;


    function new(
        string name = "axi_monitor",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    // ------------------------------------------------
    // BUILD
    // ------------------------------------------------

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        analysis_port = new(
            "analysis_port",
            this
        );

        if (!uvm_config_db #(virtual AXI_BUS)::get(
                this,
                "",
                "axi_vif",
                axi_vif
            )) begin

            `uvm_fatal(
                "AXI_MON",
                "AXI virtual interface not found"
            );

        end

    endfunction


    // ------------------------------------------------
    // RUN
    // ------------------------------------------------

    virtual task run_phase(uvm_phase phase);

        forever begin

            @(posedge axi_vif.clk);


            // =========================================
            // WRITE ADDRESS CHANNEL
            // =========================================

            if (
                axi_vif.aw_valid &&
                axi_vif.aw_ready
            ) begin

                aw_pending      = 1'b1;
                pending_aw_id   = axi_vif.aw_id;
                pending_aw_addr = axi_vif.aw_addr;

                `uvm_info(
                    "AXI_MON",
                    $sformatf(
                        "WRITE ADDRESS: ID=%0d ADDR=%h",
                        axi_vif.aw_id,
                        axi_vif.aw_addr
                    ),
                    UVM_MEDIUM
                );

            end


            // =========================================
            // WRITE DATA CHANNEL
            // =========================================

            if (
                axi_vif.w_valid &&
                axi_vif.w_ready
            ) begin

                w_pending      = 1'b1;
                pending_w_data = axi_vif.w_data;
                pending_w_strb = axi_vif.w_strb;

                `uvm_info(
                    "AXI_MON",
                    $sformatf(
                        "WRITE DATA: DATA=%h STRB=%h",
                        axi_vif.w_data,
                        axi_vif.w_strb
                    ),
                    UVM_MEDIUM
                );

            end


            // =========================================
            // WRITE RESPONSE
            // =========================================

            if (
                aw_pending &&
                w_pending &&
                axi_vif.b_valid &&
                axi_vif.b_ready
            ) begin

                axi_transaction tr;

                tr = axi_transaction::type_id::create(
                    "write_mon"
                );

                tr.is_write = 1'b1;
                tr.id       = pending_aw_id;
                tr.addr     = pending_aw_addr;
                tr.data     = pending_w_data;
                tr.strb     = pending_w_strb;
                tr.resp     = axi_vif.b_resp;


                `uvm_info(
                    "AXI_MON",
                    $sformatf(
                        "WRITE COMPLETE: ID=%0d ADDR=%h DATA=%h RESP=%0d",
                        tr.id,
                        tr.addr,
                        tr.data,
                        tr.resp
                    ),
                    UVM_MEDIUM
                );


                analysis_port.write(tr);


                aw_pending = 1'b0;
                w_pending  = 1'b0;

            end


            // =========================================
            // READ ADDRESS CHANNEL
            // =========================================

            if (
                axi_vif.ar_valid &&
                axi_vif.ar_ready
            ) begin

                axi_transaction tr;

                tr = axi_transaction::type_id::create(
                    "read_mon"
                );

                tr.is_write = 1'b0;
                tr.id       = axi_vif.ar_id;
                tr.addr     = axi_vif.ar_addr;


                `uvm_info(
                    "AXI_MON",
                    $sformatf(
                        "READ ADDRESS: ID=%0d ADDR=%h",
                        tr.id,
                        tr.addr
                    ),
                    UVM_MEDIUM
                );


                // -------------------------------------
                // Wait for READ response
                // -------------------------------------

                fork

                    begin

                        wait (
                            axi_vif.r_valid &&
                            axi_vif.r_ready
                        );

                        tr.data = axi_vif.r_data;
                        tr.resp = axi_vif.r_resp;


                        `uvm_info(
                            "AXI_MON",
                            $sformatf(
                                "READ COMPLETE: ID=%0d ADDR=%h DATA=%h RESP=%0d",
                                tr.id,
                                tr.addr,
                                tr.data,
                                tr.resp
                            ),
                            UVM_MEDIUM
                        );


                        analysis_port.write(tr);

                    end

                join_none

            end

        end

    endtask

endclass