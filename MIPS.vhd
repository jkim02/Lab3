----------------------------------------------------------------------------------
-- Company: NUS
-- Engineer: Rajesh Panicker
-- 
-- Create Date:   21:06:18 14/10/2014
-- Design Name: 	MIPS
-- Target Devices: Nexys 4 (Artix 7 100T)
-- Tool versions: ISE 14.7
-- Description: MIPS processor
--
-- Dependencies: PC, ALU, ControlUnit, RegFile
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: DO NOT modify the interface (entity). Implementation (architecture) can be modified.
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_unsigned.ALL;

entity MIPS is -- DO NOT modify the interface (entity)
    Port ( 	
			Addr_Instr 		: out STD_LOGIC_VECTOR (31 downto 0);
			Instr 			: in STD_LOGIC_VECTOR (31 downto 0);
			Addr_Data		: out STD_LOGIC_VECTOR (31 downto 0);
			Data_In			: in STD_LOGIC_VECTOR (31 downto 0);
			Data_Out			: out  STD_LOGIC_VECTOR (31 downto 0);
			MemRead 			: out STD_LOGIC; 
			MemWrite 		: out STD_LOGIC; 
			RESET				: in STD_LOGIC;
			CLK				: in STD_LOGIC
			);
end MIPS;


architecture arch_MIPS of MIPS is

----------------------------------------------------------------
-- Program Counter
----------------------------------------------------------------
component PC is
	Port(	
			PC_in 	: in STD_LOGIC_VECTOR (31 downto 0);
			PC_out 	: out STD_LOGIC_VECTOR (31 downto 0);
			RESET		: in STD_LOGIC;
			CLK		: in STD_LOGIC);
end component;



----------------------------------------------------------------
-- Control Unit
----------------------------------------------------------------
component ControlUnit is
    Port ( 	
			opcode 		: in   STD_LOGIC_VECTOR (5 downto 0);
			ImmControl	: out  STD_LOGIC;
			ALUOp 		: out  STD_LOGIC_VECTOR (2 downto 0);
			LinkOut		: out	 STD_LOGIC;
			Branch 		: out  STD_LOGIC;
			Jump	 		: out  STD_LOGIC;				
			MemRead 		: out  STD_LOGIC;	
			MemtoReg 	: out  STD_LOGIC;	
			InstrtoReg	: out  STD_LOGIC; -- true for LUI. When true, Instr(15 downto 0)&x"0000" is written to rt
			MemWrite		: out  STD_LOGIC;	
			ALUSrc 		: out  STD_LOGIC;	
			SignExtend 	: out  STD_LOGIC; -- false for ORI 
			RegWrite		: out  STD_LOGIC;	
			RegDst		: out  STD_LOGIC);
end component;


----------------------------------------------------------------
-- Wrapper
----------------------------------------------------------------

component wrapper is
	 generic (width 	: integer := 32);
    Port ( 	CLK							: in	STD_LOGIC;
				Operand1_wrapper			: in 	STD_LOGIC_VECTOR(width-1 downto 0);
				Operand2_wrapper			: in	STD_LOGIC_VECTOR(width-1 downto 0);
				ALUControl_in_wrapper	: in	STD_LOGIC_VECTOR(8 downto 0);
				Result_wrapper				: out	STD_LOGIC_VECTOR(width-1 downto 0);
				ALU_Zero_wrapper			: out	STD_LOGIC;
				ALU_Jump_wrapper			: out STD_LOGIC;
				ALU_Busy_wrapper			: out STD_LOGIC;
				Immediate_wrapper			: in 	STD_LOGIC);
end component;


----------------------------------------------------------------
-- Register File
----------------------------------------------------------------
component RegFile is
    Port ( 	
			ReadAddr1_Reg 	: in  STD_LOGIC_VECTOR (4 downto 0);
			ReadAddr2_Reg 	: in  STD_LOGIC_VECTOR (4 downto 0);
			ReadData1_Reg 	: out STD_LOGIC_VECTOR (31 downto 0);
			ReadData2_Reg 	: out STD_LOGIC_VECTOR (31 downto 0);				
			WriteAddr_Reg	: in  STD_LOGIC_VECTOR (4 downto 0); 
			WriteData_Reg 	: in STD_LOGIC_VECTOR (31 downto 0);
			RegWrite 		: in STD_LOGIC; 
			CLK 				: in  STD_LOGIC);
end component;

----------------------------------------------------------------
-- Sign_extension
----------------------------------------------------------------
component Sign_extension is
	Port ( input_16 : in  STD_LOGIC_VECTOR (15 downto 0);
           extend_32 : out  STD_LOGIC_VECTOR (31 downto 0);
			  enable : in STD_LOGIC);
