package provide odfi::rfg::interface::epp 1.0.0

package require odfi::rfg 3.0.0
package require odfi::rfg::generator::h2dl               3.0.0
package require odfi::language::nx          1.0.0
package require odfi::h2dl::stdlib 



namespace eval ::odfi::rfg::interface::epp {

    variable location [file dirname [file normalize [info script]]]
    
    #variable ftdi_tb_functions [file normalize $location/simulation/ftdi_tb_functions.v]
}


odfi::language::nx::new ::odfi::rfg::interface::epp {


    :interface : ::odfi::rfg::Interface name {
        +exportToPublic
        +exportTo ::odfi::h2dl::Module epp


        +builder  {

             ## Merge Verilog from reference Verilog Implementation
            set importedTopContent [:verilog:merge ${::ftdi::kit::rfg::location}/ftdi_interface_top.v]
  
            ## Add Companion sources 
            :attribute ::odfi::verilog companions [list  ${::ftdi::kit::rfg::location}/ftdi_interface_control_fsm.v ${::ftdi::kit::rfg::location}/OrderSorter.v ${::ftdi::kit::rfg::location}/async_fifo_ftdi/async_fifo_ftdi.xci]
    

        }

    }


}