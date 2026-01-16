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

// Bounding function
#ifndef LU_TRACE_BOUND_TYPE
#define LU_TRACE_BOUND_TYPE LU_BOUND
#endif
#ifndef LU_BOUND
#define LU_BOUND 0
#endif
#ifndef CONTROL_POINT_BOUND
#define CONTROL_POINT_BOUND 1
#endif

static const float ALPHA = 1.6; // relaxation parameter

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
// for the derivative
void get_lower_upper_extrema(
    const float c0, const float cn,
    const float m, const float M,
    const int degree,
    out float lower_extrema, out float upper_extrema)
{
    // Compute location and value of the extrema of the lower bound m + (c0 - m) * (1-t)^n + (cn - m) * t^n
    lower_extrema = min(c0, cn);
    float lower_min_t = (lower_extrema == c0) ? 0.0 : 1.0;
    if (m != c0)
    {
        float ratio = (cn - m) / (c0 - m);
        lower_min_t = 1.0 / ( 1.0 + pow(ratio, 1.0 / degree) );
        lower_extrema = min(lower_extrema, L_func(degree, lower_min_t, c0, cn, m));
    }

    // Compute location and value of the extrema of the upper bound M - (M - c0) * (1-t)^n - (M - cn) * t^n
    upper_extrema = max(c0, cn);
    float upper_max_t = (upper_extrema == c0) ? 0.0 : 1.0;
    if (M != cn)
    {
        float ratio = (M - cn) / (M - c0);
        upper_max_t = 1.0 / ( 1.0 + pow(ratio, 1.0 / degree) );
        upper_extrema = max(upper_extrema, U_func(degree, upper_max_t, c0, cn, M));
    }
}

