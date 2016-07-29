module example_rf (
    input wire clk,
    input wire res_n,
    input wire read,
    output reg [7:0] read_data,
    input wire write,
    input wire [7:0] write_data,
    output reg done,
    input wire address,
    output reg [7:0] info_scratchpad0,
    input wire info_scratchpad0_hw_write,
    input wire [7:0] info_scratchpad0_hw,
    output reg [7:0] info_scratchpad1,
    input wire info_scratchpad1_hw_write,
    input wire [7:0] info_scratchpad1_hw
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
                   always @(posedge clk or negedge res_n) begin

                        if (~ res_n) begin

                             read_data <= 0;
                             done <= 0;

                        end
                        else begin

                             if (read == 1) begin

                                  if (address == 0 && read == 1) begin

                                       read_data <= info_scratchpad0;
                                       done <= 1;

                                  end
                                  if (address == 1 && read == 1) begin

                                       read_data <= info_scratchpad1;
                                       done <= 1;

                                  end

                             end
                             else begin

                                  done <= 0;

                             end

                        end

                   end

                   
                   // Posedge
                   //------------------------
                   always @(posedge clk or negedge res_n) begin

                        if (~ res_n) begin

                             info_scratchpad0 <= 0;

                        end
                        else begin

                             if (address == 0 && write == 1) begin

                                  info_scratchpad0 <= write_data;

                             end
                             else if (info_scratchpad0_hw_write == 1) begin

                                  info_scratchpad0 <= info_scratchpad0_hw;

                             end

                        end

                   end

                   
                   // Posedge
                   //------------------------
                   always @(posedge clk or negedge res_n) begin

                        if (~ res_n) begin

                             info_scratchpad1 <= 0;

                        end
                        else begin

                             if (address == 1 && write == 1) begin

                                  info_scratchpad1 <= write_data;

                             end
                             else if (info_scratchpad1_hw_write == 1) begin

                                  info_scratchpad1 <= info_scratchpad1_hw;

                             end

                        end

                   end



endmodule
