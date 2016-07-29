

 
## Load Main TCL
source [file dirname [info script]]/../src/example_design_xilinx.tcl
 

odfi::h2dl::module example_design_xilinx_tb {
    
    :register clk {
        :attribute ::odfi::h2dl::freq 100
    }
    :register res_n
    
    
    :instantiate $example_design_xilinx -> example_design_xilinx_I
    
    $example_design_xilinx_I connect clk -> $clk
    

}

$example_design_xilinx_tb verilog:produce [file dirname [info script]]/verilog.gen


