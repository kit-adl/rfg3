`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.06.2016 13:34:37
// Design Name: 
// Module Name: nexys_demo_top
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


module nexys_demo_top(

input sysclk,
input res_n,

input  wire prog_txen,
output reg prog_siwun,

output reg [2:0] led




    );
    
    
    // LED Blink on o
    //--------------------
    // Add a litle bit of LED debugging
    // LED 3:0 are status
    //-----------------------
    // Blink LED Control
    //----------------------- 
    reg [23:0] cnt_ledreg;
   
    localparam LED_CNT_OVERFLOW = 24'd5388608;
    
    always @ (posedge sysclk or negedge res_n) begin
        if (!res_n) begin
            cnt_ledreg <= 24'd0;
            led <= 3'b110;
            prog_siwun<=1'b1;
        end else begin
        
            // Blink
            if (cnt_ledreg == LED_CNT_OVERFLOW) begin
                 cnt_ledreg <= 24'd0;
                 
                 led[0] <= ~ led[0];
                 
            end else begin
                cnt_ledreg <= cnt_ledreg + 1;
            end
            
            // LED1 is always txen
            led[1] <= prog_txen;
            
            // SIWU is always 1
            prog_siwun <= 1'b1;
        end
    end
    
    
    //-----------------------
    // EOF Blink LED Control
    //-----------------------
    
endmodule
