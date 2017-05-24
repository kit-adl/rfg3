module epp_interface (

    //======================================
    // Clocking and Reset
    //======================================
    input wire clk,
    input wire res_n,
    
    //======================================
    // EPP Interface
    //======================================
    inout  wire [7:0] EPP_DB,   // Port data bus
    input  wire EPP_ASTB,       // Address Strobe
    input  wire EPP_DSTB,       // Data Strobe
    input  wire EPP_WRITE,      // Transfer direction control 
    output wire EPP_WAIT,       // transfer synchronization (handshake)

);

// Register File Definition
//--------------------------------
reg  [4:0]  rfs_address;
wire [7:0]  rfs_read_data;
wire [7:0]  rfs_write_data;
wire        rfs_invalid_address;
wire        rfs_access_complete;
wire        rfs_read_en;
wire        rfs_write_en;



//======================================
// Register/Signal Declarations
//======================================
reg [7:0] current_state, next_state;

// Internal control signals
wire ctrlepp_WAIT;
wire ctrlepp_ASTB;
wire ctrlepp_DSTB;
wire ctrlepp_DIR;
wire ctrlepp_WR;
wire ctrlepp_addrWR;
wire [7:0] busepp_IN;

(* IOB = "TRUE" *)
reg [7:0] busepp_DATA;

wire [2:0] inputvector;


//======================================
// I/O Sync Stage
//======================================
(* IOB = "TRUE" *)
reg ast;

(* IOB = "TRUE" *)
reg dst;

(* IOB = "TRUE" *)
reg write;

// These wires are the outputs of the sync stage
// Could be removed, just there in case something would have to be fixed
wire ast_in = ast;
wire dst_in  = dst;
wire write_in  = write;

// Sync the control signals once in the IOB registers before continuing
always @(posedge clk or negedge res_n) begin
    if(~res_n) begin
         ast <= 0;
         dst <= 0;
         write <= 0;
    end else begin
        dst <= EPP_DSTB;
        ast <= EPP_ASTB;
        write <= EPP_WRITE;
    end
end

//======================================
// Defining state codes
//======================================
parameter st_eppReady     = 8'b0000_0000;
parameter st_epp_addrWRA  = 8'b0001_0100;
parameter st_epp_addrWRB  = 8'b0010_0001;
parameter st_epp_addrRDA  = 8'b0011_0010;
parameter st_epp_addrRDB  = 8'b0100_0011;
parameter st_epp_dataWRA  = 8'b0101_1000;
parameter st_epp_dataWRB  = 8'b0110_0001;
parameter st_epp_dataRDA  = 8'b0111_0010;
parameter st_epp_dataRDB  = 8'b1000_0011;

//======================================
// basic status and control mapping
//======================================
assign ctrlepp_ASTB = ast_in;
assign ctrlepp_DSTB = dst_in;
assign ctrlepp_WR = write_in;
assign EPP_WAIT = ctrlepp_WAIT;  // drive handshake from fsm output




// INOUT BUS DRIVE
/////////////////////////////

// Data bus direction control. The internal input data bus always gets the data bus. 
// The port data bus drives the internal output data bus onto the pins when the
// interface says we are doing a read cycle and we are in one of the read cycles 
// states in the fsm.
assign busepp_IN = EPP_DB;
assign EPP_DB = (ctrlepp_WR == 1'b1 && ctrlepp_DIR == 1'b1) ?  rfs_read_data : 8'bzzzzzzzz;

// Select either address or data onto the internal output data bus
//assign busepp_OUT = (ctrlepp_ASTB == 1'b0) ? {4'b0000, regepp_addr} : busepp_DATA;



//======================================
// EPP Main Control FSM
//======================================

// Map control signals from the current state
assign {rfs_write_en, ctrlepp_addrWR, ctrlepp_DIR, ctrlepp_WAIT} = current_state[3:0];
assign inputvector = {ctrlepp_ASTB, ctrlepp_DSTB, ctrlepp_WR};

// Next state logic
always @ (posedge clk or negedge res_n) begin
    if (res_n == 1'b0) begin
        current_state <= st_eppReady;
    end else begin
        current_state <= next_state;
    end 
end

always @ (*) begin
    casex({inputvector, current_state})
        {3'b0x0, st_eppReady}: next_state = st_epp_addrWRA;
        {3'b0x1, st_eppReady}: next_state = st_epp_addrRDA;
        {3'b100, st_eppReady}: next_state = st_epp_dataWRA;
        {3'b101, st_eppReady}: next_state = st_epp_dataRDA;
        {3'b1xx, st_eppReady}: next_state = st_eppReady;
        {3'bxxx, st_epp_addrWRA}: next_state = st_epp_addrWRB;
        {3'b0xx, st_epp_addrWRB}: next_state = st_epp_addrWRB;
        {3'b1xx, st_epp_addrWRB}: next_state = st_eppReady;
        {3'bxxx, st_epp_addrRDA}: next_state = st_epp_addrRDB;
        {3'b0xx, st_epp_addrRDB}: next_state = st_epp_addrRDB;
        {3'b1xx, st_epp_addrRDB}: next_state = st_eppReady;
        {3'bxxx, st_epp_dataWRA}: next_state = st_epp_dataWRB;
        {3'bx0x, st_epp_dataWRB}: next_state = st_epp_dataWRB;
        {3'bx1x, st_epp_dataWRB}: next_state = st_eppReady;
        {3'bxxx, st_epp_dataRDA}: next_state = st_epp_dataRDB;
        {3'bx0x, st_epp_dataRDB}: next_state = st_epp_dataRDB;
        {3'bx1x, st_epp_dataRDB}: next_state = st_eppReady;
        default: next_state = st_eppReady;
    endcase
end

//======================================
// EPP Address register: Read Address from bus on address strobe
//======================================

always @ (posedge clk or negedge res_n) begin
    if (res_n == 1'b0) begin
            rfs_address <= 4'b0000;
    end else begin
        if (ctrlepp_addrWR == 1'b1) begin
            rfs_address <= busepp_IN[4:0];
        end
    end
end

//======================================
// EPP Write Data registers
//======================================

// The following processes implement the interface registers. These registers
// just hold the value written so that it can be read back. In real design, the
// contents of these registers would drive additional logic. The ctrlepp_dataWR
// signal is an output from the fsm that says we are in a write data register state.
// This is combined with the address in the address registr to determine whic register
// to write.

// On DATA WR 1 => WRITE, update register
assign rfs_write_data = busepp_IN;

/*always @ (posedge clk or negedge res_n) begin
  if (res_n == 1'b0) begin
    rfs_write_en <= 0;
  end else begin
    if (ctrlepp_dataWR == 1'b1) begin

        // Drive the RFS interface
        rfs_write_en <= 1;
        rfs_write_data <= busepp_IN;

    end
    else begin 
        rfs_write_en <= 0;
    end
  end
end*/


//======================================
// EPP Read Data registers
//======================================
assign rfs_read_en = (current_state == st_epp_dataRDA);



endmodule