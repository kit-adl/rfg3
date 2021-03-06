`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.03.2016 11:15:52
// Design Name: 
// Module Name: OrderSorter
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
//			0.02 - new state machine (rejected)
//			0.03 - extended state machine; reading also working (29.06.16)
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module OrderSorter(
    
    input   wire           clk,				//clock input
    input   wire           res_n,			//reset

    input   wire   [7:0]   ri_data,			//data input from FTDI (FIFO)
    input   wire           ri_empty,		//no data flag from FTDI (FIFO)
    output  wire           ri_read,			//read enable for FTDI (FIFO)

    output  reg    [7:0]   header,			//latest command header
    output  reg    [7:0]   address,			//latest command address
    output  reg    [15:0]  length,			//latest command length (not length remaining)
    output  reg    [7:0]   value,			//latest command value byte (on write)

    output  wire           read,			//read enable for input to FTDI FIFO
    output  reg            write,			//write enable for local register in the FPGA
    output  wire   [3:0]   state			//debug output of current state machine state
);
    
assign 	   state 			= currentstate;

parameter s_idle 			= 4'b0000;
parameter s_header 			= 4'b0001;
parameter s_address 		= 4'b0011;
parameter s_length_a 		= 4'b0101;
parameter s_length_b 		= 4'b0111;
parameter s_starttransmit   = 4'b1110;
parameter s_value 			= 4'b1011;

reg [3:0] currentstate 		= s_idle;
reg [3:0] nextstate;
assign 	  ri_read			= currentstate[0] && (currentstate != s_value || header[0]); 
assign 	  read				= ((currentstate == s_value) && (~header[0]) && length_counter != 0);

// Length counter
reg [15:0] length_counter;
wire length_counter_is_one = (length_counter == 1 || length_counter == 0); 

always @(*) begin
    casex({ri_empty, length_counter_is_one, currentstate})
        {1'b0, 1'bx, s_idle}:			nextstate = s_header;
        {1'b0, 1'bx, s_header}:			nextstate = s_address;  
        {1'b0, 1'bx, s_address}: 		nextstate = s_length_a; 
        {1'b0, 1'bx, s_length_a}:		nextstate = s_length_b; 
        {1'b0, 1'bx, s_length_b}:  		nextstate = s_starttransmit;
        {1'bx, 1'bx, s_starttransmit}:	nextstate = s_value;
        {1'bx, 1'b1, s_value}:			nextstate = s_idle;
        {1'bx, 1'b0, s_value}: 			nextstate = s_value;
        default: 						nextstate = s_idle;
    endcase
end

always @(posedge clk) 
begin
    if (!res_n)
    begin 
        currentstate <= 0;
        //read <= 0;
        write <= 0;
        length <= 0;
        address <= 0;
        header <= 0;
        length_counter <= 0;
        value   <= 0;

    end 
    else begin

        // Next state propagation only on input data not empty until value
        if (!ri_empty || currentstate == s_starttransmit || (currentstate==s_value && !header[0]))
        begin
            currentstate <= nextstate;
        end 

        if (!ri_empty) begin 
        
			// Get Data based on state 
            case(currentstate)
				s_header:
					header 			<= ri_data;
				s_address:
					address 		<= ri_data;
				s_length_a:		
					length[15:8] 	<= ri_data;
				s_length_b: begin
					length[7:0] 	<= ri_data;
					length_counter 	<= {length[15:8],ri_data};
					//read <= (~header[0] && ({length[15:8],ri_data} != 16'b0));	//on read command and non-zero read length
						//to compensate for the time difference caused by the difference between wire and register			
				end
			endcase
        end

		//-- Write Case --
		if (!ri_empty && header[0] && currentstate == s_value) 
        begin
            //read <= ~header[0] ;
            write <= 1;
            value <= ri_data;
            if(length_counter > 0)
                length_counter <= length_counter - 1;
        end
		//-- Read Case --
        else if (currentstate==s_value && ~header[0]) 
        begin
            //read <= 1;
            if(length_counter > 0)
                length_counter <= length_counter - 1;
        end
		//if not in write value state: do nothing
        else begin 
            //read <= 0;
            write <= 0;
        end 
           
    end 
    
end
   
endmodule
