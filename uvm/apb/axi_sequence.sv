class axi_sequence extends uvm_sequence #(axi_transaction);

    `uvm_object_utils(axi_sequence)

    function new(string name = "axi_sequence");
        super.new(name);
    endfunction

    virtual task body();

        axi_transaction req;

        // -------------------------
        // AXI WRITE transaction
        // -------------------------
        req = axi_transaction::type_id::create("write_req");

        start_item(req);

        req.is_write = 1'b1;
        req.id       = 6'd1;
        req.addr     = 32'h0000_0010;
        req.data     = 32'hDEAD_BEEF;
        req.strb     = 4'b1111;

        finish_item(req);

        // -------------------------
        // AXI READ transaction
        // -------------------------
        req = axi_transaction::type_id::create("read_req");

        start_item(req);

        req.is_write = 1'b0;
        req.id       = 6'd2;
        req.addr     = 32'h0000_0020;
        req.data     = 32'h0;
        req.strb     = 4'b0000;

        finish_item(req);

    endtask

endclass