

 

package require odfi::rfg 3.0.0
package require odfi::rfg::stdlib 3.0.0
package require odfi::rfg::generator::h2dl 3.0.0

odfi::rfg::registerfile example_rf {

    :group info {

        repeat 2 {
            :register scratchpad$i {

                :field value {
            
                    :width set 8
                    :reset set 8'd0
                    :attribute ::odfi::rfg hardware  rw
                    :attribute ::odfi::rfg software  rw
                   
                }
            }

        }

        range 2 4 {
            :register scratchpad$i {
            
            
                :attribute ::odfi::rfg hardware rw
                
            }

        }
        
        :register readwritetest {
        
            :field a {
            
            }
            
            :field b {
                :attribute ::odfi::rfg hardware rw
            }
            
            :field c {
            
            }
            
            :field d {
                :attribute ::odfi::rfg hardware rw
            }
        }

        :register global {
            :description set "Glocal ASIC Control Register"

            :field test {
                :description set "Enable or Disable the Test mode with pattern injection"
            }
        }
        :register id {
            :description set "A runtime ID to be set, non persistent"
        }
        
        return
        :ignore {
        
            :stdlib:fifo test_fifo {
                :width set 48
                :useXilinxSimpleFifo
                
            }
        }

    }

}

[$example_rf h2dl:generate] verilog:produce [file dirname [info script]]/verilog.gen
