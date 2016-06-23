

 

package require odfi::rfg 3.0.0
package require odfi::rfg::stdlib 3.0.0
package require odfi::rfg::generator::h2dl 3.0.0
package require odfi::rfg::generator::caddress 1.0.0

odfi::rfg::registerfile example_rf {

    :group info {

        repeat 2 {
            :register scratchpad$i {

                :attribute ::odfi::rfg hardware rw
            }

        }


        :xilinx:fifo test_fifo {
            
            ## To be used before XCI read
            :useSoftReset
            :useXilinxXCIFifo [file dirname [info script]]/ip/fifo_generator_0/fifo_generator_0.xci
            
        }
        

    }

}

[$example_rf h2dl:generate] verilog:produce [file dirname [info script]]/verilog.gen
$example_rf caddress:generate [file dirname [info script]]/addresses.h RFG_