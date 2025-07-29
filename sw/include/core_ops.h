#ifndef CORE_OPS_H
#define CORE_OPS_H

#include <stddef.h>
#include <stdint.h>

#include "gadgets.h"
#include "masked.h"
#include "randombytes.h"
#ifdef USE_MASKED_ISA

volatile int globaldummy;
static inline void b_mask(uint32_t *a, size_t a_stride, uint32_t b) {
    asm volatile ("mask.b.mask (a1,a0), %[input]\n"
    "sw a0, (%[loca0])\n"
    "sw %[input], (%[dummy])"
    "sw a1, (%[loca1])\n"
    :
    : [input] "r" (b), [loca0] "r" (a), [loca1] "r" (a+a_stride), [dummy] "r" (&globaldummy)
    : "a1", "a0", "memory");
    
}
static inline void b_unmask(uint32_t *z, const uint32_t *a, size_t a_stride) {
    asm volatile (
    "lw a0, (%[loca0])\n"
    "lw a2, (%[dummy])\n"
    "lw a1, (%[loca1])\n"
    "mask.b.unmask a2,(a1,a0)\n"
    "sw a2, (%[res])\n"
    : 
    : [loca0] "r" (a), [loca1] "r" (a+a_stride), [res] "r" (z), [dummy] "r" (&globaldummy)
    : "a2", "a1", "a0", "memory");
    
}
static inline void b_not(uint32_t *z, size_t z_stride, const uint32_t *a,
                  size_t a_stride) {
    z[0] = ~a[0];
    z[z_stride] = a[a_stride];
}
static inline void b_and(uint32_t *z, size_t z_stride, const uint32_t *a,
                  size_t a_stride, const uint32_t *b, size_t b_stride) {
    
    asm volatile (
    "xor a5, t0, t1\n"
    "lw a0, (%[loca0])\n"
    "lw a2, (%[locb0])\n"
    "lw a1, (%[loca1])\n"
    "lw a3, (%[locb1])\n"
    "mask.b.and (a5,a4),(a3,a2),(a1,a0)\n"
    "sw a4, (%[res0])\n"
    "sw a0, (%[dummy])\n"
    "sw a5, (%[res1])\n"
    : 
    : [loca0] "r" (a), [loca1] "r" (a+a_stride), [locb0] "r" (b), [locb1] "r" (b+b_stride), [res0] "r" (z), [res1] "r" (z+z_stride), [dummy] "r" (&globaldummy)
    : "a5", "a4", "a3", "a2", "a1", "a0", "memory");
    
}
static inline void b_or(uint32_t *z, size_t z_stride, const uint32_t *a,
                 size_t a_stride, const uint32_t *b, size_t b_stride) {

    asm volatile (
    "lw a0, (%[loca0])\n"
    "lw a2, (%[locb0])\n"
    "lw a1, (%[loca1])\n"
    "lw a3, (%[locb1])\n"
    "mask.b.ior (a5,a4),(a3,a2),(a1,a0)\n"
    "sw a4, (%[res0])\n"
    "sw a0, (%[dummy])\n"
    "sw a5, (%[res1])\n"
   : 
   : [loca0] "r" (a), [loca1] "r" (a+a_stride), [locb0] "r" (b), [locb1] "r" (b+b_stride), [res0] "r" (z), [res1] "r" (z+z_stride), [dummy] "r" (&globaldummy)
   : "a5", "a4", "a3", "a2", "a1", "a0", "memory");

}
static inline void b_xor(uint32_t *z, size_t z_stride, const uint32_t *a,
                  size_t a_stride, const uint32_t *b, size_t b_stride) {
    asm volatile (
    "lw a0, (%[loca0])\n"
    "lw a2, (%[locb0])\n"
    "lw a1, (%[loca1])\n"
    "lw a3, (%[locb1])\n"
    "mask.b.xor (a5,a4),(a3,a2),(a1,a0)\n"
    "sw a4, (%[res0])\n"
    "sw a0, (%[dummy])\n"
    "sw a5, (%[res1])\n"
   : 
   : [loca0] "r" (a), [loca1] "r" (a+a_stride), [locb0] "r" (b), [locb1] "r" (b+b_stride), [res0] "r" (z), [res1] "r" (z+z_stride), [dummy] "r" (&globaldummy)
   : "a5", "a4", "a3", "a2", "a1", "a0", "memory");        
}
static inline void b_slli(uint32_t *z, size_t z_stride, const uint32_t *a,
                   size_t a_stride, size_t shamt) {
    size_t i;
    for (i = 0; i < NSHARES; i++) {
        z[i * z_stride] = a[i * a_stride] << shamt;
    }              
}
static inline void b_srli(uint32_t *z, size_t z_stride, const uint32_t *a,
                   size_t a_stride, size_t shamt) {
    size_t i;
    for (i = 0; i < NSHARES; i++) {
        z[i * z_stride] = a[i * a_stride] >> shamt;
    }
}

