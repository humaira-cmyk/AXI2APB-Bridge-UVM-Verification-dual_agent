// ============================================================
// Common base test. All named directed tests below remain
// available and can be run independently with +UVM_TESTNAME.
// ============================================================
class axi2apb_base_test extends uvm_test;

    `uvm_component_utils(axi2apb_base_test)

    axi2apb_env    env;
    axi_sequence   seq;
    axi_test_mode_e mode;
    string          test_label;

    function new(
        string name = "axi2apb_base_test",
        uvm_component parent = null
    );
        super.new(name, parent);
        mode       = RESET_MODE;
        test_label = "BASE TEST";
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        uvm_top.set_timeout(100us, 0);
        env = axi2apb_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);

        phase.raise_objection(this);

        `uvm_info("TEST", $sformatf("%s STARTED", test_label), UVM_LOW)

        seq = axi_sequence::type_id::create("seq");
        seq.mode = mode;
        seq.start(env.axi_ag.axi_seqr);

        `uvm_info("TEST", $sformatf("%s FINISHED", test_label), UVM_LOW)

        #100ns;
        phase.drop_objection(this);

    endtask

endclass


// 1. RESET / SMOKE
class axi2apb_reset_test extends axi2apb_base_test;
    `uvm_component_utils(axi2apb_reset_test)
    function new(string name="axi2apb_reset_test", uvm_component parent=null);
        super.new(name,parent);
    endfunction
    virtual function void build_phase(uvm_phase phase);
        mode = RESET_MODE;
        test_label = "RESET / SMOKE TEST";
        super.build_phase(phase);
    endfunction
endclass


// 2. SINGLE WRITE
class axi2apb_single_write_test extends axi2apb_base_test;
    `uvm_component_utils(axi2apb_single_write_test)
    function new(string name="axi2apb_single_write_test", uvm_component parent=null);
        super.new(name,parent);
    endfunction
    virtual function void build_phase(uvm_phase phase);
        mode = WRITE_MODE;
        test_label = "SINGLE WRITE TEST";
        uvm_config_db #(int)::set(this, "env.scoreboard", "expected_transactions", 1);
        super.build_phase(phase);
    endfunction
endclass


// 3. SINGLE READ
class axi2apb_single_read_test extends axi2apb_base_test;
    `uvm_component_utils(axi2apb_single_read_test)
    function new(string name="axi2apb_single_read_test", uvm_component parent=null);
        super.new(name,parent);
    endfunction
    virtual function void build_phase(uvm_phase phase);
        mode = READ_MODE;
        test_label = "SINGLE READ TEST";
        uvm_config_db #(int)::set(this, "env.scoreboard", "expected_transactions", 1);
        super.build_phase(phase);
    endfunction
endclass


// 4. APB WAIT STATE
class axi2apb_wait_state_test extends axi2apb_base_test;
    `uvm_component_utils(axi2apb_wait_state_test)
    function new(string name="axi2apb_wait_state_test", uvm_component parent=null);
        super.new(name,parent);
    endfunction
    virtual function void build_phase(uvm_phase phase);
        mode = WAIT_STATE_MODE;
        test_label = "APB WAIT-STATE TEST";
        uvm_config_db #(int)::set(this, "env.apb_ag.apb_drv", "wait_cycles", 3);
        uvm_config_db #(int)::set(this, "env.scoreboard", "expected_transactions", 1);
        super.build_phase(phase);
    endfunction
endclass


// 5. WRITE BACKPRESSURE
class axi2apb_write_backpressure_test extends axi2apb_base_test;
    `uvm_component_utils(axi2apb_write_backpressure_test)
    function new(string name="axi2apb_write_backpressure_test", uvm_component parent=null);
        super.new(name,parent);
    endfunction
    virtual function void build_phase(uvm_phase phase);
        mode = WRITE_BACKPRESSURE_MODE;
        test_label = "WRITE BACKPRESSURE TEST";
        uvm_config_db #(int)::set(this, "env.axi_ag.axi_drv", "bready_delay", 3);
        uvm_config_db #(int)::set(this, "env.scoreboard", "expected_transactions", 1);
        super.build_phase(phase);
    endfunction
endclass


