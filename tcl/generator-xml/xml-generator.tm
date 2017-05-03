package provide odfi::rfg::generator::xml   3.0.0
package require odfi::rfg                   3.0.0
package require odfi::files                 2.0.0

namespace eval  ::odfi::rfg::generator::xml {

    odfi::language::Language default {
    
        :XMLGenerator {
        
            +method generate targetFile {
            
                
                if {[::odfi::files::isRelative $targetFile]} {
                    lassign [::odfi::common::findFileLocation] f c up
                    set targetFile [file normalize [file dirname $f]/$targetFile]
                }
            
                file mkdir [file normalize [file dirname $targetFile]]
            
                ## Use Reduce Plus
                set res [:reducePlus {
                

                    //puts "Testing node/: [$node name get] -> [$node info class]"

                    if {[$node isClass ::odfi::rfg::RegisterFile]} {
                    
                        return "<RegisterFile name=\"[$node name get]\">[$results @> map { return [lindex $it 1]} @> mkString]</RegisterFile>"
                        
                    } elseif {[$node isClass ::odfi::rfg::Group]} {
                    
                        return "<Group name=\"[$node name get]\">[$results @> map { return [lindex $it 1]} @> mkString]</Group>"
                        
                    } elseif {[$node isClass ::odfi::rfg::Register]} {
                    
                        return "<Register name=\"[$node name get]\">[$results @> map { return [lindex $it 1]} @> mkString]</Register>"
                        
                    } elseif {[$node isClass ::odfi::rfg::Field]} {
                                        
                        return "<Field name=\"[$node name get]\" width=\"[$node width get]\" reset=\"0\">[$results @> map { return [lindex $it 1]} @> mkString]</Field>"
                        
                    } elseif {[$node isClass ::odfi::attributes::AttributeGroup]} {
                    
                        return "<Attributes for=\"[$node name get]\">[$results @> map { return [lindex $it 1]} @> mkString]</Attributes>"
                        
                    } elseif {[$node isClass ::odfi::attributes::Attribute]} {
                                        
                        return "<Attribute name=\"[$node name get]\">[$node value get]</Attribute>"
                                            
                    } else {
                        return ""
                    }
                
                
                }]
            
                ::odfi::files::writeToFile $targetFile [lindex [$res at 0] 1]
            
            }
        
        
        }

    }
    
    ::odfi::rfg::Group domain-mixins add ::odfi::rfg::generator::xml::XMLGenerator -prefix xml


}