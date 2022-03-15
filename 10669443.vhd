----------------------------------------------------------------------------------
-- Company: Polytechnic University of Milan
-- Engineer: Demis Selva (10669443 / 934172)
-- Instuctor/Supervisor: Prof. Gianluca Palermo
--
-- Project Name: Prova Finale - Progetto di Reti Logiche 2021/22
--
-- Description: N/A
-- 
----------------------------------------------------------------------------------
LIBRARY IEEE;
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE IEEE.NUMERIC_STD.ALL;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;


ENTITY project_reti_logiche IS
	PORT
	(
		i_clk : IN std_logic;
		i_rst : IN std_logic;
		i_start : IN std_logic;
		i_data : IN std_logic_vector(7 DOWNTO 0);
		o_address : OUT std_logic_vector(15 DOWNTO 0);
		o_done : OUT std_logic;
		o_en : OUT std_logic;
		o_we : OUT std_logic;
		o_data : OUT std_logic_vector (7 DOWNTO 0)
	);
END project_reti_logiche;


ARCHITECTURE Behavioral OF project_reti_logiche IS
	
	TYPE fsm_state IS (
	RESET,
	IDLE,
	WAIT_READ,
	READ_LENGTH,
	WAIT_START,
	START_PROCESS_WORD,
	WAIT_PROCESS,
	-- given FSM --
	S0,
	S1,
	S2,
	S3,
	---------------
	END_PROCESS_WORD,
	WRITE_FIRST_WORD,
	MID_SETUP,
	WRITE_SECOND_WORD,
	NEXT_WORD,
	ENDING);
	
	SIGNAL curr_state : fsm_state;
	SIGNAL last_state : fsm_state; -- last Sx state visited
	SIGNAL read_address : std_logic_vector(15 DOWNTO 0);
	SIGNAL write_address : std_logic_vector(15 DOWNTO 0);
	SIGNAL count_todo : std_logic_vector(7 DOWNTO 0);
	SIGNAL count_done : std_logic_vector(7 DOWNTO 0);
	SIGNAL u_k : std_logic_vector(7 DOWNTO 0);
	SIGNAL p_k : std_logic_vector(15 DOWNTO 0); -- both z's stored here
	SIGNAL z_1 : std_logic_vector(7 DOWNTO 0);
	SIGNAL z_2 : std_logic_vector(7 DOWNTO 0);
	SIGNAL count_state : integer; -- counts u_k processed, up to 8 (7)