end component;

----------------------------------------------------------------
-- PC Signals
----------------------------------------------------------------
	signal	PC_in 		:  STD_LOGIC_VECTOR (31 downto 0);
	signal	PC_out 		:  STD_LOGIC_VECTOR (31 downto 0);
	signal 	PC_out_add4 : STD_LOGIC_VECTOR(31 downto 0);



	
----------------------------------------------------------------
-- Control Unit Signals
----------------------------------------------------------------				
 	signal	opcode 		:  STD_LOGIC_VECTOR (5 downto 0);
	signal	ALUOp 		:  STD_LOGIC_VECTOR (2 downto 0);
	signal	ImmControl	:	STD_LOGIC;
	signal	LinkOut		:  STD_LOGIC;
	signal	Branch 		:  STD_LOGIC;
	signal	Jump	 		:  STD_LOGIC;	
	signal	MemtoReg 	:  STD_LOGIC;
	signal 	InstrtoReg	: 	STD_LOGIC;		
	signal	ALUSrc 		:  STD_LOGIC;	
	signal	SignExtend 	: 	STD_LOGIC;
	signal	RegWrite		: 	STD_LOGIC;	
	signal	RegDst		:  STD_LOGIC;

----------------------------------------------------------------
-- Wrapper Signals
----------------------------------------------------------------
	 --signal 	CLK							: STD_LOGIC;
	 signal  Operand1_wrapper			: STD_LOGIC_VECTOR(32-1 downto 0);
	 signal  Operand2_wrapper			: STD_LOGIC_VECTOR(32-1 downto 0);
	 signal  ALUControl_in_wrapper	: STD_LOGIC_VECTOR(8 downto 0);
	 signal  Result_wrapper				: STD_LOGIC_VECTOR(32-1 downto 0);
	 signal  ALU_Zero_wrapper			: STD_LOGIC;
	 signal  ALU_Jump_wrapper			: STD_LOGIC;
	 signal	ALU_Busy_wrapper			: STD_LOGIC;
	 signal  Immediate_wrapper			: STD_LOGIC;
	
----------------------------------------------------------------
-- Register File Signals
----------------------------------------------------------------
 	signal	ReadAddr1_Reg 	:  STD_LOGIC_VECTOR (4 downto 0);
	signal	ReadAddr2_Reg 	:  STD_LOGIC_VECTOR (4 downto 0);
	signal	ReadData1_Reg 	:  STD_LOGIC_VECTOR (31 downto 0);
	signal	ReadData2_Reg 	:  STD_LOGIC_VECTOR (31 downto 0);
	signal	WriteAddr_Reg	:  STD_LOGIC_VECTOR (4 downto 0); 
	signal	WriteData_Reg 	:  STD_LOGIC_VECTOR (31 downto 0);
	
	
----------------------------------------------------------------
-- Sign_extension Signals
----------------------------------------------------------------
	signal input_16 : STD_LOGIC_VECTOR (15 downto 0);
   signal extend_32 : STD_LOGIC_VECTOR (31 downto 0);
	signal enable :  STD_LOGIC;
----------------------------------------------------------------
-- Other Signals
----------------------------------------------------------------
	--<any other signals used goes here>
 signal	PC_Four : STD_LOGIC_VECTOR (31 downto 0);

----------------------------------------------------------------	
----------------------------------------------------------------
-- <MIPS architecture>
----------------------------------------------------------------
----------------------------------------------------------------
begin

----------------------------------------------------------------
-- PC port map
----------------------------------------------------------------
PC1				: PC port map
						(
						PC_in 	=> PC_in, 
						PC_out 	=> PC_out, 
						RESET 	=> RESET,
						CLK 		=> CLK
						);
						

						
						
----------------------------------------------------------------
-- ControlUnit port map
----------------------------------------------------------------
ControlUnit1 	: ControlUnit port map
						(
						opcode 		=> opcode, 
						ALUOp 		=> ALUOp,
						ImmControl	=> ImmControl,
						Branch 		=> Branch,
						LinkOut		=>	LinkOut,
						Jump 			=> Jump, 
						MemRead 		=> MemRead, 
						MemtoReg 	=> MemtoReg, 
						InstrtoReg 	=> InstrtoReg, 
						MemWrite 	=> MemWrite, 
						ALUSrc 		=> ALUSrc, 
						SignExtend 	=> SignExtend, 
						RegWrite 	=> RegWrite, 
						RegDst 		=> RegDst
						);

