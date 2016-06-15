package provide odfi::rfg::generator::h2dl      3.0.0
package require odfi::rfg                       3.0.0
package require odfi::h2dl             2.0.0
package require odfi::h2dl::verilog    2.0.0

namespace eval odfi::rfg::generator::h2dl {

    nx::Class create H2DLSupport {

        :public method h2dl:produce args {
            return [next]
        }
    }

    odfi::language::Language default {

        :H2DLGenerator {
            +exportTo ::odfi::rfg::Interface h2dl

            +method generate {{module_closure ""}} {
                puts "CREATE H2DL IN INTERFACE"

                #if {[:isClass odfi::rfg::Interface]} {
                #    :mapAddresses
                #}

                ## Create Module 
                set module [:toModule2]
                $module apply $module_closure 
                puts "Returned value: [$module info class]"

                ## Add Instance 
                set instance [:addChild [$module createInstance rfg_I]]
                :addChild $instance
                ##$instance addChild $module

                ## Push Up Registerss Interface
                $instance pushUpInterface

                return $instance
               
            }


            ## Create an H2DL Module for the register definitinos 
            +method toModule2 args {

                ## Get Interface
                set interface [current object]
                if {![$interface isClass ::odfi::rfg::Interface]} {
                    set interface [[:shade ::odfi::rfg::Interface getParentsRaw] at 0]
                    if {$interface==""} {
                        odfi::log::warn "Not Interface found in RFG hierarchy, using default register width of 8"
                        set registerSize 8
                        #error "Cannot Produce H2DL Module from Group if no interface is in hierarchy"
                    } else {
                        ## Get Register Size
                        set registerSize [$interface registerSize get]
                    }


                } else {
                    ## Get Register Size
                    set registerSize [$interface registerSize get]
                }



                

                ## Get RF 
                if {[[current object] isClass  odfi::rfg::RegisterFile]} {
                    set rf [current object]
                } else {
                    set rf [:shade odfi::rfg::RegisterFile firstChild]
                }
                
                if {$rf==""} {
                    odfi::log::error "Generating Interface without Register File" 
                    return
                }
                


                ## Map to addresses if necessary
                if {![$rf hasAttribute ::odfi::rfg::address absolute]} {
                    $rf mapAddresses
                }


                ## Get Size
                set rfSize [$rf getAttribute ::odfi::rfg::address size 1]

                ## Create Module
                set moduleName [$rf name get]
                if {![string match "*_rf" $moduleName]} {
                    set moduleName "${moduleName}_rf"
                }
                set rfgModule [odfi::h2dl::module $moduleName]
                
                $rfgModule apply {

                    ## SW IO
                    :input clk {
                        :attribute ::odfi::rfg::generator::h2dl internal true
                    }
                    :input res_n {
                        :attribute ::odfi::rfg::generator::h2dl internal true
                        :attribute ::odfi::h2dl reset $clk
                    }
                    :input  read {
                        :attribute ::odfi::rfg::generator::h2dl internal true
                    }
                    :output read_data {
                        :width set $registerSize
                        :attribute ::odfi::rfg::generator::h2dl internal true                        
                    }
                    :input  write {
                        :attribute ::odfi::rfg::generator::h2dl internal true
                    }
                    :input  write_data {
                        :width set $registerSize
                        :attribute ::odfi::rfg::generator::h2dl internal true                        
                    }
                    :output done {
                        :attribute ::odfi::rfg::generator::h2dl internal true
                    }
                    :input  address {
                        :width set $rfSize
                        :attribute ::odfi::rfg::generator::h2dl internal true                        
                    }


                    ## Create Read posedge  
                    set readIf ""
                    set readElse ""
                    set readPosedge [:posedge $clk {
                        
                        :if {! $res_n} {
                            $read_data <= 0
                            $done <= 0
                        }
                        :else {
                            set readIf [:if {$read == 1} {

                            } ]
                            :else {
                                $done <= 0;
                            }
                        }
                        
                    } ]


                    ## Map Register Definitions to Register or a sub module for example
                    ## Also create a posedge clock for this register
                    ##############
                    $rf walkDepthFirstPreorder -level 1 {

                        if {[$node isClass odfi::rfg::Register]} {

                            set addWrite   true 
                            set addRead    true
                            set addHWWrite false

                            ## Create Default Register , or use provided H2DL result
                            if {[$node isClass odfi::rfg::generator::h2dl::H2DLSupport]} {

                                set h2dlNode [$node h2dl:produce [current object]]
                                :addChild $h2dlNode

                                puts "Supported H2Dl Register created: [$h2dlNode info class]"
                                ## If the provided node is a module, then we can find special IOs for Interface
                                if {[$h2dlNode isClass ::odfi::h2dl::Module]} {

                                    set addWrite false 
                                    set addRead  false

                                    set h2dlModuleInstanceForReg [$h2dlNode createInstance [$node getHierarchyName]]
                                    :addChild $h2dlModuleInstanceForReg
                                    
                                    ## Look through IOs and make connections
                                    $h2dlModuleInstanceForReg shade odfi::h2dl::IO eachChild {
                                        {io i} =>

                                            puts "Found and IO: [$io name get] -> [$io hasAttribute ::odfi::rfg::h2dl reset]"
                                            ## Connect IOs with supported attribute
                                            ## Other IOs are just pushed_up
                                            if {[$io hasAttribute ::odfi::rfg::h2dl clock]} {
                                                $io connection $clk
                                            } elseif {[$io hasAttribute ::odfi::rfg::h2dl reset]} {
                                                $io connection $res_n
                                            } elseif {[$io hasAttribute ::odfi::rfg::h2dl read_enable]} {

                                                ## Read is controled by test case
                                                set read_enable [$rfgModule register [$node getHierarchyName]_read_enable]
                                                $io connection $read_enable
                                                
                                                ## This module's read is controled separately from other regs to make sure read_enable is always 
                                                ## reset correctly
                                                $readPosedge apply {
                                                    :if { ($address == [$node getAttribute ::odfi::rfg::address absolute]) && ($read == 1) } {
                                                    
                                                        ## Map Read data to module out
                                                        set dataOutIO [$h2dlModuleInstanceForReg shade odfi::h2dl::Output findFirstChild {$it hasAttribute ::odfi::rfg::h2dl data_out}]
                                                        if {$dataOutIO==""} {
                                                            odfi::log::error "Cannot Create read for reg with Module implementation [$node getHierarchyName] because no IO has the attribute ::odfi::rfg::h2dl data_out" 
                                                        } else {
                                                            #set targetSignal [$dataOutIO pushUp [$node getHierarchyName]]
                                                            set targetSignal [$rfgModule shade odfi::h2dl::IO findChildByProperty name [$node getHierarchyName]_[$dataOutIO name get]]
                                                            #set targetSignal [$rfgModule output [$node getHierarchyName]_[$dataOutIO name get]]
                                                            #$dataOutIO connection $targetSignal
                                                        }
                                                        
                                                        $read_data <= $targetSignal
                                                        
                                                        ## set read to 1
                                                        $read_enable <= 1
                                                        
                                                        ## Set Done 
                                                        #$done <= 1
                                                    }
                                                    :else {
                                                        ## set read to 0
                                                        $read_enable <= 0
                                                    }
                                                }
                                                
                                                
                                                


                                            } elseif {![$io hasConnection]} {
                                                $io pushUp [$node getHierarchyName]
                                            }
                                    }
                                    ## EOF IO Connections
                                    
                                    
                                    
                                    
                                }
                                ## EOF if Result is a module

                                ## If it is a write section 
                                if {[$h2dlNode hasAttribute ::odfi::rfg writeSection]} {

                                    set addWrite false

                                }

                            } 

                            if {$addWrite || $addRead} {

                                ## Check HW Rights
                                ############
                                if {[$node attributeMatch ::odfi::rfg hardware *rw*]} {
                                    puts "ADDING HW WRITE"
                                    set addHWWrite true
                                }

                                ## Add Std Reg it was not created before
                                #################
                                set h2dlReg [:shade odfi::h2dl::Signal findChildByProperty name [$node getHierarchyName]]
                                if {$h2dlReg==""} {
                                    set h2dlReg [:register [$node getHierarchyName]] 
                                    $h2dlReg apply {
                                        :width set $registerSize

                                        #### Each Field creates an output
                                        #### If no fields, just propagate the output
                                        if {[[$node shade ::odfi::rfg::Field children] size]==0} {
                                            :toOutput
                                        }
                                        $node shade ::odfi::rfg::Field eachChild {

                                            ## If Field has the same width as interface, adapt 
                                            if {[$it width get]==-1} {
                                                $it width set $registerSize
                                            }

                                            #:wire [:name get]_[$it name get]
                                            #puts "Field Bitmap -> [expr  [$it offset get]+[$it width get]-1] <- [$it offset get]"
                                            set bitmap [$h2dlReg bitMap "[expr  [$it offset get]+[$it width get]-1] <- [$it offset get]" [$it name get]]
                                            $bitmap apply {
                                                $it addChild ${:wire}
                                                #puts "Inside: [:info class]"
                                                ${:wire} toOutput {
                                                    #puts "Adding attribute isData"
                                                    :attribute ::odfi::rfg isData 1
                                                }
                                            }
                                        }
                                        
                                        #### if write rights; add an input
                                    }
                                }

                                

                                ## Add Posedge for the register write  
                                #############
                                if {$addWrite} {


                                    :posedge $clk {

                                        #:doReset $res_n
                                        :reset $res_n
                                        :if {! $res_n} {
                                            $h2dlReg <= 0
                                        }
                                        :else {

                                            :if { ($address == [$node getAttribute ::odfi::rfg::address absolute]) && ($write == 1)} {
                                                $h2dlReg <= $write_data
                                            }
                                            ## HW Write
                                            if {$addHWWrite} {
                                            
                                                ## Create IOs for HW write
                                                set hwWriteInput [$rfgModule input [$h2dlReg name get]_hw {
                                                    :width set [$h2dlReg width get]
                                                    :attribute ::odfi::rfg isData 1
                                                }]
                                                set hwWriteInputEnable [$rfgModule input [$h2dlReg name get]_hw_write {
                                                    :attribute ::odfi::rfg isData 1
                                                }]
                                                
                                                ## Add Else if write condition
                                                :elseif {$hwWriteInputEnable == 1} {
                                                    $h2dlReg <= $hwWriteInput
                                                }
                                            }
                                        }
                                        


                                    }
                                }

                                ## Add Read Case 
                                #################
                                if {$addRead} {


                                    $readIf apply {
                                        :if { ($address == [$node getAttribute ::odfi::rfg::address absolute]) && ($read == 1) } {
                                            $read_data <= $h2dlReg
                                            $done <= 1
                                        }
                                    }
                                }
                                ## Read
                                #$testCase on "{[$node getAttribute ::odfi::rfg::address absolute],1,0}" {
                                #    $read_data <= $h2dlReg
                                #    $done <= 1
                                #}
                                #$testCase on "{[$node getAttribute ::odfi::rfg::address absolute],0,1}" {
                                #    $h2dlReg <= $write_data
                                #    $done <= 1
                                #}

                            }


                        }
                        ## EOF Map register




                    }
                    ## EOF Loop on all 
                    
                    ## Set Reset
                    $readPosedge reset $res_n

                    ## Add case in Stage
                    #:stage address_decoder $clk {
                    #    :reset $res_n

                    #    $testCase detach
                    #    :addChild $testCase
                    #}


                    :object method doCreateInstance args {
                        set resInstance [next]
                        $resInstance object mixins add ::odfi::rfg::generator::h2dl::Instance
                        return $resInstance
                    }

                }

                return $rfgModule




            }
            ## EOF MOdule

            ## Create an H2DL Module for the register definitinos 
            +method toModule args {

                ## Get Interface
                set interface [current object]
                if {![$interface isClass ::odfi::rfg::Interface]} {
                    set interface [[:shade ::odfi::rfg::Interface getParentsRaw] at 0]
                    if {$interface==""} {
                        odfi::log::warn "Not Interface found in RFG hierarchy, using default register width of 8"
                        set registerSize 8
                        #error "Cannot Produce H2DL Module from Group if no interface is in hierarchy"
                    } else {
                        ## Get Register Size
                        set registerSize [$interface registerSize get]
                    }


                } else {
                    ## Get Register Size
                    set registerSize [$interface registerSize get]
                }



                ## Get Size
                set rfSize [expr int(ceil([:getAttribute odfi::rfg::address size 0]/2)) ]

                set rf [current object]

                ## Map to addresses if necessary
                if {![:hasAttribute ::odfi::rfg::address absolute]} {
                    :mapAddresses
                }

                ## Create Module
                odfi::h2dl::module [:name get]_rf {

                    ## SW IO
                    :input clk {
                        :attribute ::odfi::rfg::generator::h2dl internal true
                    }
                    :input res_n {
                        :attribute ::odfi::rfg::generator::h2dl internal true
                    }
                    :input  read {
                        :attribute ::odfi::rfg::generator::h2dl internal true
                    }
                    :output read_data {
                        :width set $registerSize
                        :attribute ::odfi::rfg::generator::h2dl internal true                        
                    }
                    :input  write {
                        :attribute ::odfi::rfg::generator::h2dl internal true
                    }
                    :input  write_data {
                        :width set $registerSize
                        :attribute ::odfi::rfg::generator::h2dl internal true                        
                    }
                    :output done {
                        :attribute ::odfi::rfg::generator::h2dl internal true
                    }
                    :input  address {
                        :width set $rfSize
                        :attribute ::odfi::rfg::generator::h2dl internal true                        
                    }



                    ## Create Case for address map
                    set testCase [:case [list $address $read $write] {

                    } ]

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

                                                ## Read is controled by test case
                                                set read_enable [:register [$node getHierarchyName]_read_enable]
                                                $testCase on "{[$node getAttribute ::odfi::rfg::address absolute],1,0}" {

                                                    ## Map Read data to Module data IO
                                                    set dataOutIO [$h2dlNode shade odfi::h2dl::Output findFirstChild {$it hasAttribute ::odfi::rfg::h2dl data_out}]
                                                    if {$dataOutIO==""} {
                                                        error "On [$node getHierarchyName], found a read enable to module, but not Output with ::odfi::rfg::h2dl data_out attribute set"
                                                    } else {

                                                        ## Set a wire on H2Dl module
                                                        set data_out_wire [[$testCase parent] wire [$node getHierarchyName]_[$dataOutIO name get] {
                                                            :width set [$dataOutIO width get]
                                                        }]
                                                        $io connection $read_enable
                                                        $dataOutIO connection $data_out_wire
                                                        $read_data <= $data_out_wire
                                                    }

                                                    $read_enable <= 1
                                                }


                                            } elseif {![$io hasConnection]} {
                                                $io pushUp [$node getHierarchyName]
                                            }
                                    }
                                }

                            } else {

                                ## Add Std Reg
                                #################

                                set h2dlReg [:register [$node getHierarchyName] {
                                    :width set $registerSize

                                    ## Each Field creates an output
                                    $node shade ::odfi::rfg::Field eachChild {
                                        #:wire [:name get]_[$it name get]
                                        set bitmap [uplevel 2 [list :bitMap "[expr  [$it width get]-1] <- [$it offset get]" [$it name get]]]
                                        $bitmap apply {
                                            #puts "Inside: [:info class]"
                                            ${:wire} toOutput
                                        }
                                    }
                                }]

                                ## Set ON for case
                                #############

                                ## Read
                                $testCase on "{[$node getAttribute ::odfi::rfg::address absolute],1,0}" {
                                    $read_data <= $h2dlReg
                                    $done <= 1
                                }
                                $testCase on "{[$node getAttribute ::odfi::rfg::address absolute],0,1}" {
                                    $h2dlReg <= $write_data
                                    $done <= 1
                                }

                            }


                        }
                        ## EOF Map register




                    }

                    ## Add case in Stage
                    :stage address_decoder $clk {
                        :reset $res_n

                        $testCase detach
                        :addChild $testCase
                    }


                    :object method doCreateInstance args {
                        set resInstance [next]
                        puts "OVERRIDE CREATE INSTANCE $resInstance"
                        ## Pushup interface
                        #$resInstance object method pushUpInterface args {
                        #    ${:clk} pushUp
                        #}
                        $resInstance object mixins add ::odfi::rfg::generator::h2dl::Instance
                        return $resInstance
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
            ## EOF MOdule
        }


    }

    puts "ADDDING TO INTERFACE"


    nx::Class create Instance {
        
        ## Push Interface (clk and res) and the IOs for registers
        :public method pushUpInterface args {

            
            ## Get parent 
            set parent [:shade odfi::h2dl::Module parent]
            if {$parent==""} {
                odfi::log::info "Cannot push up interface of RFG instance if no H2Dl parent exists"
                return
            }


            ## If parent Module has an IO or Signal for clock, then use it 
            #set res [$parent shade odfi::h2dl::Signal @> children @>  findOption { $it hasAttribute ::odfi::rfg clock} ]
            #puts "Res: [$res info class]"
            # if {[$res isNone]} {
            #    ${:clk} pushUp
            # } else {
            #    ${:clk} connection [$res getContent]
            # }

            
             ## Push Up RES 
             #${:res_n} pushUp

             ## Push Up Standard Interface            
             :shade {return [expr [$it isClass odfi::h2dl::IO] && ![$it hasAttribute ::odfi::rfg::generator::h2dl internal]]} eachChild {
                $it pushUp
             }
             
            return
             
             ${:read} pushUp
             ${:read_data} pushUp
             ${:write} pushUp
             ${:write_data} pushUp
             ${:address} pushUp
       }
    }


    ::odfi::rfg::Interface domain-mixins add odfi::rfg::generator::h2dl::H2DLGenerator -prefix h2dl
    ::odfi::rfg::RegisterFile domain-mixins add odfi::rfg::generator::h2dl::H2DLGenerator -prefix h2dl

}
