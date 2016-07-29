module example_design_xilinx_tb ;
    // Parametersrs
    //---------------


    // Signaling
    //---------------
    reg  clk;
    reg  res_n;


    // Assigments
    //---------------




    // Instances
    //---------------
    example_design_xilinx example_design_xilinx_I    (
         .clk(clk),
         .res_n(),
         .FTDI_TXE_N(),
         .FTDI_RXF_N(),
         .FTDI_RD_N(),
         .FTDI_WR_N(),
         .FTDI_DATA()
);



    // Logic
    //---------------


endmodule
