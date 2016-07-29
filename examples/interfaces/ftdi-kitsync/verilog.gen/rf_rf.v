module rf_rf (
    input wire clk,
    input wire res_n,
    input wire read,
    output reg [7:0] read_data,
    input wire write,
    input wire [7:0] write_data,
    output reg done,
    input wire address
);
              // Parametersrs
              //---------------


              // Signaling
              //---------------


              // Assigments
              //---------------




              // Instances
              //---------------


              // Logic
              //---------------
              
              // Posedge
              //------------------------
              always @(posedge clk) begin

                   if (~ res_n) begin

                        read_data <= 0;
                        done <= 0;

                   end
                   else begin

                        if (read == 1) begin

                        end
                        else begin

                             done <= 0;

                        end

                   end

              end



endmodule
