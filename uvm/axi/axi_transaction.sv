class axi_transaction extends uvm_sequence_item;

    rand bit        is_write;
    rand bit        simultaneous_rw;

    rand bit [5:0]  id;
    rand bit [31:0] addr;
    rand bit [31:0] data;
    rand bit [3:0]  strb;
    rand bit [5:0]  user;

    // Used only by SIMULTANEOUS_RW_MODE for the read request.
    rand bit [5:0]  read_id;
    rand bit [31:0] read_addr;
    rand bit [5:0]  read_user;

    // Captured AXI response information.
    bit [1:0] resp;
    bit [5:0] resp_id;
    bit [5:0] resp_user;

    function new(string name = "axi_transaction");
        super.new(name);
    endfunction

    `uvm_object_utils_begin(axi_transaction)
        `uvm_field_int(is_write,       UVM_ALL_ON)
        `uvm_field_int(simultaneous_rw,UVM_ALL_ON)
        `uvm_field_int(id,             UVM_ALL_ON)
        `uvm_field_int(addr,           UVM_ALL_ON)
        `uvm_field_int(data,           UVM_ALL_ON)
        `uvm_field_int(strb,           UVM_ALL_ON)
        `uvm_field_int(user,           UVM_ALL_ON)
        `uvm_field_int(read_id,        UVM_ALL_ON)
        `uvm_field_int(read_addr,      UVM_ALL_ON)
        `uvm_field_int(read_user,      UVM_ALL_ON)
        `uvm_field_int(resp,           UVM_ALL_ON)
        `uvm_field_int(resp_id,        UVM_ALL_ON)
        `uvm_field_int(resp_user,      UVM_ALL_ON)
    `uvm_object_utils_end

endclass

