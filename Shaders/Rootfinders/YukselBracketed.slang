// Based on https://github.com/valasekg/poly-rootfinder/blob/main/src/YukselBracketed.hlsl

#ifndef YUKSEL_BRACKETED
#define YUKSEL_BRACKETED

#include "../Polynomial.slang"
#include "Rootfinders.slang"
#include "../Surfaces.slang"

// When there are fewer intersections/roots than theoretically possible, some
// array entries are set to this value
#define NO_INTERSECTION 3.4e38

// Searches a single root of a polynomial within a given interval.
// \param out_root The location of the found root.
// \param out_end_value The value of the given polynomial at end.
// \param poly Coefficients of the polynomial for which a root should be found.
//        Coefficient poly[i] is multiplied by x^i.
// \param begin The beginning of an interval where the polynomial is monotonic.
// \param end The end of said interval.
// \param begin_value The value of the given polynomial at begin.
// \param error_tolerance The error tolerance for the returned root location.
//        Typically the error will be much lower but in theory it can be
//        bigger.
// \return true if a root was found, false if no root exists.
bool newton_bisection(inout float out_root, 
                      inout float out_end_value,
                      Polynomial poly, 
                      float begin, 
                      float end,
                      float begin_value)
{
    static const int MAX_ITERATIONS = 32;

	if (begin == end)
	{
		out_end_value = begin_value;
		return false;
	}
    // Evaluate the polynomial at the end of the interval
	out_end_value = poly.at(end);
    // If the values at both ends have the same non-zero sign, there is no root
	if (begin_value * out_end_value > 0.0)
		return false;
    // Otherwise, we find the root iteratively using Newton bisection (with
    // bounded iteration count)
	float current = 0.5 * (begin + end);
    [[loop]]
    for (int i = 0; i != MAX_ITERATIONS; ++i)
	{
        // Evaluate the polynomial and its derivative
        float derivative;
        float value = poly.valueAndDerivativeAt(current, derivative);

        // Shorten the interval
		bool right = begin_value * value > 0.0;
		begin = right ? current : begin;
		end = right ? end : current;
        // Apply Newton's method
		float guess = current - value / derivative;
        // Pick a guess
		float middle = 0.5 * (begin + end);
		float next = (begin <= guess && guess <= end) ? guess : middle;
        // Move along or terminate
        bool done = abs(next - current) < errorTolerance;
		current = next;
		if (done)
			break;
	}
	out_root = current;
	return true;
}

// Searches a single root of a polynomial within a given interval.
// uses the surface function to evaluate the polynomial
// \param out_root The location of the found root.
// \param out_end_value The value of the given polynomial at end.
// \param poly Coefficients of the polynomial for which a root should be found.
//        Coefficient poly[i] is multiplied by x^i.
// \param begin The beginning of an interval where the polynomial is monotonic.
// \param end The end of said interval.
// \param begin_value The value of the given polynomial at begin.
// \param error_tolerance The error tolerance for the returned root location.
//        Typically the error will be much lower but in theory it can be
//        bigger.
// \return true if a root was found, false if no root exists.
bool newton_bisection_with_surface(
    inout float out_root, 
    inout float out_end_value,
    Polynomial poly, 
    float begin, 
    float end,
    float begin_value)
{
    static const int MAX_ITERATIONS = 32;

    if (begin == end)
    {
        out_end_value = begin_value;
        return false;
    }
    // Evaluate the polynomial at the end of the interval
    out_end_value = poly.at(end);
    // If the values at both ends have the same non-zero sign, there is no root
    if (begin_value * out_end_value > 0.0)
        return false;
    // Otherwise, we find the root iteratively using Newton bisection (with
    // bounded iteration count)
    float current = 0.5 * (begin + end);
    [[loop]]
    for (int i = 0; i != MAX_ITERATIONS; ++i)
    {
        // Evaluate the polynomial and its derivative
        float derivative;
        float value = poly.valueAndDerivativeAt(current, derivative);
        // Replace function value with surface function evaluation
        value = SURFACE_FUNCTION(rootfinderRay.atNormalized(current));

        // Shorten the interval
        bool right = begin_value * value > 0.0;
        begin = right ? current : begin;
        end = right ? end : current;
        // Apply Newton's method
        float guess = current - value / derivative;
        // Pick a guess
        float middle = 0.5 * (begin + end);
        float next = (begin <= guess && guess <= end) ? guess : middle;
        // Move along or terminate
        bool done = abs(next - current) < errorTolerance;
        current = next;
        if (done)
            break;
    }
    out_root = current;
    return true;
}

