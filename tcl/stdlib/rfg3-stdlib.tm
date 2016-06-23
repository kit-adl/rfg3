package provide odfi::rfg::stdlib  3.0.0
package require odfi::rfg 3.0.0
package require odfi::rfg::generator::h2dl 3.0.0
package require odfi::richstream 3.0.0
package require odfi::language::nx 1.0.0

#set width 64
#puts "power of 2 for $width : [expr 2**int(ceil(log($width)/log(2)))] -> [expr 2**6] "
#exit 0

namespace eval odfi::rfg::stdlib {

    variable stdlibLocation [file dirname [file normalize [info script]]]

    ::odfi::language::Language default {

        set targetPrefix stdlib

        :fifo : ::odfi::rfg::Register name {
            +exportTo   ::odfi::rfg::Group $targetPrefix
            +mixin      ::odfi::rfg::generator::h2dl::H2DLSupport
            +var        width 8
            +var        fifoName ""

            ## After building done, maybe add a Register for control and stuff
            +builder {
                :attribute odfi::rfg::hardware rw wo
                :attribute odfi::rfg::software rw ro
                set :fifoName ${:name}
            }

            ## Use generator 
            +method generateXilinxSimpleFifo  args {
                odfi::log::info "Generating FIFO as Xilinx XCO Module"

                ## Check
                odfi::log::info "The FIFO width should be a power of 2"
                odfi::log::info "Actual width ${:width}"

                ## Get number of bits required for width, and matching power of 2 value
                set fifoWidth [expr 2**int(ceil(log(${:width})/log(2)))]
                odfi::log::info "FIFO width ${fifoWidth}"

                ## Create XCO File for the output 
                ##########
                set xcoFileContent [odfi::richstream::template::fileToString ${::odfi::rfg::stdlib::stdlibLocation}/fifo/rfg_fifo_xilinx_xco.template]
                :attribute ::odfi::h2dl sourceFile [list ${:fifoName}.xco $xcoFileContent]


                ## Create Module Instance
                ################
                set fifoModule [::odfi::h2dl::module ${:fifoName} {
                    :attribute ::odfi::h2dl blackbox true
                    :input rst {
                        :attribute ::odfi::rfg::h2dl reset true
                    }
                    :input wr_clk
                    :input rd_clk {
                        :attribute ::odfi::rfg::h2dl clock true
                    }
                    :input d_in {
                        :width set 63
                    }
                    :input wr_en 
                    :input rd_en {
                        :attribute ::odfi::rfg::h2dl read_enable true
                    }
                    :output d_out {
                        :width set 8
                        :attribute ::odfi::rfg::h2dl data true
                    }
                    :output full 
                    :output almost_full
                    :output empty
                    :output almost_empty
                    

                }]

                ## Add a Instance of this module
                set instance [:addChild [$fifoModule createInstance ${:name}]]
                #$fifoModule

            }
            
            +method useXilinxSimpleFifo  args {
                odfi::log::info "Generating FIFO as Xilinx XCO Module"

                ## Check
                odfi::log::info "The FIFO width should be a power of 2"
                odfi::log::info "Actual width ${:width}"

                ## Get number of bits required for width, and matching power of 2 value
                set fifoWidth [expr 2**int(ceil(log(${:width})/log(2)))]
                odfi::log::info "FIFO width ${fifoWidth}"
                
                if {${:width}!=${fifoWidth}} {
                    odfi::log::info "Using asymetric FIFO"
                }

                ## Create XCO File for the output 
                ##########
                #set xcoFileContent [odfi::richstream::template::fileToString ${::odfi::rfg::stdlib::stdlibLocation}/fifo/rfg_fifo_xilinx_xco.template]
               # :attribute ::odfi::h2dl sourceFile [list ${:fifoName}.xco $xcoFileContent]


                ## Create Module Instance
                ################
                set fifoModule [::odfi::h2dl::module ${:fifoName} {
                    :attribute ::odfi::h2dl blackbox true
                    :input rst {
                        :attribute ::odfi::rfg::h2dl reset true
                    }
                    :input wr_clk
                    :input rd_clk {
                        :attribute ::odfi::rfg::h2dl clock true
                    }
                    :input d_in {
                        :width set ${fifoWidth}
                    }
                    :input wr_en 
                    :input rd_en {
                        :attribute ::odfi::rfg::h2dl read_enable true
                    }
                    :output d_out {
                        :width set 8
                        :attribute ::odfi::rfg::h2dl data_out true
                    }
                    :output full 
                    :output almost_full
                    :output empty
                    :output almost_empty
                    

                }]

                ## Add a Instance of this module
                set instance [:addChild [$fifoModule createInstance ${:name}]]
                #$fifoModule

            }
            

            ## H2DL  Producer 
            +method h2dl:produce args {

                
                set childInstance [:shade odfi::h2dl::Module child 0]
                if {$childInstance!=""} {
                    return $childInstance
                }
                error "Producing H2DL on Stdlib FIFO has no default implementation"

            }

        }

    }


}