// 6. READ BACKPRESSURE
class axi2apb_read_backpressure_test extends axi2apb_base_test;
    `uvm_component_utils(axi2apb_read_backpressure_test)
    function new(string name="axi2apb_read_backpressure_test", uvm_component parent=null);
        super.new(name,parent);
    endfunction
    virtual function void build_phase(uvm_phase phase);
        mode = READ_BACKPRESSURE_MODE;
        test_label = "READ BACKPRESSURE TEST";
        uvm_config_db #(int)::set(this, "env.axi_ag.axi_drv", "rready_delay", 3);
        uvm_config_db #(int)::set(this, "env.scoreboard", "expected_transactions", 1);
        super.build_phase(phase);
    endfunction
endclass


// 7. SIMULTANEOUS READ + WRITE / READ PRIORITY
class axi2apb_simultaneous_rw_test extends axi2apb_base_test;
    `uvm_component_utils(axi2apb_simultaneous_rw_test)
    function new(string name="axi2apb_simultaneous_rw_test", uvm_component parent=null);
        super.new(name,parent);
    endfunction
    virtual function void build_phase(uvm_phase phase);
        mode = SIMULTANEOUS_RW_MODE;
        test_label = "SIMULTANEOUS READ + WRITE TEST";
        uvm_config_db #(int)::set(this, "env.scoreboard", "expected_transactions", 2);
        uvm_config_db #(int)::set(this, "env.scoreboard", "check_read_priority", 1);
        super.build_phase(phase);
    endfunction
endclass


// 8. BACK-TO-BACK WRITES
class axi2apb_back_to_back_write_test extends axi2apb_base_test;
    `uvm_component_utils(axi2apb_back_to_back_write_test)
    function new(string name="axi2apb_back_to_back_write_test", uvm_component parent=null);
        super.new(name,parent);
    endfunction
    virtual function void build_phase(uvm_phase phase);
        mode = B2B_WRITE_MODE;
        test_label = "BACK-TO-BACK WRITE TEST";
        uvm_config_db #(int)::set(this, "env.scoreboard", "expected_transactions", 4);
        super.build_phase(phase);
    endfunction
endclass


// 9. BACK-TO-BACK READS
class axi2apb_back_to_back_read_test extends axi2apb_base_test;
    `uvm_component_utils(axi2apb_back_to_back_read_test)
    function new(string name="axi2apb_back_to_back_read_test", uvm_component parent=null);
        super.new(name,parent);
    endfunction
    virtual function void build_phase(uvm_phase phase);
        mode = B2B_READ_MODE;
        test_label = "BACK-TO-BACK READ TEST";
        uvm_config_db #(int)::set(this, "env.scoreboard", "expected_transactions", 4);
        super.build_phase(phase);
    endfunction
endclass


// 10. MIXED READ / WRITE
class axi2apb_mixed_rw_test extends axi2apb_base_test;
    `uvm_component_utils(axi2apb_mixed_rw_test)
    function new(string name="axi2apb_mixed_rw_test", uvm_component parent=null);
        super.new(name,parent);
    endfunction
    virtual function void build_phase(uvm_phase phase);
        mode = MIXED_RW_MODE;
        test_label = "MIXED READ / WRITE TEST";
        uvm_config_db #(int)::set(this, "env.scoreboard", "expected_transactions", 6);
        super.build_phase(phase);
    endfunction
endclass


// 11. AXI ID
class axi2apb_id_test extends axi2apb_base_test;
    `uvm_component_utils(axi2apb_id_test)
    function new(string name="axi2apb_id_test", uvm_component parent=null);
        super.new(name,parent);
    endfunction
    virtual function void build_phase(uvm_phase phase);
        mode = ID_MODE;
        test_label = "AXI ID TEST";
        uvm_config_db #(int)::set(this, "env.scoreboard", "expected_transactions", 2);
        super.build_phase(phase);
    endfunction
endclass


// 12. AXI USER
class axi2apb_user_test extends axi2apb_base_test;
    `uvm_component_utils(axi2apb_user_test)
    function new(string name="axi2apb_user_test", uvm_component parent=null);
        super.new(name,parent);
    endfunction
    virtual function void build_phase(uvm_phase phase);
        mode = USER_MODE;
        test_label = "AXI USER TEST";
        uvm_config_db #(int)::set(this, "env.scoreboard", "expected_transactions", 2);
        super.build_phase(phase);
    endfunction
endclass


// 13. APB PSLVERR OBSERVATION
// The supplied RTL hard-codes AXI BRESP/RRESP to OKAY and does not use PSLVERR.
// Therefore this directed test expects APB PSLVERR=1 and AXI RESP=OKAY (00),
// documenting the actual DUT behavior rather than pretending it maps SLVERR.
class axi2apb_pslverr_test extends axi2apb_base_test;
    `uvm_component_utils(axi2apb_pslverr_test)
    function new(string name="axi2apb_pslverr_test", uvm_component parent=null);
        super.new(name,parent);
    endfunction
    virtual function void build_phase(uvm_phase phase);
        mode = PSLVERR_MODE;
        test_label = "APB PSLVERR OBSERVATION TEST";
        uvm_config_db #(int)::set(this, "env.apb_ag.apb_drv", "inject_slverr", 1);
        uvm_config_db #(int)::set(this, "env.scoreboard", "expect_apb_error", 1);
        uvm_config_db #(int)::set(this, "env.scoreboard", "expected_axi_resp_on_error", 0);
        uvm_config_db #(int)::set(this, "env.scoreboard", "expected_transactions", 1);
        super.build_phase(phase);
    endfunction
endclass

