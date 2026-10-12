class apb_driver extends uvm_driver #(apb_transaction);

    `uvm_component_utils(apb_driver)

    virtual APB_BUS apb_vif;

    bit [31:0] mem [bit [31:0]];

    int wait_cycles;
    int inject_slverr;


    function new(
        string name = "apb_driver",
        uvm_component parent = null
    );
        super.new(name, parent);
        wait_cycles  = 0;
        inject_slverr = 0;
    endfunction


    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        if (!uvm_config_db #(virtual APB_BUS)::get(
                this, "", "apb_vif", apb_vif
            )) begin
            `uvm_fatal("APB_DRV", "APB virtual interface not found")
        end

        if (!uvm_config_db #(int)::get(
                this, "", "wait_cycles", wait_cycles
            )) begin
            wait_cycles = 0;
        end

        if (!uvm_config_db #(int)::get(
                this, "", "inject_slverr", inject_slverr
            )) begin
            inject_slverr = 0;
        end

        `uvm_info(
            "APB_DRV",
            $sformatf(
                "Configured APB wait cycles=%0d inject_slverr=%0d",
                wait_cycles, inject_slverr
            ),
            UVM_LOW
        )

    endfunction


    virtual task run_phase(uvm_phase phase);

        bit [31:0] held_addr;
        bit [31:0] held_wdata;
        bit        held_write;
        int i;

        apb_vif.pready  <= 1'b0;
        apb_vif.prdata  <= 32'h00000000;
        apb_vif.pslverr <= 1'b0;

        forever begin

            @(posedge apb_vif.clk);

            // DUT keeps PSEL high, so PENABLE marks an active ACCESS.
            if (apb_vif.penable === 1'b1) begin

                held_addr  = apb_vif.paddr;
                held_wdata = apb_vif.pwdata;
                held_write = apb_vif.pwrite;

                `uvm_info(
                    "APB_DRV",
                    $sformatf(
                        "APB ACCESS: WRITE=%b ADDR=%h WDATA=%h",
                        held_write, held_addr, held_wdata
                    ),
                    UVM_MEDIUM
                )

                // Directed APB wait states.
                for (i = 0; i < wait_cycles; i = i + 1) begin

                    apb_vif.pready <= 1'b0;

                    `uvm_info(
                        "APB_DRV",
                        $sformatf(
                            "APB WAIT STATE %0d/%0d: PREADY=0",
                            i+1, wait_cycles
                        ),
                        UVM_MEDIUM
                    )

                    @(posedge apb_vif.clk);

                    if (apb_vif.penable !== 1'b1)
                        `uvm_error("APB_DRV", "PENABLE dropped while PREADY=0")

                    if (apb_vif.paddr !== held_addr)
                        `uvm_error("APB_DRV", "PADDR changed during wait state")

                    if (apb_vif.pwrite !== held_write)
                        `uvm_error("APB_DRV", "PWRITE changed during wait state")

                    if (held_write && (apb_vif.pwdata !== held_wdata))
                        `uvm_error("APB_DRV", "PWDATA changed during wait state")

                end

                // APB slave memory behavior.
                if (held_write === 1'b1) begin

                    mem[held_addr] = held_wdata;

                    `uvm_info(
                        "APB_DRV",
                        $sformatf(
                            "APB WRITE: ADDR=%h DATA=%h",
                            held_addr, held_wdata
                        ),
                        UVM_MEDIUM
                    )

                end
                else begin

                    if (mem.exists(held_addr))
                        apb_vif.prdata <= mem[held_addr];
                    else
                        apb_vif.prdata <= 32'h00000000;

                    `uvm_info(
                        "APB_DRV",
                        $sformatf(
                            "APB READ: ADDR=%h DATA=%h",
                            held_addr,
                            mem.exists(held_addr) ? mem[held_addr] : 32'h00000000
                        ),
                        UVM_MEDIUM
                    )

                end

                if (inject_slverr != 0) begin
                    apb_vif.pslverr <= 1'b1;
                    `uvm_info("APB_DRV", "DIRECTED PSLVERR ASSERTED", UVM_LOW)
                end
                else begin
                    apb_vif.pslverr <= 1'b0;
                end

                apb_vif.pready <= 1'b1;
                `uvm_info("APB_DRV", "APB ACCESS: PREADY=1", UVM_MEDIUM)

                @(posedge apb_vif.clk);

                apb_vif.pready  <= 1'b0;
                apb_vif.prdata  <= 32'h00000000;
                apb_vif.pslverr <= 1'b0;

            end

        end

    endtask

endclass

