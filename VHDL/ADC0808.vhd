-------------------------------------------------------------------
-- University: Universidad Pedagógica y Tecnológica de Colombia
-- Author: Edwar Javier Patiño Núñez
--
-- Create Date: 05/05/2020
-- Project Name: ADC0808
-- Description: 
-- 	This description emulates the behavior of the IC ADC0808.
--		The resolution of the input voltages is given by the value
--		of the generic signal "bits_res" (in number of bits), and
--		the bits required for integer part are given by "bits_int"
-------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ADC0808 is
	generic(
		-- Values for input voltages
		bits_int		:natural := 3;		-- Bits of the integer part (no sign bit)
		bits_res		:natural := 8		-- Resolution bits
	);
	port(
		strt		:in std_logic;														-- Start
		oe			:in std_logic;														-- Output enable
		clk		:in std_logic;														-- Clock
		in_0 		:in std_logic_vector(bits_int + bits_res downto 0);	-- IN0
		in_1 		:in std_logic_vector(bits_int + bits_res downto 0);	-- IN1
		in_2 		:in std_logic_vector(bits_int + bits_res downto 0);	-- IN2
		in_3 		:in std_logic_vector(bits_int + bits_res downto 0);	-- IN3
		in_4 		:in std_logic_vector(bits_int + bits_res downto 0);	-- IN4
		in_5 		:in std_logic_vector(bits_int + bits_res downto 0);	-- IN5
		in_6 		:in std_logic_vector(bits_int + bits_res downto 0);	-- IN6
		in_7 		:in std_logic_vector(bits_int + bits_res downto 0);	-- IN7
		v_pos		:in std_logic_vector(bits_int + bits_res downto 0);	-- Positive reference voltage
		v_neg		:in std_logic_vector(bits_int + bits_res downto 0);	-- Negative reference voltage
		add		:in std_logic_vector(2 downto 0);							-- Address
		ale		:in std_logic;														-- Address latch enable
		
		output	:inout std_logic_vector(7 downto 0);						-- Data output
		eoc		:out std_logic														-- End of conversion
	);
end entity;

architecture behavior of ADC0808 is
	signal xstrt				:std_logic := '0';
	-- Signals for address and multiplex the inputs
	signal ff_add				:std_logic_vector(2 downto 0);
	signal s_v_in				:std_logic_vector(bits_int + bits_res downto 0);
	signal v_in					:std_logic_vector(bits_int + bits_res downto 0);
	signal ld_v_in				:std_logic;
	-- Signals for DAC
	signal reg_sar				:std_logic_vector(7 downto 0);
	signal div					:std_logic_vector(7 downto 0);
	signal v_dac_num			:std_logic_vector(8 + bits_res + 3 + bits_int + bits_res downto 0);
	signal v_dac_div			:std_logic_vector(8 + 1 + bits_res downto 0);
	signal v_dac				:std_logic_vector(8 + bits_res + 3 + bits_int + bits_res downto 0);
	signal exp					:std_logic_vector(bits_res downto 0);
	-- Signals for comparator
	signal comp					:std_logic;
	-- Signals for SAR logic
	signal in_ff_sar			:std_logic_vector(7 downto 0);
	signal rst_reg_sar		:std_logic;
	signal sel_mux_ff_sar	:std_logic;
	
	signal cntr_dcdr			:std_logic_vector(2 downto 0);
	signal rst_cntr_dcdr		:std_logic;
	signal en_cntr_dcdr		:std_logic;
	signal comp_dcdr			:std_logic;
	signal dcdr					:std_logic_vector(7 downto 0);
	signal s_dcdr				:std_logic_vector(7 downto 0);
	signal en_dcdr				:std_logic;
	
	signal cntr_prds			:std_logic_vector(2 downto 0);
	signal rst_cntr_prds		:std_logic;
	signal comp_prds			:std_logic;
	signal en_cntr_prds		:std_logic;
	-- Signals for FSM
	type state_type is (rst, sample, higher, lower, periods, algorithm, load, idle);
	signal state : state_type;
	-- Signals for data output
	signal ld_output			:std_logic;
	signal s_output			:std_logic_vector(7 downto 0);
