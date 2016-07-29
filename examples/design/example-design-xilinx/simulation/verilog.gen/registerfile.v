module registerfile (
    // TX Enable, if low, data can be written
    input wire FTDI_TXE_N,
    // RX Free, if low, data can be read
    input wire FTDI_RXF_N,
    // Read, if low, FTDI outputs data
    output wire FTDI_RD_N,
    // Write, if low, FPGA/ASIC drives data to the bus
    output wire FTDI_WR_N,
    // Data InOut to read or write from FTDI
    inout wire [7:0] FTDI_DATA,
    input wire clk,
    input wire res_n,
    output wire [7:0] info_scratchpad0,
    input wire info_scratchpad0_hw_write,
    input wire [7:0] info_scratchpad0_hw,
    output wire [7:0] info_scratchpad1,
    input wire info_scratchpad1_hw_write,
    input wire [7:0] info_scratchpad1_hw
);
                   // Parametersrs
                   //---------------
                   localparam FETCH_ADDRESS = 2'd1;
                   localparam FETCH_COMMAND = 2'd2;
                   localparam FETCH_SIZE = 2'd0;
                   localparam IDLE = 2'd3;


                   // Signaling
                   //---------------
                   reg  [1:0] FTDI_READ_WRITE_state;
                   reg  [6:0] protocol0_address;
                                            reg  [6:0] protocol0_command;
                   reg  [6:0] protocol0_size;


                   // Assigments
                   //---------------




                   // Instances
                   //---------------
                   example_rf rfg_I                   (
                        .clk(clk),
                        .res_n(res_n),
                        .read(),
                        .read_data(),
                        .write(),
                        .write_data(),
                        .done(),
                        .address(),
                        .info_scratchpad0(info_scratchpad0),
                        .info_scratchpad0_hw_write(info_scratchpad0_hw_write),
                        .info_scratchpad0_hw(info_scratchpad0_hw),
                        .info_scratchpad1(info_scratchpad1),
                        .info_scratchpad1_hw_write(info_scratchpad1_hw_write),
                        .info_scratchpad1_hw(info_scratchpad1_hw)
);



                   // Logic
                   //---------------
                   
                                      //---- FSM FTDI_READ_WRITE : State Case
                   //-----------
                   casex ({FTDI_READ_WRITE_state,FTDI_RXF_N})
                        { IDLE , 1'b0 } : begin

                             FTDI_READ_WRITE_state <= FETCH_COMMAND;
 
                        end
                   endcase



endmodule
