class axi_transaction extends uvm_sequence_item;

    // -------------------------
    // AXI transaction type
    // -------------------------
    rand bit is_write;

    // -------------------------
    // AXI ID
    // -------------------------
    rand bit [5:0] id;

    // -------------------------
    // AXI address
    // -------------------------
    rand bit [31:0] addr;

    // -------------------------
    // Write data
    // -------------------------
    rand bit [31:0] data;

    // -------------------------
    // Write strobe
    // -------------------------
    rand bit [3:0] strb;

    // -------------------------
    // AXI response
    // -------------------------
    bit [1:0] resp;

    // -------------------------
    // Constructor
    // -------------------------
    function new(string name = "axi_transaction");
        super.new(name);
    endfunction

    // -------------------------
    // Print transaction
    // -------------------------
    `uvm_object_utils_begin(axi_transaction)
        `uvm_field_int(is_write, UVM_ALL_ON)
        `uvm_field_int(id,       UVM_ALL_ON)
        `uvm_field_int(addr,     UVM_ALL_ON)
        `uvm_field_int(data,     UVM_ALL_ON)
        `uvm_field_int(strb,     UVM_ALL_ON)
        `uvm_field_int(resp,     UVM_ALL_ON)
    `uvm_object_utils_end

endclass