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
            #+exportTo ::odfi::rfg::Interface h2dl

            +method mixininit args {
                puts "Registering H2DL Regenerate"
                next
                puts "Registering H2DL Regenerate"
                :onRegenerate {
                    puts "H2DL Regenerate"
                    :h2dl:generate
                }
                
            }
            +builder {
                puts "Registering H2DL Regenerate"
            }
            
            +method regenerate args {
                puts "inside h2dl regenerate"
                next
            }

            +method generate {{module_closure ""}} {
                puts "CREATE H2DL IN INTERFACE"

                #if {[:isClass odfi::rfg::Interface]} {
                #    :mapAddresses
                #}

                ## Find Existing Module
                set existingModule [:shade ::odfi::h2dl::Module findChildByAttribute ::odfi::rfg generated true]
                if {$existingModule!=""} {
                    puts "***** Removing Existing Module "
                    $existingModule wipe
                }

                ## Create Module 
                set module [:toModule]
                $module apply $module_closure 
                puts "Returned value: [$module info class]"

                ## Add Instance 
                set instance [$module getLatestInstance]
                $instance object mixins add ::odfi::rfg::generator::h2dl::Instance
                $instance attribute ::odfi::rfg generated true
                :addChild $instance
                ##$instance addChild $module

                ## Push Up Registerss Interface
                puts "============================================"
                $instance pushUpInterface
                puts "============================================"
                return $instance
               
            }


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
                #set rfgModule [odfi::h2dl::module $moduleName]
                
                set rfgModule [odfi::h2dl::module $moduleName  {
                    :attribute ::odfi::rfg generated true
                    set rfgModule [current object]
                    
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
                    set readMain ""
                    set readReset ""
                    set notReadElse ""
                    set readPosedge [:posedge $clk {
                        
                        set readReset [:if {! $res_n} {
                            $read_data <= 0
                            $done <= 0
                        }]
                        set readMain [:else {
                            set readIf [:if {$read == 1} {

                            } ]
                            set notReadElse [:else {
                            
                                $done <= 0;
                            }]
                        }]
                        
                    } ]


                    ## Map Register Definitions to Register or a sub module for example
                    ## Also create a posedge clock for this register
                    ##############
                    $rf walkDepthFirstPreorder -level 1 {

                        #puts "Found node : $node -> [$node name get] -> [$node info class]"
                        if {[$node isClass odfi::attributes::AttributeGroup]} {
                            return false
                        }
                        if {[$node isClass odfi::rfg::Register]} {

                            ::set addWrite   true 
                            ::set addRead    true
                            ::set addHWWrite false
                            ::set addHWWriteFields false

                            ## Create Default Register , or use provided H2DL result
                            ## H2DL Support means the register instance can provide an implementation alternative
                            ## it can be a module of a write posedge block for example
                            if {[$node isClass odfi::rfg::generator::h2dl::H2DLSupport]} {

                                #puts "Supported H2Dl , creating..."
                                set h2dlNode [$node h2dl:produce [current object]]
                                :addChild $h2dlNode

                                #puts "Supported H2Dl Register created: [$h2dlNode info class]"
                                ## If the provided node is a module, then we can find special IOs for Interface
                                if {[$h2dlNode isClass ::odfi::h2dl::Module]} {

                                    ::set addWrite false 
                                    ::set addRead  false

                                    set h2dlModuleInstanceForReg [$h2dlNode createInstance [$node getHierarchyName]]
                                    :addChild $h2dlModuleInstanceForReg
                                    
                                    ## Look through IOs and make connections
                                    #puts "Looking through io..."
                                    $h2dlModuleInstanceForReg shade odfi::h2dl::IO eachChild {
                                        {io i} =>

                                            #puts "Found and IO: [$io name get] -> [$io hasAttribute ::odfi::rfg::h2dl reset]"
                                            ## Connect IOs with supported attribute
                                            ## Other IOs are just pushed_up
                                            if {[$io hasAttribute ::odfi::rfg::h2dl clock]} {
                                                $io connection $clk
                                                
                                            } elseif {[$io hasAttribute ::odfi::rfg::h2dl reset]} {
                                                
                                                ## Reset pin is connected to standard reset
                                                ::set mainResetConnection ""
                                                
                                                if {[$io getAttribute ::odfi::rfg::h2dl reset]=="posedge"} {
                                                    ::set mainResetConnection "![$res_n name get]"
                                                    #$io connection "! [$res_n name get]"
                                                } else {
                                                    ::set mainResetConnection "$res_n"
                                                    #$io connection "$res_n"
                                                }
                                                
                                                ## If the reset is soft, then add an input and mux it
                                                if {[$io hasAttribute ::odfi::rfg::h2dl soft_reset]} {
                                                
                                                    ::set softResetPin ""
                                                    if {[$io getAttribute ::odfi::rfg::h2dl reset]=="posedge"} {
                                                        ::set softResetPin [$rfgModule input [$node getHierarchyName]_reset]
                                                    } else {
                                                        ::set softResetPin [$rfgModule input [$node getHierarchyName]_resn]
                                                    }
                                                    
                                                    ::set mainResetConnection " ( $mainResetConnection ) | [$softResetPin name get]"
                                                }
                                                
                                                ## make connection
                                                $io connection $mainResetConnection
                                                
                                            } elseif {[$io hasAttribute ::odfi::rfg::h2dl read_enable]} {


                                                ## Create Read enable locally width software read only if software read enabled
                                                if {[$node isSoftwareRead]} {



                                                    ## Add read enable to module to control this module
                                                    ##########
                                                    ::set read_enable [$rfgModule register [$node getHierarchyName]_read_enable]
                                                    $io connection $read_enable
                                                    
                                                    ## don't forget reset
                                                    $readReset apply {
                                                        $read_enable <= 0
                                                    }
                                                    
                                                    ## This module's read is controled separately from other regs to make sure read_enable is always 
                                                    ## reset correctly
                                                    ## Read Else is the main clock in read posedge
                                                    $readIf apply {
                                                        :if { ($address == [$node getAttribute ::odfi::rfg::address absolute]) && ($read == 1) } {
                                                        
                                                            ## Map Read data to module out
                                                            set dataOutIO [$h2dlModuleInstanceForReg shade odfi::h2dl::Output findFirstChild {$it hasAttribute ::odfi::rfg::h2dl data_out}]
                                                            if {$dataOutIO==""} {
                                                                odfi::log::error "Cannot Create read for reg with Module implementation [$node getHierarchyName] because no IO has the attribute ::odfi::rfg::h2dl data_out" 
                                                            } else {
                                                                #set targetSignal [$dataOutIO pushUp [$node getHierarchyName]]
                                                                
                                                                #set targetSignal [$rfgModule shade odfi::h2dl::IO findChildByProperty name [$node getHierarchyName]_[$dataOutIO name get]]
                                                                
                                                                set targetSignal [$rfgModule wire [$node getHierarchyName]_[$dataOutIO name get]]
                                                                $targetSignal width set [$dataOutIO width get]
                                                                $dataOutIO connection $targetSignal
                                                            }
                                                            
                                                            #puts "********* MOduel target signal: $targetSignal -> [$node getHierarchyName]_[$dataOutIO name get]"
                                                            $read_data <= "$targetSignal"
                                                            
                                                            ## set read to 1
                                                            $read_enable <= 1
                                                            
                                                            ## Set Done 
                                                            $done <= 1
                                                        }
                                                        :else {
                                                        
                                                            ## set read to 0 in normal case, but also if no read at all is provided
                                                            $read_enable <= 0
                                                            $notReadElse apply {
                                                                $read_enable <= 0
                                                            }
                                                        }
                                                    }

                                                } elseif  {[$node isHardwareRead]} {

                                                    ## Push connection up 
                                                    set targetSignal [$rfgModule wire [$node getHierarchyName]_shiftout]
                                                    $targetSignal toOutput
                                                    $io connection $targetSignal
                                                    
                                                    #$io pushUp [$node getHierarchyName]
                                                }
                                                
                                                
                                                
                                            } elseif {[$io hasAttribute ::odfi::rfg::h2dl write_enable]} {        
                                            
                                               

                                                ## Match write enable to address
                                                if {[$node isSoftwareWrite]} {

                                                    ## Write Enable is for this address
                                                    set weWire [$rfgModule wire [$node getHierarchyName]_write_enable]
                                                    $weWire assign "$address == [$node getAttribute ::odfi::rfg::address absolute]"
                                                    
                                                    $io connection $weWire



                                                } else {

                                                    $io pushUp [$node getHierarchyName]

                                                }
                                                
                                            } elseif {[$io hasAttribute ::odfi::rfg::h2dl data_in]} {    

                                                ## Data in is connected to write data signal for software write, otherwise made available
                                                if {[$node isSoftwareWrite]} {

                                                    ## Connect to write data
                                                    $io connection ${:write_data}

                                                } else {

                                                     $io pushUp [$node getHierarchyName]
                                                    
                                                }

                                            } elseif {[$io hasAttribute ::odfi::rfg::h2dl data_out]} {    

                                                ## Data Out is connected to read block which is generated by read_enable signal handler
                                                if {[$node isHardwareRead]} {
                                                    $io pushUp [$node getHierarchyName]
                                                } 
                                                
                                            } elseif {![$io hasConnection]} {
                                                $io pushUp [$node getHierarchyName]
                                            }
                                    }
                                    ## EOF IO Connections
                                    
                                    
                                    
                                    
                                }
                                ## EOF if Result is a module

                                puts "Supported H2Dl , done..."

                                ## If it is a write section 
                                if {[$h2dlNode hasAttribute ::odfi::rfg writeSection]} {

                                    set addWrite false

                                }

                            } 

                            if {$addWrite || $addRead} {

                                ## Check HW Rights
                                ############
                                
                                ## IF Register has an attribute rw for hardware, we should add the HWWrite block
                                ## If any field has the HW Write; same thing
                                if {[$node attributeMatch ::odfi::rfg hardware *rw*]} {
                                    #puts "ADDING HW WRITE"
                                    set addHWWrite true
                                }
                                
                                set foundWriteField [[$node shade odfi::rfg::Field children] findOption {
                                    if {[$it attributeMatch ::odfi::rfg hardware *w*]} {
                                        return true
                                    } else {
                                        return false 
                                    }
                                }]
                                if {[$foundWriteField isDefined]} {
                                    set addHWWrite true
                                    set addHWWriteFields true
                                } elseif {[$node attributeMatch ::odfi::rfg hardware *w*]} {
                                    set addHWWrite true
                                    set addHWWriteFields false
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
                                            ## If Field has a connetion info, make connection
                                            if {[$node hasAttribute ::odfi::h2dl connection]} {
                                                #puts "Adding connection to [:name get]"
                                                :attribute ::odfi::h2dl connection [$node getAttribute ::odfi::h2dl connection]
                                               
                                            }
                                        }
                                        $node shade ::odfi::rfg::Field eachChild {
                                            
                                            set field $it
                                            ## If Field has the same width as interface, adapt 
                                            if {[$it width get]==-1} {
                                                $it width set $registerSize
                                            }

                                            #:wire [:name get]_[$it name get]
                                            #puts "Field Bitmap -> [expr  [$it offset get]+[$it width get]-1] <- [$it offset get]"
                                            set bitmap [$h2dlReg bitMap "[expr  [$it offset get]+[$it width get]-1] <- [$it offset get]" [$it name get]]
                                            $bitmap apply {
                                                #$it addChild ${:wire}
                                                #puts "Inside: [:info class]"
                                                ${:wire} toOutput {
                                                    #puts "Adding attribute isData"
                                                    :attribute ::odfi::rfg isData 1
                                                    
                                                    ## If Field has a connetion info, make connection
                                                    if {[$field hasAttribute ::odfi::h2dl connection]} {
                                                        #puts "Adding connection to [:name get]"
                                                        :attribute ::odfi::h2dl connection [$it getAttribute ::odfi::h2dl connection]
                                                       
                                                    }
                                                    
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
                                            ################
                                            if {$addHWWrite} {
                                            
                                                set hwWriteInputEnable [$rfgModule input [$h2dlReg name get]_hw_write {
                                                   :attribute ::odfi::rfg isData 1
                                               }]
                                               ## Add Else if write condition
                                               :elseif {$hwWriteInputEnable == 1} {
                                               
                                                    ## Full Register update or Field based update
                                                    if {!$addHWWriteFields} {
                                                        
                                                        ## Create Register Input for HW write
                                                        set hwWriteInput [$rfgModule input [$h2dlReg name get]_hw {
                                                            :width set [$h2dlReg width get]
                                                            :attribute ::odfi::rfg isData 1
                                                        }]
                                                        $h2dlReg <= $hwWriteInput
                                                        
                                                    } else {
                                                    
                                                        set hwWriteWire [$rfgModule wire [$h2dlReg name get]_hw {
                                                            :width set [$h2dlReg width get]
                                                            :attribute ::odfi::rfg isData 1
                                                        }]
                                                        
                                                        set concatExpr [::odfi::h2dl::ast::ASTConcat new]
                                                                                                            
                                                        ## Create an input per write field
                                                        $node shade odfi::rfg::Field eachChildReverse {
                                                        
                                                            ## If hardware write; concat with input wire;
                                                            ## otherwise use reg value
                                                            if {[$it attributeMatch ::odfi::rfg hardware *w*]} {
                                                                
                                                                set fieldInput [$rfgModule input [$h2dlReg name get]_[$it name get]_hw {
                                                                    :width set [$it width get]
                                                                    :attribute ::odfi::rfg isData 1
                                                                }]
                                                                
                                                                #if {[$it width get]==1} {
                                                                #    
                                                                #} else {
                                                                #    lappend exprRes [list $it @ [expr [$it offset get]+[$it width get]-1] <- [$it offset get]]
                                                                #}
                                                                
                                                                #lappend exprRes [list $it]
                                                                #lappend exprRes ,
                                                                $concatExpr addChild $fieldInput
                                                                
                                                                
                                                               # set fieldInputBitMap [$hwWriteWire bitMap "[expr  [$it offset get]+[$it width get]-1] <- [$it offset get]" [$it name get]]
                                                                #$fieldInputBitMap apply {
                                                                #    ${:wire} toInput {
                                                                #        #puts "Adding attribute isData"
                                                                 #       :attribute ::odfi::rfg isData 1
                                                                 #   }
                                                                #}
                                                            } else {
                                                                
                                                                $concatExpr addChild [::odfi::h2dl::ast::buildAST $h2dlReg @ ([expr [$it offset get]+[$it width get]-1] <- [$it offset get])]
                                                                
                                                                #lappend exprRes [list $h2dlReg @ [expr [$it offset get]+[$it width get]-1] <- [$it offset get]]
                                                                #lappend exprRes ,
                                                                
                                                            }
                                                        }
                                                        
                                                        #set finalExpr [lrange $exprRes 0 end-1]
                                                        #puts "**** Final Expression : $finalExpr -> [llength $finalExpr]"
                                                        $h2dlReg <= $concatExpr
                                                        #exit
                                                    
                                                    }
                                               
                                                   
                                               }
                                               
                                               
                                               
                                                
                                                
                                            }
                                        }
                                        


                                    }
                                }
                                ## EOF Write

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
                          

                            }
                            ## EOF if add write or read

                            return false
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

                    #if {[:getLatestInstance]!=""} {
                    #    [:getLatestInstance]e object mixins add ::odfi::rfg::generator::h2dl::Instance
                    #}
                    #:object method doCreateInstance args {
                    #    set resInstance [next]
                    #    $resInstance object mixins add ::odfi::rfg::generator::h2dl::Instance
                    #    return $resInstance
                    #}

                }]

                return $rfgModule




            }
            ## EOF MOdule

        }


    }


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
             puts "Push interface on [:info class]"  
             #:shade odfi::h2dl::IO  pushUpAll {
             #    if {![$it hasAttribute ::odfi::rfg::generator::h2dl internal]} {
             #       return true
             #    } else {
              #      return false
              #   }
                
            #}      
            
            :shade odfi::h2dl::IO  pushUpAll {expr {![$it hasAttribute ::odfi::rfg::generator::h2dl internal]} }
             #:shade odfi::h2dl::IO eachChild {
              #  if {![$it hasAttribute ::odfi::rfg::generator::h2dl internal]} {
              #      $it pushUp 
              #  }
               
             #}
             
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
