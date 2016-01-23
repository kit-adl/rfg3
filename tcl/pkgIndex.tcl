set dir [file dirname [file normalize [info script]]]

package ifneeded odfi::rfg 3.0.0                    [list source $dir/rfg3.tm] 
package ifneeded odfi::rfg::stdlib  3.0.0            [list source $dir/stdlib/rfg3-stdlib.tm] 

package ifneeded odfi::rfg::generator::html 3.0.0   [list source $dir/generator-html/html-generator.tm] 
package ifneeded odfi::rfg::generator::h2dl 3.0.0   [list source $dir/generator-h2dl/h2dl-generator.tm] 
