`uvm_analysis_imp_decl(_axi)
`uvm_analysis_imp_decl(_apb)

class axi2apb_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(axi2apb_scoreboard)

    uvm_analysis_imp_axi #(
        axi_transaction,
        axi2apb_scoreboard
    ) axi_export;

    uvm_analysis_imp_apb #(
        apb_transaction,
        axi2apb_scoreboard
    ) apb_export;

    axi_transaction axi_q[$];
    apb_transaction apb_q[$];

    int pass_count;
    int fail_count;
    int compared_count;

    int expected_transactions;
    int check_read_priority;
    int priority_apb_count;

    int expect_apb_error;
    int expected_axi_resp_on_error;


    function new(
        string name = "axi2apb_scoreboard",
        uvm_component parent = null
    );
        super.new(name, parent);
        pass_count                 = 0;
        fail_count                 = 0;
        compared_count             = 0;
        expected_transactions      = 0;
        check_read_priority        = 0;
        priority_apb_count         = 0;
        expect_apb_error           = 0;
        expected_axi_resp_on_error = 0;
    endfunction


    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        axi_export = new("axi_export", this);
        apb_export = new("apb_export", this);

        void'(uvm_config_db #(int)::get(
            this, "", "expected_transactions", expected_transactions));

        void'(uvm_config_db #(int)::get(
            this, "", "check_read_priority", check_read_priority));

        void'(uvm_config_db #(int)::get(
            this, "", "expect_apb_error", expect_apb_error));

        void'(uvm_config_db #(int)::get(
            this, "", "expected_axi_resp_on_error", expected_axi_resp_on_error));

    endfunction


    virtual function void write_axi(axi_transaction tr);

        axi_transaction copy;

        copy = axi_transaction::type_id::create("axi_sb_copy");

        copy.simultaneous_rw = tr.simultaneous_rw;
        copy.is_write        = tr.is_write;
        copy.id              = tr.id;
        copy.addr            = tr.addr;
        copy.data            = tr.data;
        copy.strb            = tr.strb;
        copy.user            = tr.user;
        copy.resp            = tr.resp;
        copy.resp_id         = tr.resp_id;
        copy.resp_user       = tr.resp_user;

        axi_q.push_back(copy);

        if (tr.is_write)
            `uvm_info("SCOREBOARD", $sformatf(
                "AXI WRITE RECEIVED: ID=%0d RESP_ID=%0d ADDR=%h DATA=%h RESP=%0d USER=%0h RESP_USER=%0h",
                tr.id, tr.resp_id, tr.addr, tr.data, tr.resp,
                tr.user, tr.resp_user), UVM_MEDIUM)
        else
            `uvm_info("SCOREBOARD", $sformatf(
                "AXI READ RECEIVED: ID=%0d RESP_ID=%0d ADDR=%h DATA=%h RESP=%0d USER=%0h RESP_USER=%0h",
                tr.id, tr.resp_id, tr.addr, tr.data, tr.resp,
                tr.user, tr.resp_user), UVM_MEDIUM)

        compare_transactions();

    endfunction


    virtual function void write_apb(apb_transaction tr);

        apb_transaction copy;

        copy = apb_transaction::type_id::create("apb_sb_copy");

        copy.addr   = tr.addr;
        copy.data   = tr.data;
        copy.write  = tr.write;
        copy.strb   = tr.strb;
        copy.rdata  = tr.rdata;
        copy.slverr = tr.slverr;

        apb_q.push_back(copy);

        // For simultaneous test the DUT RTL gives READ priority.
        if (check_read_priority != 0) begin

            if (priority_apb_count == 0) begin
                if (tr.write !== 1'b0) begin
                    fail_count++;
                    `uvm_error("SCOREBOARD", "READ PRIORITY FAIL: first APB transfer was not READ")
                end
                else begin
                    `uvm_info("SCOREBOARD", "READ PRIORITY PASS: first APB transfer is READ", UVM_LOW)
                end
            end
            else if (priority_apb_count == 1) begin
                if (tr.write !== 1'b1) begin
                    fail_count++;
                    `uvm_error("SCOREBOARD", "READ PRIORITY FAIL: second APB transfer was not WRITE")
                end
                else begin
                    `uvm_info("SCOREBOARD", "READ PRIORITY PASS: second APB transfer is WRITE", UVM_LOW)
                end
            end

            priority_apb_count++;

        end

        if (tr.write)
            `uvm_info("SCOREBOARD", $sformatf(
                "APB WRITE RECEIVED: ADDR=%h DATA=%h ERR=%0d",
                tr.addr, tr.data, tr.slverr), UVM_MEDIUM)
        else
            `uvm_info("SCOREBOARD", $sformatf(
                "APB READ RECEIVED: ADDR=%h DATA=%h ERR=%0d",
                tr.addr, tr.rdata, tr.slverr), UVM_MEDIUM)

        compare_transactions();

    endfunction


    virtual function void compare_transactions();

        axi_transaction axi_tr;
        apb_transaction apb_tr;

        while ((axi_q.size() > 0) && (apb_q.size() > 0)) begin

            axi_tr = axi_q.pop_front();
            apb_tr = apb_q.pop_front();
            compared_count++;

            // Type
            if (axi_tr.is_write != apb_tr.write) begin
                fail_count++;
                `uvm_error("SCOREBOARD", $sformatf(
                    "TYPE MISMATCH: AXI_WRITE=%0d APB_WRITE=%0d",
                    axi_tr.is_write, apb_tr.write))
                continue;
            end

            // Address
            if (axi_tr.addr != apb_tr.addr) begin
                fail_count++;
                `uvm_error("SCOREBOARD", $sformatf(
                    "ADDRESS MISMATCH: AXI=%h APB=%h",
                    axi_tr.addr, apb_tr.addr))
            end
            else begin
                `uvm_info("SCOREBOARD", $sformatf(
                    "ADDRESS MATCH: %h", axi_tr.addr), UVM_LOW)
            end

            // AXI response ID must match request ID.
            if (axi_tr.id != axi_tr.resp_id) begin
                fail_count++;
                `uvm_error("SCOREBOARD", $sformatf(
                    "AXI ID MISMATCH: REQUEST_ID=%0d RESPONSE_ID=%0d",
                    axi_tr.id, axi_tr.resp_id))
            end
            else begin
                `uvm_info("SCOREBOARD", $sformatf(
                    "AXI ID MATCH: %0d", axi_tr.id), UVM_LOW)
            end

            // AXI response USER must match address-channel USER.
            if (axi_tr.user != axi_tr.resp_user) begin
                fail_count++;
                `uvm_error("SCOREBOARD", $sformatf(
                    "AXI USER MISMATCH: REQUEST_USER=%0h RESPONSE_USER=%0h",
                    axi_tr.user, axi_tr.resp_user))
            end
            else begin
                `uvm_info("SCOREBOARD", $sformatf(
                    "AXI USER MATCH: %0h", axi_tr.user), UVM_LOW)
            end

            if (axi_tr.is_write) begin

                if (axi_tr.data != apb_tr.data) begin
                    fail_count++;
                    `uvm_error("SCOREBOARD", $sformatf(
                        "WRITE DATA MISMATCH: AXI=%h APB=%h",
                        axi_tr.data, apb_tr.data))
                end
                else begin
                    pass_count++;
                    `uvm_info("SCOREBOARD", $sformatf(
                        "WRITE DATA MATCH: %h", axi_tr.data), UVM_LOW)
                end

                if (axi_tr.strb != apb_tr.strb) begin
                    fail_count++;
                    `uvm_error("SCOREBOARD", $sformatf(
                        "STRB MISMATCH: AXI=%h APB=%h",
                        axi_tr.strb, apb_tr.strb))
                end

            end
            else begin

                if (axi_tr.data != apb_tr.rdata) begin
                    fail_count++;
                    `uvm_error("SCOREBOARD", $sformatf(
                        "READ DATA MISMATCH: AXI=%h APB=%h",
                        axi_tr.data, apb_tr.rdata))
                end
                else begin
                    pass_count++;
                    `uvm_info("SCOREBOARD", $sformatf(
                        "READ DATA MATCH: %h", axi_tr.data), UVM_LOW)
                end

            end

            // APB error expectation and observed AXI response.
            if (expect_apb_error != 0) begin

                if (apb_tr.slverr !== 1'b1) begin
                    fail_count++;
                    `uvm_error("SCOREBOARD", "Expected PSLVERR=1 but APB monitor saw 0")
                end
                else begin
                    `uvm_info("SCOREBOARD", "EXPECTED APB PSLVERR OBSERVED", UVM_LOW)
                end

                if (axi_tr.resp != expected_axi_resp_on_error[1:0]) begin
                    fail_count++;
                    `uvm_error("SCOREBOARD", $sformatf(
                        "AXI ERROR RESPONSE MISMATCH: EXPECTED=%0d ACTUAL=%0d",
                        expected_axi_resp_on_error[1:0], axi_tr.resp))
                end
                else begin
                    `uvm_info("SCOREBOARD", $sformatf(
                        "AXI RESPONSE ON PSLVERR MATCHED CONFIGURED VALUE: %0d",
                        axi_tr.resp), UVM_LOW)
                end

            end
            else if (apb_tr.slverr) begin
                fail_count++;
                `uvm_error("SCOREBOARD", "Unexpected APB PSLVERR")
            end

        end

    endfunction


    virtual function void report_phase(uvm_phase phase);

        super.report_phase(phase);

        if ((expected_transactions > 0) &&
            (compared_count != expected_transactions)) begin
            fail_count++;
            `uvm_error("SCOREBOARD", $sformatf(
                "TRANSACTION COUNT MISMATCH: EXPECTED=%0d COMPARED=%0d",
                expected_transactions, compared_count))
        end

        if ((check_read_priority != 0) && (priority_apb_count < 2)) begin
            fail_count++;
            `uvm_error("SCOREBOARD", $sformatf(
                "READ PRIORITY TEST INCOMPLETE: APB_TRANSFERS=%0d",
                priority_apb_count))
        end

        `uvm_info(
            "SCOREBOARD",
            $sformatf(
                "SCOREBOARD SUMMARY: PASS=%0d FAIL=%0d COMPARED=%0d",
                pass_count, fail_count, compared_count
            ),
            UVM_NONE
        )

        if (fail_count == 0)
            `uvm_info("SCOREBOARD", "AXI2APB VERIFICATION PASSED", UVM_NONE)
        else
            `uvm_error("SCOREBOARD", "AXI2APB VERIFICATION FAILED")

    endfunction

endclass

