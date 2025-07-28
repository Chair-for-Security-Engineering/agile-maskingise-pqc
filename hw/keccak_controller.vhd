----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2018 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATA:			    13/12/2018
-- LAST CHANGES:            13/12/2018
-- MODULE NAME:			    KECCAK_CONTROLLER
--
-- REVISION:				1.00 - File created: finite state machine
--
-- LICENCE: 				Please look at licence.txt
-- USAGE INFORMATION:	    Please look at readme.txt. If licence.txt or readme.txt
--							are missing or if you have questions regarding the code
--							please contact Tim Güneysu (tim.gueneysu@rub.de) and
--                          Jan Richter-Brockmann (jan.richter-brockmann@rub.de)
--
-- THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY 
-- KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
-- PARTICULAR PURPOSE.
----------------------------------------------------------------------------------


LIBRARY IEEE;
    USE IEEE.STD_LOGIC_1164.ALL;
    USE IEEE.NUMERIC_STD.ALL;
    
LIBRARY work;
    USE work.keccak_settings.ALL;


ENTITY KECCAK_CONTROLLER IS
    Port (  
        CLK             : IN  STD_LOGIC;
        EN              : IN  STD_LOGIC;
        RESET           : IN  STD_LOGIC;
        -- CONTROL ABSORBING -----------------
        ABSORB          : OUT STD_LOGIC;
        -- CONTROL SQUEEZING -----------------
        ENABLE_ROUND    : OUT STD_LOGIC;
        -- IO --------------------------------
        RESET_IO        : OUT STD_LOGIC;
        -- COUNTER ---------------------------
        CNT_EN_ABS      : OUT STD_LOGIC;
        CNT_RST_ABS     : OUT STD_LOGIC;
        CNT_ABSORB      : IN  STD_LOGIC_VECTOR((CNT_LENGTH_ABSORB-1) DOWNTO 0);
        CNT_EN_ROUND    : OUT STD_LOGIC;
        CNT_RST_ROUND   : OUT STD_LOGIC;
        CNT_ROUND       : IN  STD_LOGIC_VECTOR((CNT_LENGTH_ROUND-1)  DOWNTO 0)
    );
END KECCAK_CONTROLLER;



-- ARCHITECTURE ------------------------------------------------------------------
ARCHITECTURE FSM OF KECCAK_CONTROLLER IS



-- SIGNALS -----------------------------------------------------------------------
TYPE STATES IS (S_RESET, S_ABSORB_PERMUT);
SIGNAL STATE : STATES := S_RESET;



-- FSM ---------------------------------------------------------------------------
BEGIN

    -- FINITE STATE MACHINE - PROCESS --------------------------------------------
    MOORE : PROCESS(CLK, RESET)
    BEGIN
        -- STATE TRANSITIONS -----------------------------------------------------
        IF RISING_EDGE(CLK) THEN
            IF RESET = '1' THEN
                RESET_IO        <= '1';

                ABSORB          <= '0';
                ENABLE_ROUND    <= '0';
                
                -- COUNTER ------------
                CNT_EN_ABS      <= '0';
                CNT_RST_ABS     <= '1';
                CNT_EN_ROUND    <= '0';
                CNT_RST_ROUND   <= '1';
                
                STATE           <= S_RESET;
            ELSE
                CASE STATE IS
                    
                    ------------------------------------------------------------------
                    WHEN S_RESET        =>                        
                        -- COUNTER ------------
                        CNT_EN_ABS      <= '0';
                        CNT_RST_ABS     <= '1';
                        CNT_EN_ROUND    <= '0';
                        CNT_RST_ROUND   <= '1';
                        
                        
                        IF(EN = '1') THEN
                            ABSORB          <= '1';
                            ENABLE_ROUND    <= '1';
                            RESET_IO        <= '0';
                            
                            -- TRANSITION -----
                            STATE           <= S_ABSORB_PERMUT;
                        ELSE
                            ABSORB          <= '0';
                            ENABLE_ROUND    <= '0';
                            RESET_IO        <= '1';
                            
                            -- TRANSITION -----
                            STATE       <= S_RESET;
                        END IF;
                    ------------------------------------------------------------------
                    
                    ------------------------------------------------------------------
                    WHEN S_ABSORB_PERMUT   =>
                        -- INTERALS ----------
                        RESET_IO        <= '0';

                        ABSORB          <= '0';
                        ENABLE_ROUND    <= '1';
                        
                        
                        -- COUNTER ------------
                        CNT_EN_ABS      <= '0';
                        CNT_RST_ABS     <= '0';
                        CNT_EN_ROUND    <= '1';
                        CNT_RST_ROUND   <= '0';
                        
                        -- TRANSITION ---------
                        IF(to_integer(unsigned(CNT_ROUND)) = (N_R-1)) THEN
                            STATE       <= S_RESET;
                        ELSE
                            STATE       <= S_ABSORB_PERMUT;
                        END IF;
                    ------------------------------------------------------------------
                    
                END CASE;
            END IF;
        END IF;
    END PROCESS;
    
    

END FSM;
