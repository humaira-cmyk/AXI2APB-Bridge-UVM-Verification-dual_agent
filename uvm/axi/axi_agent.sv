class axi_agent extends uvm_agent;

    `uvm_component_utils(axi_agent)

    axi_sequencer axi_seqr;
    axi_driver    axi_drv;
    axi_monitor   axi_mon;

    function new(
        string name = "axi_agent",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        axi_seqr = axi_sequencer::type_id::create(
            "axi_seqr",
            this
        );

        axi_drv = axi_driver::type_id::create(
            "axi_drv",
            this
        );

        axi_mon = axi_monitor::type_id::create(
            "axi_mon",
            this
        );
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        axi_drv.seq_item_port.connect(
            axi_seqr.seq_item_export
        );
    endfunction

endclass