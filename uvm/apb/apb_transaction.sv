class apb_transaction extends uvm_sequence_item;

    rand bit [31:0] addr;
    rand bit [31:0] data;
    rand bit        write;
    rand bit [3:0]  strb;

    bit [31:0]      rdata;
    bit             slverr;

    function new(string name = "apb_transaction");
        super.new(name);
    endfunction

    `uvm_object_utils_begin(apb_transaction)
        `uvm_field_int(addr,   UVM_ALL_ON)
        `uvm_field_int(data,   UVM_ALL_ON)
        `uvm_field_int(write,  UVM_ALL_ON)
        `uvm_field_int(strb,   UVM_ALL_ON)
        `uvm_field_int(rdata,  UVM_ALL_ON)
        `uvm_field_int(slverr, UVM_ALL_ON)
    `uvm_object_utils_end

endclass