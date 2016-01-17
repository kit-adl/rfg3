package provide odfi::rfg::generator::h2dl      3.0.0
package require odfi::rfg                       3.0.0
package require odfi::h2dl             2.0.0
package require odfi::h2dl::verilog    2.0.0

namespace eval odfi::rfg::generator::h2dl {


    odfi::language::Language default {

        :H2DLGenerator {

            ## Create an H2DL Module 
            +method toModule args {

                ## Get Interface
                set interface [[:shade ::odfi::rfg::Interface getParentsRaw] at 0]
                if {$interface==""} {
                    error "Cannot Produce H2DL Module from Group if no interface is in hierarchy"
                }

                ## Get Size 
                set rfSize [expr int(ceil([:getAttribute odfi::rfg::address size 0]/2)) ]

                set rf [current object]

                odfi::h2dl::module [:name get]_rf {
                    
                    ## SW IO 
                    :input clk 
                    :input res_n
                    :input  read
                    :output read_data {
                        :width set [$interface registerSize get]
                    }
                    :input  write
                    :input  write_data {
                        :width set [$interface registerSize get]
                    }
                    :output done
                    :input  address {
                        :width set $rfSize
                    }



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

    ::odfi::rfg::Group domain-mixins add odfi::rfg::generator::h2dl::H2DLGenerator -prefix h2dl


}
