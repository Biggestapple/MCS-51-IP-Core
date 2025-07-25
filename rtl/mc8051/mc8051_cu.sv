//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
//	FILE: 		mc8051_cu.sv
// 	AUTHOR:		Biggest_apple
// 	
//	ABSTRACT:	
// 	KEYWORDS:	fpga, basic module,signal process
// 
// 	MODIFICATION HISTORY:
//	$Log$
//			Biggest_apple				2023.12.20		Create the project
//			Biggest_apple				2024.1.1		The first test
//			Biggest_apple				2024.2.2		Finished all the micocode
//			Biggest_apple				2024.2.11		Add interrupt relevant circuit
//			Biggest_apple				2024.2.19		Improve micocode structure
//			Biggest_apple				2024.2.20		Fixed bugs in multi-cycles instructions
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
//			Biggest_apple				2024.9.3		Fixed bugs in FSM circuit
//			Biggest_apple				2024.10.5		Rebuild All
//			Biggest_apple				2024.11.17		Nothing to say ... ... 
//			Biggest_apple				2024.11.18		Completed the J_Group instruction and interrupt function
//			Biggest_apple				2024.11.19		All Done Great !
//			Biggest_apple				2024.11.21		Bit Addressing still has problems (No problem actually )
//          Biggest_apple               2024.12.24      Added peripheral sfr control logic
//          Biggest_apple               2025.7.25       Added the debugger interface (test only)     
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
`timescale 				1ns/1ps
`include				"global_param.v"
/*
			Notifaction:				Machine Cycle Define as followed
			
			S1_stage					-->				Fetching the instruction (The first Opcode) to instr_buf
										|S1_0			:Setting up the control signal and update the PC value
										|S1_1			:Waiting the data ready
										
														S2 & S3 (Optional RAM/ROM fetch stage based on 'x_sx_rd_ram_nprg')
														There are five modes for addressing
														1. From Rom  (Default ExRom						)-Not supporting IRom yet
														2. From ExRam
														3. From IRam (Lower 128 byte					)
														4. From IRam (Upper 128 byte direct addressing	)
														5. From IRam (Upper 128 byte indirect addressing)
			S2_stage					-->
										|S2_0			
										|S2_1			
			S3_stage					-->				Fetching the next Opcode if needed which can also be discarded	
														Or Access the external ram EG.MOVX code
										|S3_0			This has the same process as S1_i, just omits here
										|S3_1
										
										
			S4_stage					-->				Operating the ALU
										|S4_0			Setting up the alu_temper register
										|S4_1			Waiting alu_done,as the alu has finished calculating, the the alu_o_temp_register
														has been set EG.AX_temp,BX_temp,PSW_temp
														
			S5_stage					-->				Write back to ExRam, uIRam, lIRAM ...		
										|S5_0
										|S5_1
										
			S6_stage					-->				This stage is used for interrupt control,jump control,debug control ...
										|S6_0
										|S6_1
*/
module	mc51_cu(
	input					clk,
	input					reset_n,
	
//	The following signals actually convey internal properties of instructions
	input					i_is_s2_update_pc,
	input					i_is_s3_update_pc,
	
	input		[2:0]		i_s2_fetch_mode_sel,
	input		[2:0]		i_s3_fetch_mode_sel,
	input		[2:0]		i_s5_write_mode_sel,
	
//	input		[2:0]		i_s2_mem_addr_sel,
//	input		[2:0]		i_s3_mem_addr_sel,
//	input		[2:0]		i_flag_set_mode_sel,
	input					i_is_multi_cycles,
//	input		[3:0]		i_jump_mode_sel,
	input		[2:0]		i_reg_tar_sel,
	input		[2:0]		i_reg_sor_sel,
	input		[2:0]		i_pc_reload_mode_sel,
	
//	End here 		... ...
	
	input		[7:0]		i_alu_o1_temp,
	input		[7:0]		i_alu_o2_temp,
	input		[7:0]		i_alu_psw_temp,
	input					i_alu_ready,

	input					i_jp_active,
	
	input		[15:0]		i_s2_mem_addr_d,
	input		[15:0]		i_s3_mem_addr_d,
	input		[15:0]		i_s5_mem_addr_d,
	
	input		[7:0]		i_mem_wdata,
	input		[7:0]		i_mem_rdata,
	
	output		[3:0]		o_t_p_d,
	output		[3:0]		o_t_p_q,
	output		[1:0]		o_ci_stage,
    output                  o_s1_done_tick,
    output                  o_s2_done_tick,
    output                  o_s3_done_tick,
//	ci: current instruction stage
	output		[7:0]		o_pcl,
	output		[7:0]		o_pch,
	output		[7:0]		o_psw,
	output		[7:0]		o_acc,
	output		[7:0]		o_bx,
	output		[7:0]		o_sp,
	output		[7:0]		o_dpl,
	output		[7:0]		o_dph,
	output		[7:0]		o_sx_0,
	output		[7:0]		o_sx_1,
	output		[7:0]		o_s2_data_buffer,
	output		[7:0]		o_s3_data_buffer,
	output		[7:0]		o_s1_instr_buffer,
//	End here 		... ...
	output					o_we_n,
	output					o_rd_n,
	output					o_psen_n,
    output                  o_peri_sfr_req,
	input					i_data_rdy,
//	Interrput control interface
	input					i_int_req_n,
	output					o_int_ack_n,
	input		[7:0]		i_int_so_num,
	output					o_int_reti,

// Debugger interface connected to the DBGU (Debugger Unit) module
    output                  o_cpu_err_halt,
    output      [7:0]       o_cpu_err_code,
    output                  o_cpu_haltReq_n,


    input       [2:0]       i_cpu_dbg_mode,
    output                  o_cpu_dbg_halt, 
    input                   i_cpu_dbg_tick,

    input       [15:0]      i_cpu_dbg_brkPC,
    output                  o_cpu_dbg_brkHit_n,
/*
    input                   i_cpu_dbg_memRd_n,
    input                   i_cpu_dbg_memWr_n,
    input       [15:0]      i_cpu_dbg_memAddr,
    input       [7:0]       i_cpu_dbg_memWdata,
    output      [7:0]       o_cpu_dbg_memRdata,
    output                  o_cpu_dbg_mem_rdy
*/
    input                   i_cpu_dbgBoot_req_n,
    output                  o_cpu_dbgBoot_ack_n,

    input       [3:0]       i_cpu_dbgBoot_entPoint
);
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
reg		[7:0]		s1_instr_buffer_q;
reg		[7:0]		s1_instr_buffer_d;
reg		[7:0]		s2_data_buffer_q;
reg		[7:0]		s2_data_buffer_d;
reg		[7:0]		s3_data_buffer_q;
reg		[7:0]		s3_data_buffer_d;
							//Shadow register group	#4
