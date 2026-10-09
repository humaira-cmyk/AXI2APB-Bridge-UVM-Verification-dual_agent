class axi2apb_env extends uvm_env;

    `uvm_component_utils(axi2apb_env)

    axi_agent          axi_ag;
    apb_agent          apb_ag;
    axi2apb_scoreboard scoreboard;

    function new(
        string name = "axi2apb_env",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        axi_ag = axi_agent::type_id::create(
            "axi_ag",
            this
        );

        apb_ag = apb_agent::type_id::create(
            "apb_ag",
            this
        );

        scoreboard = axi2apb_scoreboard::type_id::create(
            "scoreboard",
            this
        );

    endfunction

virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    axi_ag.axi_mon.analysis_port.connect(
        scoreboard.axi_export
    );

    apb_ag.apb_mon.analysis_port.connect(
        scoreboard.apb_export
    );

endfunction
endclass