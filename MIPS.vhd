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
-- ALU
----------------------------------------------------------------
--component ALU is
--    Port ( 	
--			ALU_InA 		: in  STD_LOGIC_VECTOR (31 downto 0);				
--			ALU_InB 		: in  STD_LOGIC_VECTOR (31 downto 0);
--			ALU_Out 		: out STD_LOGIC_VECTOR (31 downto 0);
--			ALU_Control	: in  STD_LOGIC_VECTOR (7 downto 0);
--			ALU_zero		: out STD_LOGIC);
--end component;
component ALU is
	generic (width 	: integer := 32);
	Port	(
			Clk			: in	STD_LOGIC;
			Control		: in	STD_LOGIC_VECTOR (5 downto 0);
			Operand1		: in	STD_LOGIC_VECTOR (width-1 downto 0);
			Operand2		: in	STD_LOGIC_VECTOR (width-1 downto 0);
			Result1		: out	STD_LOGIC_VECTOR (width-1 downto 0);
			Result2		: out	STD_LOGIC_VECTOR (width-1 downto 0);
			Status		: out	STD_LOGIC_VECTOR (2 downto 0); -- busy (multicycle only), overflow (add and sub), zero (sub)
			Debug			: out	STD_LOGIC_VECTOR (width-1 downto 0));	
end component;

