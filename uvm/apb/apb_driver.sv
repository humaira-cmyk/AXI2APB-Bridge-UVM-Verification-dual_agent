class apb_driver extends uvm_driver #(apb_transaction);

    `uvm_component_utils(apb_driver)

    virtual APB_BUS apb_vif;

    bit [31:0] mem [bit [31:0]];


    function new(
        string name = "apb_driver",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction


    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db #(virtual APB_BUS)::get(
                this,
                "",
                "apb_vif",
                apb_vif
            )) begin

            `uvm_fatal(
                "APB_DRV",
                "APB virtual interface not found"
            )

        end

    endfunction


    virtual task run_phase(uvm_phase phase);

        apb_vif.pready  <= 1'b0;
        apb_vif.prdata  <= 32'h00000000;
        apb_vif.pslverr <= 1'b0;

        forever begin

            @(posedge apb_vif.clk);

            // Wait for actual APB ACCESS phase.
            // PSEL is permanently 1 in this DUT.
            if (apb_vif.penable === 1'b1) begin

                `uvm_info(
                    "APB_DRV",
                    $sformatf(
                        "APB ACCESS: WRITE=%b ADDR=%h WDATA=%h",
                        apb_vif.pwrite,
                        apb_vif.paddr,
                        apb_vif.pwdata
                    ),
                    UVM_MEDIUM
                );


                if (apb_vif.pwrite === 1'b1) begin

                    mem[apb_vif.paddr] = apb_vif.pwdata;

                    `uvm_info(
                        "APB_DRV",
                        $sformatf(
                            "APB WRITE: ADDR=%h DATA=%h",
                            apb_vif.paddr,
                            apb_vif.pwdata
                        ),
                        UVM_MEDIUM
                    );

                end
                else begin

                    if (mem.exists(apb_vif.paddr))
                        apb_vif.prdata <= mem[apb_vif.paddr];
                    else
                        apb_vif.prdata <= 32'h00000000;

                    `uvm_info(
                        "APB_DRV",
                        $sformatf(
                            "APB READ: ADDR=%h DATA=%h",
                            apb_vif.paddr,
                            mem.exists(apb_vif.paddr)
                                ? mem[apb_vif.paddr]
                                : 32'h00000000
                        ),
                        UVM_MEDIUM
                    );

                end


                apb_vif.pslverr <= 1'b0;

                // Complete APB ACCESS
                apb_vif.pready <= 1'b1;

                `uvm_info(
                    "APB_DRV",
                    "APB ACCESS: PREADY=1",
                    UVM_MEDIUM
                );

                @(posedge apb_vif.clk);

                apb_vif.pready  <= 1'b0;
                apb_vif.prdata  <= 32'h00000000;
                apb_vif.pslverr <= 1'b0;

            end

        end

    endtask

endclass