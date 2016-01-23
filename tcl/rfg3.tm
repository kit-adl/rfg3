## RFG Register File Generator
## Copyright (C) 2014-2015  University of Heidelberg - Computer Architecture Group
## Copyright (C) 2014-2015  University of Karlsruhe  - ASIC and Detector Lab Group
## 
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU Lesser General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
## 
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
## 
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.
package provide odfi::rfg       3.0.0


package require odfi::language   1.0.0 
package require odfi::attributes 2.0.0
package require odfi::h2dl       2.0.0

namespace eval odfi::rfg {

    odfi::language::Language default {


       # +type Group {#

           # +exportTo Group
           # :register name {

            #}
        #}
        ## Common Data 
        #####################
        +type RFGNode {

            +method getHierarchyName {{separator _}} {

                return [:shade { return [expr [$it isClass odfi::rfg::RFGNode] && ![$it isClass odfi::rfg::RegisterFile] ]} formatHierarchyString {$it name get} _]_[$node name get]

            }
        }
        +type Description : RFGNode {

            +var description ""
            +mixin ::odfi::attributes::AttributesContainer
        }

        

        ## Hierarchy
        #####################

        :group : Description name  {
            +exportTo Group
            #+mixin ::odfi::attributes::AttributesContainer

            ## RF Top interface, which is a group 
            :registerFile : Group name {
                +exportTo RegisterFile
                #+exportTo Interface
                +exportTo Group
                +exportToPublic
                +expose    name

                ## Walk the tree and add addresses to everyone
                +method mapAddresses args {

                    ## Find Interface 
                    #############
                    ## Get Interface
                    set interface [current object]
                    if {![$interface isClass ::odfi::rfg::Interface]} {
                        set interface [[:shade ::odfi::rfg::Interface getParentsRaw] at 0]
                        if {$interface==""} {
                            error "Register File Cannot Map Addresses because the register size is required to generate correct address increment"
                        } 
                    }

                    

                    ## Address increment in bytes
                    set registerIncrement [expr [$interface registerSize get]/8]
                    set currentAddress 0
                    :walkDepthFirstPostorder {

                        if {[$node isClass odfi::rfg::Register]} {
                            puts "On Register, current address is $currentAddress"
                            $node attribute odfi::rfg::address absolute $currentAddress
                            incr currentAddress $registerIncrement
                        }

                        return true
                    }

                }


            }

            ## Group Common 
            :register : Description name {
                +mixin ::odfi::attributes::AttributesContainer
                :field : Description name {
                    +var width 1
                    +var reset 0
                }
            }
        }



        ## Interface Wrapper
        #################
        :interface : ::odfi::h2dl::Module name {
            +exportToPublic
            +expose    name
            +mixin ::odfi::attributes::AttributesContainer
            +mixin RegisterFile
            +exportTo ::odfi::h2dl::Module rfg
            
            ## Register size in bits
            +var registerSize 8 

            ## Generic Builder
            +builder {
                puts "Builder for Interface"
                :onBuildDone {

                    ::puts "Done Build Interface, creating H2DL "

                }
            }


             +method h2dl:generate args {
                puts "CREATE H2DL IN INTERFACE"

                ## Map Addresses 
                :mapAddresses

                ## Find Interface 
                #############
                ## Get Interface
                set interface [current object]
                if {![$interface isClass ::odfi::rfg::Interface]} {
                    set interface [[:shade ::odfi::rfg::Interface getParentsRaw] at 0]
                    if {$interface==""} {
                        error "Register File Cannot Map Addresses because the register size is required to generate correct address increment"
                    } 
                }

                ## Get Size 
                set rfSize [expr int(ceil([:getAttribute odfi::rfg::address size 0]/2)) ]

                set rf [current object]

                :module [:name get]_rf {
                    
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
                ## EOF MODULE 
            }
            ## EOF generate

        }

        

    }

}