----------------------------------------------------------------
-- Control Unit
----------------------------------------------------------------
component ControlUnit is
    Port ( 	
			opcode 		: in   STD_LOGIC_VECTOR (5 downto 0);
			ALUOp 		: out  STD_LOGIC_VECTOR (1 downto 0);
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
-- ALU Control
----------------------------------------------------------------

component ALU_Control_Unit is
    Port (
			Instruction_Low : in  STD_LOGIC_VECTOR (5 downto 0);
         ALUOp_in : in  STD_LOGIC_VECTOR (1 downto 0);
         ALUControl_out : out  STD_LOGIC_VECTOR (7 downto 0));
end component;


----------------------------------------------------------------
-- Wrapper
----------------------------------------------------------------
component wrapper is
	Port (
			ALUControl_in	: in	STD_LOGIC_VECTOR(7 downto 0);
			Wrap_Control	: out	STD_LOGIC_VECTOR(5 downto 0));
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
-- ALU Signals
----------------------------------------------------------------
--	signal	ALU_InA 		:  STD_LOGIC_VECTOR (31 downto 0);
--	signal	ALU_InB 		:  STD_LOGIC_VECTOR (31 downto 0);
--	signal	ALU_Out 		:  STD_LOGIC_VECTOR (31 downto 0);
--	signal	ALU_Control	:  STD_LOGIC_VECTOR (7 downto 0);
--	signal	ALU_zero		:  STD_LOGIC;			
--	signal	Clk			:	STD_LOGIC;
	constant	width 		: 	integer := 32;
	signal	Control		:	STD_LOGIC_VECTOR (5 downto 0);
	signal	Operand1		:	STD_LOGIC_VECTOR (width-1 downto 0);
	signal	Operand2		:	STD_LOGIC_VECTOR (width-1 downto 0);
	signal	Result1		:	STD_LOGIC_VECTOR (width-1 downto 0);
	signal	Result2		:	STD_LOGIC_VECTOR (width-1 downto 0);
	signal	Status		:	STD_LOGIC_VECTOR (2 downto 0); -- busy (multicycle only), overflow (add and sub), zero (sub)
	signal	Debug			:	STD_LOGIC_VECTOR (width-1 downto 0);
	
----------------------------------------------------------------
-- Control Unit Signals
----------------------------------------------------------------				
 	signal	opcode 		:  STD_LOGIC_VECTOR (5 downto 0);
	signal	ALUOp 		:  STD_LOGIC_VECTOR (1 downto 0);
	signal	Branch 		:  STD_LOGIC;
	signal	Jump	 		:  STD_LOGIC;	
	signal	MemtoReg 	:  STD_LOGIC;
	signal 	InstrtoReg	: 	STD_LOGIC;		
	signal	ALUSrc 		:  STD_LOGIC;	
	signal	SignExtend 	: 	STD_LOGIC;
	signal	RegWrite		: 	STD_LOGIC;	
	signal	RegDst		:  STD_LOGIC;

----------------------------------------------------------------
-- ALU Control
----------------------------------------------------------------

	signal	Instruction_Low :	STD_LOGIC_VECTOR (5 downto 0);
   signal 	ALUOp_in : 			STD_LOGIC_VECTOR (1 downto 0);
   signal 	ALUControl_out :	STD_LOGIC_VECTOR (7 downto 0);


----------------------------------------------------------------
-- Wrapper Signals
----------------------------------------------------------------
	signal	ALUControl_in	:	STD_LOGIC_VECTOR(7 downto 0);
	signal	Wrap_Control	:	STD_LOGIC_VECTOR(5 downto 0);

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
-- ALU port map
----------------------------------------------------------------
ALU1 				: ALU port map
						(
						Clk		=> Clk,
						Control	=> Control,
						Operand1	=> Operand1,
						Operand2	=> Operand2,
						Result1	=> Result1,
						Result2	=> Result2,
						Status	=> Status, -- busy (multicycle only), overflow (add and sub), zero (sub)
						Debug		=> Debug
						);
						
						
----------------------------------------------------------------
-- ControlUnit port map
----------------------------------------------------------------
ControlUnit1 	: ControlUnit port map
						(
						opcode 		=> opcode, 
						ALUOp 		=> ALUOp, 
						Branch 		=> Branch, 
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
-- ALU_Control_Unit port map
----------------------------------------------------------------
ALUControl1		: ALU_Control_Unit port map
						(
						Instruction_Low 	=> Instruction_Low,
						ALUOp_in				=> ALUOp_in,
						ALUControl_out		=> ALUControl_out
						);
						
----------------------------------------------------------------
-- Wrapper port map
----------------------------------------------------------------
Wrapper1			: wrapper port map
						(
						ALUControl_in		=> ALUControl_in,
						Wrap_Control 		=> Wrap_Control
						);
						
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
combinational: process (PC_Four, PC_out, Branch, ALU_zero, Jump, Instr, AluOp, MemtoReg, InstrtoReg, AluSrc,
								extend_32, RegDst, ReadData1_Reg, ReadData2_Reg, Alu_Out, Data_In)

begin

PC_Four <= PC_out + "100"; --Instruction incrementer
Addr_Instr <= PC_out;
opcode <= Instr(31 downto 26); 
ReadAddr1_Reg <= Instr(25 downto 21);
ReadAddr2_Reg <= Instr(20 downto 16);
Instruction_Low <= Instr(5 downto 0);
ALUOp_in <= ALUOp;
--ALU_Control(7 downto 6) <= ALUOp(1 downto 0);
--ALU_Control(5 downto 0) <= Instr(5 downto 0); --Combine ALUOp and Instr into the 8-bit form that ALU1 can process
Control <= Wrap_Control;

--ALU_InA <= ReadData1_Reg; --Direct input with no shenanigans
Operand1 <= ReadData1_Reg; --Direct input with no shenanigans
input_16 <= Instr(15 downto 0); --Split up of instructions into their respective parts
Data_Out <= ReadData2_Reg;
--Addr_Data <= ALU_Out;
Addr_Data <= Result1;

if Jump = '1' then
	PC_in <= PC_Four(31 downto 28) & Instr(25 downto 0) & "00";
else
	if Branch = '1' and ALU_zero = '1' then	--The AND gate
		PC_in <= PC_Four + (extend_32(29 downto 0) & "00");
	else
		PC_in <= PC_Four;
	end if;
end if; --PC multiplexer

if ALUSrc = '1' then
	--ALU_InB <= extend_32;
	Operand2 <= extend_32;
else
	--ALU_InB <= ReadData2_Reg;
	Operand2 <= ReadData2_Reg;
end if; --ALU multiplexer

if RegDst = '1' then
	WriteAddr_Reg <= Instr(15 downto 11);
else
	WriteAddr_Reg <= Instr(20 downto 16);
end if; --Write Address Multiplexer

if InstrtoReg = '1' then
	WriteData_Reg <= Instr(15 downto 0) & x"0000";
else
	if MemtoReg = '1' then
		WriteData_Reg <= Data_In;
	else
		--WriteData_Reg <= ALU_Out;
		WriteData_Reg <= Result1;
	end if;
end if; --Data Multiplexer


end process;

end arch_MIPS;
----------------------------------------------------------------	
----------------------------------------------------------------
-- </MIPS architecture>
----------------------------------------------------------------
----------------------------------------------------------------	
