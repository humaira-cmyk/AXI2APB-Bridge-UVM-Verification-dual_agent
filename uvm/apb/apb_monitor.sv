class apb_monitor extends uvm_monitor;

    `uvm_component_utils(apb_monitor)

    virtual APB_BUS apb_vif;

    uvm_analysis_port #(apb_transaction) analysis_port;

    function new(
        string name = "apb_monitor",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        analysis_port = new("analysis_port", this);

        if (!uvm_config_db #(virtual APB_BUS)::get(
                this,
                "",
                "apb_vif",
                apb_vif
            )) begin
            `uvm_fatal(
                "APB_MON",
                "APB virtual interface not found"
            )
        end
    endfunction

    virtual task run_phase(uvm_phase phase);

        forever begin

            @(posedge apb_vif.clk);

            // Sample only the completing edge of the ACCESS phase
            // (PSEL && PENABLE && PREADY). Triggering on PENABLE alone
            // reported every transfer twice, which desynced the scoreboard.
            if (apb_vif.psel && apb_vif.penable && apb_vif.pready) begin

                apb_transaction tr;

                tr = apb_transaction::type_id::create(
                    "apb_mon_tr"
                );

                tr.addr  = apb_vif.paddr;
                tr.write = apb_vif.pwrite;
                tr.data  = apb_vif.pwdata;
                tr.strb  = 4'b1111;

                tr.rdata  = apb_vif.prdata;
                tr.slverr = apb_vif.pslverr;

                if (tr.write) begin
                    `uvm_info(
                        "APB_MON",
                        $sformatf(
                            "WRITE: ADDR=%h DATA=%h STRB=%h ERR=%0d",
                            tr.addr,
                            tr.data,
                            tr.strb,
                            tr.slverr
                        ),
                        UVM_MEDIUM
                    )
                end
                else begin
                    `uvm_info(
                        "APB_MON",
                        $sformatf(
                            "READ: ADDR=%h DATA=%h ERR=%0d",
                            tr.addr,
                            tr.rdata,
                            tr.slverr
                        ),
                        UVM_MEDIUM
                    )
                end

                analysis_port.write(tr);

            end

        end

    endtask

endclass