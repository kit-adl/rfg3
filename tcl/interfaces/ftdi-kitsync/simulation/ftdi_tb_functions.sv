// FTDI Model
//--------------------
logic FTDI_CLK;
logic FTDI_TXE_N;
logic FTDI_RXF_N = 1;
logic FTDI_RD_N;
logic FTDI_OE_N;
logic FTDI_WR_N;

wire  [7:0] FTDI_DATA;
//reg   [7:0] FTDI_DATA_REG; 
 
// Queue of 8 bit logic
logic [7:0] ftdi_out_data[$];  
//assign FTDI_RXF_N = !(ftdi_out_data.size > 0);

assign FTDI_DATA = (FTDI_OE_N==0) ? 0 ftdi_out_data[0] : 8'hzz;

// FTDI Clock for now 60Mhz
always begin 
    #8.3 FTDI_CLK <= ~FTDI_CLK;
end

initial begin 

    // Reset 
    wait(res_n == 0);
    FTDI_CLK = 0;
    FTDI_TXE_N = 0;
    //FTDI_RXF_N = 1;
    
    // EOF reset 
    wait(res_n == 1);


    // Wait for device to ask for data
    //------------------
    //@(negedge FTDI_RD_N);
    


end 

always @(posedge FTDI_RD_N)
begin
    


    //if (FTDI_RD_N==0)
    //begin 
        //ftdi_out_data.pop_front();
    //end

end

// RXF
always @(posedge FTDI_CLK)
begin
    if (res_n==1)
    begin 

         


        // RDN and data pop
        if (FTDI_RD_N==0)
        begin
             ftdi_out_data.pop_front();
        end

         // RX F 
         if(ftdi_out_data.size>0) 
         begin
            FTDI_RXF_N <= 0; 
         end 
         else begin
            FTDI_RXF_N <= 1; 
        end
    end
end 

task ftdi_put;
    input [7:0] data;

    ftdi_out_data.push_back(data);


endtask 