// Finds all roots of the given polynomial in the interval [begin, end] and
// writes them to out_roots. Some entries will be NO_INTERSECTION but other
// than that the array is sorted. The last entry is always NO_INTERSECTION.
void YukselBracketed(
    inout float out_roots[POLYNOMIAL_DEGREE + 1], 
    const Polynomial poly, 
    float begin, float end)
{
    // Construct the quadratic derivative of the polynomial. We divide each
    // derivative by the factorial of its order, such that the constant
    // coefficient can be copied directly from poly. That is a safeguard
    // against overflow and makes it easier to avoid spilling below. The
    // factors happen to be binomial coefficients then.
    
    // this is the (POLYNOMIAL_DEGREE - 2)th derivative - the derivative[] is filled left-to-right
	Polynomial derivative;
	derivative[0] = poly[POLYNOMIAL_DEGREE - 2]; // constant coeff, i.e. this was a_{N-2} * x^{N-2}, divided by (N-2)!
	derivative[1] = float(POLYNOMIAL_DEGREE - 1) * poly[POLYNOMIAL_DEGREE - 1]; // linear coeff, this was a_{N-1} * x^{N-1} 
	derivative[2] = (0.5f * float((POLYNOMIAL_DEGREE - 1) * POLYNOMIAL_DEGREE)) * poly[POLYNOMIAL_DEGREE - 0]; // quadratic coeff, i.e. a_N * x^N

    // set all the rest coefficients to 0
	[[unroll]]
	for (int i = 3; i != POLYNOMIAL_DEGREE + 1; ++i)
		derivative[i] = 0.0f;

    // Compute two roots of the (N-2)th derivative using the quadratic formula
	float discriminant = derivative[1] * derivative[1] - 4.0f * derivative[0] * derivative[2];
	if (discriminant >= 0.0f)
	{
		float sqrt_discriminant = sqrt(discriminant);
		float scaled_root = derivative[1] + ((derivative[1] > 0.0) ? sqrt_discriminant : (-sqrt_discriminant));
		float root_0 = clamp(-2.0f * derivative[0] / scaled_root, begin, end);
		float root_1 = clamp(-0.5f * scaled_root / derivative[2], begin, end);
		out_roots[POLYNOMIAL_DEGREE - 2] = min(root_0, root_1);
		out_roots[POLYNOMIAL_DEGREE - 1] = max(root_0, root_1);
	}
	else
	{
        // Indicate that the (N-2)th derivative has a single root        
		out_roots[POLYNOMIAL_DEGREE - 2] = begin;
		out_roots[POLYNOMIAL_DEGREE - 1] = begin;
	}
    
    // Make out_roots = [B B B B ... R2 R1 E], B: begin, Ri: root i, E: end
    // The last entry in the root array is set to end to make it easier to
    // iterate over relevant intervals, all untouched roots are set to begin.
    // TLDR: out_roots is populated from right-to-left
	out_roots[POLYNOMIAL_DEGREE] = end;
	[[unroll]]
	for (int i = 0; i != POLYNOMIAL_DEGREE - 2; ++i)
		out_roots[i] = begin;

    // Work your way up to derivatives of higher degree until you reach the
    // polynomial itself. This implementation may seem peculiar: It always
    // treats the derivative as though it had degree POLYNOMIAL_DEGREE and it
    // constructs the derivatives in a contrived way. Changing that would
    // reduce the number of arithmetic instructions roughly by a factor of two.
    // However, it would also cause register spilling, which has a far more
    // negative impact on the overall run time. Profiling indicates that the
    // current implementation has no spilling whatsoever.

    // Iterate from the (N-3)th derivative up to the 0th - so we start from the (N-2)th
	[[loop]]
	for (int degree = 3; degree != POLYNOMIAL_DEGREE + 1; ++degree)
	{
        // Take the integral of the previous derivative (scaled such that the
        // constant coefficient can still be copied directly from poly)
		float prev_derivative_order = float(POLYNOMIAL_DEGREE + 1 - degree);

		[[unroll]]
		for (int i = POLYNOMIAL_DEGREE; i != 0; --i)
		{
            // integration: shift the coefficients to the right and multiply by integration scaling
			derivative[i] = derivative[i - 1] * (prev_derivative_order * (1.0f / float(i)));
		}

        // Copy the constant coefficient without causing spilling. This part
        // would be harder if the derivative were not scaled the way it is.
		[[unroll]]
		for (int i = 0; i != POLYNOMIAL_DEGREE - 2; ++i)
		{
			derivative[0] = (degree == POLYNOMIAL_DEGREE - i) ? poly[i] : derivative[0];
		}
		//derivative[0] = poly[POLYNOMIAL_DEGREE - degree];

        // Determine the value of this (scaled) derivative at begin
		float begin_value = derivative.at(begin);

        // Iterate over the intervals where roots may be found
		[[unroll]]
		for (int i = 0; i != POLYNOMIAL_DEGREE; ++i)
		{
			if (i < POLYNOMIAL_DEGREE - degree)
				continue;

			float current_begin = out_roots[i];
			float current_end = out_roots[i + 1];

            // Try to find a root
			float root;
            #ifdef USE_SURFACE_EVALUATION_IN_YUKSEL
            bool root_found = (degree == POLYNOMIAL_DEGREE) ?
                newton_bisection_with_surface(root, begin_value, derivative, current_begin, current_end, begin_value) :
                newton_bisection(root, begin_value, derivative, current_begin, current_end, begin_value);
            #else
                 bool root_found = newton_bisection(root, begin_value, derivative, current_begin, current_end, begin_value);
            #endif
			if (root_found)
			{
				out_roots[i] = root;
			}
			else
			{
				if (degree < POLYNOMIAL_DEGREE)
				{
                    // Create an empty interval for the next iteration
					out_roots[i] = out_roots[i - 1];
				}
				else
				{
					out_roots[i] = NO_INTERSECTION;
				}
			}
		}
	}

    // We no longer need this array entry
	out_roots[POLYNOMIAL_DEGREE] = NO_INTERSECTION;
}

#endif // YUKSEL_BRACKETED