## Xilinx Stuff
##########################

odfi::language::nx::new ::odfi::rfg::xilinx {

    :fifo : ::odfi::rfg::Register name {
        +exportTo ::odfi::rfg::Group xilinx
        +mixin      ::odfi::rfg::generator::h2dl::H2DLSupport
        
        +var softReset false
        
        +method useSoftReset args {
            set :softReset true
        }
        
        ## XILINX XCI Format support
        ###########
        +method useXilinxXCIFifo xciFile {
        
            ## Checks
            #############
            if {![file exists $xciFile]} {
                odfi::log::error "Xilinx FIFO XCI $xciFile does not exist"
            }
            
            ## Create Module based on file 
            ############
            set fileContent [odfi::files::readFileContent $xciFile]
        
            puts "Done XCI Reading"
            
            ## get Name
            regexp {<spirit:instanceName>([\w_-]+)<\/spirit:instanceName>} $fileContent -> instanceName
            
            ## Prepare Module based on name 
            set module [::odfi::h2dl::module $instanceName]
            $module attribute ::odfi::h2dl blackbox true
            :addChild $module
            
            ## get depth
            regexp {<spirit:configurableElementValue spirit:referenceId="PARAM_VALUE.Output_Depth">([0-9]+)<\/spirit:configurableElementValue>} $fileContent -> depth
            :attribute ::odfi::rfg::stdlib::fifo depth $depth
            
            ## First Word through 
            set options [:spiritGetElementValue $fileContent PARAM_VALUE.Performance_Options]
            if {[string match *First_Word_Fall_Through* $options]} {
                :attribute ::odfi::rfg::stdlib::fifo fallthrough true
            }
            
            ## IOs: Find data and address length
            #######################
            set fifoReg [current object]
            
            ## One or two clocks?
            set independentClocks false 
            if {[:spiritGetElementValue  $fileContent PARAM_VALUE.Fifo_Implementation]=="Independent_Clocks_Block_RAM"} {
                set independentClocks true
            } else {
                $module input clk {
                   :attribute ::odfi::rfg::h2dl clock true                  
                }
            }
            
            ## Reset?
            if {[:spiritGetElementValue  $fileContent PARAM_VALUE.Reset_Pin]} {
                $module input rst {
                    :attribute ::odfi::rfg::h2dl reset posedge  
                    
                    if {${:softReset}} {
                        :attribute ::odfi::rfg::h2dl soft_reset true
                    }   
                         
                }
            }
            
            ## Input 
            $module input din {
                :width set [$fifoReg spiritGetElementValue $fileContent PARAM_VALUE.Input_Data_Width]
            }
            $module input wr_en {
                        
            }
            if {$independentClocks} {
                $module input wr_clk {
                  
                }
            }
            
            ## output 
            $module output dout {
                :width set [$fifoReg spiritGetElementValue $fileContent PARAM_VALUE.Output_Data_Width]
                :attribute ::odfi::rfg::h2dl data_out true     
            }
            $module input rd_en {
                :attribute ::odfi::rfg::h2dl read_enable true     
            }
            if {$independentClocks} {
                $module input rd_clk {
                  :attribute ::odfi::rfg::h2dl clock true    
                }
            }
            
            ## Full/empty
            $module output full {
            }
            $module output empty {
            }
            
            ## Almost empty
            if {[:spiritGetElementValue  $fileContent PARAM_VALUE.Almost_Empty_Flag]} {
                $module output almost_empty {
                }
            }
            
            ## Almost full
            if {[:spiritGetElementValue  $fileContent PARAM_VALUE.Almost_Full_Flag]} {
                $module output almost_full {
                }
            }
            #puts "AFULL: $almostFull"
            
            
        }
        
        +method spiritGetElementValue {content name} {
            regexp "<spirit:configurableElementValue spirit:referenceId=\"$name\">(\[\\w_-\]+)<\\/spirit:configurableElementValue>" $fileContent -> result
            
            return $result
                        
        }
        
        ## H2DL  Producer 
        +method h2dl:produce args {

            
            set childInstance [:shade odfi::h2dl::Module child 0]
            if {$childInstance!=""} {
                return $childInstance
            }
            error "Producing H2DL on Stdlib FIFO has no default implementation"

        }
        
        
    }

}
