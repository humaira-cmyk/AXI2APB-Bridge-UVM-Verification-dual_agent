`uvm_analysis_imp_decl(_axi)
`uvm_analysis_imp_decl(_apb)


class axi2apb_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(axi2apb_scoreboard)


    // =================================================
    // ANALYSIS PORTS
    // =================================================

    uvm_analysis_imp_axi #(
        axi_transaction,
        axi2apb_scoreboard
    ) axi_export;


    uvm_analysis_imp_apb #(
        apb_transaction,
        axi2apb_scoreboard
    ) apb_export;


    // =================================================
    // TRANSACTION QUEUES
    // =================================================

    axi_transaction axi_q[$];
    apb_transaction apb_q[$];


    // =================================================
    // STATISTICS
    // =================================================

    int pass_count = 0;
    int fail_count = 0;


    // =================================================
    // CONSTRUCTOR
    // =================================================

    function new(
        string name = "axi2apb_scoreboard",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    // =================================================
    // BUILD
    // =================================================

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        axi_export = new(
            "axi_export",
            this
        );

        apb_export = new(
            "apb_export",
            this
        );

    endfunction


    // =================================================
    // AXI MONITOR TRANSACTION
    // =================================================

    virtual function void write_axi(
        axi_transaction tr
    );

        axi_transaction copy;

        copy = axi_transaction::type_id::create(
            "axi_sb_copy"
        );

        copy.is_write = tr.is_write;
        copy.id       = tr.id;
        copy.addr     = tr.addr;
        copy.data     = tr.data;
        copy.strb     = tr.strb;
        copy.resp     = tr.resp;

        axi_q.push_back(copy);


        if (tr.is_write) begin

            `uvm_info(
                "SCOREBOARD",
                $sformatf(
                    "AXI WRITE RECEIVED: ADDR=%h DATA=%h RESP=%0d",
                    tr.addr,
                    tr.data,
                    tr.resp
                ),
                UVM_MEDIUM
            );

        end
        else begin

            `uvm_info(
                "SCOREBOARD",
                $sformatf(
                    "AXI READ RECEIVED: ADDR=%h DATA=%h RESP=%0d",
                    tr.addr,
                    tr.data,
                    tr.resp
                ),
                UVM_MEDIUM
            );

        end


        compare_transactions();

    endfunction


    // =================================================
    // APB MONITOR TRANSACTION
    // =================================================

    virtual function void write_apb(
        apb_transaction tr
    );

        apb_transaction copy;

        copy = apb_transaction::type_id::create(
            "apb_sb_copy"
        );

        copy.addr   = tr.addr;
        copy.data   = tr.data;
        copy.write  = tr.write;
        copy.strb   = tr.strb;
        copy.rdata  = tr.rdata;
        copy.slverr = tr.slverr;

        apb_q.push_back(copy);


        if (tr.write) begin

            `uvm_info(
                "SCOREBOARD",
                $sformatf(
                    "APB WRITE RECEIVED: ADDR=%h DATA=%h ERR=%0d",
                    tr.addr,
                    tr.data,
                    tr.slverr
                ),
                UVM_MEDIUM
            );

        end
        else begin

            `uvm_info(
                "SCOREBOARD",
                $sformatf(
                    "APB READ RECEIVED: ADDR=%h DATA=%h ERR=%0d",
                    tr.addr,
                    tr.rdata,
                    tr.slverr
                ),
                UVM_MEDIUM
            );

        end


        compare_transactions();

    endfunction


    // =================================================
    // COMPARE AXI ↔ APB
    // =================================================

    virtual function void compare_transactions();

        axi_transaction axi_tr;
        apb_transaction apb_tr;


        while (
            (axi_q.size() > 0) &&
            (apb_q.size() > 0)
        ) begin

            axi_tr = axi_q.pop_front();
            apb_tr = apb_q.pop_front();


            // -----------------------------------------
            // TYPE CHECK
            // -----------------------------------------

            if (axi_tr.is_write != apb_tr.write) begin

                fail_count++;

                `uvm_error(
                    "SCOREBOARD",
                    $sformatf(
                        "TYPE MISMATCH: AXI_WRITE=%0d APB_WRITE=%0d",
                        axi_tr.is_write,
                        apb_tr.write
                    )
                );

                continue;

            end


            // -----------------------------------------
            // ADDRESS CHECK
            // -----------------------------------------

            if (axi_tr.addr != apb_tr.addr) begin

                fail_count++;

                `uvm_error(
                    "SCOREBOARD",
                    $sformatf(
                        "ADDRESS MISMATCH: AXI=%h APB=%h",
                        axi_tr.addr,
                        apb_tr.addr
                    )
                );

            end
            else begin

                `uvm_info(
                    "SCOREBOARD",
                    $sformatf(
                        "ADDRESS MATCH: %h",
                        axi_tr.addr
                    ),
                    UVM_LOW
                );

            end


            // =========================================
            // WRITE
            // =========================================

            if (axi_tr.is_write) begin


                // -------------------------------------
                // WRITE DATA
                // -------------------------------------

                if (axi_tr.data != apb_tr.data) begin

                    fail_count++;

                    `uvm_error(
                        "SCOREBOARD",
                        $sformatf(
                            "WRITE DATA MISMATCH: AXI=%h APB=%h",
                            axi_tr.data,
                            apb_tr.data
                        )
                    );

                end
                else begin

                    pass_count++;

                    `uvm_info(
                        "SCOREBOARD",
                        $sformatf(
                            "WRITE DATA MATCH: %h",
                            axi_tr.data
                        ),
                        UVM_LOW
                    );

                end


                // -------------------------------------
                // STRB
                // -------------------------------------

                if (axi_tr.strb != apb_tr.strb) begin

                    fail_count++;

                    `uvm_error(
                        "SCOREBOARD",
                        $sformatf(
                            "STRB MISMATCH: AXI=%h APB=%h",
                            axi_tr.strb,
                            apb_tr.strb
                        )
                    );

                end


                // -------------------------------------
                // APB ERROR
                // -------------------------------------

                if (apb_tr.slverr) begin

                    fail_count++;

                    `uvm_error(
                        "SCOREBOARD",
                        "Unexpected APB SLVERR on WRITE"
                    );

                end

            end


            // =========================================
            // READ
            // =========================================

            else begin


                // -------------------------------------
                // READ DATA
                //
                // APB READ DATA should become
                // AXI RDATA.
                // -------------------------------------

                if (axi_tr.data != apb_tr.rdata) begin

                    fail_count++;

                    `uvm_error(
                        "SCOREBOARD",
                        $sformatf(
                            "READ DATA MISMATCH: AXI=%h APB=%h",
                            axi_tr.data,
                            apb_tr.rdata
                        )
                    );

                end
                else begin

                    pass_count++;

                    `uvm_info(
                        "SCOREBOARD",
                        $sformatf(
                            "READ DATA MATCH: %h",
                            axi_tr.data
                        ),
                        UVM_LOW
                    );

                end


                // -------------------------------------
                // APB ERROR
                // -------------------------------------

                if (apb_tr.slverr) begin

                    fail_count++;

                    `uvm_error(
                        "SCOREBOARD",
                        "Unexpected APB SLVERR on READ"
                    );

                end

            end

        end

    endfunction


    // =================================================
    // REPORT
    // =================================================

   virtual function void report_phase(uvm_phase phase);

    super.report_phase(phase);

    `uvm_info(
        "SCOREBOARD",
        $sformatf(
            "SCOREBOARD SUMMARY: PASS=%0d FAIL=%0d",
            pass_count,
            fail_count
        ),
        UVM_NONE
    );

    if (fail_count == 0) begin

        `uvm_info(
            "SCOREBOARD",
            "AXI2APB VERIFICATION PASSED",
            UVM_NONE
        );

    end
    else begin

        `uvm_error(
            "SCOREBOARD",
            "AXI2APB VERIFICATION FAILED"
        );

    end

endfunction

endclass