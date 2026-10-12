typedef enum {
    RESET_MODE,
    WRITE_MODE,
    READ_MODE,
    WAIT_STATE_MODE,
    WRITE_BACKPRESSURE_MODE,
    READ_BACKPRESSURE_MODE,
    SIMULTANEOUS_RW_MODE,
    B2B_WRITE_MODE,
    B2B_READ_MODE,
    MIXED_RW_MODE,
    ID_MODE,
    USER_MODE,
    PSLVERR_MODE
} axi_test_mode_e;


class axi_sequence extends uvm_sequence #(axi_transaction);

    `uvm_object_utils(axi_sequence)

    axi_test_mode_e mode;

    function new(string name = "axi_sequence");
        super.new(name);
        mode = WRITE_MODE;
    endfunction


    // ---------------------------------------------------------
    // Helper: send one normal AXI transaction
    // ---------------------------------------------------------
    task send_one(
        input bit        wr,
        input bit [5:0]  tx_id,
        input bit [31:0] tx_addr,
        input bit [31:0] tx_data,
        input bit [3:0]  tx_strb,
        input bit [5:0]  tx_user
    );
        axi_transaction tr;

        tr = axi_transaction::type_id::create("tr");
        start_item(tr);

        tr.simultaneous_rw = 1'b0;
        tr.is_write        = wr;
        tr.id              = tx_id;
        tr.addr            = tx_addr;
        tr.data            = tx_data;
        tr.strb            = tx_strb;
        tr.user            = tx_user;
        tr.read_id         = '0;
        tr.read_addr       = '0;
        tr.read_user       = '0;

        finish_item(tr);
    endtask


    // ---------------------------------------------------------
    // Helper: send simultaneous read + write request
    // ---------------------------------------------------------
    task send_simultaneous(
        input bit [5:0]  wr_id,
        input bit [31:0] wr_addr,
        input bit [31:0] wr_data,
        input bit [5:0]  wr_user,
        input bit [5:0]  rd_id,
        input bit [31:0] rd_addr,
        input bit [5:0]  rd_user
    );
        axi_transaction tr;

        tr = axi_transaction::type_id::create("simultaneous_tr");
        start_item(tr);

        tr.simultaneous_rw = 1'b1;

        // Write request uses the normal fields.
        tr.is_write  = 1'b1;
        tr.id        = wr_id;
        tr.addr      = wr_addr;
        tr.data      = wr_data;
        tr.strb      = 4'hF;
        tr.user      = wr_user;

        // Read request uses the dedicated secondary fields.
        tr.read_id   = rd_id;
        tr.read_addr = rd_addr;
        tr.read_user = rd_user;

        finish_item(tr);
    endtask


    task body();

        case (mode)

            RESET_MODE: begin
                `uvm_info("SEQ", "RESET / SMOKE TEST STARTED", UVM_LOW)
                #100ns;
                `uvm_info("SEQ", "RESET / SMOKE TEST FINISHED", UVM_LOW)
            end

            WRITE_MODE: begin
                send_one(1'b1, 6'd1, 32'h00000010, 32'hDEADBEEF, 4'hF, 6'h00);
                `uvm_info("SEQ", "SINGLE WRITE SENT: ADDR=0x10 DATA=DEADBEEF", UVM_LOW)
            end

            READ_MODE: begin
                send_one(1'b0, 6'd2, 32'h00000010, 32'h00000000, 4'hF, 6'h00);
                `uvm_info("SEQ", "SINGLE READ SENT: ADDR=0x10", UVM_LOW)
            end

            WAIT_STATE_MODE: begin
                send_one(1'b1, 6'd3, 32'h00000020, 32'h12345678, 4'hF, 6'h00);
                `uvm_info("SEQ", "WAIT-STATE WRITE SENT: ADDR=0x20 DATA=12345678", UVM_LOW)
            end

            WRITE_BACKPRESSURE_MODE: begin
                send_one(1'b1, 6'd4, 32'h00000030, 32'hA5A5A5A5, 4'hF, 6'h00);
                `uvm_info("SEQ", "WRITE BACKPRESSURE TRANSACTION SENT", UVM_LOW)
            end

            READ_BACKPRESSURE_MODE: begin
                send_one(1'b0, 6'd5, 32'h00000034, 32'h00000000, 4'hF, 6'h00);
                `uvm_info("SEQ", "READ BACKPRESSURE TRANSACTION SENT", UVM_LOW)
            end

            SIMULTANEOUS_RW_MODE: begin
                // DUT gives READ priority when read and write are pending together.
                send_simultaneous(
                    6'd6, 32'h00000060, 32'hCAFEBABE, 6'h01,
                    6'd7, 32'h00000064,                6'h02
                );
                `uvm_info("SEQ", "SIMULTANEOUS READ + WRITE SENT", UVM_LOW)
            end

            B2B_WRITE_MODE: begin
                send_one(1'b1, 6'd8,  32'h00000040, 32'h11111111, 4'hF, 6'h00);
                send_one(1'b1, 6'd9,  32'h00000044, 32'h22222222, 4'hF, 6'h00);
                send_one(1'b1, 6'd10, 32'h00000048, 32'h33333333, 4'hF, 6'h00);
                send_one(1'b1, 6'd11, 32'h0000004C, 32'h44444444, 4'hF, 6'h00);
                `uvm_info("SEQ", "4 BACK-TO-BACK WRITES SENT", UVM_LOW)
            end

            B2B_READ_MODE: begin
                send_one(1'b0, 6'd12, 32'h00000050, 32'h0, 4'hF, 6'h00);
                send_one(1'b0, 6'd13, 32'h00000054, 32'h0, 4'hF, 6'h00);
                send_one(1'b0, 6'd14, 32'h00000058, 32'h0, 4'hF, 6'h00);
                send_one(1'b0, 6'd15, 32'h0000005C, 32'h0, 4'hF, 6'h00);
                `uvm_info("SEQ", "4 BACK-TO-BACK READS SENT", UVM_LOW)
            end

            MIXED_RW_MODE: begin
                send_one(1'b1, 6'd16, 32'h00000070, 32'h1111AAAA, 4'hF, 6'h00);
                send_one(1'b0, 6'd17, 32'h00000070, 32'h0,        4'hF, 6'h00);
                send_one(1'b1, 6'd18, 32'h00000074, 32'h2222BBBB, 4'hF, 6'h00);
                send_one(1'b1, 6'd19, 32'h00000078, 32'h3333CCCC, 4'hF, 6'h00);
                send_one(1'b0, 6'd20, 32'h00000074, 32'h0,        4'hF, 6'h00);
                send_one(1'b0, 6'd21, 32'h00000078, 32'h0,        4'hF, 6'h00);
                `uvm_info("SEQ", "MIXED READ/WRITE SEQUENCE SENT", UVM_LOW)
            end

            ID_MODE: begin
                send_one(1'b1, 6'd23, 32'h00000090, 32'h55AA55AA, 4'hF, 6'h00);
                send_one(1'b0, 6'd41, 32'h00000090, 32'h0,        4'hF, 6'h00);
                `uvm_info("SEQ", "ID TEST SENT: WRITE ID=23, READ ID=41", UVM_LOW)
            end

            USER_MODE: begin
                send_one(1'b1, 6'd24, 32'h000000A0, 32'hABCDEF01, 4'hF, 6'h15);
                send_one(1'b0, 6'd25, 32'h000000A0, 32'h0,        4'hF, 6'h2A);
                `uvm_info("SEQ", "USER TEST SENT: AWUSER=0x15, ARUSER=0x2A", UVM_LOW)
            end

            PSLVERR_MODE: begin
                send_one(1'b1, 6'd26, 32'h000000B0, 32'hBAD0BAD0, 4'hF, 6'h00);
                `uvm_info("SEQ", "PSLVERR DIRECTED WRITE SENT", UVM_LOW)
            end

            default: begin
                `uvm_error("SEQ", "INVALID AXI SEQUENCE MODE")
            end

        endcase

        `uvm_info("SEQ", "SEQUENCE BODY FINISHED", UVM_LOW)

    endtask

endclass