reg		[7:0]		sx_0_q;
reg		[7:0]		sx_0_d;
reg		[7:0]		sx_1_q;
reg		[7:0]		sx_1_d;

reg					psen_n;
reg					we_n;
reg					rd_n;
reg                 peri_sfr_req_q;
reg                 peri_sfr_req_d;
							//Timing-phase counter
reg		[3:0]		t_p_q;
reg		[3:0]		t_p_d;
							//Internal ram block define
reg		[7:0]		iram	[0:	`IRAM_SIZE -1];
							//Define special function register There are kernel-related register
reg		[7:0]		pcl_d;
reg		[7:0]		pcl_q;
reg		[7:0]		pch_q;
reg		[7:0]		pch_d;
reg		[7:0]		acc_d;
reg		[7:0]		acc_q;
reg		[7:0]		b_q;
reg		[7:0]		b_d;
reg		[7:0]		sp_d;
reg		[7:0]		sp_q;
reg		[7:0]		dpl_q;
reg		[7:0]		dpl_d;
reg		[7:0]		dph_q;
reg		[7:0]		dph_d;

reg		[7:0]		psw_q;
reg		[7:0]		psw_d;

reg		[1:0]		multi_cycle_times;
reg		[7:0]		s3_addr_truncat;
reg		[7:0]		s2_addr_truncat;
reg		[7:0]		s5_addr_truncat;

reg					s1_done_tick;
reg					s2_done_tick;
reg					s3_done_tick;
reg					s6_done_tick;
reg					al_done_tick;

reg					int_req_n0;
reg					int_req_n1;
reg		[7:0]		int_so_num;
reg					int_ack_n;
wire				int_req_n;
reg					int_reti;

                            //Debugger related registers
reg                 cpu_err_halt_q;
reg                 cpu_err_halt_d;
reg     [7:0]       cpu_err_code_q;
reg     [7:0]       cpu_err_code_d;

reg     [2:0]       cpu_dbg_mode;
reg                 cpu_dbg_tick;

reg                 cpu_dbg_halt_q;
reg                 cpu_dbg_halt_d;

reg     [15:0]      cpu_dbg_brkPC;
reg                 cpu_dbg_brkHit_n;

reg     [3:0]       cpu_dbg_boot_entPoint;
reg                 cpu_dbg_boot_ack_n;
reg                 cpu_dbg_boot_req_n;
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always @(posedge clk or negedge reset_n)
    if(~reset_n) begin
        cpu_dbg_brkPC                   <=      16'hzzzz;
        cpu_dbg_boot_entPoint           <=      4'hz;
        cpu_dbg_boot_req_n              <=      1'b1;
    end else begin
        cpu_dbg_brkPC                   <=      i_cpu_dbg_brkPC;
        cpu_dbg_boot_entPoint           <=      i_cpu_dbgBoot_entPoint;
        cpu_dbg_boot_req_n              <=      i_cpu_dbgBoot_req_n;
    end

always @(posedge clk or negedge reset_n)
    if(~reset_n)
        cpu_dbg_tick                    <=      1'b0;
    else
        cpu_dbg_tick                    <=      i_cpu_dbg_tick;

always @(posedge clk or negedge reset_n)
    if(~reset_n)
        cpu_dbg_mode                    <=      `DBG_RUN_MODE;
    else
        cpu_dbg_mode                    <=      i_cpu_dbg_mode;

always @(posedge clk or negedge reset_n)
    if(~reset_n)
        {cpu_err_halt_q,cpu_dbg_halt_q} <=      2'b00;
    else
        {cpu_err_halt_q,cpu_dbg_halt_q} <=      {cpu_err_halt_d,cpu_dbg_halt_d};

always @(posedge clk or negedge reset_n)
    if(~reset_n)
        cpu_err_code_q                  <=      `NONE_ERROR_BASE;
    else
        cpu_err_code_q                  <=      cpu_err_code_d;

always_comb begin : CPU_ERR_PROC_LOGIC
    cpu_err_halt_d      =   cpu_err_halt_q;
    cpu_err_code_d      =   cpu_err_code_q;

    if(t_p_d == `S8_HALT_LOOP) begin
        cpu_err_halt_d  =   1'b1;
        cpu_err_code_d  =   `HALT_ERROR_BASE + t_p_q;
    end
end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
							//Interrput signals synchronization
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		{int_req_n1,int_req_n0}			<=		2'b11;
	else 
		{int_req_n1,int_req_n0}			<=		{int_req_n0,i_int_req_n	};
assign				int_req_n			=		int_req_n1;
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		int_so_num						<=		8'h00;
	else
		int_so_num						<=		i_int_so_num;
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
							//Just SDRAM type
reg					is_s5_wr_iram;
reg					is_s5_wr_sfr;
always @(posedge clk)
	if(is_s5_wr_iram)
		iram[s5_addr_truncat]			<=		i_mem_wdata;

//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
reg		[7:0]		sfr_rd_temp;
reg					is_s2_fetch_sfr;
reg					is_s3_fetch_sfr;
reg                 is_rd_periCtrl_sfr;
reg		[7:0]		sfr_addr;
always @(*) begin
    is_rd_periCtrl_sfr  =       1'b0;
	sfr_addr		    =		(is_s2_fetch_sfr	==	1'b1)	?	s2_addr_truncat:
							    (is_s3_fetch_sfr	==	1'b1)	?	s3_addr_truncat:8'h00;
	if(is_s2_fetch_sfr|is_s3_fetch_sfr) begin
		case(sfr_addr)
			`ACC	:			sfr_rd_temp		=	acc_q;
			`B		:			sfr_rd_temp		=	b_q;
			`SP		:			sfr_rd_temp		=	sp_q;
			`DPL	:			sfr_rd_temp		=	dpl_q;
			`DPH	:			sfr_rd_temp		=	dph_q;
			`PSW	:			sfr_rd_temp		=	psw_q;
			default: begin
				$display ("%m :at time %t Warning no such SFR and return 8'bzzzz_zzzz.", $time);
                $display ("%m :at time %t Trying fetching peripheral sfr.", $time);
				sfr_rd_temp		    =	8'bzzzz_zzzz;
                is_rd_periCtrl_sfr  =   1'b1;
			end
		endcase
	end else
		sfr_rd_temp	=		8'bzzzz_zzzz;

end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always @(*) begin
		s2_addr_truncat	=	i_s2_mem_addr_d[7:0];
		s3_addr_truncat	=	i_s3_mem_addr_d[7:0];
		s5_addr_truncat	=	i_s5_mem_addr_d[7:0];
end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		t_p_q			<=	`S1_0;
	else
		t_p_q			<=	t_p_d;
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always @(posedge clk or negedge reset_n) begin
    if(~reset_n)
        peri_sfr_req_q       <=  1'b0;
    else
        peri_sfr_req_q       <=  peri_sfr_req_d;
