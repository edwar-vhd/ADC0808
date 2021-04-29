-------------------------------------------------------------------
-- University: Universidad Pedagógica y Tecnológica de Colombia
-- Author: Edwar Javier Patiño Núñez
--
-- Create Date: 07/05/2020
-- Project Name: ADC0808_tb
-- Description: 
-- 	This Test Bench script generates four input signals at different
--		frequencies to simulate the aliasing effect in the IC ADC0808.
--
--		The formar for the voltages is: "sign - integer part - decimal part"
--
--		Example:
--			For represent 2.25V with bits_int = 3 and bits_res = 8
--				"0_010_01000000" => (without the "_" sign)
--			
--			For represent -3.25V with bits_int = 3 and bits_res = 8
--				"1_100_11000000"
-------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
use std.textio.all;

entity ADC0808_tb is 
end entity;

architecture behavior of ADC0808_tb is
	constant clk_adc_prd :time := 2 us; --500KHz
	constant t_sample	 	:time := 200 us; --5KHz
	
	-- Testbench internal signals
	file vector_data_00	:text;
	file vector_data_01	:text;
	file vector_data_02	:text;
	file vector_data_03	:text;

	constant bits_int		:natural := 2;
	constant bits_res		:natural := 8;
	
	signal strt				:std_logic := '0';
	signal oe				:std_logic := '1';
	signal clk				:std_logic := '0';
	signal in_0 			:std_logic_vector(bits_int + bits_res downto 0);
	signal in_1 			:std_logic_vector(bits_int + bits_res downto 0);
	signal in_2 			:std_logic_vector(bits_int + bits_res downto 0);
	signal in_3 			:std_logic_vector(bits_int + bits_res downto 0);
	signal in_4 			:std_logic_vector(bits_int + bits_res downto 0);
	signal in_5 			:std_logic_vector(bits_int + bits_res downto 0);
	signal in_6 			:std_logic_vector(bits_int + bits_res downto 0);
	signal in_7 			:std_logic_vector(bits_int + bits_res downto 0);
	signal v_pos			:std_logic_vector(bits_int + bits_res downto 0);
	signal v_neg			:std_logic_vector(bits_int + bits_res downto 0);
	signal add				:std_logic_vector(2 downto 0) := "000";
	signal ale				:std_logic;
		
	signal output			:std_logic_vector(7 downto 0);
	signal eoc				:std_logic;
begin
	---------------------------------------------------------
	-- Instantiate and map the unit under test
	---------------------------------------------------------
	-- Channel selection latch (See timing of ADC0808)
	ale <= strt;		
		
	DUT: entity work.ADC0808
		generic map(
			bits_int => bits_int,
			bits_res	=> bits_res
		)
		port map(
			strt		=> strt,
			oe			=> oe,
			clk		=> clk,
			in_0 		=> in_0,
			in_1 		=> in_1,
			in_2 		=> in_2,
		   in_3 		=> in_3,
		   in_4 		=> in_4,
		   in_5 		=> in_5,
		   in_6 		=> in_6,
		   in_7 		=> in_7,
		   v_pos		=> v_pos,
		   v_neg		=> v_neg,
		   add		=> add,
		   ale		=> ale,
		          
		   output	=> output,
		   eoc		=> eoc
		);
	
	-- Start signal generation
	strt_gen: process
	begin		
		strt <= '0';
		wait for t_sample - 2 us;
		strt <= '1';
		wait for 2 us;
	end process;

	-- Clock signal generation (500KHz)
	clk_gen: process
	begin
		clk <= not clk;
		wait for clk_adc_prd/2;
	end process;
	
	---------------------------------------------------------------------------
	-- These process reads the file "sine.txt" found in the simulation project area.
	-- It will read the data and send it as input data to the ADC.
	---------------------------------------------------------------------------
	in_0_gen: process
		variable vect_line_data :line;
		variable data				:integer;
	begin
		file_open(vector_data_00, "sine.txt", read_mode);									-- Open the file
		while not endfile(vector_data_00) loop													-- Read while file is not finished
			readline(vector_data_00, vect_line_data);											-- Read a line
			read(vect_line_data, data);															-- Read the value
			in_0 <= std_logic_vector(to_signed(data, 1 + bits_int + bits_res));		-- Value type conversion
			wait for 33 us;																			-- Signal at 30Hz
		end loop;
		file_close(vector_data_00);																-- Close the file
	end process;
	
	in_1_gen: process
		variable vect_line_data :line;
		variable data				:integer;
	begin
		file_open(vector_data_01, "sine.txt", read_mode);
		while not endfile(vector_data_01) loop
			readline(vector_data_01, vect_line_data);
			read(vect_line_data, data);
			in_1 <= std_logic_vector(to_signed(data, 1 + bits_int + bits_res));
			wait for 3 us;																				-- Signal at 300Hz
		end loop;
		file_close(vector_data_01);
	end process;
	
	in_2_gen: process
		variable vect_line_data :line;
		variable data				:integer;
	begin
		file_open(vector_data_02, "sine.txt", read_mode);
		while not endfile(vector_data_02) loop
			readline(vector_data_02, vect_line_data);
			read(vect_line_data, data);
			in_2 <= std_logic_vector(to_signed(data, 1 + bits_int + bits_res));
			wait for 333 ns;																			-- Signal at 3KHz
		end loop;
		file_close(vector_data_02);
	end process;
	
	in_3_gen: process
		variable vect_line_data :line;
		variable data				:integer;
	begin
		file_open(vector_data_03, "sine.txt", read_mode);
		while not endfile(vector_data_03) loop
			readline(vector_data_03, vect_line_data);
			read(vect_line_data, data);
			in_3 <= std_logic_vector(to_signed(data, 1 + bits_int + bits_res));
			wait for 33 ns;																				-- Signal at 50KHz
		end loop;
		file_close(vector_data_03);
	end process;
		
	in_4 <= v_pos; 				-- 3.3V
	in_5 <= v_neg; 				-- 0V
	in_6 <= '0'&v_pos(bits_int + bits_res downto 1); -- 1.15V
	in_7 <= "01010000000"; 		-- 2.5V
	
	-- Supply voltages (Reference Voltages)
	v_pos <= "01101001100";		-- +3.3V
	v_neg	<= "00000000000";		-- 0V
	
	-- Address (Selection Analog channel)
	add_gen: process
	begin
		wait for 33 ms;
		add <= std_logic_vector(unsigned(add) + 1);
	end process;
 end architecture;