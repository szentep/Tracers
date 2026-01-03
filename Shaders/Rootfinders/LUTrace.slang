#ifndef LU_TRACE
#define LU_TRACE

#include "../Polynomial.slang"
#include "Rootfinders.slang"

// Configuration
static const int MAX_LU_ITERATIONS = 10000;
static const float ALPHA = 1.0; // relaxation parameter


// Lower bound function L(t, curve)
float L_func(Polynomial der, float t, float m)
{
    float c0 = der.coeffs[0];
    float cn = der.coeffs[POLYNOMIAL_DEGREE - 1];
    return m + (c0 - m) * pow(1.0 - t, POLYNOMIAL_DEGREE - 1) + (cn - m) * pow(t, POLYNOMIAL_DEGREE - 1);
}

// Upper bound function U(t, curve)
float U_func(Polynomial der, float t, float M)
{
    float c0 = der.coeffs[0];
    float cn = der.coeffs[POLYNOMIAL_DEGREE - 1];
    return M + (c0 - M) * pow(1.0 - t, POLYNOMIAL_DEGREE - 1) + (cn - M) * pow(t, POLYNOMIAL_DEGREE - 1);
}

// Calculates min and max Lipschitz constants
void min_max_Lipschitz(Polynomial der, out float min_L, out float max_L)
{
    // Find min (m) and max (M) of derivative control points
    float m = der.coeffs[0];
    float M = der.coeffs[0];

    for (int i = 1; i < POLYNOMIAL_DEGREE; i++) // degree of derivative is POLYNOMIAL_DEGREE - 1
    {
        m = min(m, der.coeffs[i]);
        M = max(M, der.coeffs[i]);
    }

    float der0 = der.coeffs[0];
    float dern = der.coeffs[POLYNOMIAL_DEGREE - 1]; // last coeff of derivative

    // Calculate min_t
    float min_t = 0.0;
    if (m != der0)
    {
        // TODO avoid cancellation problems
        float ratio = (dern - m) / (der0 - m);
        min_t = 1.0 / (1.0 + pow(ratio, 1./(POLYNOMIAL_DEGREE - 2.)));
    }

    // Calculate max_t
    float max_t = 0.0;
    if (M != der0)
    {
        // TODO avoid cancellation problems
        float ratio = (dern - M) / (der0 - M);
        max_t = 1.0 / (1.0 + pow(ratio, 1./(POLYNOMIAL_DEGREE - 2.)));
    }

    // Final bounds
    float L_at_t = L_func(der, min_t, m);
    min_L = min(L_at_t, min(der0, dern));

    float U_at_t = U_func(der, max_t, M);
    max_L = max(U_at_t, max(der0, dern));
}

struct StepResult
{
    float step;
    float f_val;
    float L;
};

// The Heuristic Lipschitz step function
StepResult LU_lipschitz_step(Polynomial poly, float min_L, float max_L, float t)
{
    StepResult res;

    res.f_val = poly.at(t);

    res.L = (res.f_val < 0.0) ? max_L : min_L;

    res.step = (res.L == 0.0) ? 0.0 : abs(res.f_val / res.L);

    return res;
}

// Root finder
float LUTrace(const Polynomial poly, float begin, float end, inout bool hit)
{
    Polynomial der = poly.derivativePolynomial();
    float min_L, max_L;
    min_max_Lipschitz(der, min_L, max_L);

    float t = begin;

    // Tracing loop with relaxation and step back
    for (int i = 0; i < MAX_LU_ITERATIONS && t < end; ++i)
    {
        // Calculate current state at t
        StepResult curr = LU_lipschitz_step(poly, min_L, max_L, t);

        // Check convergence
        if (abs(curr.f_val) < errorTolerance * abs(curr.L)) // Approximate distance from the root
        {
            hit = true;
            return t;
        }

        float delta = ALPHA * curr.step;
        
        // Guess ahead
        StepResult guess = LU_lipschitz_step(poly, min_L, max_L, t + delta);

        // Check if guess landed on root
        if (abs(guess.f_val) < errorTolerance * abs(guess.L)) // Approximate distance from the root 
        {
            hit = true;
            return t + delta;
        }

        // Do step back if we overshot
        if ((t + curr.step) < (t + delta - guess.step))
        {
            delta = curr.step;
        }
        else
        {
            delta = delta + guess.step;
        }

        t += delta;
    }

    hit = false;
    return end;
}

#endif // LU_TRACE