// Use the lower and upper bounders to figure out what are the extrema of the lower and upper bounding functions
// for the derivative
// specify the [a,b] interval to calculate for a range
void get_lower_upper_extrema(
    const float c0, const float cn,
    const float m, const float M,
    const int degree,
    float a, float b,
    out float lower_extrema, out float upper_extrema
    )
{
    // Compute location and value of the extrema of the lower bound m + (c0 - m) * (1-t)^n + (cn - m) * t^n
    lower_extrema = min(L_func(degree, a, c0, cn, m), L_func(degree, b, c0, cn, m));
    float lower_min_t = (lower_extrema == c0) ? 0.0 : 1.0;
    if (m != c0)
    {
        float ratio = (cn - m) / (c0 - m);
        lower_min_t = 1.0 / ( 1.0 + pow(ratio, 1.0 / degree) );
        clamp(lower_min_t, a, b);
        lower_extrema = min(lower_extrema, L_func(degree, lower_min_t, c0, cn, m));
    }

    // Compute location and value of the extrema of the upper bound M - (M - c0) * (1-t)^n - (M - cn) * t^n
    upper_extrema = max(U_func(degree, a, c0, cn, M), U_func(degree, b, c0, cn, M));
    float upper_max_t = (upper_extrema == c0) ? 0.0 : 1.0;
    if (M != cn)
    {
        float ratio = (M - cn) / (M - c0);
        upper_max_t = 1.0 / ( 1.0 + pow(ratio, 1.0 / degree) );
        clamp(upper_max_t, a, b);
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
    float lower_extrema, upper_extrema;
    get_lower_upper_extrema(der_first, der_last, m, M, degree-1, lower_extrema, upper_extrema);

    // Use Lipschitz-constant
    //return max(abs(lower_extrema), abs(upper_extrema));

    // Use the one-sided Lipschitz-constant
    float f_val = poly.at(0);
    return (f_val < 0) ? abs(upper_extrema) : abs(lower_extrema);
}

// Use the lower and upper bounders for the derivative to figure out what are the extrema of the function over [a, b]
float min_max_bound(const Polynomial poly, const int degree, float f_val, float a, float b)
{
    float m, M;
    min_max_derivativeControlPoints(poly, degree, m, M);

    // First and last coefficients of the derivative
    float der_first = degree * (poly[1] - poly[0]);
    float der_last  = degree * (poly[degree] - poly[degree-1]);

    // Calculate the extrema of the lower bounding generalized paraboloids
    float lower_extrema, upper_extrema;
    get_lower_upper_extrema(der_first, der_last, m, M, degree-1, a, b, lower_extrema, upper_extrema);

    // Use Lipschitz-constant
    return max(abs(lower_extrema), abs(upper_extrema));

    // Use the one-sided Lipschitz-constant
    //return (f_val < 0) ? abs(upper_extrema) : abs(lower_extrema);
}

// Clip the interval [0,1] to the region where the one-sided lower and upper bounds cross zero
// return false if no crossing occurs
bool clipInterval(
    const float c0, const float cn,
    const float m, const float M,
    const int degree,
    out float lower_extrema, out float upper_extrema)
{
    lower_extrema = 0;
    upper_extrema = 1;

    // Lower left
    if (m != c0)
    {
        float ratio = m / (m - c0);
        if (ratio > 0)
        {
            float t = 1 - pow(ratio, 1 / degree);
            lower_extrema = max(lower_extrema, t);
        }
        else return false;
    }
    // Upper left
    if (M != c0)
    {
        float ratio = M / (M - c0);
        if (ratio > 0)
        {
            float t = 1 - pow(ratio, 1 / degree);
            lower_extrema = max(lower_extrema, t);
        }
        else return false;
    }

    // Lower right
    if (m != cn)
    {
        float ratio = m / (m - cn);
        if (ratio > 0)
        {
            float t = pow(ratio, 1 / degree);
            upper_extrema = min(upper_extrema, t);
        }
        else return false;
    }
    // Upper right
    if (M != cn)
    {
        float ratio = M / (M - cn);
        if (ratio > 0)
        {
            float t = pow(ratio, 1 / degree);
            upper_extrema = min(upper_extrema, t);
        }
        else return false;
    }

    return true;
}

struct StepResult
{
    float step;
    float f_val;
};

// The Heuristic Lipschitz step function
StepResult LU_lipschitz_step(const Polynomial poly, float L, float t, float m, float M)
{
    StepResult res;

    res.f_val = poly.at(t);

    //L = min_max_bound(poly, poly.N, res.f_val, t, 1); // override Lipschitz-constat with value on [t, 1]
    res.step = (L == 0.0) ? 0.0 : abs(res.f_val) / L;

    /*
    if (res.f_val >= 0)
    {
        float ratio = m / (m - res.f_val);
        if (ratio > 0)
        {
            // t + (1 - t) * (1 - pow(ratio, 1 / poly.N));
            float root = 1 + (t - 1) * pow(ratio, 1 / poly.N);
            res.step = max(res.step, root - t);
        }
        else
        {
            res.step = 1 - t;
        }
    }
    else
    {
        float ratio = M / (M - res.f_val);
        if (ratio > 0)
        {
            float root = 1 + (t - 1) * pow(ratio, 1 / poly.N);
            res.step = max(res.step, root - t);
        }
        else
        {
            res.step = t;
        }
    }
    //*/

    return res;
}

// Root finder
float LUTrace(const Polynomial poly, float begin, float end, inout bool hit)
{
    float m, M;
    min_max_controlPoints(poly, m, M);

    // Early-out 1: check if all coefficients are of the same sign
#if EARLY_OUT >= 1
    if (m > errorTolerance || M < -errorTolerance)
    {
        DEBUG_COLOR = float3(0,1,0);
        hit = false;
        return end;
    }
#endif

    // Compute bounds on the derivative
#if LU_TRACE_BOUND_TYPE == LU_BOUND
    float L = min_max_derivativeLipschitz(poly, poly.N);
#elif LU_TRACE_BOUND_TYPE == CONTROL_POINT_BOUND
    float minP, MaxP;
    min_max_derivativeControlPoints(poly, poly.N, minP, MaxP);
    float L = max(abs(minP), abs(MaxP));
#endif

    // Early-out 2: check if the extrema of the lower bound crosses the zero level
#if EARLY_OUT >= 2
    // Use two-sided extrema on the derivative bounds
    float minF, maxF;
    get_lower_upper_extrema(poly[0], poly[poly.N], m, M, poly.N, minF, maxF);
    if (minF > errorTolerance || maxF < -errorTolerance)
    {
        DEBUG_COLOR = float3(1, 0, 0);
        hit = false;
        return end;
    }

    // Use one-sided extrema on the function bounds
    bool intersectionPossible = clipInterval(poly[0], poly[poly.N], m, M, poly.N, minF, maxF);
    if (!intersectionPossible)
    {
        DEBUG_COLOR = float3(0,0,1);
        hit = false;
        return end;
    }

    // move begin to L/U intersect
    begin = max(begin, minF);
    end = min(end, maxF);
#endif

    float t = begin;
    float prev_step = 0;
    float delta = 0;

    // Keinert’s relaxed trace algorithm
    [[loop]]
    for (int i = 0; i < MAX_LU_ITERATIONS && t < end; ++i)
    {
        // Calculate current state at t
        float guess = t + delta;
        StepResult curr = LU_lipschitz_step(poly, L, guess, m, M);

        // Check convergence
        if (abs(curr.f_val) < errorTolerance * L) // Approximate distance from the root
        {
            hit = true;
            return guess;
        }

        // stepback needed
        if (delta > prev_step + curr.step) {
            delta = prev_step;
        } else { // apply step
            t = guess;
            delta = ALPHA * curr.step;
            prev_step = curr.step;
        }
    }

    return end;
}

#endif // LU_TRACE
