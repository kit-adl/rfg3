package provide odfi::rfg::interface::ftdi232hkitsync 1.0.0

package require odfi::rfg 3.0.0
package require odfi::rfg::generator::h2dl               3.0.0
package require odfi::language::nx          1.0.0
package require odfi::h2dl::stdlib 




namespace eval ::ftdi::kit::rfg {

    variable location [file dirname [file normalize [info script]]]
    
    variable ftdi_tb_functions [file normalize $location/simulation/ftdi_tb_functions.v]
}

odfi::language::nx::new ::ftdi::kit::rfg {

    :sync : ::odfi::rfg::Interface name {

        +exportToPublic
        +exportTo ::odfi::h2dl::Module ftdi232hkit
        +expose name
        
        +var outputOrderSorter false
        
        +builder {
              
            ## Prepare IO and base structure    
            puts "Sync building"
            
            ## Merge Verilog from reference Verilog Implementation
            set importedTopContent [:verilog:merge ${::ftdi::kit::rfg::location}/ftdi_interface_top.v]
  
            ## Add Companion sources 
            :attribute ::odfi::verilog companions [list  ${::ftdi::kit::rfg::location}/ftdi_interface_control_fsm.v ${::ftdi::kit::rfg::location}/OrderSorter.v ${::ftdi::kit::rfg::location}/async_fifo_ftdi/async_fifo_ftdi.xci]
    
            ## Finishing internal connection to RFG after regenerate done, meaning after the user has setup the RFG            
            :onRegenerateDone {

               
                ## Generate H2DL 
                ## Make RTL View 
                ## Generate creates the RFG Module, instantiate it in this module, and return the instance

               # set rfgInstance [:findChildByAttribute ::odfi::rfg generated true]
               set rfgInstance [:h2dl:generate]
              
                ## Connections of interface's regs for control to the register file module
                :wire rfg_read_done 
                :wire rfg_read_data {
                    :width set 8
                }
                [$rfgInstance findChildByProperty name clk]  connection clk
                [$rfgInstance findChildByProperty name res_n] connection res_n 
                [$rfgInstance findChildByProperty name read_data] connection $rfg_read_data
                [$rfgInstance findChildByProperty name write_data] connection ordersorter_value
                [$rfgInstance findChildByProperty name done] connection $rfg_read_done
                [$rfgInstance findChildByProperty name read] connection ordersorter_read
                [$rfgInstance findChildByProperty name write] connection ordersorter_write
                [$rfgInstance findChildByProperty name address] connection ordersorter_address


                ## If OrderSorter output is used, propagate the order sorter outputs
                if {${:outputOrderSorter}} {
                    
                    $importedTopContent removeCommentSection ossig
                
                    :output  ordersorter_header {
                        :width set 8
                    }     
                    :output ordersorter_address {
                        :width set 8
                    } 
                    :output ordersorter_length {
                        :width set 16
                    }
                    :output ordersorter_value {
                        :width set 8
                    } 
                    :output   ordersorter_read
                    :output   ordersorter_write
                }
                
                ## Push Up all data io
                #[$rfgInstance findChildrenByAttributeNot ::odfi::rfg::generator::h2dl internal true] foreach {
                #    puts "Found IO to push"
                    #$it pushUp
                #}


            }
            


            
        }

        #+method createInstance name {
        #    set res [next]
        #    puts "OVERRIDEN CREATE INSTANCE $name"
        #}

        +method doCreateInstance args {
            set r [next]
            puts "OVERRIDEN DO CREATE INSTANCE $r"
            $r onParentAdded {
                
                set newParent [[:getParentsRaw] at end]
                #puts "Added SYNC FTDI to parent $newParent"
                if {[$newParent isClass ::odfi::h2dl::Module]} {

                    :shade odfi::h2dl::IO eachChild {

                        if {[string match "FTDI*" [$it name get]]} {
                            $it pushUp
                        }
                    }
                    
                }


            }
            return $r
        }

        ## 
        #+method createInstance name {
         #   set res [next]
          #  puts "OVERRIDEN CREATE INSTANCE $res"
        #}

        +method upInterface args {

        }

    }

}

