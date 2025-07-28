----------------------------------------------------------------------------------
-- COPYRIGHT (c) 2018 ALL RIGHT RESERVED
--
-- COMPANY:					Ruhr-University Bochum, Chair for Security Engineering
-- AUTHOR:					Jan Richter-Brockmann
--
-- CREATE DATA:			    13/12/2018
-- LAST CHANGES:            13/12/2018
-- MODULE NAME:			    KECCAK_SETTINGS
--
-- REVISION:				1.00 - Contains all settings for the KECCAK core
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
--
-- Additional Comments:
--          _ _ _ _ _
--        /         /|
--    w /         /  |
--    /         /    |
--  /_ _ _ _ _/      |
--  |         |      / 
--  |         |    /
--  |         |  /
--  |_ _ _ _ _|/
--
-- STATE_WIDTH = {25,50,100,200,400,800,1600}
--
----------------------------------------------------------------------------------


LIBRARY IEEE;
    USE IEEE.STD_LOGIC_1164.ALL;
    USE IEEE.NUMERIC_STD.ALL;
    
    

PACKAGE keccak_settings IS 

    -- SETTINGS ------------------------------------------------------------------
    -- Settings KECCAK
    CONSTANT STATE_WIDTH        : integer := 800;                      -- Size of the state (unrolled matrix)
    CONSTANT RATE               : integer := 576;                      -- The rate is used to determine the number of random output bits
    CONSTANT N_R                : integer := 26;                       -- n_r = 12 + 2*log2(LANE_WIDTH) - How to calculate this in VHDL?
    CONSTANT D                  : integer := 576;                      -- Number of output bits
    
    -- Settings Seed
    CONSTANT SEED_LENGTH        : integer := 576;                      -- Number of bits of the seed
    
    
    
    -- CONSTANTS AND DEFINITIONS -------------------------------------------------
    -- This settings are calculated by the above ones
    CONSTANT LANE_WIDTH         : integer := STATE_WIDTH / 25;          -- LANE_WIDTH = w 
    CONSTANT ABSORBING_PHASES   : integer := 1;--CEIL(SEED_LENGTH,RATE);    -- Determines the required number of absorbing phases before providing any random output 
    CONSTANT SEED_LANES         : integer := RATE/LANE_WIDTH;           -- ceil(RATE/LANE_WIDTH) - has to be adapted if the rate is not a multiple of LANE_WIDTH

    -- Settings Counter
    CONSTANT CNT_LENGTH_ABSORB  : integer := 1;                         -- ceil(CNT_LENGTH_ABSORB = log_2(ABSORBING_PHASES)) 
    CONSTANT CNT_LENGTH_ROUND   : integer := 5;                         -- ceil(CNT_LENGTH_ROUND = log_2(N_R))

    -- define the keccak matrix
    SUBTYPE dim1 IS STD_LOGIC_VECTOR(LANE_WIDTH-1 DOWNTO 0);
    TYPE dim1_vecTOr IS ARRAY(natural RANGE <>) OF dim1;
    SUBTYPE dim2 IS dim1_vecTOr(4 DOWNTO 0);
    TYPE dim2_vecTOr IS ARRAY(natural RANGE <>) OF dim2;
    SUBTYPE keccak_m IS dim2_vecTOr(4 DOWNTO 0);
 
    -- define the index LUT for the roh step   
    TYPE indexlut IS ARRAY (0 TO 4, 0 TO 4) of integer RANGE 0 TO 63;
    CONSTANT rohINdex : INdexlut := ((0, 1, 62, 28, 27), (36, 44, 6, 55, 20), (3, 10, 43, 25, 39), (41, 45, 15, 21, 8), (18, 2, 61, 56, 14));

END PACKAGE;
