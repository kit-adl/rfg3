package provide odfi::rfg::generator::h2dl      3.0.0
package require odfi::rfg                       3.0.0
package require odfi::h2dl             2.0.0
package require odfi::h2dl::verilog    2.0.0

namespace eval odfi::rfg::generator::h2dl {

    nx::Trait create H2DLSupport {

    }

    odfi::language::Language default {

        :H2DLGenerator {
            +exportTo ::odfi::rfg::Interface -prefix h2dl

            +method generate args {
                puts "CREATE H2DL IN INTERFACE"

                if {[:isClass odfi::rfg::Interface]} {
                    :mapAddresses
                }
                ## Create Module 
                set module [:toModule]

                ## Add Instance 
                set instance [:addChild [$module createInstance rfg_I]]

                ## Push Up Registerss Interface
                $instance pushUpInterface
               
            }

            ## Create an H2DL Module for the register definitinos 
            +method toModule args {

                ## Get Interface
                set interface [current object]
                if {![$interface isClass ::odfi::rfg::Interface]} {
                    set interface [[:shade ::odfi::rfg::Interface getParentsRaw] at 0]
                    if {$interface==""} {
                        error "Cannot Produce H2DL Module from Group if no interface is in hierarchy"
                    } 
                }
                
                ## Get Register Size 
                set registerSize [$interface registerSize get]

                ## Get Size 
                set rfSize [expr int(ceil([:getAttribute odfi::rfg::address size 0]/2)) ]

                set rf [current object]

                odfi::h2dl::module [:name get]_rf {
                    
                    ## SW IO 
                    :input clk 
                    :input res_n
                    :input  read
                    :output read_data {
                        :width set $registerSize
                    }
                    :input  write
                    :input  write_data {
                        :width set $registerSize
                    }
                    :output done
                    :input  address {
                        :width set $rfSize
                    }

                    ## Map Register Definitions to Register or something else 
                    ##############

                    $rf walkDepthFirstPreorder -level 1 {

                        if {[$node isClass odfi::rfg::Register]} {

                            ## Create Default Register , or use provided H2DL result 
                            if {[$node isClass odfi::rfg::generator::h2dl::H2DLSupport]} {
                                set h2dlNode [$node h2dl:produce]
                                :addChild $h2dlNode

                                puts "Supported H2Dl Register created module: [$h2dlNode info class]"
                                ## If the provided node is a module, then we can find special IOs for Interface 
                                if {[$h2dlNode isClass ::odfi::h2dl::Module]} {
                                    $h2dlNode shade odfi::h2dl::IO eachChild {
                                        {io i} => 

                                            puts "Found and IO: [$io name get] -> [$io hasAttribute ::odfi::rfg::h2dl reset]"
                                            ## Connect IOs with supported attribute 
                                            ## Other IOs are just pushed_up
                                            if {[$io hasAttribute ::odfi::rfg::h2dl clock]} {
                                                $io connection $clk
                                            } elseif {[$io hasAttribute ::odfi::rfg::h2dl reset]} {
                                                $io connection $res_n 
                                            } elseif {[$io hasAttribute ::odfi::rfg::h2dl read_enable]} {
                                                $io connection $read 
                                            } else {
                                                $io pushUp [$node getHierarchyName]
                                            }
                                    }
                                }

                            } else {

                                ## Add Std Reg 
                                set h2dlReg [:register [$node getHierarchyName] {
                                    :width set $registerSize

                                    ## Each Field creates an output 
                                    $node shade ::odfi::rfg::Field eachChild {
                                        #:wire [:name get]_[$it name get]
                                        set bitmap [uplevel 2 [list :bitMap 0 [$it name get]]]
                                        $bitmap apply {
                                            #puts "Inside: [:info class]"
                                            #${:wire} toOutput
                                        }
                                    }
                                }]

                            }
                        }
                    }

                    return

                    ## Register fields make up the IOs
                    $rf walkDepthFirstPreorder -level 1 {

                        if {[$node isClass odfi::rfg::Field]} {

                            ## Output For hardware access
                            set hReadWrite [$node getAttribute odi::rfg::hardware rw "rw"]
                            :output [$node shade { return [expr [$it isClass odfi::rfg::Description] && ![$it isClass odfi::rfg::RegisterFile] ]} formatHierarchyString {$it name get} _]_[$node name get] {
                                :width set [$node width get]
                            }
                            #:register [$node shade { return [expr [$it isClass odfi::rfg::Description] && ![$it isClass odfi::rfg::RegisterFile] ]} formatHierarchyString {$it name get} _]_[$node name get] {
                            #    :width set [$node width get]
                            #}

                        }
                        return true
                    } 

                    ## Instances
                    #################


                    ## Read 
                    ####################
                    :posedge $clk {
                    #    :reset $res_n
                        :case {$read $address} {
                    
                            $rf walkDepthFirstPreorder -level 1 {
                                if {[$node isClass odfi::rfg::Register]} {
                                    :on [$node name get] {
                                        
                                    }
                                }
                                return true
                            }

                        }
                   }

                    ## Write 
                    ####################
                    :posedge $clk {
  #                      
                    }

                }

                

            }
        }


    }

    puts "ADDDING TO INTERFACE"

    #::odfi::rfg::Interface domain-mixins add odfi::rfg::generator::h2dl::H2DLGenerator -prefix h2dl


}
