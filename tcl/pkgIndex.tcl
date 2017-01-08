set dir [file dirname [file normalize [info script]]]

package ifneeded odfi::rfg 3.0.0                    [list source $dir/rfg3.tm] 
package ifneeded odfi::rfg::stdlib  3.0.0            [list source $dir/stdlib/rfg3-stdlib.tm] 

package ifneeded odfi::rfg::generator::html 3.0.0   [list source $dir/generator-html/html-generator.tm] 
package ifneeded odfi::rfg::generator::h2dl 3.0.0   [list source $dir/generator-h2dl/h2dl-generator.tm] 
package ifneeded odfi::rfg::generator::xml  3.0.0   [list source $dir/generator-xml/xml-generator.tm] 

package ifneeded odfi::rfg::generator::caddress 1.0.0   [list source $dir/generator-caddress/caddress-generator.tm] 

## Interfaces
package ifneeded odfi::rfg::interface::ftdi232h     1.0.0 [list source $dir/interfaces/ftdi/ftdi-232h-1.x.tm] 
package ifneeded odfi::rfg::interface::ftdi232hkitsync 1.0.0 [list source $dir/interfaces/ftdi-kitsync/ftdi-kitsync-232h-1.x.tm] 