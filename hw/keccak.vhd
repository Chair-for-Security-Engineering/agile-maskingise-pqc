----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2018 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATA:			    13/12/2018
-- LAST CHANGES:            13/06/2019
-- MODULE NAME:			    KECCAK
--
-- REVISION:				1.10 - Modified to use it as PRNG
--
-- LICENCE: 				Please look at licence.txt
-- USAGE INFORMATION:	    Please look at readme.txt. If licence.txt or readme.txt
--							are missing or if you have questions regarding the code
--							please contact Tim G�neysu (tim.gueneysu@rub.de) and
--                          Jan Richter-Brockmann (jan.richter-brockmann@rub.de)
--
-- THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY 
-- KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
-- IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
-- PARTICULAR PURPOSE.
----------------------------------------------------------------------------------

LIBRARY IEEE;
    USE IEEE.STD_LOGIC_1164.ALL;
    USE IEEE.STD_LOGIC_UNSIGNED.ALL;
    USE IEEE.NUMERIC_STD.ALL;

LIBRARY work;
    USE work.keccak_settings.ALL;
    

ENTITY KECCAK IS
    PORT ( CLK          : IN  STD_LOGIC;
           RESET        : IN  STD_LOGIC;
           ENABLE       : IN  STD_LOGIC;
           -- SEED ---------------------
           M            : IN  STD_LOGIC_VECTOR (RATE-1 DOWNTO 0);
           -- PRNG ---------------------
           PRNG_OUT     : OUT STD_LOGIC_VECTOR (D-1 DOWNTO 0));
END KECCAK;



ARCHITECTURE Structural OF KECCAK IS



-- SIGNALS -----------------------------------------------------------------------
SIGNAL STATE_IN, STATE_IN_M, STATE_OUT      : keccak_m := (OTHERS => (OTHERS => (OTHERS => '0')));
SIGNAL STATE_OUT_REG                        : keccak_m;
SIGNAL ROUND_NUMBER                         : STD_LOGIC_VECTOR(4 DOWNTO 0) := (OTHERS => '0');
SIGNAL ROUND_NUMBER_IN                      : STD_LOGIC_VECTOR(4 DOWNTO 0) := (OTHERS => '0');
SIGNAL USE_M                                : STD_LOGIC := '1';

-- ABSORBING PHASE
SIGNAL ABSORB                               : STD_LOGIC;
SIGNAL M_PART                               : STD_LOGIC_VECTOR((RATE-1) DOWNTO 0);

-- SQUEEZING PHASE 
SIGNAL OUT_EN                               : STD_LOGIC;

-- COUNTER
SIGNAL CNT_EN_ROUND, CNT_RST_ROUND          : STD_LOGIC;
SIGNAL CNT_ROUND                            : STD_LOGIC_VECTOR((CNT_LENGTH_ROUND-1) DOWNTO 0); 
SIGNAL CNT_EN_ABS, CNT_RST_ABS              : STD_LOGIC;
SIGNAL CNT_ABSORB                           : STD_LOGIC_VECTOR((CNT_LENGTH_ABSORB-1) DOWNTO 0); 

SIGNAL RESET_IO                             : STD_LOGIC;
SIGNAL ENABLE_ROUND                         : STD_LOGIC;