static inline void b_sll1(uint32_t *z, size_t z_stride, const uint32_t *a,
                   size_t a_stride) {
    asm volatile (
    "lw a0, (%[loca0])\n"
    "lw a1, (%[dummy])\n"
    "lw a1, (%[loca1])\n"
    "mask.b.slli (a3,a2),(a1,a0),1\n"
    "sw a2, (%[res0])\n"
    "sw a0, (%[dummy])\n"
    "sw a3, (%[res1])\n"
    :
    : [loca0] "r" (a), [loca1] "r" (a+a_stride), [res0] "r" (z), [res1] "r" (z+z_stride), [dummy] "r" (&globaldummy)
    : "a3", "a2", "a1", "a0", "memory");
     
}

static inline void b_srl1(uint32_t *z, size_t z_stride, const uint32_t *a,
                   size_t a_stride) {
    asm volatile (
    "lw a0, (%[loca0])\n"
    "lw a1, (%[dummy])\n"
    "lw a1, (%[loca1])\n"
    "mask.b.srli (a3,a2),(a1,a0),1\n"
    "sw a2, (%[res0])\n"
    "sw a0, (%[dummy])\n"
    "sw a3, (%[res1])\n"
    :
    : [loca0] "r" (a), [loca1] "r" (a+a_stride), [res0] "r" (z), [res1] "r" (z+z_stride), [dummy] "r" (&globaldummy)
    : "a3", "a2", "a1", "a0", "memory");
    
}

static inline void b_add(uint32_t *z, size_t stride_z, const uint32_t *a,
                   size_t stride_a, const uint32_t *b, size_t stride_b) {
    asm volatile (
    "lw a0, (%[loca0])\n"
    "lw a2, (%[locb0])\n"
    "lw a1, (%[loca1])\n"
    "lw a3, (%[locb1])\n"
    "mask.b.add (a5,a4),(a3,a2),(a1,a0)\n"
    "sw a4, (%[res0])\n"
    "sw a0, (%[dummy])\n"
    "sw a5, (%[res1])\n"
   : 
   : [loca0] "r" (a), [loca1] "r" (a+stride_a), [locb0] "r" (b), [locb1] "r" (b+stride_b), [res0] "r" (z), [res1] "r" (z+stride_z), [dummy] "r" (&globaldummy)
   : "a5", "a4", "a3", "a2", "a1", "a0", "memory"); 
   
}
static inline void b_sub(uint32_t *z, size_t stride_z, const uint32_t *a,
                   size_t stride_a, const uint32_t *b, size_t stride_b) {
    asm volatile (
    "lw a0, (%[loca0])\n"
    "lw a2, (%[locb0])\n"
    "lw a1, (%[loca1])\n"
    "lw a3, (%[locb1])\n"
    "mask.b.sub (a5,a4),(a1,a0),(a3,a2)\n"
    "sw a4, (%[res0])\n"
    "sw a0, (%[dummy])\n"
    "sw a5, (%[res1])\n"
   : 
   : [loca0] "r" (a), [loca1] "r" (a+stride_a), [locb0] "r" (b), [locb1] "r" (b+stride_b), [res0] "r" (z), [res1] "r" (z+stride_z), [dummy] "r" (&globaldummy)
   : "a5", "a4", "a3", "a2", "a1", "a0", "memory");
   
}

#else  // DONT USE_MASKED_ISA

