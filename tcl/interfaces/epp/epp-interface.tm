package provide odfi::rfg::interface::epp 1.0.0

package require odfi::rfg 3.0.0
package require odfi::rfg::generator::h2dl               3.0.0
package require odfi::language::nx          1.0.0
package require odfi::h2dl::stdlib 



namespace eval ::odfi::rfg::interface::epp {

    variable location [file dirname [file normalize [info script]]]
    

}


odfi::language::nx::new ::odfi::rfg::interface::epp {


    :interface : ::odfi::rfg::Interface name {
        +exportToPublic
        +exportTo ::odfi::h2dl::Module epp
        +expose name

        +builder  {

             ## Merge Verilog from reference Verilog Implementation
            set importedTopContent [:verilog:merge ${::odfi::rfg::interface::epp::location}/epp_interface.v]
  
            
            ## Finishing internal connection to RFG after regenerate done, meaning after the user has setup the RFG            
            :onRegenerateDone {

                ## Generates and HDL Decoder for RFG and returns a module instance
                ########
                set rfgInstance [:h2dl:generate]

                ## Connect RFD Harware IO to local state machine input/outputs
                [$rfgInstance findChildByProperty name clk]  connection clk
                [$rfgInstance findChildByProperty name res_n] connection res_n 
                [$rfgInstance findChildByProperty name read_data] connection rfs_read_data
                [$rfgInstance findChildByProperty name write_data] connection rfs_write_data
                [$rfgInstance findChildByProperty name done] connection rfs_access_complete
                [$rfgInstance findChildByProperty name read] connection rfs_read
                [$rfgInstance findChildByProperty name write] connection rfs_write
                [$rfgInstance findChildByProperty name address] connection rfs_address
            }

        }

    }


}