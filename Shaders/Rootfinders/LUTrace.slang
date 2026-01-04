#ifndef LU_TRACE
#define LU_TRACE

#include "../Polynomial.slang"
#include "Rootfinders.slang"

// Configuration
#ifndef MAX_LU_ITERATIONS
#define MAX_LU_ITERATIONS 10000
#endif

#ifndef EARLY_OUT
#define EARLY_OUT 0
#endif

static const float ALPHA = 1.0; // relaxation parameter

static float3 DEBUG_COLOR = float3(0);

// Lower bound function L(t, curve)
float L_func(const int degree, float t, float c0, float cn, float m)
{
    return m + (c0 - m) * pow(1.0 - t, degree) + (cn - m) * pow(t, degree);
}

// Upper bound function U(t, curve)
float U_func(const int degree, float t, float c0, float cn, float M)
{
    return M - (M - c0) * pow(1.0 - t, degree) - (M - cn) * pow(t, degree);
}

// Find min (m) and max (M) of control points
void min_max_controlPoints(const Polynomial poly, out float m, out float M)
{
    m = poly[0];
    M = poly[0];

    for (int i = 1; i <= poly.N; i++)
    {
        m = min(m, poly[i]);
        M = max(M, poly[i]);
    }
}

// Find min (m) and max (M) of derivative control points
void min_max_derivativeControlPoints(const Polynomial poly, const int degree, out float m, out float M)
{
    m = poly[1] - poly[0];
    M = m;

    for (int i = 1; i < degree; i++)
    {
        m = min(m, poly[i + 1] - poly[i]);
        M = max(M, poly[i + 1] - poly[i]);
    }

    m *= degree;
    M *= degree;
}

// Use the lower and upper bounders to figure out what are the extrema of the lower and upper bounding functions
void get_lower_upper_extrema(const float c0, const float cn, const float m, const float M, const int degree, out float lower_extrema, out float upper_extrema)
{
    // Compute location and value of the extrema of the lower bound m + (c0 - m) * (1-t)^n + (cn - m) * t^n
    lower_extrema = min(c0, cn);
    float lower_min_t = (lower_extrema == c0) ? 0.0 : 1.0;
    if (m != c0)
    {
        float ratio = (cn - m) / (c0 - m);
        lower_min_t = 1.0 / (1.0 + pow(ratio, 1.0 / (degree)));
        lower_extrema = min(lower_extrema, L_func(degree, lower_min_t, c0, cn, m));
    }

    // Compute location and value of the extrema of the upper bound M - (M - c0) * (1-t)^n - (M - cn) * t^n
    upper_extrema = max(c0, cn);
    float upper_max_t = (upper_extrema == c0) ? 0.0 : 1.0;
    if (M != cn)
    {
        float ratio = (M - cn) / (M - c0);
        upper_max_t = 1.0 / ( 1.0 + pow(ratio, 1.0 / (degree) ) );
        upper_extrema = max(upper_extrema, U_func(degree, upper_max_t, c0, cn, M));
    }
}

// Calculates a Lipschitz bound of the input polynomial, using the extrema bounds of its
// derivative polynomial. The derivative is bounded using the proposed method. 
float min_max_derivativeLipschitz(const Polynomial poly, const int degree)
{
    float m, M;
    min_max_derivativeControlPoints(poly, degree, m, M);

    // First and last coefficients of the derivative
    float der_first = degree * (poly[1] - poly[0]);
    float der_last  = degree * (poly[degree] - poly[degree-1]);

    // Calculate the extrema of the lower bounding generalized paraboloids
    float lower_extrema = min(der_first, der_last);
    float upper_extrema = max(der_first, der_last);
    get_lower_upper_extrema(der_first, der_last, m, M, degree-1, lower_extrema, upper_extrema);

    return max(abs(lower_extrema), abs(upper_extrema));
}

// Use the lower and upper bounders to figure out what are the extrema of the function over [a, b]
float min_max_bound(const Polynomial poly, const int degree, float a, float b)
{
    float m, M;
    min_max_derivativeControlPoints(poly, degree, m, M);

    // First and last coefficients of the derivative
    float der_first = degree * (poly[1] - poly[0]);
    float der_last  = degree * (poly[degree] - poly[degree-1]);

    // Calculate the extrema of the lower bounding generalized paraboloids
    float lower_extrema = min(der_first, der_last);
    float upper_extrema = max(der_first, der_last);
    get_lower_upper_extrema(der_first, der_last, m, M, degree-1, lower_extrema, upper_extrema);

    return max(abs(lower_extrema), abs(upper_extrema));
}

struct StepResult
{
    float step;
    float f_val;
    float L;
};

// The Heuristic Lipschitz step function
StepResult LU_lipschitz_step(Polynomial poly, float L, float t)
{
    StepResult res;

    res.f_val = poly.at(t);

    res.step = (L == 0.0) ? 0.0 : abs(res.f_val) / L;

    return res;
}

// Root finder
float LUTrace(const Polynomial poly, float begin, float end, inout bool hit)
{
    // Early-out 1: check if all coefficients are of the same sign
#if EARLY_OUT >= 1
    float m, M;
    min_max_controlPoints(poly, m, M);
    if (m > errorTolerance || M < -errorTolerance)
    {
        DEBUG_COLOR = float3(0,1,0);
        hit = false;
        return end;
    }
#endif

    // Compute bounds on the derivative
    float L = min_max_derivativeLipschitz(poly, poly.N);

    // Early-out 2: check if the extrema of the lower bound crosses the zero level
#if EARLY_OUT >= 2
    float minF, maxF;
    get_lower_upper_extrema(poly[0], poly[poly.N], m, M, poly.N, minF, maxF);
    if (minF > errorTolerance || maxF < -errorTolerance)
    {
        DEBUG_COLOR = float3(1, 0, 0);
        hit = false;
        return end;
    }
#endif


    float t = begin;

    // Tracing loop with relaxation and step back
    for (int i = 0; i < MAX_LU_ITERATIONS && t < end; ++i)
    {
        // Calculate current state at t
        StepResult curr = LU_lipschitz_step(poly, L, t);

        // Check convergence
        if (abs(curr.f_val) < errorTolerance * L) // Approximate distance from the root
        {
            hit = true;
            return t;
        }

        float delta = ALPHA * curr.step;
        
        // Guess ahead
        StepResult guess = LU_lipschitz_step(poly, L, t + delta);

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