begin
	---------------------------------------------------------
	-- Address and Multiplexor Inputs
	---------------------------------------------------------
	ffadd: process(ale)
	begin
		if rising_edge(ale) then
			ff_add <= add;
		end if;
	end process;
	
	with ff_add select s_v_in <= 	in_0 when "000",
											in_1 when "001",
											in_2 when "010",
											in_3 when "011",
											in_4 when "100",
											in_5 when "101",
											in_6 when "110",
											in_7 when others;
	
	ff_v_in: process(ld_v_in)
	begin
		if rising_edge(ld_v_in) then
			v_in <= s_v_in;
		end if;
	end process;
										
	---------------------------------------------------------
	-- Internal DAC
	---------------------------------------------------------
	div <= "11111111";
	exp <= std_logic_vector(to_unsigned(2**bits_res, bits_res + 1));
	v_dac_num <= std_logic_vector(signed('0'&(unsigned(reg_sar)*unsigned(exp)))*signed(signed(v_pos(bits_int + bits_res)&v_pos) - signed(v_neg(bits_int + bits_res)&v_neg)));
	v_dac_div <= std_logic_vector(signed('0'&(unsigned(div)*unsigned(exp))));
	v_dac <= std_logic_vector(signed(signed(v_dac_num)/signed(v_dac_div))+(signed(v_neg)));
	
	---------------------------------------------------------
	-- Comparator
	---------------------------------------------------------
	comparator: process(v_in,v_dac)
	begin
		if signed(v_in) < signed(v_dac) then
			comp <= '1';
		else
			comp <= '0';
		end if;
	end process;
	
	---------------------------------------------------------
	-- SAR logic
	---------------------------------------------------------
	generate_ff_sar: for i in 0 to 7 generate
		ff_sar: process(clk, rst_reg_sar)
		begin
			if rst_reg_sar = '1' then
				reg_sar(i) <= '0';
			elsif rising_edge(clk) then
				if dcdr(i) = '1' then
					reg_sar(i) <= in_ff_sar(i);
				end if;
			end if;
		end process;
		
		with sel_mux_ff_sar select in_ff_sar(i) <= '1' when '1', '0' when others;
	end generate;
		
	counter_decoder: process(clk, rst_cntr_dcdr)
	begin
		if rst_cntr_dcdr = '1' then
			cntr_dcdr <= "111";
		elsif rising_edge(clk) then
			if en_cntr_dcdr = '1' then
				cntr_dcdr <= std_logic_vector(unsigned(cntr_dcdr) - 1);
			end if;
		end if;
	end process;
	
	comp_dcdr <= '1' when (unsigned(cntr_dcdr) = 7) else '0';

	with cntr_dcdr select s_dcdr <=	"10000000" when "111",
												"01000000" when "110",
												"00100000" when "101",
												"00010000" when "100",
												"00001000" when "011",
												"00000100" when "010",
												"00000010" when "001",
												"00000001" when others;
	
	with en_dcdr select dcdr <= s_dcdr when '1', "00000000" when others;
	
	counter_periods: process(clk, rst_cntr_prds)
	begin
		if rst_cntr_prds = '1' then
			cntr_prds <= "111";
		elsif rising_edge(clk) then
			if en_cntr_prds = '1' then
				cntr_prds <= std_logic_vector(unsigned(cntr_prds) - 1);
			end if;
		end if;
	end process;
	
	comp_prds <= '1' when (unsigned(cntr_prds) = 7) else '0';
	
	---------------------------------------------------------
	-- FSM
	---------------------------------------------------------
	process
	begin	
		wait until rising_edge(strt);
		xstrt <= '1';
		wait for 1 us;
		xstrt <= '0';
	end process;
	
	-- Logic to advance to the next state
	process (clk, xstrt)
	begin
		if xstrt = '1' then
			state <= rst;
		elsif (falling_edge(clk)) then
			case state is
				when rst =>
					if xstrt = '0' then
						state <= sample;						
					else
						state <= rst;
					end if;
					
				when sample =>
					state <= higher;
					
				when higher=>
					if comp = '1' then
						state <= lower;
					else
						state <= periods;
					end if;
					
				when lower =>
					state <= periods;
					
				when periods =>
					if comp_prds = '1' then
						state <= algorithm;
					else
						state <= periods;
					end if;
					
				when algorithm =>
					if comp_dcdr = '1' then
						state <= load;
					else
						state <= higher;
					end if;
					
				when load =>
					state <= idle;
					
				when idle =>
					state <= idle;
			end case;
		end if;
	end process;
	
	-- Output depends only on the current state
	process (state)
	begin
		case state is
			when rst =>
				eoc					<= '1';
				ld_v_in				<= '0';
				sel_mux_ff_sar		<= '1';
				rst_cntr_dcdr		<= '1';	
				en_cntr_dcdr		<= '0';
				en_dcdr				<= '0';
				rst_cntr_prds		<= '1';
				en_cntr_prds		<= '0';
				ld_output			<= '0';
				rst_reg_sar			<= '1';
			when sample =>
				eoc					<= '0';
				ld_v_in				<= '1';
				sel_mux_ff_sar		<= '1';
				rst_cntr_dcdr		<= '1';	
				en_cntr_dcdr		<= '0';
				en_dcdr				<= '0';
				rst_cntr_prds		<= '0';
				en_cntr_prds		<= '1';
				ld_output			<= '0';
				rst_reg_sar			<= '0';
			when higher =>
				eoc					<= '0';
				ld_v_in				<= '0';
				sel_mux_ff_sar		<= '1';
				rst_cntr_dcdr		<= '0';	
				en_cntr_dcdr		<= '0';
				en_dcdr				<= '1';
				rst_cntr_prds		<= '0';
				en_cntr_prds		<= '1';
				ld_output			<= '0';
				rst_reg_sar			<= '0';
			when lower =>
				eoc					<= '0';
				ld_v_in				<= '0';
				sel_mux_ff_sar		<= '0';
				rst_cntr_dcdr		<= '0';	
				en_cntr_dcdr		<= '0';
				en_dcdr				<= '1';
				rst_cntr_prds		<= '0';
				en_cntr_prds		<= '1';
				ld_output			<= '0';
				rst_reg_sar			<= '0';
			when periods =>
				eoc					<= '0';
				ld_v_in				<= '0';
				sel_mux_ff_sar		<= '0';
				rst_cntr_dcdr		<= '0';	
				en_cntr_dcdr		<= '0';
				en_dcdr				<= '0';
				rst_cntr_prds		<= '0';
				en_cntr_prds		<= '1';
				ld_output			<= '0';
				rst_reg_sar			<= '0';
			when algorithm =>
				eoc					<= '0';
				ld_v_in				<= '0';
				sel_mux_ff_sar		<= '0';
				rst_cntr_dcdr		<= '0';
				en_cntr_dcdr		<= '1';
				en_dcdr				<= '0';
				rst_cntr_prds		<= '0';
				en_cntr_prds		<= '1';
				ld_output			<= '0';
				rst_reg_sar			<= '0';
			when load =>
				eoc					<= '0';
				ld_v_in				<= '0';
				sel_mux_ff_sar		<= '0';
				rst_cntr_dcdr		<= '0';	
				en_cntr_dcdr		<= '0';
				en_dcdr				<= '0';
				rst_cntr_prds		<= '0';
				en_cntr_prds		<= '0';
				ld_output			<= '1';
				rst_reg_sar			<= '0';
			when idle =>
				eoc					<= '1';
				ld_v_in				<= '0';
				sel_mux_ff_sar		<= '0';
				rst_cntr_dcdr		<= '0';	
				en_cntr_dcdr		<= '0';
				en_dcdr				<= '0';
				rst_cntr_prds		<= '0';
				en_cntr_prds		<= '0';
				ld_output			<= '0';
				rst_reg_sar			<= '0';
		end case;
	end process;

	---------------------------------------------------------
	-- Output register
	---------------------------------------------------------
	reg_output: process(clk)
	begin
		if rising_edge(clk) then
			if ld_output = '1' then
				s_output <= reg_sar;
			end if;
		end if;
	end process;
	
	output_enable: process(oe, s_output)
	begin
		if oe = '1' then
			output <= s_output;
		else
			output <= (others=>'Z');
		end if;
	end process;
end architecture;