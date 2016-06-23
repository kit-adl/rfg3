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
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module OrderSorter(
    
    input   wire            clk,
    input   wire            res_n,

    input   wire    [7:0]   ri_data,
    input   wire            ri_empty,
    output  wire             ri_read,

    output  reg    [7:0]    header,
    output  reg    [7:0]    address,
    output  reg    [15:0]   length,
    output  reg    [7:0]    value,

    //output  wire            OOrderReady
    output  reg            read,
    output  reg            write

    );

parameter s_idle = 4'b0000;
parameter s_header = 4'b0011;
parameter s_address = 4'b0101;
parameter s_length_a = 4'b0111;
parameter s_length_b = 4'b1001;
parameter s_value = 4'b1011;
parameter s_done = 4'b1100;

reg [3:0] currentstate = s_idle, nextstate;
assign ri_read = currentstate[0];

// Length counter
reg [15:0] length_counter;
wire length_counter_is_one = length_counter ==1 ;

always @(*) begin
    casex({ri_empty, length_counter_is_one, currentstate})
        {1'b0, 1'bx, s_idle}: begin
            nextstate = s_header;
        end
        {1'b0, 1'bx,s_header}: begin
            nextstate = s_address;  
        end
        {1'b0, 1'bx,s_address}: begin
            nextstate = s_length_a; 
        end
        {1'b0,1'bx, s_length_a}: begin
            nextstate = s_length_b; 
        end
        {1'b0, 1'bx,s_length_b}: begin      
            nextstate = s_value;  
        end
        {1'b1, 1'b1, s_value}: begin
            nextstate = s_idle;
        end
        {1'b0, 1'b1, s_value}: begin
           nextstate = s_idle;
        end
        {1'b1, 1'b0, s_value}: begin
            nextstate = s_value;
        end
        {1'b0, 1'b0, s_value}: begin
            nextstate = s_value;
        end
        /*{1'b0, s_done}: begin
            nextstate = s_header;
        end
        {1'b1, s_done}: begin
            nextstate = s_idle;
        end*/
        default: nextstate = s_idle;
    endcase
end

always @(posedge clk) 
begin
    if (!res_n)
    begin 
        currentstate <= 0;
        read <= 0;
        write <= 0;
        length <= 0;
        address <= 0;
        header <= 0;
        length_counter <= 0;
       // ri_read <= 0;
        value   <= 0;

    end 
    else begin

        // Next state propagation only on input data not empty until value
        if (!ri_empty || (currentstate==s_value && !header[0]))
        begin
            currentstate <= nextstate;
        end 

        // Data path for header->length states
        if (!ri_empty) begin 
        
            // Get Data based on state 
            if (currentstate==s_length_a)
            begin
                length[15:8] <= ri_data;
                //ri_read <= 1;
            end 
            else if (currentstate==s_length_b)
            begin
                length[7:0] <= ri_data;
                length_counter <= {length[15:8],ri_data};
                //ri_read <= 1;
            end 
            else if (currentstate==s_address)
            begin
                address <= ri_data;
                //ri_read <= 1;
            end 
            else if (currentstate==s_header)
            begin
                header <= ri_data;
                //ri_read <= 1;
            end 
            else if (currentstate==s_value)
            begin

                /*read <= ~header[0] ;
                write <= header[0];
                value <= ri_data;
                length_counter <= length_counter - 1;*/

                // Value State behavior depends on Read or Write
                /*if (~header[0]) 
                begin

                end */
               
            end 
            else begin 
                //ri_read <= 0;
            end 


        end
        else begin
            //read <= 0;
            //write <= 0;
        end

        // When in value, and write, progress on data not empty
        // When in value and read, then just ignore data not empty
        if (!ri_empty && header[0] && currentstate==s_value) 
        begin
            //read <= ~header[0] ;
            write <= header[0];
            value <= ri_data;
            length_counter <= length_counter - 1;
        end
        else if (~header[0] && currentstate==s_value) 
        begin
            // Read case
            read <= ~header[0] ;
            length_counter <= length_counter - 1;
        end
        else begin 
            read <= 0;
            write <= 0;
        end 
        
        
        
        
    end 
    
end


    
    
    
endmodule