end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
/*
    reg                 is_rd_periCtrl_sfr;
    always @(*)
        case(sfr_addr)
            `ACC,`B,`SP,`DPL,`DPH,`PSW	:   is_rd_periCtrl_sfr =   1'b0;
            default                     :   is_rd_periCtrl_sfr =   1'b1;
        endcase
*/
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//

reg                 is_wr_periCtrl_sfr;
always @(*)
    case(s5_addr_truncat)
        `ACC,`B,`SP,`DPL,`DPH,`PSW	:   is_wr_periCtrl_sfr =   1'b0;
        default                     :   is_wr_periCtrl_sfr =   1'b1;
    endcase

//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
/*
    task s2_where_to_go(
        input	[2:0]	i_s2_fetch_mode_sel,
        output	[3:0]	t_p_d
        );
                                //Very interesting grammar ...
        case(i_s2_fetch_mode_sel)
            `DISCARD_MODE	:		t_p_d	=	`S4_0;
            `IND_EXROM_MODE,
            `IND_EXRAM_MODE,
            `IND_IRAM_MODE,
            `DIR_IRAM_MODE	:		t_p_d	=	`S2_0;
            default: begin
                        $display ("%m :at time %t Error: Fetched INVALID MCCODE during S1 in cu_module.", $time);
                        t_p_d	=	`S8_HALT_LOOP;
                    end
        endcase
    endtask
*/
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always_comb begin : GDB_BRKHIT_LOGIC
    if(cpu_dbg_mode == `DBG_BREAK_MODE && t_p_q == `S1_0)
        cpu_dbg_brkHit_n   =   ~(i_cpu_dbg_brkPC == {pch_q,pcl_q});
    else
        cpu_dbg_brkHit_n   =   1'b1;
