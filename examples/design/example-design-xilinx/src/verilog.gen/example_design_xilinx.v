module example_design_xilinx (
    // TX Enable, if low, data can be written
    input wire FTDI_TXE_N,
    // RX Free, if low, data can be read
    input wire FTDI_RXF_N,
    // Read, if low, FTDI outputs data
    output wire FTDI_RD_N,
    // Write, if low, FPGA/ASIC drives data to the bus
    output wire FTDI_WR_N,
    // Data InOut to read or write from FTDI
    inout wire [7:0] FTDI_DATA
);
    // Parametersrs
    //---------------


    // Signaling
    //---------------


    // Assigments
    //---------------




    // Instances
    //---------------
    registerfile registerfile    (
         .FTDI_TXE_N(FTDI_TXE_N),
         .FTDI_RXF_N(FTDI_RXF_N),
         .FTDI_RD_N(FTDI_RD_N),
         .FTDI_WR_N(FTDI_WR_N),
         .FTDI_DATA(FTDI_DATA),
         .clk(),
         .res_n()
);



    // Logic
    //---------------
    


endmodule
