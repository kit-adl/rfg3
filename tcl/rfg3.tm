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
package require odfi::log        1.0.0

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

            +var cachedHierName ""

            +method getHierarchyName {{separator _}} {

                if {${:cachedHierName}==""} {
                    set hierName [:shade { 
                                return [expr [$it isClass odfi::rfg::RFGNode] && ![$it isClass odfi::rfg::RegisterFile] ]
                                } formatHierarchyString {$it name get} _]
                    if {$hierName==""} {
                        set :cachedHierName [:name get]
                    } else {
                        set :cachedHierName [join [list $hierName [:name get]] _]
                    }
                    #puts "Hier Name of: [:name get] is $hierName"
                    #set :cachedHierName [join [list $hierName [:name get]] _]
                }

                return ${:cachedHierName}
                
                #return [:shade { return [expr [$it isClass odfi::rfg::RFGNode] && ![$it isClass odfi::rfg::RegisterFile] ]} formatHierarchyString {$it name get} _]_[:name get]

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
            +var instanceName ""
            
            ## Register size in bits
            +var registerSize 8 
            
            +method init args {
                next
                puts "On Interface Init"
                :registerEventPoint regenerate
                :registerEventPoint regenerateDone
            }
            
            +method mixininit args {
                next
            }
            
            +builder {
                
                ## Use class name for module name
                ## Main name is the instance name
                #puts "Class Name: [:info class]"
                set :instanceName [:name get]
               
                
                ## Add to Container Module
                ## Do this at the end to let implementation builders have time to work
 
                :onBuildDone {
                    puts "Inside Interface builder with parent: [:parent]"
                    :regenerate
                    return
                    
                }
               
                
                
            
            }
            ## EOF Builder
            
            +method getRegisterFile args {

                return  [:shade odfi::rfg::RegisterFile firstChild]
           
            }

            ## Push Signals marked as external
            ## Useful for external Chip Interface to be easily connected
            +method pushExternal args {
            
                ## get interface instance
                set p [:parent]
                if {$p!="" && [$p isClass ::odfi::h2dl::Module]} {
                    set instance [$p shade ::odfi::h2dl::Instance findChildByProperty name ${:instanceName}]
                    if {$instance!=""} {
                        $instance shade ::odfi::h2dl::IO eachChild {
                            if {[$it hasAttribute ::odfi::rfg::h2dl external]} {
                                $it pushUp
                            }
                        }
                    }
                    
                }
            
            }
            
            ## Regenerate the 
            +method regenerate args {
                next
                #puts "Calling Regenerate"
                set targetInterface [current object]
                if {[:isClass ::odfi::h2dl::Instance]} {
                    set targetInterface [:master get]
                }
                
                
                ## Clean Any Instance of RFG Module
                #########
                $targetInterface callRegenerate
                $targetInterface callRegenerateDone
            }
            
            
            +method transferIOToInstance {instance io} {
                next
                #puts "overriding transfer of IO [$io name get] to instance"
                if {[$io hasAttribute ::odfi::h2dl connection]} {
                    #puts "-> Adding connection"
                    [$instance findChildByProperty name [$io name get]] connection [$io getAttribute ::odfi::h2dl connection]
                }
            }
            
            ## Pulling
            ####################
            +method pull {instance match as targetBaseName} {
            
                ## Pull is called on instance for connections but need master for formal definitions
                ##########
                set interfaceMaster [:master get]
                puts "Pull on: [:master get]"
            
                ## Checks
                #############
                set registerFile [$interfaceMaster shade ::odfi::rfg::RegisterFile firstChild -error "Cannot run Pull if no register file is present"]
                
                
                ## Create / Get Group
                ########
                set groupName [$instance name get]
                set group  [$registerFile group $groupName]
                
                ## Get All the IO matching name
                #########
                
                set pullIO [$instance shade ::odfi::h2dl::IO findChildrenByProperty name $match]
                
                ## Exclude already connected ones
                set pullIO [$pullIO filterNot {$it hasConnection}]
                
                puts "Pulling IO: [$pullIO size]"
               
               ## Create registers and align IOs in them
               #############
               
               ## use target base name to create registers
               ## look for an existing register and take its index as base or start at 0
               set currentRegister ""
               set lastRegister [[$group shade ::odfi::rfg::Register findChildrenByProperty name $targetBaseName*] last]
               set regIndex 0
               if {$lastRegister!=""} {
                 regexp {.+([\d]+)} [$lastRegister name get] -> regIndex
                 incr regIndex
               }
               
               $pullIO isEmpty {
               
               } else {
                 
                 $pullIO foreach {
                    {io ioIndex} => 
                    
                   
                    ## - Take needed width                   
                    set needed [$io width get]
  
                    ## - If IO is wider than register size, create multiple registers
                    ## - Otherwise add as field
                    if {$needed>${:registerSize}} {
                        
                        puts "Pulling IO [$io name get], needing $needed bits, per register ${:registerSize}"
                        
                        ## Calculate numer of required registers
                        set requiredTotal [expr int(ceil($needed/${:registerSize}))]
                        
                        ## Create a new register for each and use up the bits
                        repeat $requiredTotal {
                            set splittingRegister [$group register [$io name get]$i]
                            
                            ## Connection is just a range of target
                            
                            $splittingRegister attribute ::odfi::h2dl connection [$io expr:range [expr $i*${:registerSize}] -> [expr $i*${:registerSize}+${:registerSize}-1] ]
                            $io connection [$io name get]
                        }
                    
                    } else {
                        
                        ## If no current register, create one
                        if {$currentRegister==""} {
                            set currentRegister [$group register ${targetBaseName}$regIndex]
                            incr regIndex
                        }
                        
                        ## - Take remaining in current Register
                        set remaining [expr ${:registerSize} - [$currentRegister getWidth] ]
                        
                        ## If not enough room, go to next register and remaining is now the full register width
                        if {$needed>$remaining} {
                            set currentRegister [$group register ${targetBaseName}$regIndex]
                            incr regIndex
                            set remaining ${:registerSize}
                        }
                    
                        $currentRegister field [$io name get] {
                            :width set [$io width get]
                            :attribute ::odfi::h2dl connection $io
                            #puts "Adding connection to [current object] [:name get]"
                        }
                    }
                 
                 }
                 ## EOF IO Foreach
                 
                 ## Regenerate to reflect changes
                 :regenerate
                 
                 ## Now Make Connections
                 
                    
               }
               
                
            
            }

   

        }

        ## Hierarchy
        #####################

        :group : Description name  {
            +exportTo Group
            +unique    name
            #+mixin ::odfi::attributes::AttributesContainer

            ## RF Top interface, which is a group 
            :registerFile : Group name {
                +exportTo RegisterFile
                +exportTo Interface
                +exportTo Group
                +exportToPublic
                +expose    name
                +unique    name

                ## Walk the tree and add addresses to everyone
                +method mapAddresses args {

                    ## Find Interface 
                    #############
                    ## Get Interface
                    set interface [current object]
                    if {![$interface isClass ::odfi::rfg::Interface]} {
                        set interface [[:shade ::odfi::rfg::Interface getParentsRaw] at 0]
                        if {$interface==""} {
                        
                            if {[[current object] hasAttribute ::odfi::rfg registerSize]} {

                                set registerSize [[current object] getAttribute ::odfi::rfg registerSize]
                                odfi::log::info "Mapping Addresses using attribute register Size $registerSize"
                                
                            } else {
                                odfi::log::warn "No Interface found in RFG hierarchy and no ::odfi::rfg::registerSize attribute , using default register width of 8"
                                set registerSize 8
                            }
                        
                           
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

                +method getRegisterSize {{defaultSize 8}} {

                    set registerSize $defaultSize

                    ## Find Interface 
                    #############
                    ## Get Interface
                    set interface [current object]
                    if {![$interface isClass ::odfi::rfg::Interface]} {
                        set interface [[:shade ::odfi::rfg::Interface getParentsRaw] at 0]
                        if {$interface==""} {
                        
                            if {[[current object] hasAttribute ::odfi::rfg registerSize]} {

                                set registerSize [[current object] getAttribute ::odfi::rfg registerSize]
                                odfi::log::info "Mapping Addresses using attribute register Size $registerSize"
                                
                            } else {
                                odfi::log::warn "No Interface found in RFG hierarchy and no ::odfi::rfg::registerSize attribute , using default register width of 8"
                                
                            }  
                           
                            #error "Register File Cannot Map Addresses because the register size is required to generate correct address increment"
                        } else {
                            ## Get Register Size 
                            set registerSize [$interface registerSize get]
                        }
                    } else {
                        ## Get Register Size 
                        set registerSize [$interface registerSize get]                        
                    }

                    return $registerSize


                }

                +method setDualPort args {
                    :attribute ::odfi::rfg dualport true 
                }

                +method onDualPort {DPC else notDPC} {

                    if {[:hasAttribute ::odfi::rfg dualport]} {
                        :applyUp $DPC 
                    } else {
                        :applyUp $notDPC
                    }

                }


            }

            ## Group Common 
            :register : Description name {
                +mixin ::odfi::attributes::AttributesContainer
                +var reset 0
                +var width -1



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

                ##  Rights 
                +method softwareRead args {

                    :attribute ::odfi::rfg::rights sw ro
                }
                +method softwareWrite args {

                    :attribute ::odfi::rfg::rights sw wo
                }

                +method isSoftwareRead args {
                    return [:attributeMatch ::odfi::rfg::rights sw *r*]
                }
                +method isSoftwareWrite args {
                    return [:attributeMatch ::odfi::rfg::rights sw *w*]
                }

                +method hardwareWrite args {
                    :attribute ::odfi::rfg::rights hw wo
                }
                +method hardwareRead args {
                    :attribute ::odfi::rfg::rights hw ro
                }

                +method hardwareWrittenFromSoftware args {
                    :attribute ::odfi::rfg::hw sw_written 1
                }

                 +method isHardwareRead args {
                    return [:attributeMatch ::odfi::rfg::rights hw *r*]
                }
                +method isHardwareWrite args {
                    return [:attributeMatch ::odfi::rfg::rights hw *w*]
                }

                ## Returns empty string if not found
                +method findInterface args {

                    return  [:findParentInPrimaryLine {$it isClass ::odfi::rfg::Interface}]
                 

                }
                
                ## Width is sum of Fields of default size
                +method getWidth args {
                    
                    if {[:shade odfi::rfg::Field firstChild]==""} {
                        set interface [:findInterface]
                        if {$interface==""} {
                            return 0
                        } else {
                        puts "Reg get width: [$interface info class]"
                            return [$interface registerSize get]
                        }
                       
                    } else {
                        set sum 0 s
                        [:shade ::odfi::rfg::Field children] @> map {return [$it width get]} @> foreach {
                         set sum [expr $sum + $it]
                        }
                    }
                    
                    
                    
                    return $sum
                }
                
                ## Set the absolute address
                +method address addr {
                    :attribute ::odfi::rfg::address absolute [expr int($addr)]
                }

                ## Lsit format: MSB  .... LSB , thus reverse the args before processing
                +method fieldsFromList  args {
                    
                    foreach f [lreverse $args] {
                        
                        regexp {(\w+)(?:\((\d+):(\d+)\))?} $f -> name msb lsb
                        
                        ## Create field
                        puts "Creating field with: $name $msb <- $lsb"
                        :field $name {
                            if {$msb!="" && $lsb !=""} {
                                :width set [expr $msb - $lsb +1]
                            }
                        }
                        
                        
                    }
                    
                    
                    
                }

                +method reserved  args { 
                    :field RSVD {
                        :attribute ::odfi::rfg reserved true
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