end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
task s1_rd_instr_buffer(
    input   [7:0]   i_mem_rdata,

    output  [3:0]   t_p_d,
    output          rd_n,
    output          psen_n,
    output  [7:0]   s1_instr_buffer_d
    );
    rd_n		        =	1'b0;
    psen_n		        =	1'b0;
    s1_instr_buffer_d	=	i_mem_rdata;
                    
    t_p_d		        =	`S1_1;
endtask
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
task s3_where_to_go(
	input	[2:0]	i_s3_fetch_mode_sel,
	output	[3:0]	t_p_d
	);
	case(i_s3_fetch_mode_sel)
		`DISCARD_MODE	:		t_p_d	=	`S4_0;
		`IND_EXROM_MODE,
		`IND_EXRAM_MODE,
		`IND_IRAM_MODE,
		`DIR_IRAM_MODE	:		t_p_d	=	`S3_0;
		default: begin
					$display ("%m :at time %t Error: Fetched INVALID MCCODE during S2 in cu_module.", $time);
					t_p_d	=	`S8_HALT_LOOP;
				end
	endcase
endtask
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always @(posedge clk or negedge reset_n)
    if(~reset_n)        s1_instr_buffer_q       <=  8'bzzzz_zzzz;
    else                s1_instr_buffer_q       <=  s1_instr_buffer_d;
always @(posedge clk or negedge reset_n)
    if(~reset_n)        s2_data_buffer_q        <=  8'bzzzz_zzzz;
    else                s2_data_buffer_q        <=  s2_data_buffer_d;
always @(posedge clk or negedge reset_n)
    if(~reset_n)        s3_data_buffer_q        <=  8'bzzzz_zzzz;
    else                s3_data_buffer_q        <=  s3_data_buffer_d;
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
always_comb begin : MAIN_CU_FSM_LOGIC
                            //The following circuit is to generate the output signals
	t_p_d				=	t_p_q;
	
	is_s2_fetch_sfr		=	1'b0;
	is_s3_fetch_sfr		=	1'b0;
	is_s5_wr_iram		=	1'b0;
	is_s5_wr_sfr		=	1'b0;
	
	psen_n				=	1'b1;
	we_n				=	1'b1;
	rd_n				=	1'b1;
    peri_sfr_req_d      =   peri_sfr_req_q;
	
	s1_instr_buffer_d	=	s1_instr_buffer_q;
	s2_data_buffer_d	=	s2_data_buffer_q;
	s3_data_buffer_d	=	s3_data_buffer_q;
	
	s1_done_tick		=	1'b0;
	s2_done_tick		=	1'b0;
	s3_done_tick		=	1'b0;
	s6_done_tick		=	1'b0;
	al_done_tick		=	1'b0;
	
	int_ack_n			=	1'b1;
/*
    cpu_err_halt_d      =   cpu_dbg_halt_q;
    cpu_err_code_d      =   cpu_dbg_halt_q;
*/
    cpu_dbg_halt_d      =   cpu_dbg_halt_q;
    cpu_dbg_boot_ack_n  =   1'b1;

	case(t_p_q)
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
		`S1_0:				// Beside getting the current instruction 
							// in s1 ~s2 phase,we should generate the next PC value (address)...
            case(cpu_dbg_mode)
                `DBG_RUN_MODE:
/*
                    begin
                        rd_n		        =	1'b0;
                        psen_n		        =	1'b0;
                        s1_instr_buffer_d	=	i_mem_rdata;
                    
                        t_p_d		        =	`S1_1;
                        cpu_dbg_halt_d      =   1'b0;
                    end
