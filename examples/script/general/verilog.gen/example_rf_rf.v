module example_rf_rf (
    input wire clk,
    input wire res_n,
    input wire read,
    output reg [7:0] read_data,
    input wire write,
    input wire [7:0] write_data,
    output reg done,
    input wire [2:0] address,
    output wire [7:0] info_scratchpad0_value,
    output wire [7:0] info_scratchpad1_value,
    output wire [7:0] info_scratchpad2_value,
    output wire [7:0] info_scratchpad3_value,
    output wire info_global_test,
    output wire [7:0] info_id_id
);
              // Parametersrs
              //---------------


              // Signaling
              //---------------
              reg  [7:0] info_global;
              reg  [7:0] info_id;
              reg  [7:0] info_scratchpad0;
              reg  [7:0] info_scratchpad1;
              reg  [7:0] info_scratchpad2;
              reg  [7:0] info_scratchpad3;


              // Assigments
              //---------------
              assign info_scratchpad0_value = info_scratchpad0[7:0];
              assign info_scratchpad1_value = info_scratchpad1[7:0];
              assign info_scratchpad2_value = info_scratchpad2[7:0];
              assign info_scratchpad3_value = info_scratchpad3[7:0];
              assign info_global_test = info_global[0:0];
              assign info_id_id = info_id[7:0];




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
                             if (address == 2 && read == 1) begin

                                  read_data <= info_scratchpad2;
                                  done <= 1;

                             end
                             if (address == 3 && read == 1) begin

                                  read_data <= info_scratchpad3;
                                  done <= 1;

                             end
                             if (address == 4 && read == 1) begin

                                  read_data <= info_global;
                                  done <= 1;

                             end
                             if (address == 5 && read == 1) begin

                                  read_data <= info_id;
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

                   end

              end

              
              // Posedge
              //------------------------
              always @(posedge clk or negedge res_n) begin

                   if (~ res_n) begin

                        info_scratchpad2 <= 0;

                   end
                   else begin

                        if (address == 2 && write == 1) begin

                             info_scratchpad2 <= write_data;

                        end

                   end

              end

              
              // Posedge
              //------------------------
              always @(posedge clk or negedge res_n) begin

                   if (~ res_n) begin

                        info_scratchpad3 <= 0;

                   end
                   else begin

                        if (address == 3 && write == 1) begin

                             info_scratchpad3 <= write_data;

                        end

                   end

              end

              
              // Posedge
              //------------------------
              always @(posedge clk or negedge res_n) begin

                   if (~ res_n) begin

                        info_global <= 0;

                   end
                   else begin

                        if (address == 4 && write == 1) begin

                             info_global <= write_data;

                        end

                   end

              end

              
              // Posedge
              //------------------------
              always @(posedge clk or negedge res_n) begin

                   if (~ res_n) begin

                        info_id <= 0;

                   end
                   else begin

                        if (address == 5 && write == 1) begin

                             info_id <= write_data;

                        end

                   end

              end



endmodule
