interface APB_BUS #(
    parameter int unsigned APB_ADDR_WIDTH = 32,
    parameter int unsigned APB_DATA_WIDTH = 32
);
    logic clk;

    logic                        penable;
    logic                        pwrite;
    logic [APB_ADDR_WIDTH-1:0]  paddr;
    logic                        psel;
    logic [APB_DATA_WIDTH-1:0]  pwdata;

    logic [APB_DATA_WIDTH-1:0]  prdata;
    logic                        pready;
    logic                        pslverr;


    // -------------------------
    // APB Master Modport
    // -------------------------
    modport Master (
        output penable,
        output pwrite,
        output paddr,
        output psel,
        output pwdata,

        input  prdata,
        input  pready,
        input  pslverr
    );


    // -------------------------
    // APB Slave Modport
    // -------------------------
    modport Slave (
        input  penable,
        input  pwrite,
        input  paddr,
        input  psel,
        input  pwdata,

        output prdata,
        output pready,
        output pslverr
    );

endinterface