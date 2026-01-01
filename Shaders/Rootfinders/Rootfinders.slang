#ifndef ROOTFINDERS
#define ROOTFINDERS

#include "../Settings.slang"

#include "RayMarch.slang"
#include "YukselBracketed.slang"

cbuffer RootFinderCB
{
    float errorTolerance; // TODO populate from CPU side
};

// ------------------------------------------------------------------
// Unified rootfinder Interfaces
// ------------------------------------------------------------------

// Finds the first root of the given polynomial in the interval [begin, end]
float YukselBracketed(const Polynomial poly, float begin, float end, inout bool hit)
{
    // Call the rootfinder to get all roots
    float roots[POLYNOMIAL_DEGREE + 1];
    YukselBracketed(roots, poly, begin, end);

    // The roots are sorted, so return the first one that is valid
    for (int i = 0; i <= POLYNOMIAL_DEGREE; ++i)
    {
        if (roots[i] != NO_INTERSECTION)
        {
            hit = true;
            return roots[i];
        }
    }
    return begin;
}

#endif // ROOTFINDERS
