
//Parameter definition
parameter   PRIORITY = 1'b0; // 1'b0 = read priority,  1'b1 = write priority



//wire and register definitions

//fifo control signals
wire            writeFIFO_almost_empty;
wire            writeFIFO_empty;
wire            writeFIFO_rd_en;
wire            readFIFO_almost_full;
//wire            readFIFO_full;
wire            readFIFO_wr_en;

//wires for connecting the FIFO data busses to the IO buffer
wire    [7:0]   data2ftdi;
wire    [7:0]   data2fifo;


//Asynchronous assignments
assign writeFIFO_rd_en  = ~FTDI_TXE_N && ~FTDI_WR_N;
assign readFIFO_wr_en   = ~FTDI_RXF_N && ~FTDI_RD_N;
 
//FIFO for writing to the FTDI
async_fifo_toFTDI writeFIFO_I (
    .din(wi_data),
    .rd_clk(prog_clko),
    .rd_en(writeFIFO_rd_en || ~res_n_logic),
    .rst(~res_n_logic),
    .wr_clk(wi_clk),
    .wr_en(wi_wr),
    .almost_empty(writeFIFO_almost_empty),
    .dout(data2ftdi),
    .empty(writeFIFO_empty),
    .full(wi_full),
    .almost_full(wi_almost_full)
);


//FIFO for reading data from the FTDI
async_fifo_fromFTDI readFIFO_I (
    .din(data2fifo),
    .rd_clk(ri_clk),
    .rd_en(ri_rd || ~res_n_logic),
    .rst(~res_n_logic),
    .wr_clk(prog_clko),
    .wr_en(readFIFO_wr_en),
    .almost_empty(ri_almost_empty),
    .almost_full(readFIFO_almost_full),
    .dout(ri_data),
    .empty(ri_empty),
    .full()
);

//controlling FSM
ftdi_interface_control_fsm fsm_I ( 
    .clk(prog_clko), 
    .res_n(res_n_logic), 
    .rxf_n(FTDI_RXF_N), 
    .txe_n(FTDI_TXE_N), 
    .rf_almost_full(readFIFO_almost_full), 
    .wf_almost_empty(writeFIFO_almost_empty), 
    .wf_empty(writeFIFO_empty), 
    .prio(PRIORITY), 
    .rd_n(FTDI_RD_N), 
    .oe_n(FTDI_OE_N), 
    .wr_n(FTDI_WR_N)
);

//IO Buffer for the bidirectional data bus to the FTDI
genvar i;
generate
    for (i = 0; i < 8; i = i + 1) begin: buffer
        IOBUF ftdi_data_obuft_I (
            .I(data2ftdi[i]),
            .O(data2fifo[i]),
            .T(~FTDI_OE_N),
            .IO(FTDI_DATA[i])
        );
    end
endgenerate