*/
                    begin
                        s1_rd_instr_buffer(i_mem_rdata, t_p_d, rd_n, psen_n, s1_instr_buffer_d);
                        cpu_dbg_halt_d      =   1'b0;
                    end
                `DBG_HALT_MODE:
                    begin
                        cpu_dbg_halt_d          =   1'b1;
                        t_p_d                   =   `S1_0;
                            // Just the cpu halted here and we can only 
                            // access to the iram/exram/register in this mode but how to do this ???
                            // We can inject the mov-secp instruction /// Just LCALL jump to the DBG program that's genius
                        if(~cpu_dbg_boot_req_n ) begin
                            cpu_dbg_boot_ack_n  =   1'b0;
                            //Load the "LCALL" Instruction
					        s1_instr_buffer_d	=	`LCALL;
					        s2_data_buffer_d	=	8'h00;
					        s3_data_buffer_d	=	cpu_dbg_boot_entPoint + `DBG_VTAB_SADDR;
					
							//Jump to S4_0 stage
					        t_p_d				=	`S4_0;
                        end 
                    end
                `DBG_STEP_MODE:
                    begin
                        cpu_dbg_halt_d          =   1'b1;
                        t_p_d		            =	`S1_0;
                        if(cpu_dbg_tick) begin
                            s1_rd_instr_buffer(i_mem_rdata, t_p_d, rd_n, psen_n, s1_instr_buffer_d);
                            cpu_dbg_halt_d      =   1'b0;
                            $display ("%m :at time %t DBG: Halt has been steped out.", $time);
                        end
                    end
                `DBG_BREAK_MODE:
                    begin
                            // Todo: Implement the break dbg mode
                            // If hit the break point, then halt the cpu ... 
                        if(~cpu_dbg_brkHit_n & ~cpu_dbg_tick) begin
                            cpu_dbg_halt_d      =   1'b1;
                            t_p_d               =	`S1_0;
                            $display ("%m :at time %t DBG: Halt has been ENTERED at point %h.", $time , cpu_dbg_brkPC);
                        end else begin
                            cpu_dbg_halt_d      =   1'b0;
                            $display ("%m :at time %t DBG: Halt has been steped out.", $time);
                            s1_rd_instr_buffer(i_mem_rdata, t_p_d, rd_n, psen_n, s1_instr_buffer_d);
                        end
                    end
                default:
                    begin
                        $display ("%m :at time %t Error: Invalid DBG mode code.", $time);
                        t_p_d	=	`S8_HALT_LOOP;
                    end
            endcase
		`S1_1:
			begin
                            // Tricky Bugs Here !!!
				rd_n		        =	1'b0;
				psen_n		        =	1'b0;
//              s1_instr_buffer_d	=	i_mem_rdata;
                s1_instr_buffer_d   =   (multi_cycle_times == 2'b00 )   ?   i_mem_rdata :   s1_instr_buffer_q;
                            // Locked the pos-fetch instruction during multi-cycle process
				if(multi_cycle_times	!=	2'b00) begin
					s1_done_tick		=	1'b0;
							// PC value shouldn't update
                    t_p_d               =   `S2_0;
//					s2_where_to_go(	i_s2_fetch_mode_sel,	t_p_d);
				end else if(i_data_rdy) begin
/*
					rd_n		=	1'b1;
					psen_n		=	1'b1;
*/
					s1_done_tick		=	1'b1;