static inline void b_mask(uint32_t *a, size_t a_stride, uint32_t b) {
    size_t i;
    a[0] = b;
    for (i = 1; i < NSHARES; i++) {
        uint32_t r = randomint();
        a[i * a_stride] = r;
        a[0] ^= r;
    }
}

static inline void b_unmask(uint32_t *z, const uint32_t *a, size_t a_stride) {
    size_t i;

    *z = a[0 * a_stride];
    for (i = 1; i < NSHARES; i++) {
        *z ^= a[i * a_stride];
    }
}

static inline void b_not(uint32_t *z, size_t z_stride, const uint32_t *a,
                  size_t a_stride) {
    
    volatile uint32_t dummy = randomint();
    volatile uint32_t* dummy_ptr = &dummy;
    volatile uint32_t tmp0;
    volatile uint32_t tmp1;
    tmp0 = *dummy_ptr;
    tmp0 = ~a[0];
    z[0] = tmp0;
    if (z != a) // this will be left out due to inline
    {
        size_t i;
        for (i = 1; i < NSHARES; i++) {
            z[i * z_stride] = a[i * a_stride];
        }
    }
}

static inline void b_and(uint32_t *z, size_t z_stride, const uint32_t *a,
                  size_t a_stride, const uint32_t *b, size_t b_stride) {
    masked_and(NSHARES, z, z_stride, a, a_stride, b, b_stride);
}

static inline void b_or(uint32_t *z, size_t z_stride, const uint32_t *a,
                 size_t a_stride, const uint32_t *b, size_t b_stride) {
    masked_or(NSHARES, z, z_stride, a, a_stride, b, b_stride);
}

static inline void b_xor(uint32_t *z, size_t z_stride, const uint32_t *a,
                  size_t a_stride, const uint32_t *b, size_t b_stride) {
    masked_xor(NSHARES, z, z_stride, a, a_stride, b, b_stride);
}

static inline void b_slli(uint32_t *z, size_t z_stride, const uint32_t *a,
                   size_t a_stride, size_t shamt) {
    size_t i;
    for (i = 0; i < NSHARES; i++) {
        z[i * z_stride] = a[i * a_stride] << shamt;
    }
}

static inline void b_srli(uint32_t *z, size_t z_stride, const uint32_t *a,
                        size_t a_stride, size_t shamt) {
    size_t i;
    for (i = 0; i < NSHARES; i++) {
        z[i * z_stride] = a[i * a_stride]>> shamt;
    }
}

static inline void b_sll1(uint32_t *z, size_t z_stride, const uint32_t *a,
                   size_t a_stride) {
    size_t i;
    for (i = 0; i < NSHARES; i++) {
        z[i * z_stride] = a[i * a_stride] << 1;
    }
}

static inline void b_srl1(uint32_t *z, size_t z_stride, const uint32_t *a,
                   size_t a_stride) {
    size_t i;
    for (i = 0; i < NSHARES; i++) {
        z[i * z_stride] = a[i * a_stride] >> 1;
    }
}

static inline void b_add(uint32_t *z, size_t stride_z, const uint32_t *a,
                   size_t stride_a, const uint32_t *b, size_t stride_b) {
  add(z, stride_z, a, stride_a, b, stride_b, 32);
}

// UNSAFE, only for functional testing!
static inline void b_sub(uint32_t *z, size_t stride_z, const uint32_t *a,
                   size_t stride_a, const uint32_t *b, size_t stride_b) {
    uint32_t A,B;
    b_unmask(&A, a, stride_a);
    b_unmask(&B, b, stride_b);
    b_mask(z, stride_z, A-B);
}
#endif // USE_MASKED_ISA


