package provide odfi::rfg::generator::caddress      1.0.0
package require odfi::rfg                       3.0.0
package require odfi::richstream 3.0.0

namespace eval odfi::rfg::generator::caddress {

    nx::Class create  CAddressGenerator {
        
        :public method generate {targetFile {prefix ""}} {
            
            ## Walk Through all 
            ## Get RF 
            if {[[current object] isClass  odfi::rfg::RegisterFile]} {
                set rf [current object]
            } else {
                set rf [:shade odfi::rfg::RegisterFile firstChild]
            }
            
            if {$rf==""} {
                odfi::log::error "Generating C Addresses without Register File" 
                return
            }
            
            ## Map to addresses if necessary
            if {![$rf hasAttribute ::odfi::rfg::address absolute]} {
                $rf mapAddresses
            }
            
            ## Generate
            #############
            
            set hout [::new ::odfi::richstream::RichStream #auto]
            $hout streamToFile $targetFile
            $rf walkDepthFirstPreorder -level 1 {
            
                if {[$node isClass odfi::rfg::Register]} {
                    $hout puts "#define [string toupper $prefix[$node getHierarchyName]] 0x[$node getAttribute ::odfi::rfg::address absolute]"
                }
                                    
            }
            $hout close
        
        }
        
    
    }
    
    ::odfi::rfg::Interface    domain-mixins add odfi::rfg::generator::caddress::CAddressGenerator -prefix caddress
    ::odfi::rfg::RegisterFile domain-mixins add odfi::rfg::generator::caddress::CAddressGenerator -prefix caddress

}
