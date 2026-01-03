#ifndef RAY_MARCH
#define RAY_MARCH

#include "../Polynomial.slang"
#include "Rootfinders.slang"


// Refines the hit location using the Bisection Method
float refinePolynomialIntersection(Polynomial p, float t, float fMin, float lastStep)
{
    float tMin = t - lastStep;
    float tMax = t;

    [[unroll]]
    for (int i = 0; i < BINARY_SEARCH_ITERATIONS; i++)
    {
        float tMid = (tMin + tMax) * 0.5;
        float f_val = p.at(tMid);

        if (f_val * fMin > 0.0) tMin = tMid;
        else tMax = tMid;
    }
    return tMax;
}

// Searches the smallest root of a polynomial within a given interval.
// \param poly Coefficients of the polynomial for which a root should be found.
//        Coefficient poly[i] is multiplied by x^i.
// \param begin The beginning of the search interval
// \param end The end of search interval.
// \return the root and set hit to true if root was found, false if no root exists
float rayMarch(const Polynomial poly, float begin, float end, inout bool hit)
{
    float t = begin;
    float stepSize = (end - begin) / float(MAX_RAYMARCHING_STEPS);
    float f_val = poly.at(t);
    float prev_f = 0.0;

    for (int i = 0; i < MAX_RAYMARCHING_STEPS; i++)
    {
        t += stepSize;
        float f_val = poly.at(t);

        if (prev_f * f_val < 0.0)
        {
            hit = true;
            break;
        }

        prev_f = f_val;
    }

    // Refine the root if we hit
    if (hit)
    {
        t = refinePolynomialIntersection(poly, t, prev_f, stepSize);
    }

    return t;
}

#endif // RAY_MARCH
