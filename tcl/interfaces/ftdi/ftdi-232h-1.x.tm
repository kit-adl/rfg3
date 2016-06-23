package provide odfi::rfg::interface::ftdi232h 1.0.0

package require odfi::rfg 3.0.0
package require odfi::rfg::generator::h2dl               3.0.0
package require odfi::language::nx          1.0.0
package require odfi::h2dl::stdlib 


odfi::language::nx::new ::odfi::rfg::interface::ftdi232h {

    :ftdi232hasync : ::odfi::rfg::Interface name {
        +exportToPublic
        +exportTo ::odfi::h2dl::Module ftdi
        +expose name
    
        ## Export to H2DL
        #######################
        +builder {
        
            ## IO Must be placed now
            
            ## FTDI IO 
            ##############
            #:input   FTDI_CLK
            :input   FTDI_TXE_N {
                :description set "TX Enable, if low, data can be written"
                :attribute ::odfi::rfg::h2dl external true
                
            }
            :input   FTDI_RXF_N {
                :description set "RX Free, if low, data can be read"
                :attribute ::odfi::rfg::h2dl external true
                                   
            }
            :output  FTDI_RD_N {
                :description set "Read, if low, FTDI outputs data"
                :attribute ::odfi::rfg::h2dl external true
                                    
            }
            :output  FTDI_WR_N {
                :description set "Write, if low, FPGA/ASIC drives data to the bus"
                :attribute ::odfi::rfg::h2dl external true
                                    
            }
            
            #:output  FTDI_OE_N
            
            :inout   FTDI_DATA {
                :description set "Data InOut to read or write from FTDI"
                :attribute ::odfi::rfg::h2dl external true
                
                :width set 8
                :highz "$FTDI_RD_N == 0"
                                        
            }            
            
            ## System IO
            :input clk {
                :attribute ::odfi::h2dl::clock freq 100
                
            }
            :input res_n
            
            ## Create RFG Module after Definition has been set
            :onBuildDone {

                    puts "BUILDING FTDI INterface"

                    ## Find Regsiter File 
                    ##########
                    set rf [current object]
                    if {$rf==""} {
                        error "Cannot find a Register File to add to FTDI Interface"
                    }



                    ## Return a Top Module 
                    ############

                    ## RFG interface 
                    ###############
                    set instance [:h2dl:generate]
                    
                    ## Connect System
                    ##########
                    $instance connect clk -> ${:clk}
                    $instance connect res_n -> ${:res_n}
                    
                    #set instance [:addChild [$rfgModule createInstance rfg_I]]
                    #$instance pushUpInterface
                    #$instance addChild $rfgModule
                    
                    #:addChild [$rf h2dl:toModule]
                    #set rfInterface [:lastChild]
                    #$rfInterface pushUpInterface
                    #[:addChild [[$rf h2dl:toModule] createInstance rfg_I]] pushUpInterface
                    
                    
                    ## FSM
                    ######################
                    set freq [${:clk} getAttribute ::odfi::h2dl::clock freq]
                    set clockTime [expr 1.0/($freq*pow(10,6))]
                    
                    ## Check timing!
                    ## Target tick is from spec
                    ## we will need various tick outputs
                    set targetTimeUnit [expr 1*pow(10,-9)]
                   
                    ## create counter with according size
                    #:stdlib:counter timingTickCounter {
                    ##    :overflow set true
                    #    :tick read_pulse_width [expr 30*pow(10,-9) * $targetTimeUnit/$clockTime]
                    #}
                    
                    
                    puts "Creating Implementation with input time $clockTime s"
                    
                    :fsm FTDI_READ_WRITE {

                        :register protocol0_command {
                            :width set 7
                        }
                        :register protocol0_address {
                            :width set 7
                        }
                        :register protocol0_size {
                            :width set 7
                        }

                        :state IDLE {

                            #:condition xxx READ 
                            :do {
                                #$FTDI_DATA <= 0
                            }

                            :progressOn "${:FTDI_RXF_N} == 0"

                            :state FETCH_COMMAND {

                                :entering {
                                    $protocol0_command <= ${:FTDI_DATA}
                                }
                                
                                

                                :state FETCH_ADDRESS {

                                    :state FETCH_SIZE {

                                    }
                                }
                            }
                        }
                       

                    }
                    ## EOF FSM
                    
                    ## Create case for FSM
                    $FTDI_READ_WRITE toCase [current object]
                  
            
            }
        }

    }

}

