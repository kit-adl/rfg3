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

* On Windows you can use the PowerShell to download the tool

	$ Invoke-WebRequest https://www.idyria.com/access/osi/files/builds/tcl/rfg-full-latest-win64.exe -OutFile rfg.exe

* On Windows using Msys like Bash (Msys2/Git Bash)

	$ curl -o rfg.exe https://www.idyria.com/access/osi/files/builds/tcl/rfg-full-latest-win64.exe
	
* Now write the file simplestart.tcl:

~~~~~~

	## Load the RFG Tool
	package require odfi::rfg 3.0.0
	
	## Load the Verilog Generator
	package require odfi::rfg::generator::verilog 3.0.0
	
	
	## Now Create the Register File Description
	odfi::rfg::registerFile testRF {
		
		:register dummy {
			
		}
	}
	
	## Finally Generate the Verilog Output
	## Format: registerFile verilog:generate targetFolder
	$testRF verilog:generate .


~~~~~~

Now run this script through the RFG TCL interpreter:

	$ rfg simplestart.tcl

You should see a new file has been created: testRF.v , which contains the dummy register with an address based interface and an output for the hardware to access the value
of the register:

## Where to go?

To use the tool at its full extend, you will need: 

* An IO interface to drive the address base interface. This could be a custom protocol over a standard physical interface like SPI or and FTDI Fifo chip.
** Some standard interfaces are available in the library
** Learn how to write one from IO interface documentation category
* The register definition have support for various features like fields to access the single bits of the register
** Consult the Syntax reference for the list of standard features
* Some Registers can have a special implementation or behaviour, like a counting register, or a register backed by a FIFO. Some standard components are available
from the Standard Library
** The RFG API language can be easily extended to add your own custom special registers, see the Extension documentation


