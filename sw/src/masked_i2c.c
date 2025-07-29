#include <stdint.h>
#include <stddef.h>
#include "core_ops.h"
#include "gadgets.h"
#include "masked_fwsampling.h"

// expects non bitsliced inputs
void coeff_to_regular(uint32_t poly[NSHARES][N_PADDED/32], uint32_t index[NSHARES][W_PADDED]) {
  size_t i,j;
  uint32_t cntmsk[NSHARES], cmpres[NSHARES], one[NSHARES], shifted_one[NSHARES], current_or_one[NSHARES];
  b_mask(one, 1, 1);
  for (i = 0; i < N_PADDED/32; i++) // init to zero
  {
    b_mask(&poly[0][i], N_PADDED/32, 0);
  }

  for (i = 0; i < N; i++)
  {
    if ((i%32) == 0) {
      copy_sharing(NSHARES, shifted_one, 1, one, 1);
    }
    b_or(current_or_one, 1, &poly[0][i/32], N_PADDED/32, shifted_one, 1);
    b_mask(cntmsk, 1, i);
    // Potential location for inline ASM for further improvement
    for (j = 0; j < W; j++)
    {
      b_cmpeq(cmpres, 1, cntmsk, 1, &index[0][j], W_PADDED);
      b_cmov(&poly[0][i/32], N_PADDED/32, current_or_one, 1, cmpres, 1);
    }
    if ((i%32) != 31 && i < N-1) {
      b_sll1(shifted_one, 1, shifted_one, 1);
    }
  }
}

// expects non bitsliced inputs
void bs_coeff_to_regular(uint32_t poly[NSHARES][N_PADDED/32], uint32_t index[NSHARES][W_PADDED]) 
{
  uint32_t i_index[NSHARES][W*32], p_index[NSHARES][32] = {0};
  uint32_t res[NSHARES]; // result of comparison
  size_t i,j,s;

  // transpose masked indices 32 times repeatedly
  for (s = 0; s < NSHARES; s++) 
  {
    for (i = 0; i < W; i++) 
    {
      for (j = 0; j < 32; j++)
      {
        i_index[s][i*32 + j] = index[s][i];
      }
      transpose32(&i_index[s][i*32]);
    }
  }


  // init poly to zero
#if defined(USE_MASKED_ISA) || defined(USE_MASKED_ISE)
  for (i = 0; i < N_PADDED/32; i++)
  {
    b_mask(&poly[0][i], N_PADDED/32, 0);
  }
#else
  for (s = 0; s < NSHARES; s++)
  {
    for (i = 0; i < N_PADDED/32; i++)
    {
      poly[s][i] = 0;
    }
  }
#endif


  for (i = 0; i < N; i += 32) // iterate over whole polynomial
  {
    for (j = i; j < i+32; j++) // generate bitsliced indices
    { 
      p_index[0][j-i] = j;
    }
    transpose32(p_index[0]);
#if defined(USE_MASKED_ISA) || defined(USE_MASKED_ISE)
    for (j = 0; j < 32; j++) // masked instructions require already masked input
    {
      b_mask(&p_index[0][j], 32, p_index[0][j]);
    }
#endif
    
    for(j = 0; j < W; j++) // iterate over all nonzero indices
    {
      // index of coefficient equal to the current nonzero coefficient?
      masked_bs_eq(res, 1, p_index[0], 32, &i_index[0][j*32], W*32, LOG_N);
      // if yes, set coefficient in poly to 1
      masked_bs_sel(res, 1, &poly[0][i/32], N_PADDED/32, res, 1, 1);
    }
  }
}

