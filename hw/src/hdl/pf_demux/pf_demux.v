

`timescale 1ns / 1ps

module pf_demux(

input   S_AXI_LITE_clk,
input   S_AXI_LITE_aresetn,
input   M_AXI_LITE_ROLE0PF_clk,
input   M_AXI_LITE_ROLE0PF_aresetn,
input   M_AXI_LITE_ROLE1PF_clk,
input   M_AXI_LITE_ROLE1PF_aresetn,
input   M_AXI_LITE_SHELLPF_clk,
input   M_AXI_LITE_SHELLPF_aresetn,

// DEMUX Select Pins
input   wire [29 : 0]   S_AXI_LITE_awuser,
input   wire [29 : 0]   S_AXI_LITE_aruser,

// PCIE M_AXI_LITE BUS PORTS
input   wire [31 : 0]   S_AXI_LITE_awaddr,
input   wire [2 : 0]    S_AXI_LITE_awprot,
input   wire            S_AXI_LITE_awvalid,
output  wire            S_AXI_LITE_awready,
input   wire [31 : 0]   S_AXI_LITE_wdata,
input   wire [3 : 0]    S_AXI_LITE_wstrb,
input   wire            S_AXI_LITE_wvalid,
output  wire            S_AXI_LITE_wready,
output  wire            S_AXI_LITE_bvalid,
output  wire [1 : 0]    S_AXI_LITE_bresp,
input   wire            S_AXI_LITE_bready,

input   wire [31 : 0]   S_AXI_LITE_araddr,
input   wire [2 : 0]    S_AXI_LITE_arprot,
input   wire            S_AXI_LITE_arvalid,
output  wire            S_AXI_LITE_arready,
output  wire [31 : 0]   S_AXI_LITE_rdata,
output  wire [1 : 0]    S_AXI_LITE_rresp,
output  wire            S_AXI_LITE_rvalid,
input   wire            S_AXI_LITE_rready,

// ROLE0PF SAXI BUS Interface
output  wire [31 : 0]   M_AXI_LITE_awaddr_ROLE0PF,
output  wire [2 : 0]    M_AXI_LITE_awprot_ROLE0PF,
output  wire            M_AXI_LITE_awvalid_ROLE0PF,
input   wire            M_AXI_LITE_awready_ROLE0PF,
output  wire [31 : 0]   M_AXI_LITE_wdata_ROLE0PF,
output  wire [3 : 0]    M_AXI_LITE_wstrb_ROLE0PF,
output  wire            M_AXI_LITE_wvalid_ROLE0PF,
input   wire            M_AXI_LITE_wready_ROLE0PF,
input   wire [1 : 0]    M_AXI_LITE_bresp_ROLE0PF,
input   wire            M_AXI_LITE_bvalid_ROLE0PF,
output  wire            M_AXI_LITE_bready_ROLE0PF,

output  wire [31 : 0]   M_AXI_LITE_araddr_ROLE0PF,
output  wire [2 : 0]    M_AXI_LITE_arprot_ROLE0PF,
output  wire            M_AXI_LITE_arvalid_ROLE0PF,
input   wire            M_AXI_LITE_arready_ROLE0PF,
input   wire [31 : 0]   M_AXI_LITE_rdata_ROLE0PF,
input   wire [1 : 0]    M_AXI_LITE_rresp_ROLE0PF,
input   wire            M_AXI_LITE_rvalid_ROLE0PF,
output  wire            M_AXI_LITE_rready_ROLE0PF,

// ROLE1PF SAXI BUS Interface
output  wire [31 : 0]   M_AXI_LITE_awaddr_ROLE1PF,
output  wire [2 : 0]    M_AXI_LITE_awprot_ROLE1PF,
output  wire            M_AXI_LITE_awvalid_ROLE1PF,
input   wire            M_AXI_LITE_awready_ROLE1PF,
output  wire [31 : 0]   M_AXI_LITE_wdata_ROLE1PF,
output  wire [3 : 0]    M_AXI_LITE_wstrb_ROLE1PF,
output  wire            M_AXI_LITE_wvalid_ROLE1PF,
input   wire            M_AXI_LITE_wready_ROLE1PF,
input   wire [1 : 0]    M_AXI_LITE_bresp_ROLE1PF,
input   wire            M_AXI_LITE_bvalid_ROLE1PF,
output  wire            M_AXI_LITE_bready_ROLE1PF,

output  wire [31 : 0]   M_AXI_LITE_araddr_ROLE1PF,
output  wire [2 : 0]    M_AXI_LITE_arprot_ROLE1PF,
output  wire            M_AXI_LITE_arvalid_ROLE1PF,
input   wire            M_AXI_LITE_arready_ROLE1PF,
input   wire [31 : 0]   M_AXI_LITE_rdata_ROLE1PF,
input   wire [1 : 0]    M_AXI_LITE_rresp_ROLE1PF,
input   wire            M_AXI_LITE_rvalid_ROLE1PF,
output  wire            M_AXI_LITE_rready_ROLE1PF,

// SHELLPF SAXI BUS Interface
output  wire [31 : 0]   M_AXI_LITE_awaddr_SHELLPF,
output  wire [2 : 0]    M_AXI_LITE_awprot_SHELLPF,
output  wire            M_AXI_LITE_awvalid_SHELLPF,
input   wire            M_AXI_LITE_awready_SHELLPF,
output  wire [31 : 0]   M_AXI_LITE_wdata_SHELLPF,
output  wire [3 : 0]    M_AXI_LITE_wstrb_SHELLPF,
output  wire            M_AXI_LITE_wvalid_SHELLPF,
input   wire            M_AXI_LITE_wready_SHELLPF,
input   wire [1 : 0]    M_AXI_LITE_bresp_SHELLPF,
input   wire            M_AXI_LITE_bvalid_SHELLPF,
output  wire            M_AXI_LITE_bready_SHELLPF,

output  wire [31 : 0]   M_AXI_LITE_araddr_SHELLPF,
output  wire [2 : 0]    M_AXI_LITE_arprot_SHELLPF,
output  wire            M_AXI_LITE_arvalid_SHELLPF,
input   wire            M_AXI_LITE_arready_SHELLPF,
input   wire [31 : 0]   M_AXI_LITE_rdata_SHELLPF,
input   wire [1 : 0]    M_AXI_LITE_rresp_SHELLPF,
input   wire            M_AXI_LITE_rvalid_SHELLPF,
output  wire            M_AXI_LITE_rready_SHELLPF
    );


// wire and register declarations
reg [1:0] demux_select = 2'b10;


/////////////////////////////////////////////////////
// State Machine to control the demux Select Signal
/////////////////////////////////////////////////////

// STATE definition
reg         [4:0]   state           = 5'b00001;
localparam  [4:0]   IDLE            = 5'b00001,
                    WRITE_REQUEST   = 5'b00010,
                    READ_REQUEST    = 5'b00100,
                    WAIT_BRESP      = 5'b01000,
                    WAIT_RRESP      = 5'b10000;

always @(posedge S_AXI_LITE_clk)
begin
    if(!S_AXI_LITE_aresetn)
    begin
        demux_select        <= 2'b10;
        state               <= 5'b00001;
    end // end of if block
    else
    begin
        case (state)
            IDLE :begin
                if (S_AXI_LITE_awvalid)
                begin
                    state <= WRITE_REQUEST;
                end// end of if block
                else if (S_AXI_LITE_arvalid)
                begin
                    state <= READ_REQUEST;
                end // end of else if block
                else
                begin
                    state <= IDLE;
                end // end of else block

                demux_select        <= 2'b10;
            end // end of IDLE case

// WRITE REQUEST control logic is defined in the following states.

            WRITE_REQUEST :begin
                if(S_AXI_LITE_awuser[1:0]==2'b00)
                begin
                    demux_select <= 2'b10;
                end // end of if block
                else if(S_AXI_LITE_awuser[1:0]==2'b01)
                begin
                    demux_select <= 2'b00;
                end // end of else block
                else if(S_AXI_LITE_awuser[1:0]==2'b10)
                begin
                    demux_select <= 2'b01;
                end // end of else block

                state   <= WAIT_BRESP;
            end // end of WRITE_REQUEST

            WAIT_BRESP :begin
                if(S_AXI_LITE_bvalid & S_AXI_LITE_bready)
                begin
                    state        <= IDLE;
                    demux_select <= 2'b10;
                end
                else
                begin
                    state        <= WAIT_BRESP;
                    demux_select <= demux_select;
                end
            end // end of WAIT_BRESP

// READ REQUEST control logic is defined in the following blocks.

            READ_REQUEST :begin
                if(S_AXI_LITE_aruser[1:0]==2'b00)
                begin
                   demux_select <= 2'b10;
                end // end of if block
                else if(S_AXI_LITE_aruser[1:0]==2'b01)
                begin
                   demux_select <= 2'b00;
                end // end of if block
                else if(S_AXI_LITE_aruser[1:0]==2'b10)
                begin
                   demux_select <= 2'b01;
                end // end of if block

                state <= WAIT_RRESP;
            end // end of READ_REQUEST

            WAIT_RRESP : begin
                if(S_AXI_LITE_rvalid & S_AXI_LITE_rready)
                begin
                    state           <= IDLE;
                    demux_select    <= 2'b10;
                end
                else
                begin
                    state           <= WAIT_RRESP;
                    demux_select    <= demux_select;
                end
            end // end of WAIT_RRESP

        endcase// end of case block
    end
end // end of always block


///////////////////////////
// Write Channel Mappings
///////////////////////////

/*
Note : If the state machine is in WAIT_BRESP state , check for 2 conditions :-
a) if the demux_select is set to 1 , then connect to ShellPF else connect to Role0PF
b) if the state machine is not in WAIT_BRESP state, then drive awready to 0.
*/
assign S_AXI_LITE_awready = (state[3])? (demux_select[1]? M_AXI_LITE_awready_SHELLPF:
                                        (demux_select[0]? M_AXI_LITE_awready_ROLE1PF:
                                                          M_AXI_LITE_awready_ROLE0PF)): 0;

/*
Note:
if the state machine is in WAIT_BRESP state, check for 2 conditions :-
a) if the demux_select is set to 1 connect S_AXI_LITE_awvalid to ShellPF else drive to 0, viceversa for Role0PF
b) if !state[3] then drive both to 0
*/
assign M_AXI_LITE_awvalid_SHELLPF = (state[3])? ((demux_select[1:0]==2'b10)? S_AXI_LITE_awvalid: 0): 0;
assign M_AXI_LITE_awvalid_ROLE0PF = (state[3])? ((demux_select[1:0]==2'b00)? S_AXI_LITE_awvalid: 0): 0;
assign M_AXI_LITE_awvalid_ROLE1PF = (state[3])? ((demux_select[1:0]==2'b01)? S_AXI_LITE_awvalid: 0): 0;


/*
Similarly drive the wvalid and wready signals
*/
assign S_AXI_LITE_wready = (state[3])? (demux_select[1]? M_AXI_LITE_wready_SHELLPF:
                                       (demux_select[0]? M_AXI_LITE_wready_ROLE1PF:
                                                         M_AXI_LITE_wready_ROLE0PF)): 0;

assign M_AXI_LITE_wvalid_SHELLPF = (state[3])? ((demux_select[1:0]==2'b10)? S_AXI_LITE_wvalid: 0): 0;
assign M_AXI_LITE_wvalid_ROLE0PF = (state[3])? ((demux_select[1:0]==2'b00)? S_AXI_LITE_wvalid: 0): 0;
assign M_AXI_LITE_wvalid_ROLE1PF = (state[3])? ((demux_select[1:0]==2'b01)? S_AXI_LITE_wvalid: 0): 0;

// Bresp signal mapping
assign M_AXI_LITE_bready_SHELLPF = (state[3])? ((demux_select[1:0]==2'b10)? S_AXI_LITE_bready: 0): 0;
assign M_AXI_LITE_bready_ROLE0PF = (state[3])? ((demux_select[1:0]==2'b00)? S_AXI_LITE_bready: 0): 0;
assign M_AXI_LITE_bready_ROLE1PF = (state[3])? ((demux_select[1:0]==2'b01)? S_AXI_LITE_bready: 0): 0;

assign S_AXI_LITE_bvalid = (state[3])? (demux_select[1]? M_AXI_LITE_bvalid_SHELLPF:
                                       (demux_select[0]? M_AXI_LITE_bvalid_ROLE1PF:
                                                         M_AXI_LITE_bvalid_ROLE0PF)): 0;
assign S_AXI_LITE_bresp  = (state[3])? (demux_select[1]? M_AXI_LITE_bresp_SHELLPF:
                                       (demux_select[0]? M_AXI_LITE_bresp_ROLE1PF:
                                                         M_AXI_LITE_bresp_ROLE0PF)): 0;

assign M_AXI_LITE_awaddr_SHELLPF = S_AXI_LITE_awaddr & 32'h01FFFFFF;
assign M_AXI_LITE_awaddr_ROLE0PF = S_AXI_LITE_awaddr & 32'h01FFFFFF;
assign M_AXI_LITE_awaddr_ROLE1PF = S_AXI_LITE_awaddr & 32'h01FFFFFF;

assign M_AXI_LITE_awprot_SHELLPF = S_AXI_LITE_awprot;
assign M_AXI_LITE_awprot_ROLE0PF = S_AXI_LITE_awprot;
assign M_AXI_LITE_awprot_ROLE1PF = S_AXI_LITE_awprot;

assign M_AXI_LITE_wdata_SHELLPF = S_AXI_LITE_wdata;
assign M_AXI_LITE_wdata_ROLE0PF = S_AXI_LITE_wdata;
assign M_AXI_LITE_wdata_ROLE1PF = S_AXI_LITE_wdata;

assign M_AXI_LITE_wstrb_SHELLPF = S_AXI_LITE_wstrb;
assign M_AXI_LITE_wstrb_ROLE0PF = S_AXI_LITE_wstrb;
assign M_AXI_LITE_wstrb_ROLE1PF = S_AXI_LITE_wstrb;


//////////////////////////
// Read Channel Mappings
//////////////////////////

assign S_AXI_LITE_arready = (state[4])? (demux_select[1]? M_AXI_LITE_arready_SHELLPF:
                                        (demux_select[0]? M_AXI_LITE_arready_ROLE1PF:
                                                          M_AXI_LITE_arready_ROLE0PF)): 0;

assign M_AXI_LITE_arvalid_SHELLPF = (state[4])? ((demux_select[1:0]==2'b10)? S_AXI_LITE_arvalid: 0): 0;
assign M_AXI_LITE_arvalid_ROLE0PF = (state[4])? ((demux_select[1:0]==2'b00)? S_AXI_LITE_arvalid: 0): 0;
assign M_AXI_LITE_arvalid_ROLE1PF = (state[4])? ((demux_select[1:0]==2'b01)? S_AXI_LITE_arvalid: 0): 0;

assign S_AXI_LITE_rvalid = (state[4])? (demux_select[1]? M_AXI_LITE_rvalid_SHELLPF:
                                       (demux_select[0]? M_AXI_LITE_rvalid_ROLE1PF:
                                                         M_AXI_LITE_rvalid_ROLE0PF)): 0;

assign M_AXI_LITE_rready_SHELLPF = (state[4])? ((demux_select[1:0]==2'b10)? S_AXI_LITE_rready: 0): 0;
assign M_AXI_LITE_rready_ROLE0PF = (state[4])? ((demux_select[1:0]==2'b00)? S_AXI_LITE_rready: 0): 0;
assign M_AXI_LITE_rready_ROLE1PF = (state[4])? ((demux_select[1:0]==2'b01)? S_AXI_LITE_rready: 0): 0;

assign S_AXI_LITE_rdata = (state[4])? (demux_select[1]? M_AXI_LITE_rdata_SHELLPF:
                                      (demux_select[0]? M_AXI_LITE_rdata_ROLE1PF:
                                                        M_AXI_LITE_rdata_ROLE0PF)): 0;

assign S_AXI_LITE_rresp = (state[4])? (demux_select[1]? M_AXI_LITE_rresp_SHELLPF:
                                      (demux_select[0]? M_AXI_LITE_rresp_ROLE1PF:
                                                        M_AXI_LITE_rresp_ROLE0PF)): 0;

assign M_AXI_LITE_araddr_SHELLPF = S_AXI_LITE_araddr & 32'h01FFFFFF;
assign M_AXI_LITE_araddr_ROLE0PF = S_AXI_LITE_araddr & 32'h01FFFFFF;
assign M_AXI_LITE_araddr_ROLE1PF = S_AXI_LITE_araddr & 32'h01FFFFFF;

assign M_AXI_LITE_arprot_SHELLPF = S_AXI_LITE_arprot;
assign M_AXI_LITE_arprot_ROLE0PF = S_AXI_LITE_arprot;
assign M_AXI_LITE_arprot_ROLE1PF = S_AXI_LITE_arprot;

endmodule

