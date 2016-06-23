package require odfi::rfg::interface::ftdi232hkitsync 1.0.0



::ftdi::kit::rfg::sync top {
    
    :outputOrderSorter set true
    
    :registerFile rf {
    
    }

}

$top verilog:produce [file dirname [info script]]/verilog.gen

