//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
//	FILE: 		basic_periDev.v
// 	AUTHOR:		Biggest_apple
// 	
//	ABSTRACT:	
// 	KEYWORDS:	fpga, basic module,signal process
// 
// 	MODIFICATION HISTORY:
//	$Log$
//			Biggest_apple				2024.12.20		Create the file
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
`timescale 				1ns/1ps
`include				"global_param.v"
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
/*
`define             ENABLE_ENHANCE_IO
*/
`define             DISABLE_ENHANCE_IO
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
module nvi_periDev(
	input					    clk,
	input					    reset_n,
//Naive-Memory Interface
    input                       mem_sel,
    input       [15:0]          mem_addr,
    input                       mem_we_n,
    input                       mem_rd_n,
    input                       mem_sfr_n,
    input       [7:0]           mem_wdata,

    output reg  [7:0]           mem_rdata,
    output                      mem_ready_out,
//Interrupt REQ PORT
    input       [7:0]           int_resp_n,

    output                      int_exIO0,
    output                      int_exIO1,
    output                      int_TF0,
    output                      int_TF1,
    output                      int_UART0,

//IO Port & USART PORT
    inout       [7:0]           io_p0,
    inout       [7:0]           io_p1,
    inout       [7:0]           io_p2,
    inout       [7:0]           io_p3,

    input                       us_rx,
    output                      us_tx

);

reg     [7:0]       TCON_q;
reg     [7:0]       TCON_d;
reg     [7:0]       TMOD_q;
reg     [7:0]       TMOD_d;

reg     [7:0]       SCON_q;
reg     [7:0]       SCON_d;
reg     [7:0]       SBUF_q;
reg     [7:0]       SBUF_d;

reg     [7:0]       PCON_q;
reg     [7:0]       PCON_d;
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
reg     [3:0]       clk_div12_cnt;
always_ff @(posedge clk or negedge reset_n) begin : CLK_DIV12_GENERATOR
    if(~reset_n)    clk_div12_cnt   <=  'd1;
    else            clk_div12_cnt   <=  (clk_div12_cnt  ==  'd12)   ?   'd1 :   clk_div12_cnt + 1;
end
wire                clk_div12_pluse =   (clk_div12_cnt  ==  'd6 );
wire                clk_div12_seq   =   (clk_div12_cnt  >=  'd6 );
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
reg     [1:0]       t0_extIN_saFF;
always_ff @(posedge clk or negedge reset_n) begin : T0_EXTIN_SA_FlipFlop
    if(~reset_n)    t0_extIN_saFF   <=  2'b00;
    else            t0_extIN_saFF   <=  (clk_div12_pluse  ==  1'b1)   ?   {t0_extIN_saFF[0],io_p3[4]} :   t0_extIN_saFF;
end
wire                t0_extIN_neg    =   (t0_extIN_saFF  ==  2'b10);
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
reg     [1:0]       t1_extIN_saFF;
always_ff @(posedge clk or negedge reset_n) begin : T1_EXTIN_SA_FlipFlop
    if(~reset_n)    t1_extIN_saFF   <=  2'b00;
    else            t1_extIN_saFF   <=  (clk_div12_pluse  ==  1'b1)   ?   {t1_extIN_saFF[0],io_p3[5]} :   t1_extIN_saFF;
end
wire                t1_extIN_neg    =   (t1_extIN_saFF  ==  2'b10);
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
reg                 w_GATE0;
reg                 w_CT0;

reg                 w_GATE1;
reg                 w_CT1;

reg                 t0_refPulse;
reg                 t1_refPulse;

always_comb begin : TIMER0_RefPulse_SOURCE
    if(w_CT0    ==  1'b0)
        t0_refPulse     =   ((~w_GATE0)  |  io_p3[2])    ?   clk_div12_pluse    :   1'b0;
    else
        t0_refPulse     =   ((~w_GATE0)  |  io_p3[2])    ?   t0_extIN_neg       :   1'b0;
end

always_comb begin : TIMER1_RefPulse_SOURCE
    if(w_CT1    ==  1'b0)
        t1_refPulse     =   ((~w_GATE1)  |  io_p3[3])    ?   clk_div12_pluse    :   1'b0;
    else
        t1_refPulse     =   ((~w_GATE1)  |  io_p3[3])    ?   t1_extIN_neg       :   1'b0;
end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
reg     [7:0]       TH0_q,TH0_d;
reg     [7:0]       TL0_q,TL0_d;
reg     [7:0]       TH1_q,TH1_d;
reg     [7:0]       TL1_q,TL1_d;

reg     [7:0]       TH0_d0,TL0_d0;
reg     [7:0]       TH1_d0,TL1_d0;

reg                 w_TR0;
reg                 w_TR1;
                            //  Stupid Design here ... ...
reg     [1:0]       w_MOD0;
reg     [1:0]       w_MOD1;

reg                 TF0_d0;
reg                 TF0_q;

reg                 TF1_d0;
reg                 TF1_q;
                            //  TF1_d1 is used for baud rate generation
reg                 TF1_d1;

wire    [15:0]      T0_16B  =   {TH0_q,     TL0_q};
wire    [15:0]      T1_16B  =   {TH1_q,     TL1_q};
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always_ff @(posedge clk or negedge reset_n) begin : TIMER_FFLOGIC
    if(~reset_n) begin
        {TH0_q,     TL0_q}  <=  16'h00_00;
        {TH1_q,     TL1_q}  <=  16'h00_00;
    end else begin
        {TH0_q,     TL0_q}  <=  {TH0_d,     TL0_d};
        {TH1_q,     TL1_q}  <=  {TH1_d,     TL1_d};
    end
end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always_comb begin : TIMER_COLOGIC
    TH0_d0              =   TH0_q;
    TL0_d0              =   TL0_q;
    TF0_d0              =   TF0_q;

    TH1_d0              =   TH1_q;
    TL1_d0              =   TL1_q;
    TF1_d0              =   TF1_q;

    TF1_d1              =   1'b0;

                            // Classify different working modes for timer0
    case(w_MOD0)
        2'b00:  
            begin
                {TH0_d,     TL0_d}      =   (T0_16B[13] ==  1'b1    &&  w_TR0   &&  t0_refPulse)   ?   'b0     :   T0_16B +1;
//              {TH1_d,     TL1_d}      =   (T1_16B[13] ==  1'b1    &&  w_TR1   &&  t1_refPulse)   ?   'b0     :   T1_16B +1;

//              TF1_d0                  =   (T1_16B[13] ==  1'b1)   ?   1'b1    :   TF1_q;
                TF0_d0                  =   (T0_16B[13] ==  1'b1)   ?   1'b1    :   TF0_q;
            end
        2'b01:
            begin
                {TH0_d,     TL0_d}      =   (&  T0_16B ==  1'b1    &&  w_TR0   &&  t0_refPulse)   ?   'b0     :   T0_16B +1;
//              {TH1_d,     TL1_d}      =   (&  T1_16B ==  1'b1    &&  w_TR1   &&  t1_refPulse)   ?   'b0     :   T1_16B +1;

//              TF1_d0                  =   (&  T1_16B ==  1'b1)    ?   1'b1    :   TF1_q;
                TF0_d0                  =   (&  T0_16B ==  1'b1)    ?   1'b1    :   TF0_q;
            end
        2'b10:
            begin
                            // AutoReload mode
                TL0_d                   =   (&  TL0_q ==  1'b1    &&  w_TR0   &&  t0_refPulse)    ?   TH0_q   :   TL0_q +1;
//              TL1_d                   =   (&  TL1_q ==  1'b1    &&  w_TR1   &&  t1_refPulse)    ?   TH1_q   :   TL1_q +1;

//              TF1_d0                  =   (&  TL1_q ==  1'b1)     ?   1'b1    :   TF1_q;
                TF0_d0                  =   (&  TL0_q ==  1'b1)     ?   1'b1    :   TF0_q;
            end
        2'b11:
            begin
                TL0_d                   =   (&  TL0_q ==  1'b1    &&  w_TR0   &&  t0_refPulse)    ?   'b0     :   TL0_q +1;
                TH0_d                   =   (&  TH0_q ==  1'b1    &&  w_TR1   &&  t1_refPulse)    ?   'b0     :   TH0_q +1;

                TF1_d0                  =   (&  TH0_q ==  1'b1)     ?   1'b1    :   TF1_q;
                TF0_d0                  =   (&  TL0_q ==  1'b1)     ?   1'b1    :   TF0_q;

                TL1_d                   =   (&  TL1_q ==  1'b1)     ?   TH1_q   :   TL1_q +1;
                TF1_d1                  =   (&  TL1_q ==  1'b1);
            end
        default:    begin       end
    endcase
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
    case(w_MOD1)
        2'b00:
            begin
                {TH1_d,     TL1_d}      =   (T1_16B[13] ==  1'b1    &&  w_TR1   &&  t1_refPulse)   ?   'b0     :   T1_16B +1;
                TF1_d0                  =   (T1_16B[13] ==  1'b1)   ?   1'b1    :   TF1_q;
            end
        2'b01:
            begin
                {TH1_d,     TL1_d}      =   (&  T1_16B ==  1'b1     &&  w_TR1   &&  t1_refPulse)   ?   'b0     :   T1_16B +1;
                TF1_d0                  =   (&  T1_16B ==  1'b1)    ?   1'b1    :   TF1_q;
            end
        2'b10:
            begin
                TL1_d                   =   (&  TL1_q ==  1'b1      &&  w_TR1   &&  t1_refPulse)    ?   TH1_q   :   TL1_q +1;
                TF1_d0                  =   (&  TL1_q ==  1'b1)     ?   1'b1    :   TF1_q;
            end
        2'b11:
            begin
                $display ("%m :at time %t Error: Not support such timer1_MOD --> 2'b11 .", $time);
            end
        default:    begin       end
    endcase
end

//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
reg                 w_SMOD;
/*
reg                 uart_baudRate_pulse;
*/
reg     [1:0]       TF1_d0_saFF;
always_ff @(posedge clk or negedge reset_n)
    if(~reset_n)    TF1_d0_saFF     <=  2'b00;
    else            TF1_d0_saFF     <=  {TF1_d0_saFF[0],TF1_d1};
wire                TF1_d0_pos      =   (TF1_d0_saFF ==  2'b01);

reg     [4:0]       uart_baudRate_cnt;
always_ff @(posedge clk or negedge reset_n) begin : UART0_BandRate_SOURCE
    if(~reset_n   |   w_MOD != 2'b11)    
        uart_baudRate_cnt           <=  5'h0;
    else if(TF1_d0_pos)
        uart_baudRate_cnt           <=  uart_baudRate_cnt  +    (5'h1   <<  w_SMOD)
end

reg     [1:0]       uart_baudRate_cnt_saFF;
always_ff @(posedge clk or negedge reset_n)
    if(~reset_n)    uart_baudRate_cnt_saFF     <=   2'b00;
    else            uart_baudRate_cnt_saFF     <=   {uart_baudRate_cnt_saFF[0],uart_baudRate_cnt[4]};
wire                uart_baudRate_pulse        =    (uart_baudRate_cnt_saFF ==  2'b01);
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
reg                 uart_wr_sbuf_active;
reg                 SM0_FE_q;
reg                 RI_q,TI_q;

reg                 SM0_FE_clr;
reg                 RI_clr,TI_clr;                
                            //There are four serial port modes for 8051's uart
                            //Remark : 'sa' means --> 'sample'
reg                 uart_rd_sbuf_active;
reg     [2:0]       uart_rx_saFF;
always_ff @(posedge clk or negedge reset_n)
    if(~reset_n)    uart_rx_saFF                <=  3'b111;
    else if(clk_div12_pluse)
        uart_rx_saFF    <=  {uart_rx_saFF[1:0],us_rx};
wire                uart_rx_sa  =   ~(uart_rx_saFF  ==  3'b000);

reg                 uart_tx_triGate;
reg                 uart_rx_triGate;

reg     [3:0]       uart_tx_bitcnt;
reg     [3:0]       uart_rx_bitcnt;

wire                w_TB8;

reg     [7:0]       uart_tx_buf_fromBus_d;
reg     [8:0]       uart_tx_buf;
reg     [8:0]       uart_rx_buf;

reg     [2:0]       uart_tx_wstate;

localparam          UART_TX_IDLE    =   'd0;
localparam          UART_TX_ACT0    =   'd1;
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always_ff @(posedge clk or negedge reset_n) begin : UART0_TX_FFLOGIC
    if(~reset_n) begin
        uart_tx_bitcnt      <=  4'h0;
        TI_q                <=  1'b0;

        uart_tx_wstate      <=  UART_TX_IDLE;
        uart_tx_buf         <=  9'b1_1111_1111;
    end else begin

        case(uart_tx_wstate)
            UART_TX_IDLE:
                begin
                    TI_q                <=  (   TI_clr  )   ?   1'b0:   TI_q;
                    if(uart_wr_sbuf_active) begin
                            //Load TX Data to TX buffer
                            //TODO: HERE    ... ...
                        uart_tx_buf     <=  {w_TB8, uart_tx_buf_fromBus_d   };
                        uart_tx_wstate  <=  UART_TX_ACT0;
                    end else
                        uart_tx_wstate  <=  UART_TX_IDLE;
                end
            UART_TX_ACT0:   //Remark: ACT0 state is for synchornization operation
                if()
            default:    begin       end
        endcase
    end

end

always_ff @(posedge clk or negedge reset_n) begin : UART0_RX_FFLOGIC
    if(~reset_n) begin
       uart_rx_bitcnt       <=  4'h0; 

       uart_wstate          <=  UART_RX_IDLE;
    end else begin
        

    end

end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always_comb begin : UART0_COLOGIC
    uart_tx_triGate =   1'b1;
    uart_rx_triGate =   1'bz;

    case(w_SMOD)
        2'b00:
            begin
                
            end

    endcase
end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//



//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
endmodule