// Our instruction extension:
static inline void b_cmov(uint32_t *z, size_t z_stride, const uint32_t *a,
                   size_t a_stride, const uint32_t *cond, size_t cond_stride) {
    // expects cond to be one bit
#ifdef USE_MASKED_EXT
    asm volatile (
    "lw a5, (%[cond1])\n"
    "lw a1, (%[new1])\n"
    "lw a3, (%[old1])\n"
    "lw a4, (%[cond0])\n"
    "lw a0, (%[new0])\n"
    "lw a2, (%[old0])\n"
    "mask.b.cmov (a3,a2),(a1,a0),(a5,a4)\n"
    "sw a2, (%[res0])\n"
    "sw a0, (%[dummy])\n"
    "sw a3, (%[res1])\n"
    : 
    : [cond0] "r" (cond), [cond1] "r" (cond+cond_stride), [new0] "r" (a), [new1] "r" (a+a_stride), [old0] "r" (z), [old1] "r" (z+z_stride), [res0] "r" (z), [res1] "r" (z+z_stride), [dummy] "r" (&globaldummy)
    : "a5", "a4", "a3", "a2", "a1", "a0", "memory");
#elif defined USE_MASKED_ISA
    uint32_t cond_mask[NSHARES];
    uint32_t xor [NSHARES];

    for (int s = 0; s < NSHARES; s++) {
        // expand from 1 bit to registerwidth:
        cond_mask[s] = ~((cond[s * cond_stride] & 1) - 1);
    }
    b_xor(xor, 1, z, z_stride, a, a_stride);
    b_and(xor, 1, xor, 1, cond_mask, 1);
    b_xor(z, z_stride, z, z_stride, xor, 1);    
#else
    masked_sel(cond, cond_stride, z, z_stride, a, a_stride);
#endif
}

// returns 1 if b > a
static inline void b_cmpg(uint32_t *z, size_t stride_z, const uint32_t *a,
                   size_t stride_a, const uint32_t *b, size_t stride_b) {
#ifdef USE_MASKED_EXT
    asm volatile (
    "lw a0, (%[in0])\n"
    "lw a2, (%[in2])\n"
    "lw a1, (%[in1])\n"
    "lw a3, (%[in3])\n"
    "mask.b.cmpgt (a5,a4),(a3,a2),(a1,a0)\n"
    "sw a4, (%[res0])\n"
    "sw a0, (%[dummy])\n"
    "sw a5, (%[res1])\n"
    : 
    : [in0] "r" (b), [in1] "r" (b+stride_b), [in2] "r" (a), [in3] "r" (a+stride_a), [res0] "r" (z), [res1] "r" (z+stride_z), [dummy] "r" (&globaldummy)
    :  "a5", "a4", "a3", "a2", "a1", "a0", "memory");
#elif defined USE_MASKED_ISA
    b_sub(z, stride_z, a, stride_a, b, stride_b);
    b_srli(z, stride_z, z, stride_z, 31);
#else
    cmpg(z, stride_z, a, stride_a, b, stride_b, 32);
#endif
}

static inline void b_cmpeq(uint32_t *z, size_t stride_z, const uint32_t *a,
                    size_t stride_a, const uint32_t *b, size_t stride_b) {
#ifdef USE_MASKED_EXT
    asm volatile (
    "lw a0, (%[in0])\n"
    "lw a2, (%[in2])\n"
    "lw a1, (%[in1])\n"
    "lw a3, (%[in3])\n"
    "mask.b.cmpeq (a5,a4),(a3,a2),(a1,a0)\n"
    "sw a4, (%[res0])\n"
    "sw a0, (%[dummy])\n"
    "sw a5, (%[res1])\n"
    :
    : [in0] "r" (b), [in1] "r" (b+stride_b), [in2] "r" (a), [in3] "r" (a+stride_a), [res0] "r" (z), [res1] "r" (z+stride_z), [dummy] "r" (&globaldummy)
    : "a5", "a4", "a3", "a2", "a1", "a0", "memory");
#elif defined USE_MASKED_ISA
    // for the not extended masked ISA, we can compute the cmpeq
    // more efficiently with subtractions:
    uint32_t tmp1[NSHARES];
    uint32_t tmp2[NSHARES];
    b_sub(tmp1, 1, a, stride_a, b, stride_b);
    b_srli(tmp1, 1, tmp1, 1, 31);
    b_sub(tmp2, 1, b, stride_b, a, stride_a);
    b_srli(tmp2, 1, tmp2, 1, 31);
    b_or(tmp1, 1, tmp1, 1, tmp2, 1);
    b_not(tmp1, 1, tmp1, 1);
    b_mask(tmp2, 1, 1);
    b_and(z, stride_z, tmp1, 1, tmp2, 1);
#else
    masked_eq(z, stride_z, a, stride_a, b, stride_b, 32);
#endif 
}

#endif // CORE_OPS_H