BEGIN

	MAIN : PROCESS(i_clk)
	BEGIN
		IF rising_edge(i_clk) THEN
			IF i_rst = '1' THEN
				-- initial reset --
				curr_state <= RESET;
			ELSE
			
				CASE curr_state IS
			
					WHEN RESET =>
						
						-- initial setup --
						o_en <= '0';
						o_we <= '0';
						read_address <= (others => '0');
						write_address <= "0000001111101000"; -- default 1000
						o_address <= (others => '0');
						count_todo <= (others => '0');
						count_done <= (others => '0');
						o_data <= (others => '0');
						o_done <= '0';
						count_state <= 0;
						
						curr_state <= IDLE;
						
					WHEN IDLE =>
					    
				        IF i_start = '1' THEN
                            read_address <= (others => '0');
						    write_address <= "0000001111101000"; 
						    o_address <= (others => '0');
						    o_en <= '1';
						    count_todo <= (others => '0');
						    count_done <= (others => '0');
						    o_data <= (others => '0');
						    count_state <= 0;
					        z_1 <= (others => '0');
                            z_2 <= (others => '0');
                            u_k <= (others => '0');
                            p_k <= (others => '0');
				            curr_state <= WAIT_READ;
						END IF;
						
				    WHEN WAIT_READ =>
				        
				        curr_state <= READ_LENGTH;
						
					WHEN READ_LENGTH =>
						
						count_todo <= i_data;
						count_done <= (others => '0');
						read_address <= std_logic_vector(unsigned(read_address) + 1);
						last_state <= S0;
						curr_state <= WAIT_START;
						
					WHEN WAIT_START =>
					
					   o_address <= read_address;
					   curr_state <= START_PROCESS_WORD;
					
					WHEN START_PROCESS_WORD =>
					
					   IF count_done = count_todo THEN
					       -- done --
					       o_done <= '1';
					       curr_state <= ENDING;
					   ELSE
					       curr_state <= WAIT_PROCESS;
					   END IF;
					
					WHEN WAIT_PROCESS =>
					
					   u_k <= i_data;
					   count_state <= 0;
					   read_address <= std_logic_vector(unsigned(read_address) + 1);
					   curr_state <= last_state;
					
					WHEN S0 =>
					
					   IF count_state < 8 THEN
					       IF u_k(7-count_state) = '0' THEN
					           p_k(15-count_state*2) <= '0';
					           p_k(13-count_state*2+1) <= '0';
                               count_state <= count_state + 1;
                               curr_state <= S0;
					       ELSE
					           p_k(15-count_state*2) <= '1';
					           p_k(13-count_state*2+1) <= '1';
                               count_state <= count_state + 1;
                               curr_state <= S2;
					       END IF;
					   ELSE
					       -- all u_k processed --
					       count_done <= std_logic_vector(unsigned(count_done) + 1);
					       last_state <= S0;
					       count_state <= count_state + 1;
					       curr_state <= END_PROCESS_WORD;
					   END IF;
					
					WHEN S1 =>
					
					   IF count_state < 8 THEN
					       IF u_k(7-count_state) = '0' THEN
					           p_k(15-count_state*2) <= '1';
					           p_k(13-count_state*2+1) <= '1';
                               count_state <= count_state + 1;
                               curr_state <= S0;
					       ELSE
					           p_k(15-count_state*2) <= '0';
					           p_k(13-count_state*2+1) <= '0';
                               count_state <= count_state + 1;
                               curr_state <= S2;
					       END IF;
					   ELSE
					       -- all u_k processed --
					       count_done <= std_logic_vector(unsigned(count_done) + 1);
					       last_state <= S1;
					       count_state <= count_state + 1;
					       curr_state <= END_PROCESS_WORD;
					   END IF;
					
					WHEN S2 =>
					
					   IF count_state < 8 THEN
					       IF u_k(7-count_state) = '0' THEN
					           p_k(15-count_state*2) <= '0';
					           p_k(13-count_state*2+1) <= '1';
                               count_state <= count_state + 1;
                               curr_state <= S1;
					       ELSE
					           p_k(15-count_state*2) <= '1';
					           p_k(13-count_state*2+1) <= '0';
                               count_state <= count_state + 1;
                               curr_state <= S3;
					       END IF;
					   ELSE
					       -- all u_k processed --
					       count_done <= std_logic_vector(unsigned(count_done) + 1);
					       last_state <= S2;
					       count_state <= count_state + 1;
					       curr_state <= END_PROCESS_WORD;
					   END IF;
					
					WHEN S3 =>
					
					   IF count_state < 8 THEN
					       IF u_k(7-count_state) = '0' THEN
					           p_k(15-count_state*2) <= '1';
					           p_k(13-count_state*2+1) <= '0';
                               count_state <= count_state + 1;
                               curr_state <= S1;
					       ELSE
					           p_k(15-count_state*2) <= '0';
					           p_k(13-count_state*2+1) <= '1';
                               count_state <= count_state + 1;
                               curr_state <= S3;
					       END IF;
					   ELSE
					       -- all u_k processed --
					       count_done <= std_logic_vector(unsigned(count_done) + 1);
					       last_state <= S3;
					       count_state <= count_state + 1;
					       curr_state <= END_PROCESS_WORD;
					   END IF;
					
					WHEN END_PROCESS_WORD =>
					
					   o_we <= '1';
					   z_1 <= p_k(15 downto 8);
					   z_2 <= p_k(7 downto 0);
					   o_address <= write_address;
					   curr_state <= WRITE_FIRST_WORD;
					
					WHEN WRITE_FIRST_WORD =>
					
					   o_data <= z_1;
					   write_address <= std_logic_vector(unsigned(write_address) + 1);
					   curr_state <= MID_SETUP;
					
					WHEN MID_SETUP =>
					
					   o_address <= write_address;
					   curr_state <= WRITE_SECOND_WORD;
					
					WHEN WRITE_SECOND_WORD =>
					
					   o_data <= z_2;
					   write_address <= std_logic_vector(unsigned(write_address) + 1);
					   curr_state <= NEXT_WORD;
						
					WHEN NEXT_WORD =>
						
						o_we <= '0';
						o_address <= read_address;
						curr_state <= START_PROCESS_WORD;
						z_1 <= (others => '0');
                        z_2 <= (others => '0');
                        u_k <= (others => '0');
                        p_k <= (others => '0');
						
					WHEN ENDING =>
						
						IF (i_start = '0') THEN
							o_done <= '0';
							o_en <= '0';
							curr_state <= IDLE;
						ELSE
							o_done <= '0';
							o_we <= '0';
						END IF;
						
				END CASE;
				
			END IF;
			
		END IF;
		
	END PROCESS;
	
END Behavioral;