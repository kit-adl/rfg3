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

        ## Interface Wrapper
        #################
        :interface : ::odfi::h2dl::Module name {
            +exportToPublic
            +expose    name
            +exportTo ::odfi::h2dl::Module rfg
            
            ## Register size in bits
            +var registerSize 8 

   

        }

        ## Hierarchy
        #####################

        :group : Description name  {
            +exportTo Group
            #+mixin ::odfi::attributes::AttributesContainer

            ## RF Top interface, which is a group 
            :registerFile : Group name {
                +exportTo RegisterFile
                +exportTo Interface
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
                            odfi::log::warn "Not Interface found in RFG hierarchy, using default register width of 8"
                            set registerSize 8
                            #error "Register File Cannot Map Addresses because the register size is required to generate correct address increment"
                        } else {
                            ## Get Register Size 
                            set registerSize [$interface registerSize get]
                        }
                    } else {
                        ## Get Register Size 
                        set registerSize [$interface registerSize get]                        
                    }

                    

                    ## Address increment in bytes
                    set registerIncrement [expr $registerSize/8]
                    set currentAddress 0
                    :walkDepthFirstPostorder {

                        if {[$node isClass odfi::rfg::Register]} {
                            #puts "On Register, current address is $currentAddress"
                            $node attribute ::odfi::rfg::address absolute $currentAddress
                            incr currentAddress $registerIncrement
                        }

                        return true
                    }

                    ## Add Address Size as attribute  and next power of two
                    :attribute ::odfi::rfg::address size [expr $currentAddress == 0 ? 1 : int(ceil(log($currentAddress)/log(2)))]


                }


            }

            ## Group Common 
            :register : Description name {
                +mixin ::odfi::attributes::AttributesContainer

                ## End of register, if no field, create a field with same name and width as register 
                +builder {
                    :onBuildDone {
                        if {[:shade odfi::rfg::Field firstChild]==""} {
                            #:field $name {
                            #    :width set -1
                            #}
                        }
                    }
                }

                ## Field 
                :field : Description name {
                    +var width 1
                    +var offset 0
                    +var reset 0
                    
                    ## Assign Offset based on previous 
                    +builder {
                        set previous [:shade odfi::rfg::Field getPreviousSibling]

                        if {$previous!="" && [$previous isClass odfi::rfg::Field] } {
                            set :offset [expr [$previous offset get]+[$previous width get]]
                        }
                    }
                }
            }
        }



       

        

    }

}