//					s1_instr_buffer_d	=	i_mem_rdata;
                    t_p_d               =   `S2_0;
//					s2_where_to_go(	i_s2_fetch_mode_sel,	t_p_d);
                end
			end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
			`S2_0:
					case(i_s2_fetch_mode_sel)
						`IND_EXROM_MODE,
						`IND_EXRAM_MODE:begin
								psen_n	=	(i_s2_fetch_mode_sel	==	`IND_EXRAM_MODE)	?	1'b1:1'b0;
								rd_n	=	1'b0;
								t_p_d	=	`S2_1;
							end
						`IND_IRAM_MODE,
							//Must distinguish SFR_SPACE - NORMAL_SPACE and BIT_SPACE
						`DIR_IRAM_MODE:begin
								if(s2_addr_truncat	>=	`IRAM_UPPER_BASE	) begin
							//Access to SFR_SPACE or Unexist space
									if(i_s2_fetch_mode_sel	==	`IND_IRAM_MODE	) begin
										$display ("%m :at time %t Error: Fetched INVALID ADDR in cu_module. (Not supporting in 8051 system)", $time);
                                        t_p_d                   =   `S8_HALT_LOOP;
                                    end else begin
                                        is_s2_fetch_sfr		=	1'b1;

                                        if(is_rd_periCtrl_sfr   ) begin
                                            rd_n                =   1'b0;
                                            t_p_d               =   `S2_1;
                                            peri_sfr_req_d      =   1'b1;
                                        end else begin
                                            s2_data_buffer_d	=	sfr_rd_temp;
                                            s3_where_to_go(	i_s3_fetch_mode_sel,	t_p_d);
                                        end
									end
							//How to fetch data from SFR_SPACE ... ...
							//Note here not finish yet ... ...
								end else begin
									s2_data_buffer_d		=	iram[s2_addr_truncat];
							//Access to NORMAL_SPACE
                                    s3_where_to_go(	i_s3_fetch_mode_sel,	t_p_d);
								end
/*
                                t_p_d	=	`S3_0;
*/
//                              s3_where_to_go(	i_s3_fetch_mode_sel,	t_p_d);
							end
                        `DISCARD_MODE:
                                t_p_d	=   `S4_0;
						default:
							begin 
								$display ("%m :at time %t Error: Fetched INVALID MCCODE during S2 in cu_module.", $time);
								t_p_d	=	`S8_HALT_LOOP;
							end
					endcase
			`S2_1:
				begin
					if(i_data_rdy) begin
						rd_n		        =	1'b1;
						psen_n		        =	1'b1;
                        peri_sfr_req_d      =   1'b0;
						s2_data_buffer_d	=	i_mem_rdata;
						s2_done_tick		=	1'b1;
                        s3_where_to_go(	i_s3_fetch_mode_sel,	t_p_d);
					end else begin
							//Understanding ... ... ?
						rd_n		=	1'b0;
						psen_n		=	(i_s2_fetch_mode_sel	==	`IND_EXRAM_MODE)	?	1'b1	:	1'b0;
					end
				end
				
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
			`S3_0:
					case(i_s3_fetch_mode_sel)
						`IND_EXROM_MODE,
						`IND_EXRAM_MODE:begin
								psen_n	=	(i_s3_fetch_mode_sel	==	`IND_EXRAM_MODE)	?	1'b1:1'b0;
								rd_n	=	1'b0;
								t_p_d	=	`S3_1;
							end
						`IND_IRAM_MODE,
							//Must distinguish SFR_SPACE - NORMAL_SPACE
						`DIR_IRAM_MODE:begin
								if(s3_addr_truncat	>=	`IRAM_UPPER_BASE	) begin
							//Access to SFR_SPACE or Unexist space
									if(i_s3_fetch_mode_sel	==	`IND_IRAM_MODE	) begin
										$display ("%m :at time %t Error: Fetched INVALID ADDR in cu_module. (Not supporting in 8051 system)", $time);
                                        t_p_d	                =	`S4_0;
                                    end else begin
                                        is_s3_fetch_sfr		=	1'b1;

                                        if(is_rd_periCtrl_sfr) begin
                                            rd_n                =   1'b0;
                                            t_p_d               =   `S3_1;
                                            peri_sfr_req_d      =   1'b1;
                                        end else begin
										    s3_data_buffer_d	=	sfr_rd_temp;
                                            t_p_d               =	`S4_0;
                                        end
									end
							//How to fetch data from SFR_SPACE ... ...
							//Note here not finish yet ... ...
								end else begin
									s3_data_buffer_d		=	iram[s3_addr_truncat];
							//Access to NORMAL_SPACE
                                    t_p_d	                =	`S4_0;
                                end
//								t_p_d	=	`S4_0;
							end
						default:
							begin 
								$display ("%m :at time %t Error: Fetched INVALID MCCODE during S3 in cu_module.", $time);
								t_p_d	=	`S8_HALT_LOOP;
							end
					endcase
			`S3_1:
				begin
					if(i_data_rdy) begin
						rd_n		        =	1'b1;
						psen_n		        =	1'b1;
                        peri_sfr_req_d      =   1'b0;
						s3_data_buffer_d	=	i_mem_rdata;
						s3_done_tick		=	1'b1;
						
						t_p_d		        =	`S4_0;
					end else begin
							//Understanding ... ... ?
						rd_n		=	1'b0;
						psen_n		=	(i_s3_fetch_mode_sel	==	`IND_EXRAM_MODE)	?	1'b1	:	1'b0;
					end
				end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//		
			`S4_0:		t_p_d		=	(i_alu_ready			==	1'b1			)	?	`S4_1	:	`S4_0;
			`S4_1:		t_p_d		=	`S5_0;
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
			`S5_0:			//Write back to Iram or exram
				case(i_s5_write_mode_sel)
					`WR_DISCARD_MODE	:	t_p_d		=	`S6_0;
					`WR_IND_2IRAM_MODE	,
					`WR_DIR_2IRAM_MODE	:	begin
							if(s5_addr_truncat	>=	`IRAM_UPPER_BASE	) begin
								if(i_s5_write_mode_sel	==	`WR_IND_2IRAM_MODE	) begin
									$display ("%m :at time %t Error: Write INVALID DATA in cu_module. (Not supporting in 8051 system)", $time);
                                    t_p_d			        =	`S6_0;
                                end else begin
                                    if(is_wr_periCtrl_sfr) begin
                                        we_n	            =	1'b0;
							            t_p_d	            =	`S5_1;
                                        peri_sfr_req_d      =   1'b1;
                                    end else begin
									    is_s5_wr_sfr	    =	1'b1;
                                        t_p_d			    =	`S6_0;
                                    end
                                end
//								t_p_d			=	`S6_0;
							end else begin
							//Write back to NORMAL_SPACE
								t_p_d			=	`S6_0;
								is_s5_wr_iram	=	1'b1;
							end
						end
					`WR_2EXRAM_MODE		:	begin
							we_n	=	1'b0;
							t_p_d	=	`S5_1;
						end		
					default: begin
						$display ("%m :at time %t Error: Fetched INVALID MCCODE during S5 in cu_module.", $time);
						t_p_d		=	`S8_HALT_LOOP;
					end
				endcase
			`S5_1:
				begin
					if(i_data_rdy) begin
						we_n	            =	1'b1;
						t_p_d	            =	`S6_0;
                        peri_sfr_req_d      =   1'b0;
                    end else begin
						we_n	            =	1'b0;
                    end
				end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
			`S6_0:
							//The S6 stage is the most complex stage which should 
							//be designed carefully.
							//For J_Group instruction and interrupt process
				if(i_is_multi_cycles	)
					t_p_d			=	`S1_1;
				else begin
					t_p_d			=	`S6_1;
							//Not finished here
					s6_done_tick	=	1'b1;
				end
			`S6_1:
				if(~int_req_n			) begin
							//The interrupt request occurs
					int_ack_n			=	1'b0;
							//Load the "LCALL" Instruction
					s1_instr_buffer_d	=	`LCALL;
					s2_data_buffer_d	=	`INT_VTAB_SADDR	+	int_so_num;
					s3_data_buffer_d	=	8'h00;
					
							//Jump to S4_0 stage
					t_p_d				=	`S4_0;
					$display ("%m :at time %t Entering the interrupt %h - service. Loading LCALL instruction.", $time,	int_so_num);
				end else begin
					t_p_d				=	`S1_0;
					al_done_tick		=	1'b1;
				end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
			`S8_HALT_LOOP:		
							//Just stop here for debugging
				t_p_d	=	`S8_HALT_LOOP;
				
		default: begin
		
			end		
	endcase
end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
							//The following circuit is to generate the pc_value
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		{pch_q,pcl_q}	<=	{`PCH_RESET,`PCL_RESET};
	else
		{pch_q,pcl_q}	<=	{pch_d,pcl_d};

always @(*) begin
	{pch_d,pcl_d}	=	{pch_q,pcl_q};
	if(	(s1_done_tick						)|
		(s2_done_tick && i_is_s2_update_pc	)|
		(s3_done_tick && i_is_s3_update_pc	)
	)
		{pch_d,pcl_d}	=	{pch_q,pcl_q} +	1'b1;
	else if (s6_done_tick	)	begin
							//Reload the pc for J_Group instruction
		if(i_jp_active	)
			case(i_pc_reload_mode_sel)
				`PC_NUL_RELOAD		:		{pch_d,pcl_d}	=	{pch_q,pcl_q};
				`PC_11B_RELOAD		:		{pch_d,pcl_d}	=	{{pch_q[7:3],s1_instr_buffer_q[7:5]},s2_data_buffer_q};
				`PC_ROF_RELOAD		:		{pch_d,pcl_d}	=	{pch_d,pcl_d}	+	{{8{s2_data_buffer_q[7]}},s2_data_buffer_q};
				`PC_RXF_RELOAD		:		{pch_d,pcl_d}	=	{pch_d,pcl_d}	+	{{8{s3_data_buffer_q[7]}},s3_data_buffer_q};
							//Won't use alu module for simplicity
				`PC_IND_RELOAD		:		{pch_d,pcl_d}	=	{8'b0,acc_q	}	+	{dph_q,	dpl_q};
				`PC_16B_RELOAD		:		{pch_d,pcl_d}	=	{s3_data_buffer_q,	s2_data_buffer_q};
							//For "LJMP" instruction	
				`PC_16X_RELOAD		:		{pch_d,pcl_d}	=	{sx_0_q,s2_data_buffer_q};		
				default:
					$display ("%m :at time %t Warning No such PC_RELOAD_MODE! PC's unchanged.", $time);
			endcase
		else
							//Normal case here
			{pch_d,pcl_d}	=	{pch_q,pcl_q};
	end else
		{pch_d,pcl_d}	=	{pch_q,pcl_q};
	
	if({pch_d,pcl_d}	>=	16'hff_f0)
		$display ("%m :at time %t Warning PC register may hit the boundary causing unpredictable action.", $time);
end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
							//The following circuit is about the register update
reg		[2:0]		reg_sor_sel;
reg		[2:0]		reg_tar_sel;

always @(posedge clk or negedge reset_n)
	if(~reset_n) begin
		reg_sor_sel		<=	'h0;
		reg_tar_sel		<=	'h0;
	end else if (t_p_d		==	`S4_0	) begin
		reg_sor_sel		<=	i_reg_sor_sel;
		reg_tar_sel		<=	i_reg_tar_sel;
	end

wire	[7:0]		w_reg_wdata;
always @(posedge clk or negedge reset_n)
	if(~reset_n) begin
		sx_0_q			<=	'h0;
		sx_1_q			<=	'h0;
		acc_q			<=	'h0;
		b_q				<=	'h0;
		
//		psw_q			<=	'h0;
		sp_q			<=	`STACK_RESET;
		dph_q			<=	'h0;
		dpl_q			<=	'h0;
	end else begin
							//
							//This part mostly depends on instruction structure and behavior
		if(t_p_d		==	`S4_1	)
							//Stupid grammar ... ... Maybe shouldn't be like this
			case(reg_tar_sel)
				`TO_ACC_REG		:		acc_q		<=		w_reg_wdata;
				`TO_BX_REG		:		b_q			<=		w_reg_wdata;
				`TO_SP_REG		:		sp_q		<=		w_reg_wdata;
				`TO_DPTRH_REG	:		dph_q		<=		w_reg_wdata;
				`TO_DPTRL_REG	:		dpl_q		<=		w_reg_wdata;
				`TO_SX0_REG		:		sx_0_q		<=		w_reg_wdata;
				`TO_SX1_REG		:		sx_1_q		<=		w_reg_wdata;
				`TO_IDLE_0		:		begin				end
				default: begin
					$display ("%m :at time %t Warning PC register may hit the boundary causing unpredictable action.", $time);
				end
			endcase
		else if(t_p_q	==	`S5_0	&&	is_s5_wr_sfr)
							//Write back to sfr_space
			case(s5_addr_truncat)
				`ACC	:		acc_q		<=		i_mem_wdata;
				`B		:		b_q			<=		i_mem_wdata;
				`SP		:		sp_q		<=		i_mem_wdata;
				`DPL	:		dpl_q		<=		i_mem_wdata;
				`DPH	:		dph_q		<=		i_mem_wdata;
			default: begin
					$display ("%m :at time %t Warning invalid sfr_addr ! Data Ignored.", $time);
				end
			endcase
		
	end
assign	w_reg_wdata		=	(reg_sor_sel	==	`FROM_NULL_0)	?	8'h00:
							(reg_sor_sel	==	`FROM_S2_BUF)	?	s2_data_buffer_q:
							(reg_sor_sel	==	`FROM_S3_BUF)	?	s3_data_buffer_q:
							(reg_sor_sel	==	`FROM_A_TEMP)	?	i_alu_o1_temp:
							(reg_sor_sel	==	`FROM_B_TEMP)	?	i_alu_o2_temp:
							(reg_sor_sel	==	`FROM_SXRE_0)	?	sx_0_q:
							(reg_sor_sel	==	`FROM_SXRE_1)	?	sx_1_q:		8'bzzzz_zzzz;

//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
							//The following circuit is about the program statue register (PSR)	update which depends on  "i_flag_set_mode_sel" signal
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		psw_q			<=	`PSW_RESET;		
	else begin
							//PSW register contents:	{cy_set,ac_set,fg_set,rs0_set[3:2],ov_set,1'b0,pr_set};
		if(t_p_d		==	`S4_1	)
			psw_q		<=	i_alu_psw_temp;
	
	end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
							//Multi-cycles' instructions control circuit
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		multi_cycle_times		<=		2'b00;
	else if(t_p_q		==	`S6_0) begin
		multi_cycle_times		<=		(i_is_multi_cycles	)	?	multi_cycle_times	+1'b1:2'b00;
		
		if(i_is_multi_cycles	)
			$display ("%m :at time %t Current instruction: %h --> Stage: %d.",	$time,	s1_instr_buffer_q,	multi_cycle_times);
	end
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
							//Interrput control logic block
always @(posedge clk or negedge reset_n)
	if(~reset_n)
		int_reti				<=		1'b0;
	else if(al_done_tick)
		if(s1_instr_buffer_q	==	`RETI	)
			int_reti			<=		1'b1;
		else
			int_reti			<=		1'b0;
	else
			int_reti			<=		1'b0;

//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
							//Output-Interface combine logic here
assign		o_t_p_d				    =		t_p_d;
assign		o_t_p_q				    =		t_p_q;
assign		o_ci_stage			    =		multi_cycle_times;
assign		o_pcl				    =		pcl_q;
assign		o_pch				    =		pch_q;
assign		o_s2_data_buffer	    =		s2_data_buffer_q;
assign		o_s3_data_buffer	    =		s3_data_buffer_q;
assign		o_we_n				    =		we_n;
assign		o_rd_n				    =		rd_n;
assign		o_psen_n			    =		psen_n;
assign		o_int_ack_n			    =		int_ack_n;
assign		o_int_reti			    =		int_reti;
assign		o_psw				    =		psw_q;
assign		o_s1_instr_buffer	    =		s1_instr_buffer_q;
assign		o_acc				    =		acc_q;
assign		o_bx				    =		b_q;
assign		o_sp				    =		sp_q;
assign		o_dpl				    =		dpl_q;
assign		o_dph				    =		dph_q;
assign		o_sx_0				    =		sx_0_q;
assign		o_sx_1				    =		sx_1_q;
assign      o_s1_done_tick          =       s1_done_tick;
assign      o_s2_done_tick          =       s2_done_tick;
assign      o_s3_done_tick          =       s3_done_tick;
assign      o_peri_sfr_req          =       peri_sfr_req_q  |   peri_sfr_req_d;
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
assign      o_cpu_dbg_boot_ack_n    =   cpu_dbg_boot_ack_n;
assign      o_cpu_dbg_brkHit_n      =   cpu_dbg_brkHit_n;

assign      o_cpu_err_halt          =   cpu_err_halt_q;
assign      o_cpu_err_code          =   cpu_err_code_q;

assign      o_cpu_dbg_halt          =   cpu_dbg_halt_q;
assign      o_cpu_dbgBoot_ack_n     =   cpu_dbg_boot_ack_n;

assign      o_cpu_haltReq_n         =   ~ (cpu_dbg_halt_q | cpu_err_halt_q);
//-----------------------------------------------------------------------------------------------------------------------------------------------------------//
endmodule