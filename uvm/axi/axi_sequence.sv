class axi_sequence extends uvm_sequence #(axi_transaction);

    `uvm_object_utils(axi_sequence)

    function new(string name = "axi_sequence");
        super.new(name);
    endfunction


    task body();

        axi_transaction tr;


        // =================================================
        // WRITE
        // =================================================

        tr = axi_transaction::type_id::create("write_tr");

        start_item(tr);

        tr.is_write = 1'b1;
        tr.id       = 6'd1;
        tr.addr     = 32'h00000010;
        tr.data     = 32'hDEADBEEF;
        tr.strb     = 4'hF;

        finish_item(tr);

        `uvm_info(
            "SEQ",
            "WRITE SENT: ADDR=0x10 DATA=DEADBEEF",
            UVM_LOW
        );


        // =================================================
        // READ SAME ADDRESS
        // =================================================

        tr = axi_transaction::type_id::create("read_tr");

        start_item(tr);

        tr.is_write = 1'b0;
        tr.id       = 6'd2;
        tr.addr     = 32'h00000010;
        tr.data     = 32'h0;
        tr.strb     = 4'hF;

        finish_item(tr);

        `uvm_info(
            "SEQ",
            "READ SENT: ADDR=0x10",
            UVM_LOW
        );


        // =================================================
        // END
        // =================================================

        `uvm_info(
            "SEQ",
            "SEQUENCE BODY FINISHED",
            UVM_LOW
        );

    endtask

endclass