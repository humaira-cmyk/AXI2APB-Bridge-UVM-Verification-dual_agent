class axi2apb_test extends uvm_test;

    `uvm_component_utils(axi2apb_test)

    axi2apb_env env;
    axi_sequence seq;

    function new(
        string name = "axi2apb_test",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        uvm_top.set_timeout(100us, 0);

        env = axi2apb_env::type_id::create(
            "env",
            this
        );

    endfunction

  task run_phase(uvm_phase phase);

    phase.raise_objection(this);

    `uvm_info("TEST", "STARTING SEQUENCE", UVM_LOW)

    seq = axi_sequence::type_id::create("seq");

    seq.start(env.axi_ag.axi_seqr);

    `uvm_info("TEST", "SEQUENCE RETURNED", UVM_LOW)

    #100;

    phase.drop_objection(this);

endtask

endclass