#ifndef POLYNOMIAL
#define POLYNOMIAL

#include "Settings.slang"
#include "EFT.slang"

//
// Utility class and functions to represent and evaluate polynomials
//

// Default evaluation schemes
#ifndef EVALUATION_SCHEME_MONOMIAL
#define EVALUATION_SCHEME_MONOMIAL Horner
#endif

#ifndef EVALUATION_SCHEME_BERNSTEIN
#define EVALUATION_SCHEME_BERNSTEIN deCasteljau
#endif


struct Polynomial
{
    float coeffs[POLYNOMIAL_DEGREE + 1];
    const static int N = POLYNOMIAL_DEGREE;

    // Slang allows overriding operator[] with __subscript syntax:
    __subscript(int x) -> float
    {
        get { return coeffs[x]; }
        set { coeffs[x] = newValue; }
    }

    float Horner(float t)
    {
        float result = coeffs[N];
        [[unroll]]
        for (int i = N - 1; i >= 0; --i)
        {
            result = t * result + coeffs[i];
        }
        return result;
    }

    float ChudySimple(float t)
    {
        float h = 1.0;
        const float t1 = 1.0 - t;
        float q = coeffs[0];
        [[unroll]]
        for (int k = 1; k <= N; ++k)
        {
            /*
            h *= t * (N + 1 - k) / k;
            q = q * t1 + h * coeffs[k]; //*/
            /*
            h *= t * (N + 1 - k);
            h /= (k * t1 + h);
            float h1 = 1 - h;
            q = h1 * q + h * coeffs[k]; //*/
            //*
            h *= t * (N + 1 - k);
            float x = k * t1;
            float d = x + h;
            float h1 = x / d;
            h /= d;
            q = h1 * q + h * coeffs[k];//*/
        }
        return q;
    }

    float deCasteljau(float t)
    {
        float q[N + 1];
        for (int k = 0; k <= N; ++k) q[k] = coeffs[k];
        for (int k = 1; k <= N; ++k)
        {
            for (int l = 0; l <= N - k; ++l)
            {
                q[l] = lerp(q[l], q[l + 1], t);
            }
        }
        return q[0];
    }

    // Compensated Horner's method for polynomial evaluation
    float compensatedHorner(float t)
    {
        float s = coeffs[N];
        float c = 0.0f; 

        [unroll] 
        for (int i = N - 1; i >= 0; --i)
        {
            float2 p = twoProd(s, t);

            float2 s2 = twoSum(p.x, coeffs[i]);
            s = s2.x;

            // Accumulate correction term
            // We use standard ops here as this is the lower-significance part
            c = mad(c, t, p.y + s2.y);
        }

        return s + c;
    }

    // evaluate polynomial at t
    float at(float t)
    {
    #if SELECTED_BASIS == BASIS_ID_MONOMIAL
        return EVALUATION_SCHEME_MONOMIAL(t);
    #elif SELECTED_BASIS == BASIS_ID_BERNSTEIN
        return EVALUATION_SCHEME_BERNSTEIN(t);
    #endif
    }

    // evaluate polynomial and derivative at t
    float valueAndDerivativeAt(float t, out float derivative)
    {
        float value = coeffs[POLYNOMIAL_DEGREE] * t + coeffs[POLYNOMIAL_DEGREE - 1];
		derivative = coeffs[POLYNOMIAL_DEGREE];

		[[unroll]]
		for (int j = POLYNOMIAL_DEGREE - 2; j != -1; --j)
		{
			derivative = derivative * t + value;
			value = value * t + coeffs[j];
		}
        return value;
    }

    // compute first derivative of the polynomial
    Polynomial derivativePolynomial()
    {
        Polynomial der;
        [[unroll]]
        for (int i = 0; i < POLYNOMIAL_DEGREE; ++i) // degree of derivative is POLYNOMIAL_DEGREE - 1
        {
            #if SELECTED_BASIS == BASIS_ID_MONOMIAL
                der[i] = (i + 1) * coeffs[i + 1];
            #elif SELECTED_BASIS == BASIS_ID_BERNSTEIN
                der[i] = POLYNOMIAL_DEGREE * (coeffs[i + 1] - coeffs[i]);
            #endif
        }
        return der;
    }

}

#endif // POLYNOMIAL
