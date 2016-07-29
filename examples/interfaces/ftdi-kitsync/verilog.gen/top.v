module top (
    input wire clk,
    input wire res_n,
    input wire prog_clko,
    input wire FTDI_TXE_N,
    input wire FTDI_RXF_N,
    output wire FTDI_RD_N,
    output wire FTDI_OE_N,
    output wire FTDI_WR_N,
    inout wire [7:0] FTDI_DATA,
    output wire [7:0] ordersorter_header,
    output wire [7:0] ordersorter_address,
    output wire [15:0] ordersorter_length,
    output wire [7:0] ordersorter_value,
    output wire ordersorter_read,
    output wire ordersorter_write
);
    // Parametersrs
    //---------------


    // Signaling
    //---------------
    wire  [7:0] rfg_read_data;
    wire  rfg_read_done;


    // Assigments
    //---------------


    
// Section Verilog Imported Content 




//-- FIFO Connection
wire            wi_clk;
wire            wi_wr;
wire    [7:0]   wi_data;
wire            wi_full;
wire            wi_almost_full;

//-- FIFO interface for reading data from the FTDI
wire            ri_read;
wire    [7:0]   ri_data;
wire            ri_empty;
wire            ri_almost_empty;
OrderSorter ordersorter_I (
    .ri_data,
    .ri_empty,
    .ri_read,
    .clk,
    .res_n(res_n),
    .header(ordersorter_header),
    .address(ordersorter_address),
    .length(ordersorter_length),
    .value(ordersorter_value),
    .read(ordersorter_read),
    .write(ordersorter_write)
);

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
 
// FIFO for writing to the FTDI
//----------------------
async_fifo_ftdi writeFIFO_I (
	.rd_clk(prog_clko),
	.rd_en(writeFIFO_rd_en || ~res_n),
	.rst(~res_n),
    .dout(data2ftdi),
	
    // Write to FIFO when there is a read_done from RFG
    .wr_clk(clk),
	.wr_en(rfg_read_done),
    .din(rfg_read_data),
	.almost_empty(writeFIFO_almost_empty),
	
	.empty(writeFIFO_empty),
	.full(wi_full),
	.almost_full(wi_almost_full)
);


//FIFO for reading data from the FTDI
//---------------------
async_fifo_ftdi readFIFO_I (
	.din(data2fifo),
	.rd_clk(clk),
	.rd_en(ri_read),
	.rst(~res_n),
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
    .res_n(res_n), 
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







    // Instances
    //---------------
    rf_rf rfg_I    (
         .clk(clk),
         .res_n(res_n),
         .read(ordersorter_read),
         .read_data(rfg_read_data),
         .write(ordersorter_write),
         .write_data(ordersorter_value),
         .done(rfg_read_done),
         .address(ordersorter_address)
);



    // Logic
    //---------------


endmodule