-- STRUCTURAL --------------------------------------------------------------------
BEGIN

    -- I/O Register --------------------------------------------------------------
    keccak_ctr : PROCESS (clk, reset)
    BEGIN
        IF(RISING_EDGE(clk)) THEN 
            IF(RESET ='1') THEN
                STATE_OUT_REG <= (OTHERS => (OTHERS => (OTHERS => '0')));
            ELSE
                IF(ENABLE = '1') THEN
                    STATE_OUT_REG <= STATE_OUT;
                ELSE
                    STATE_OUT_REG <= STATE_OUT_REG;
                END IF;
            END IF;
        END IF;
    END PROCESS;
    ------------------------------------------------------------------------------
    
    
    -- ABSORBING PHASE: Add the seed to the current state ------------------------
    --M_PART <= M((to_integer(unsigned(CNT_ABSORB))+1)*RATE-1 DOWNTO to_integer(unsigned(CNT_ABSORB))*RATE) WHEN (to_integer(unsigned(CNT_ABSORB)) <= CNT_LENGTH_ABSORB) ELSE (OTHERS => '0');
    --M_PART <= M WHEN (TO_INTEGER(UNSIGNED(CNT_ABSORB)) < (ABSORBING_PHASES-1)) ELSE M(RATE-1 DOWNTO ABSORBING_PHASES*RATE-SEED_LENGTH) & "01" & '1' & (ABSORBING_PHASES*RATE-SEED_LENGTH-4 DOWNTO 1 => '0') & '1';
    M_PART <= M; -- NO PADDING USED HERE
    
    f001: FOR y IN 0 TO 4 GENERATE
        f002: FOR x IN 0 TO 4 GENERATE
            f003: FOR z IN 0 TO LANE_WIDTH-1 GENERATE
                i001: IF (y*5+x) < SEED_LANES GENERATE
                    STATE_IN_M(x)(y)(z) <= STATE_OUT_REG(x)(y)(z) XOR M_PART(RATE-1-(LANE_WIDTH*(y*5+x)+z));
                END GENERATE;
                i002: IF (y*5+x) >= SEED_LANES GENERATE
                    STATE_IN_M(x)(y)(z) <= STATE_OUT_REG(x)(y)(z);
                END GENERATE;
            END GENERATE;
        END GENERATE;
    END GENERATE;
    ------------------------------------------------------------------------------


    -- KECCAK ROUND FUNCTION -----------------------------------------------------
    -- decide wether the seed is used or not 
    STATE_IN <= STATE_IN_M WHEN (ABSORB = '1') ELSE STATE_OUT_REG;
    
    KECCAK_ROUND : ENTITY work.keccak_round
    PORT MAP (
        STATE_IN     => STATE_IN,
        STATE_OUT    => STATE_OUT,
        ROUND_NUMBER => CNT_ROUND
    );
    ------------------------------------------------------------------------------
    
    
    -- SQUEEZING PHASE: Return the random bits -----------------------------------
    o001 : FOR y IN 0 TO 4 GENERATE
        o002 : FOR x IN 0 TO 4 GENERATE
            o003 : FOR z IN 0 TO LANE_WIDTH-1 GENERATE
                o004 : IF (((x+y*5)*LANE_WIDTH+z) < D) GENERATE
                    PRNG_OUT(D-1-((x+y*5)*LANE_WIDTH+z)) <= STATE_OUT_REG(x)(y)(z);
                END GENERATE;
            END GENERATE;
        END GENERATE;
    END GENERATE;
    ------------------------------------------------------------------------------
    
    
    -- COUNTER -------------------------------------------------------------------
    COUNTER_ROUND : ENTITY work.KECCAK_COUNTER
    GENERIC MAP (
        SIZE            => CNT_LENGTH_ROUND,
        MAX_VALUE       => N_R-1)
    PORT MAP (
        CLK             => CLK,
        EN              => ENABLE,
        RST             => RESET,
        CNT_OUT         => CNT_ROUND
    );
    
    COUNTER_ABSORB : ENTITY work.KECCAK_COUNTER
    GENERIC MAP (
        SIZE            => CNT_LENGTH_ABSORB,
        MAX_VALUE       => ABSORBING_PHASES)
    PORT MAP (
        CLK             => CLK,
        EN              => CNT_EN_ABS,
        RST             => CNT_RST_ABS,
        CNT_OUT         => CNT_ABSORB
    );
    ------------------------------------------------------------------------------
    
    
    -- FSM -----------------------------------------------------------------------
    -- FSM : ENTITY work.KECCAK_CONTROLLER
    -- PORT MAP (
    --     CLK             => CLK,
    --     EN              => ENABLE,
    --     RESET           => RESET,
    --     -- CONTROL ---------------------
    --     ABSORB          => ABSORB,
    --     ENABLE_ROUND    => ENABLE_ROUND,
    --     RESET_IO        => RESET_IO,
    --     -- COUNTER ---------------------
    --     CNT_EN_ABS      => CNT_EN_ABS,
    --     CNT_RST_ABS     => CNT_RST_ABS,
    --     CNT_ABSORB      => CNT_ABSORB,
    --     CNT_EN_ROUND    => CNT_EN_ROUND,
    --     CNT_RST_ROUND   => CNT_RST_ROUND,
    --     CNT_ROUND       => CNT_ROUND
    -- );
    ------------------------------------------------------------------------------

END Structural;
