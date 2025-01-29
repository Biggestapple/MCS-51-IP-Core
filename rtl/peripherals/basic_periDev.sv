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
    input                       intEX0_n,
    input                       intEX1_n,

    inout       [7:0]           io_p0,
    inout       [7:0]           io_p1,
    inout       [7:0]           io_p2,
    inout       [7:0]           io_p3,

    input                       us_rx,
    output                      us_tx

);
/*
        int_UART0_ack_n,int_TF1_ack_n,int_exIO1_ack_n,int_TF0_ack_n,int_exIO0_ack_n
*/
wire    int_UART0_ack_n,int_TF1_ack_n,int_exIO1_ack_n,int_TF0_ack_n,int_exIO0_ack_n;
assign  {int_UART0_ack_n,int_TF1_ack_n,int_exIO1_ack_n,int_TF0_ack_n,int_exIO0_ack_n}   =   int_resp_n[4:0];
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
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
wire                periDev_config_active   =   ~mem_sfr_n  &&  mem_sel;
wire                PCON_config_active  =   (~mem_we_n    &&  periDev_config_active)   &&  (mem_addr[7:0]  ==  `PCON);
wire                TCON_config_active  =   (~mem_we_n    &&  periDev_config_active)   &&  (mem_addr[7:0]  ==  `TCON);
wire                uart_wr_sbuf_active =   (~mem_we_n    &&  periDev_config_active)   &&  (mem_addr[7:0]  ==  `SBUF);
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
reg     [3:0]       clk_div12_cnt;
always_ff @(posedge clk or negedge reset_n) begin : CLK_DIV12_GENERATOR
    if(~reset_n)    clk_div12_cnt   <=  'd1;
    else            clk_div12_cnt   <=  (clk_div12_cnt  ==  'd12)   ?   'd1 :   clk_div12_cnt + 1;
end
wire                clk_div12_pluse =   (clk_div12_cnt  ==  'd6 );
wire                clk_div12_seq   =   (clk_div12_cnt  >=  'd6 );
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
reg     [0:0]       clk_div2_cnt;
always_ff @(posedge clk or negedge reset_n) begin : CLK_DIV2_GENERATOR
    if(~reset_n)    clk_div2_cnt    <=  'd1;
    else            clk_div2_cnt    <=  clk_div2_cnt    +  1;
end
wire                clk_div2_pulse  =   (clk_div2_cnt   ==  'd0);
wire                clk_div2_seq    =   clk_div2_cnt;
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
wire                w_GATE0;
wire                w_CT0;

wire                w_GATE1;
wire                w_CT1;

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

wire                w_TR0;
wire                w_TR1;

wire                w_IT1;
wire                w_IT0;
                            //  Stupid Design here ... ...
wire    [1:0]       w_MOD0;
wire    [1:0]       w_MOD1;

reg                 TF0_d0;
reg                 TF0_q;

reg                 TF1_d0;
reg                 TF1_q;
                            //  TF1_d1 is used for baud rate generation
reg                 TF1_d1;
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
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
                {TH0_d0,     TL0_d0}    =   (T0_16B[13] ==  1'b1    &&  w_TR0   &&  t0_refPulse)   ?   'b0     :   T0_16B +1;
//              {TH1_d0,     TL1_d0}    =   (T1_16B[13] ==  1'b1    &&  w_TR1   &&  t1_refPulse)   ?   'b0     :   T1_16B +1;

//              TF1_d0                  =   (T1_16B[13] ==  1'b1)   ?   1'b1    :   TF1_q;
                TF0_d0                  =   (T0_16B[13] ==  1'b1)   ?   1'b1    :   TF0_q;
            end
        2'b01:
            begin
                {TH0_d0,     TL0_d0}    =   (&  T0_16B ==  1'b1    &&  w_TR0   &&  t0_refPulse)   ?   'b0     :   T0_16B +1;
//              {TH1_d0,     TL1_d0}    =   (&  T1_16B ==  1'b1    &&  w_TR1   &&  t1_refPulse)   ?   'b0     :   T1_16B +1;

//              TF1_d0                  =   (&  T1_16B ==  1'b1)    ?   1'b1    :   TF1_q;
                TF0_d0                  =   (&  T0_16B ==  1'b1)    ?   1'b1    :   TF0_q;
            end
        2'b10:
            begin
                            // AutoReload mode
                TL0_d0                  =   (&  TL0_q ==  1'b1    &&  w_TR0   &&  t0_refPulse)    ?   TH0_q   :   TL0_q +1;
//              TL1_d0                  =   (&  TL1_q ==  1'b1    &&  w_TR1   &&  t1_refPulse)    ?   TH1_q   :   TL1_q +1;

//              TF1_d0                  =   (&  TL1_q ==  1'b1)     ?   1'b1    :   TF1_q;
                TF0_d0                  =   (&  TL0_q ==  1'b1)     ?   1'b1    :   TF0_q;
            end
        2'b11:
            begin
                TL0_d0                  =   (&  TL0_q ==  1'b1    &&  w_TR0   &&  t0_refPulse)    ?   'b0     :   TL0_q +1;
                TH0_d0                  =   (&  TH0_q ==  1'b1    &&  w_TR1   &&  t1_refPulse)    ?   'b0     :   TH0_q +1;

                TF1_d0                  =   (&  TH0_q ==  1'b1)     ?   1'b1    :   TF1_q;
                TF0_d0                  =   (&  TL0_q ==  1'b1)     ?   1'b1    :   TF0_q;

                TL1_d0                  =   (&  TL1_q ==  1'b1)     ?   TH1_q   :   TL1_q +1;
                TF1_d1                  =   (&  TL1_q ==  1'b1);
            end
        default:    begin       end
    endcase
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
    case(w_MOD1)
        2'b00:
            begin
                {TH1_d0,     TL1_d0}    =   (T1_16B[13] ==  1'b1    &&  w_TR1   &&  t1_refPulse)   ?   'b0     :   T1_16B +1;
                TF1_d0                  =   (T1_16B[13] ==  1'b1)   ?   1'b1    :   TF1_q;
            end
        2'b01:
            begin
                {TH1_d0,     TL1_d0}    =   (&  T1_16B ==  1'b1     &&  w_TR1   &&  t1_refPulse)   ?   'b0     :   T1_16B +1;
                TF1_d0                  =   (&  T1_16B ==  1'b1)    ?   1'b1    :   TF1_q;
            end
        2'b10:
            begin
                TL1_d0                  =   (&  TL1_q ==  1'b1      &&  w_TR1   &&  t1_refPulse)    ?   TH1_q   :   TL1_q +1;
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
reg     [1:0]       w_SM01;
reg     [1:0]       TF1_d0_saFF;
always_ff @(posedge clk or negedge reset_n)
    if(~reset_n)    TF1_d0_saFF     <=  2'b00;
    else            TF1_d0_saFF     <=  {TF1_d0_saFF[0],TF1_d1};
wire                TF1_d0_pos      =   (TF1_d0_saFF ==  2'b01);
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
wire                uart_baudRate_source_pulse      =   (w_SM01 ==  2'b01 || w_SM01 == 2'b10)   ?   TF1_d0_pos  :   clk_div2_pulse;
reg     [4:0]       uart_tx_baudRate_cnt;
always_ff @(posedge clk or negedge reset_n) begin : UART0_TX_BandRate_SOURCE
    if(~reset_n )    
        uart_tx_baudRate_cnt        <=  5'h0;
    else if(uart_baudRate_source_pulse)
        uart_tx_baudRate_cnt        <=  uart_tx_baudRate_cnt  +    (5'h1   <<  w_SMOD);
end

reg     [1:0]       uart_tx_baudRate_cnt_saFF;
always_ff @(posedge clk or negedge reset_n)
    if(~reset_n)    uart_tx_baudRate_cnt_saFF   <=   2'b00;
    else            uart_tx_baudRate_cnt_saFF   <=   {uart_tx_baudRate_cnt_saFF[0],uart_tx_baudRate_cnt[4]};
wire                uart_tx_baudRate_pulse      =    (uart_tx_baudRate_cnt_saFF ==  2'b01);
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
reg     [4:0]       uart_rx_baudRate_cnt;
reg                 uart_rx_active;
always_ff @(posedge clk or negedge reset_n) begin : UART0_RX_BandRate_SOURCE
    if(~reset_n )    
        uart_rx_baudRate_cnt        <=  5'h0;
    else if(uart_rx_active)
        uart_rx_baudRate_cnt        <=  5'h0;
    else if(uart_baudRate_source_pulse)
        uart_rx_baudRate_cnt        <=  uart_rx_baudRate_cnt  +    (5'h1   <<  w_SMOD);
end

reg     [1:0]       uart_rx_baudRate_cnt_saFF;
always_ff @(posedge clk or negedge reset_n)
    if(~reset_n)    uart_rx_baudRate_cnt_saFF   <=   2'b00;
    else            uart_rx_baudRate_cnt_saFF   <=   {uart_rx_baudRate_cnt_saFF[0],uart_tx_baudRate_cnt[4]};
wire                uart_rx_baudRate_pulse      =    (uart_rx_baudRate_cnt_saFF ==  2'b01);
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
//wire              uart_wr_sbuf_active;
reg                 SM0_FE_q;
reg                 RI_q,TI_q;

reg                 SM0_FE_clr;
reg                 RI_clr,TI_clr;    
                            //There are four serial port modes for 8051's uart
                            //Remark : 'sa' means --> 'sample'
reg                 uart_rd_sbuf_active;
reg     [2:0]       uart_rx_saFF;

reg                 uart_tx_triGate;
reg                 uart_rx_triGate;
always_ff @(posedge clk or negedge reset_n)
    if(~reset_n)    uart_rx_saFF                <=  3'b111;
    else if(clk_div12_pluse)
        uart_rx_saFF    <=  {uart_rx_saFF[1:0],uart_rx_triGate};
wire                uart_rx_sa  =   ~(uart_rx_saFF  ==  3'b000);

reg     [3:0]       uart_tx_bitcnt;
reg     [3:0]       uart_rx_bitcnt;

wire                w_TB8;
wire                w_REN;
wire                w_SMOD0;

reg     [7:0]       uart_tx_buf_fromBus_d;
reg     [8:0]       uart_tx_buf;
reg     [8:0]       uart_rx_buf;

reg     [2:0]       uart_tx_wstate;
/*
reg     [7:0]       uart_clk_divForSM10;
*/
localparam          UART_TX_IDLE        =   'd0;
localparam          UART_TX_ACT0        =   'd1;
localparam          UART_TX_ACT1        =   'd2;
localparam          UART_TX_DONE        =   'd4;
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always_ff @(posedge clk or negedge reset_n) begin : UART0_TX_FFLOGIC
    if(~reset_n) begin
        uart_tx_bitcnt      <=  4'h0;
        TI_q                <=  1'b0;

        uart_tx_wstate      <=  UART_TX_IDLE;
        uart_tx_buf         <=  9'b1_1111_1111;
//      uart_clk_divForSM10 <=  8'h00;
    end else begin

        case(uart_tx_wstate)
            UART_TX_IDLE:
                begin
                    TI_q                    <=  (   TI_clr  )   ?   1'b0:   TI_q;
                    if(uart_wr_sbuf_active) begin
                            //Load TX Data to TX buffer
                            //TODO: HERE    ... ...
                        uart_tx_bitcnt      <=  'd0;
//                      uart_clk_divForSM10 <=  'd0;

                        uart_tx_buf         <=  {w_TB8, uart_tx_buf_fromBus_d   };
                        uart_tx_wstate      <=  UART_TX_ACT0;
                    end else
                        uart_tx_wstate      <=  UART_TX_IDLE;
                end
            UART_TX_ACT0:   //Remark: ACT0 state is for synchornization operation
                if(clk_div12_pluse)
                    uart_tx_wstate      <=  UART_TX_ACT1;
                else
                    uart_tx_wstate      <=  UART_TX_ACT0;
            UART_TX_ACT1:
                case(w_SM01)
                    2'b00:  //Serial Port Mode 0
                        if(clk_div12_pluse) begin
                            uart_tx_bitcnt      <=  (uart_tx_bitcnt ==  'd7)    ?   'd0 :   uart_tx_bitcnt  +   1;
                            // LSB Mode
                            if(uart_tx_bitcnt ==  'd7)
                                uart_tx_wstate  <=  UART_TX_DONE;
                        end
                    2'b01,2'b11,2'b10:
                        if(uart_tx_baudRate_pulse) begin
                            if(uart_tx_bitcnt   ==  ('d1 +'d2 + 'd8 + w_SM01[1] )   ) begin
                            // Sync_t + start_t + end_t + bit_8_t + exbit_1_t
                                uart_tx_wstate  <=  UART_TX_DONE;
                            end else
                                uart_tx_bitcnt  <=  uart_tx_bitcnt  +   1;
                        end
/*
                    2'b10:
                        if(     (w_SMOD   ==  1'b1    &&  uart_clk_divForSM10 == 'd31)
                           ||   (w_SMOD   ==  1'b0    &&  uart_clk_divForSM10 == 'd63)      ) begin
                            
                                if(uart_tx_bitcnt   ==  'd1 +'d2 + 'd8 +'d1)
                                    uart_tx_wstate  <=  UART_TX_DONE;
                                else
                                    uart_tx_bitcnt  <=  uart_tx_bitcnt  +   1;
                            
                            end else    begin
                                uart_clk_divForSM10 <=  uart_clk_divForSM10 +1;
                            end
*/
                    default:    begin       end
                endcase
            UART_TX_DONE:
                begin
                    TI_q            <=  1'b1;
                    uart_tx_wstate  <=  UART_TX_IDLE;
                end
            default:    begin       end
        endcase
    end

end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
reg     [2:0]       uart_rx_wstate;
localparam          UART_RX_IDLE        =   'd0;
localparam          UART_RX_SM00_SYNC   =   'd1;
localparam          UART_RX_SM00_ACT0   =   'd2;
localparam          UART_RX_SERI_ACT0   =   'd3;
localparam          UART_RX_SERI_ACT1   =   'd4;
localparam          UART_RX_DONE        =   'd5;

always_ff @(posedge clk or negedge reset_n) begin : UART0_RX_FFLOGIC
    if(~reset_n) begin
        uart_rx_bitcnt      <=  4'h0; 
        uart_rx_wstate      <=  UART_RX_IDLE;

        RI_q                <=  1'b0;
        SM0_FE_q            <=  1'b0;

        uart_rx_active      <=  1'b0;
        uart_rx_buf         <=  9'b0_0000_0000;
    end else begin
        uart_rx_active      <=  1'b0;
        case(uart_rx_wstate)
            UART_RX_IDLE:
                begin
                    RI_q        <=  (   RI_clr      )   ?   1'b0:   RI_q;
                    SM0_FE_q    <=  (   SM0_FE_clr  )   ?   1'b0:   SM0_FE_q;
                    if(w_REN    ==  1'b1) begin
                        if(w_SM01   ==  2'b00) begin
                            if( RI_clr  ) begin
                                uart_rx_wstate  <=  UART_RX_SM00_SYNC;
                                uart_rx_bitcnt  <=  4'h0;
                            end
                        end else begin
                            if(uart_rx_sa   ==  1'b0) begin
                                uart_rx_active  <=  1'b1;
                                uart_rx_wstate  <=  UART_RX_SERI_ACT0;
                                uart_rx_bitcnt  <=  4'h0;
                            end
                        end
                    end
                end
            UART_RX_SERI_ACT0:
                if(uart_rx_baudRate_pulse)
                    if(uart_rx_sa   ==  1'b0)
                        uart_rx_wstate      <=  UART_RX_SERI_ACT1;
                    else
                        uart_rx_wstate      <=  UART_RX_IDLE;
                else
                    uart_rx_wstate          <=  UART_RX_SERI_ACT0;
            UART_RX_SERI_ACT1:
                begin
                    if(uart_rx_baudRate_pulse) begin
                        uart_rx_bitcnt              <=  uart_rx_bitcnt + 1;
                        if(uart_rx_bitcnt   <=  ('d7 + w_SM01[1]))
                            uart_rx_buf[uart_rx_bitcnt]     <=  uart_rx_sa;
                        else if(uart_rx_bitcnt  ==  ('d8 + w_SM01[1]))
                            if(uart_rx_sa   )
                                uart_rx_wstate      <=  UART_RX_DONE;
                            else begin
                                uart_rx_wstate      <=  UART_RX_DONE;
                                SM0_FE_q            <=  1'b1;
                            end
                    end
                end
            UART_RX_SM00_SYNC:
                if(clk_div12_pluse)
                    uart_rx_wstate          <=  UART_RX_SM00_ACT0;
                else
                    uart_rx_wstate          <=  UART_RX_SM00_SYNC;
            UART_RX_SM00_ACT0:
                if(clk_div12_pluse) begin
                    uart_rx_bitcnt                      <=  uart_rx_bitcnt +1;
                    uart_rx_buf[uart_rx_bitcnt]         <=  uart_rx_sa;

                    if(uart_rx_bitcnt   ==  'd7)
                        uart_rx_wstate      <=  UART_RX_DONE;
                end
            UART_RX_DONE:
                begin
                    RI_q            <=  1'b1;
                    uart_rx_wstate  <=  UART_RX_IDLE;
                end
            default:    begin           end
        endcase
    end
end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always_comb begin : UART0_COLOGIC
    uart_tx_triGate =   1'b1;
    uart_rx_triGate =   1'bz;

    case(w_SM01)
        2'b00:
            if(uart_tx_wstate   ==  UART_TX_ACT0) begin
                uart_rx_triGate =   uart_tx_buf[uart_tx_bitcnt];
            end else if(uart_tx_wstate  ==  UART_TX_ACT1) begin
                uart_rx_triGate =   uart_tx_buf[uart_tx_bitcnt];
                uart_tx_triGate =   clk_div12_seq;
            end else if(uart_rx_wstate  ==  UART_RX_SM00_ACT0)
                uart_tx_triGate =   clk_div12_seq;
        2'b01,2'b10,2'b11:
            if(uart_tx_wstate   ==  UART_TX_ACT1)
                case(uart_tx_bitcnt)
                    'd1:    uart_tx_triGate =   1'b1;
                    'd2:    uart_tx_triGate =   1'b0;
                    'd3,'d4,'d5,'d6,'d7,'d8,'d9,'d10:
                            uart_tx_triGate =   uart_tx_buf[uart_tx_bitcnt - 'd3];
                    'd11:
                        if(w_SM01[1]    ==  1'b1)
                            uart_tx_triGate =   uart_tx_buf[uart_tx_bitcnt - 'd3];
                        else
                            uart_tx_triGate =   1'b1;
                    'd12:
                        uart_tx_triGate     =   1'b1;
                endcase
        default:    begin   uart_tx_triGate =   1'bz;   end
    endcase
end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
reg     [7:0]       io_p0_q;
reg     [7:0]       io_p0_d0;
reg     [7:0]       io_p1_q;
reg     [7:0]       io_p1_d0;
reg     [7:0]       io_p2_q;
reg     [7:0]       io_p2_d0;
reg     [7:0]       io_p3_q;
reg     [7:0]       io_p3_d0;

reg     [7:0]       io_p0_d1;
reg     [7:0]       io_p1_d1;
reg     [7:0]       io_p2_d1;
reg     [7:0]       io_p3_d1;

`ifdef ENABLE_ENHANCE_IO
reg     [7:0]       IOCON0_q;
reg     [7:0]       IOCON0_d;
reg     [7:0]       IOCON1_q;
reg     [7:0]       IOCON1_d;
reg     [7:0]       IOCON2_q;
reg     [7:0]       IOCON2_d;
reg     [7:0]       IOCON3_q;
reg     [7:0]       IOCON3_d;
`endif
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
reg     [7:0]       io_p0_sa0,io_p0_sa1;
reg     [7:0]       io_p1_sa0,io_p1_sa1;
reg     [7:0]       io_p2_sa0,io_p2_sa1;
reg     [7:0]       io_p3_sa0,io_p3_sa1;
always_ff @(posedge clk)    {io_p0_sa1,io_p0_sa0}   <=  {io_p0_sa0,io_p0    };
always_ff @(posedge clk)    {io_p1_sa1,io_p1_sa0}   <=  {io_p1_sa0,io_p1    };
always_ff @(posedge clk)    {io_p2_sa1,io_p2_sa0}   <=  {io_p2_sa0,io_p2    };
always_ff @(posedge clk)    {io_p3_sa1,io_p3_sa0}   <=  {io_p3_sa0,io_p3    };
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
`ifdef ENABLE_ENHANCE_IO
                            //TODO: RESERVE

`elsif DISABLE_ENHANCE_IO
genvar      io_index;
    always_comb begin : IO_COLOGIC
        io_p0_d1        =       io_p0_sa1;
        io_p1_d1        =       io_p1_sa1;
        io_p2_d1        =       io_p2_sa1;
        io_p3_d1        =       io_p3_sa1;
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
//        generate

//TODO:
/*
            for(io_index =0; io_index <8; io_index = io_index +1) begin
                io_p0[io_index] =   io_p0_q[io_index]   ?   1'bz    :   1'b0;
                io_p1[io_index] =   io_p1_q[io_index]   ?   1'bz    :   1'b0;
                io_p2[io_index] =   io_p2_q[io_index]   ?   1'bz    :   1'b0;
                io_p3[io_index] =   io_p3_q[io_index]   ?   1'bz    :   1'b0;
            end
*/
//        endgenerate
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
    end
            for(io_index =0; io_index <8; io_index = io_index +1) begin
                assign  io_p0[io_index] =   io_p0_q[io_index]   ?   1'bz    :   1'b0;
                assign  io_p1[io_index] =   io_p1_q[io_index]   ?   1'bz    :   1'b0;
                assign  io_p2[io_index] =   io_p2_q[io_index]   ?   1'bz    :   1'b0;
                assign  io_p3[io_index] =   io_p3_q[io_index]   ?   1'bz    :   1'b0;
            end
`endif
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always_ff @(posedge clk or negedge reset_n) begin : IO_CON_FFLOGIC
    if(~reset_n) begin
        io_p0_q             <=      8'b1111_1111;
        io_p1_q             <=      8'b1111_1111;
        io_p2_q             <=      8'b1111_1111;
        io_p3_q             <=      8'b1111_1111;
    end else begin
        io_p0_q             <=      io_p0_d0;
        io_p1_q             <=      io_p1_d0;
        io_p2_q             <=      io_p2_d0;
        io_p3_q             <=      io_p3_d0;
    end
end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always_ff @(posedge clk or negedge reset_n) begin : SFR_CON_FFLOGIC
    if(~reset_n) begin
        SCON_q              <=      8'b0000_0000;
        PCON_q              <=      8'b00z1_0000;
        TMOD_q              <=      8'b0000_0000;
        TCON_q              <=      8'b0000_0000;
    end else begin
        SCON_q              <=      SCON_d;
        PCON_q              <=      PCON_d;
        TMOD_q              <=      TMOD_d;
        TCON_q              <=      TCON_d;
    end
end
wire                RB8_q               =   uart_rx_buf[8];

reg                 TF0_clr;
reg                 TF1_clr;
reg                 IE0_clr;
reg                 IE1_clr;

reg                 IE1_q;
reg                 IE0_q;
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
wire                intEX0_req;
wire                intEX1_req;

reg     [1:0]       intEX0_saFF;
reg     [1:0]       intEX1_saFF;

always @(posedge clk or negedge reset_n)
    if(~reset_n) begin
        intEX0_saFF     <=      2'b00;
        intEX1_saFF     <=      2'b00;
    end else begin
        intEX0_saFF     <=      {intEX0_saFF[0],    ~intEX0_n};
        intEX1_saFF     <=      {intEX1_saFF[0],    ~intEX1_n};
    end
assign  intEX0_req      =   (w_IT0  ==  1'b1)   ?   intEX0_saFF ==  2'b01   :   intEX0_saFF[0];
assign  intEX1_req      =   (w_IT1  ==  1'b1)   ?   intEX1_saFF ==  2'b01   :   intEX1_saFF[0];
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always @(posedge clk or negedge reset_n)
    if(~reset_n) begin
        IE0_q               <=      1'b0;
        IE1_q               <=      1'b0;
    end else begin
        IE0_q               <=      (IE0_clr    )   ?   1'b0    :   ((IE0_q  ==  1'b1)  ?   1'b1:   intEX0_req)   ;
                            //TODO: Here ... ... 
        IE1_q               <=      (IE1_clr    )   ?   1'b0    :   ((IE1_q  ==  1'b1)  ?   1'b1:   intEX1_req)   ;
    end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always @(posedge clk or negedge reset_n)
    if(~reset_n) begin
        TF0_q               <=      1'b0;
        TF1_q               <=      1'b0;
    end else begin
        TF0_q               <=      (TF0_clr    )   ?   1'b0    :   TF0_d0;
                            //TODO: Here ... ... 
        TF1_q               <=      (TF1_clr    )   ?   1'b0    :   TF1_d0;
    end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always_comb begin : SFR_CON_COLOGIC
    RI_clr                  =       PCON_config_active  &   (~mem_wdata[0]);
    TI_clr                  =       PCON_config_active  &   (~mem_wdata[1]);
    SM0_FE_clr              =       PCON_config_active  &   (~mem_wdata[7]);

    TF0_clr                 =       (TCON_config_active &   (~mem_wdata[5]))    |   (~int_TF0_ack_n     );
    TF1_clr                 =       (TCON_config_active &   (~mem_wdata[7]))    |   (~int_TF1_ack_n     );
    IE0_clr                 =       (TCON_config_active &   (~mem_wdata[1]))    |   (~int_exIO0_ack_n   );
    IE1_clr                 =       (TCON_config_active &   (~mem_wdata[3]))    |   (~int_exIO1_ack_n   );
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
    if(w_SMOD0)
        SCON_d              =       {SM0_FE_q,SCON_q[6:3],RB8_q,TI_q,RI_q   };
    else
        SCON_d              =       {SCON_q[7:3],RB8_q,TI_q,RI_q            };
    PCON_d                  =       PCON_q;
    TMOD_d                  =       TMOD_q;

    TL0_d                   =       TL0_d0;
    TH0_d                   =       TH0_d0;

    TL1_d                   =       TL1_d0;
    TH1_d                   =       TH1_d0;

    TCON_d                  =       {TF1_q,TCON_q[6],TF0_q,TCON_q[4],IE1_q,TCON_q[2],IE0_q,TCON_q[0]};

    io_p0_d0                =       io_p0_q;
    io_p1_d0                =       io_p1_q;
    io_p2_d0                =       io_p2_q;
    io_p3_d0                =       io_p3_q;

    if(~mem_we_n    &&  periDev_config_active)
    case(mem_addr[7:0])
        `SCON:              SCON_d                  =   mem_wdata;
        `SBUF:              uart_tx_buf_fromBus_d   =   mem_wdata;
        `PCON:              PCON_d                  =   mem_wdata;
        `TMOD:              TMOD_d                  =   mem_wdata;
        `TCON:              TCON_d                  =   mem_wdata;

        `TL0:               TL0_d                   =   mem_wdata;
        `TH0:               TH0_d                   =   mem_wdata;
        `TL1:               TL1_d                   =   mem_wdata;
        `TH1:               TH1_d                   =   mem_wdata;
    endcase
end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
reg     [7:0]       mem_rdata_buf_q;
reg     [7:0]       mem_rdata_buf_d;

always_comb begin
    if(~mem_rd_n    &&  periDev_config_active)
        case(mem_addr[7:0])
            `SCON:          mem_rdata_buf_d     =   SCON_q;
            `PCON:          mem_rdata_buf_d     =   PCON_q;
            `SBUF:          mem_rdata_buf_d     =   uart_rx_buf[7:0];
            `TMOD:          mem_rdata_buf_d     =   TMOD_q;
            `TCON:          mem_rdata_buf_d     =   TCON_q;

            `P0:            mem_rdata_buf_d     =   io_p0_d1;
            `P1:            mem_rdata_buf_d     =   io_p1_d1;
            `P2:            mem_rdata_buf_d     =   io_p2_d1;
            `P3:            mem_rdata_buf_d     =   io_p3_d1;

            default :       mem_rdata_buf_d     =   8'bzzzz_zzzz;
        endcase
    else
        mem_rdata_buf_d     =   mem_rdata_buf_q;
    mem_rdata       =   mem_rdata_buf_q;
end
always @(posedge clk or negedge reset_n)
    if(~reset_n)    mem_rdata_buf_q     <=  8'hzz;
    else            mem_rdata_buf_q     <=  mem_rdata_buf_d;
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
                            //SCON_q[5:6]   -->   {SM2,SM1}
assign  w_SM01              =       (w_SMOD0    ==  1'b1)   ?   {SCON_q[5], SCON_q[6]   }   :{SCON_q[6],SCON_q[7]};
assign  w_REN               =       SCON_q[4];
assign  w_TB8               =       SCON_q[3];

assign  w_SMOD              =       PCON_q[7];
assign  w_SMOD0             =       PCON_q[6];

assign  w_CT0               =       TMOD_q[2];
assign  w_MOD0              =       TMOD_q[1:0];
assign  w_GATE0             =       TMOD_q[3];
assign  w_CT1               =       TMOD_q[6];
assign  w_MOD1              =       TMOD_q[5:4];
assign  w_GATE1             =       TMOD_q[7];

assign  w_IT1               =       TCON_q[2];
assign  w_IT0               =       TCON_q[0];
assign  w_TR0               =       TCON_q[4];
assign  w_TR1               =       TCON_q[6];

assign  int_exIO0           =       IE0_q;
assign  int_exIO1           =       IE1_q;
assign  int_TF0             =       TF0_q;
assign  int_TF1             =       TF1_q;
assign  int_UART0           =       RI_q    |   TI_q;
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
assign  mem_ready_out       =       1'b1;
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
endmodule