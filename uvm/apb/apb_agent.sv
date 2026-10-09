class apb_agent extends uvm_agent;

    `uvm_component_utils(apb_agent)

    apb_driver  apb_drv;
    apb_monitor apb_mon;

    function new(
        string name = "apb_agent",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        apb_drv = apb_driver::type_id::create(
            "apb_drv",
            this
        );

        apb_mon = apb_monitor::type_id::create(
            "apb_mon",
            this
        );
    endfunction

endclass