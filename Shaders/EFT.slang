#ifndef EFT
#define EFT

#include "Settings.slang"

//
// Error-Free Transformations (EFT) of two-operand operators
//

// returns (hi, lo) with hi+lo = a+b exactly
precise float2 twoSum(float a, float b)
{
    precise float s = a + b;                 // 1 op  (rounded sum)
    precise float bb = s - a;                // 2 op
    precise float aa = s - bb;               // 3 op
    precise float err = (a - aa) + (b - bb); // 4 & 5 ops
    return float2(s, err);                   // pair is exact
}

// Computes p = fl(a * b) and error e using FMA.
precise float2 twoProd(float a, float b)
{
    precise float p = a * b;
    precise float e = mad(a, b, -p);
    return float2(p, e);
}

// re-normalize so |lo| ≤ ½ ulp(hi)
float2 renorm(float2 x) 
{
    float2 t = twoSum(x.x, x.y);
    return float2(t.x, t.y); // hi = t.x, lo = t.y  (non-overlap)
}

// add two DS numbers, return DS
float2 dsAdd(float2 a, float2 b) 
{
    float2 s = twoSum(a.x, b.x); // add highs
    //float lo = float(double(a.y) + double(b.y) + double(s.y));  
    float lo = a.y + b.y + s.y; // collect low parts
    return renorm(float2(s.x, lo));
}

#endif // EFT
