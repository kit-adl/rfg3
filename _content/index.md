<%=
	set :pageName "Welcome to RFG3"
	set :shortName "Home"
%>


# Register File Generators (RFG) 3 
 
RFG is a small tcl tool used to describe a set a registers needed in a hardware design, and generate
the appropriate documentation and hardware description in Verilog to rapidly read and write the registers from
the hardware and software components.

RFG features enable customisation of the register implementation for special common use cases like FIFOs, counters etc...

RFG3 is based on the newest Language Definition API from the ODFI library and the NX scripting language.
If you are looking for the actual most featured version, have a look at RFG2 maintained at the University of Heidelberg.

## Installation

To use RFG3, you can install the TCL release and its dependencies using the ODFI manager, or use a single file release.

Single File Releases are available at: <% :mdLink https://www.idyria.com/access/osi/files/builds/tcl/ %> 

The Single File Release is an all-in-one TCL interpreter which you can use to run and RFG script.


## Quick Start

RFG usage is based on a single script, from which you can make calls to the API to describe the registers and generate the outputs.
This method enables a simple usage by just writting a TCL file and running it, or embedding  easily into any existing script flow.

Assuming you are using a single file release executable, which you have renamed as "rfg"

overview.tcl:

	## Load the RFG Tool
	package require odfi::rfg 3.0.0
	
	## Load the Verilog Generator
	
	## Now Create the Register File Description
	set test true
	
	## Finally Generate the Verilog Output
	



Now run this script through the RFG TCL interpreter:

>rfg overview.tcl

You should see the output:

* first_rfg.v

Which contains your register with a read and write interface

