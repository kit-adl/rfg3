

 

package require odfi::rfg 3.0.0
package require odfi::rfg::stdlib 3.0.0
package require odfi::rfg::generator::h2dl 3.0.0

package require odfi::rfg::interface::ftdi232h 1.0.0

odfi::h2dl::module example_design_xilinx {
    
    ## System 
    :input clk 
    :input res_n
    
    
    ## Create FTDI RFG
    :ftdi:ftdi232hasync registerfile {
    
        :registerFile example_rf {
        
            :group info {
        
                repeat 2 {
                    :register scratchpad$i {
        
                        :attribute ::odfi::rfg hardware rw
                    }
        
                }
        
        
                #:xilinx:fifo test_fifo {
                #    :useXilinxXCIFifo [file dirname [info script]]/ip/fifo_generator_0/fifo_generator_0.xci
                #    
                #}
                
        
            }
        
        }
    }
    ## EOF RF
    
    $registerfile pushExternal
    $registerfile connect clk -> $clk
    $registerfile connect res_n -> $res_n

}

#$example_design_xilinx verilog:produce [file dirname [info script]]/verilog.gen