----------------------------------------------------------------
-- Wrapper port map
----------------------------------------------------------------
Wrapper1			: wrapper port map
						( 	
				CLK => CLK,
				Operand1_wrapper	=> Operand1_wrapper,
				Operand2_wrapper	=> Operand2_wrapper,
				ALUControl_in_wrapper => ALUControl_in_wrapper,
				Result_wrapper	=> Result_wrapper,
				ALU_Zero_wrapper => ALU_Zero_wrapper,
				ALU_Jump_wrapper => ALU_Jump_wrapper,
				ALU_Busy_wrapper => ALU_Busy_wrapper,
				Immediate_wrapper	=> Immediate_wrapper);
						
----------------------------------------------------------------
-- Register file port map
----------------------------------------------------------------
RegFile1			: RegFile port map
						(
						ReadAddr1_Reg 	=>  ReadAddr1_Reg,
						ReadAddr2_Reg 	=>  ReadAddr2_Reg,
						ReadData1_Reg 	=>  ReadData1_Reg,
						ReadData2_Reg 	=>  ReadData2_Reg,
						WriteAddr_Reg 	=>  WriteAddr_Reg,
						WriteData_Reg 	=>  WriteData_Reg,
						RegWrite 		=> RegWrite,
						CLK 				=> CLK				
						);


----------------------------------------------------------------
-- Sign_extension port map
----------------------------------------------------------------
SignExtender : sign_extension port map
					(
					input_16 => input_16,
					 extend_32 => extend_32,
					 enable => SignExtend
					);
					
----------------------------------------------------------------
-- Processor logic
----------------------------------------------------------------
--<Rest of the logic goes here>
--Notes:
	--Variables get their values instantaneously
	--Signals are scheduled to get RHS after a specified delay
	--If, Case, Loop --All sequential statements
	--When...Else, With...Select,all concurrent statements
----------------------------------------------------------------
-- Combinational logic -executes at time T and not T
----------------------------------------------------------------
--None of these statements should appear on the LHS more than once
Immediate_wrapper <= ImmControl; --Mapping of immediate signal
PC_Four <= PC_Out + "100"; --PCadder
Addr_Instr <= PC_out; --Mapping of PC to Addr_Instr, the output of the entire MIPS processor.
opcode <= Instr(31 downto 26);
ReadAddr1_Reg <= Instr(25 downto 21);
ReadAddr2_Reg <= Instr(20 downto 16); --Direct mapping of the accepted parts of the instructino to the register file's inputs.
ALUControl_in_wrapper(8 downto 6) <= ALUOp(2 downto 0); --ALUOp goes from Control Unit to wrapper.
ALUControl_in_wrapper(5 downto 0) <= Instr(5 downto 0); --Combine ALUOp and Instr into the 9-bit form that ALU1 can process
Operand1_wrapper <= ReadData1_Reg; --Direct input with no shenanigans, from the RegFile
input_16 <= Instr(15 downto 0); --Split up of instructions into their respective parts
Data_Out <= ReadData2_Reg; -- The presence or absence of this should not affect internal workings of MIPS
Addr_Data <= Result_wrapper; --It is connected as it should be in the sche

PC_in <= PC_Out when ALU_Busy_wrapper = '1' else
			ReadData1_Reg when ALU_Jump_wrapper = '1' and Jump = '0' else -- Jump Register [JR], jump to address in register $s with a 1 instruction delay.
			PC_Four (31 downto 28) & Instr(25 downto 0) & "00" when Jump = '1' else -- Normal jump, BGEZ
			PC_Four + (extend_32(29 downto 0) & "00") when Branch = '1' and ALU_zero_wrapper = '1' else -- BEQ
			PC_Four; --Normal instruction increment

WriteAddr_Reg <= "11111" when Jump = '1' and LinkOut = '1' else --Register is set to $31 to store the last address;
				     Instr(15 downto 11) when LinkOut = '0' and RegDst = '1' else
					  Instr(20 downto 16);
WriteData_Reg <= PC_out + "1000" when (Jump = '1' and LinkOut = '1') --JAL
											  or (Branch = '1' and ALU_zero_wrapper = '1' and LinkOut = '1' and Instr(20) = '1') else --BGEZAL 
				     Instr(15 downto 0) & x"0000" when InstrtoReg = '1' else --LUI
					  Data_In when InstrtoReg = '0' and MemtoReg = '1' else --On general principle of MemtoReg = 1, apparently.
					  Result_wrapper when InstrtoReg = '0' and MemtoReg = '0';
					  
Operand2_wrapper <= extend_32 when ALUSrc = '1' else
					  ReadData2_Reg when ALUSrc = '0';


end arch_MIPS;
----------------------------------------------------------------	
----------------------------------------------------------------
-- </MIPS architecture>
----------------------------------------------------------------
----------------------------------------------------------------	
