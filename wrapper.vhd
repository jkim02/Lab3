----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:07:37 11/10/2014 
-- Design Name: 
-- Module Name:    wrapper - wrapper_arch 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity wrapper is
    Port ( ALUControl_out	: in	STD_LOGIC_VECTOR(7 downto 0);
           Control			: out	STD_LOGIC_VECTOR(5 downto 0));
end wrapper;

architecture wrapper_arch of wrapper is

variable ALUOp	: STD_LOGIC_VECTOR(1 downto 0) := (others=>'0');
variable funct : STD_LOGIC_VECTOR(5 downto 0) := (others=>'0');
variable AplusB 	: STD_LOGIC_VECTOR (31 downto 0);
variable AminusB 	: STD_LOGIC_VECTOR (31 downto 0);
variable suboverflow: STD_LOGIC;
variable AorB 		: STD_LOGIC_VECTOR (31 downto 0);

begin

process (ALUControl_out)

begin
	ALUOp	:= ALUControl_out(7 downto 6);
	funct := ALUControl_out(5 downto 0);

	--AplusB := ALU_InA + ALU_InB;
	--AminusB := ALU_InA - ALU_InB;
	--suboverflow := ( ALU_InA(31) xor  ALU_InB(31) )  and ( ALU_InB(31) xnor AminusB(31) );
	--AorB := ALU_InA or ALU_InB;

	--ALU_zero <= '0'; -- default. changed only by BEQ

	case ALUOp is
	when "00" => -- lw, sw
		--ALU_Out <= AplusB;
		-- addition
		Control <= "00010";
	
	when "01" => -- beq
		-- assert ALU_zero
		--if AminusB = x"00000000" then
		--	ALU_zero <= '1';
		--end if;
	
	when "10" =>		-- R-type
		case funct is
		when "100000"=> --add
			Control <= "00010";
	
		when "100010"=> --sub
			Control <= "00110";
	
		when "100100"=> --and
			Control <= "00000";
	
		when "100101"=> --or
			Control <= "00001";
	
		when "100111"=> --nor
			Control <= "01100";
		
		when "101010"=> --slt
			--ALU_Out(0) <= AminusB(31) xor suboverflow;
			Control <= "00111";

		when others =>	null;
		end case;

	when "11" => -- ori
		ALU_Out <= AorB;

	when others => null;
	end case;

	
end process;

end wrapper_arch;

