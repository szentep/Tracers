#ifndef POLYNOMIAL
#define POLYNOMIAL

//
// Utility class and functions to represent and evaluate polynomials
//

#ifndef POLYNOMIAL_FIT_DEGREE
#define POLYNOMIAL_FIT_DEGREE 1
#endif

// Basis function for polynomial fitting
#ifndef BASIS_ID_MONOMIAL
#define BASIS_ID_MONOMIAL 0
#endif
#ifndef BASIS_ID_BERNSTEIN
#define BASIS_ID_BERNSTEIN 1
#endif

#ifndef SELECTED_BASIS
#define SELECTED_BASIS BASIS_ID_MONOMIAL
#endif

// Evaluation scheme for the monomial basis
#ifndef MONOMIAL_EVAL_HORNER
#define MONOMIAL_EVAL_HORNER 0
#endif
#ifndef MONOMIAL_EVAL_COMP_HORNER
#define MONOMIAL_EVAL_COMP_HORNER 1
#endif

#ifndef EVALUATION_SCHEME_MONOMIAL
#define EVALUATION_SCHEME_MONOMIAL MONOMIAL_EVAL_COMP_HORNER
#endif

// ------------------------------------------------------------------
// Error-Free Transformations (EFT)
// ------------------------------------------------------------------

// Computes s = fl(a + b) and error e.
void TwoSum(float a, float b, out float s, out float e)
{
    // 'precise' prevents the compiler from optimizing (s - a) -> b
    precise float sum = a + b;
    precise float v = sum - a;
    precise float e_a = sum - v;
    s = sum;
    precise float err = (a - e_a) + (b - v);
    e = err;
}

// Computes p = fl(a * b) and error e using FMA.
void TwoProduct(float a, float b, out float p, out float e)
{
    precise float prod = a * b;
    p = prod;
    
    // fma(a, b, c) = (a * b) + c computed with infinite precision, then rounded.
    // This isolates the rounding error of the multiplication.
    precise float err = fma(a, b, -prod);
    e = err;
}

struct Polynomial
{
    float coeffs[POLYNOMIAL_FIT_DEGREE + 1];
    const static int N = POLYNOMIAL_FIT_DEGREE;

    float horner(float t)
    {
        float result = coeffs[N];
        for (int i = N - 1; i >= 0; --i)
        {
            result = t * result + coeffs[i];
        }
        return result;
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
    float compHorner(float t)
    {
        float s = coeffs[N];
        float c = 0.0f; 

        [unroll] 
        for (int i = N - 1; i >= 0; --i)
        {
            float p, pi;
            TwoProduct(s, t, p, pi);

            float s_new, sigma;
            TwoSum(p, coeffs[i], s_new, sigma);
            s = s_new;

            // Accumulate correction term
            // We use standard ops here as this is the lower-significance part
            c = c * t + (pi + sigma);
        }

        return s + c;
    }

    // evaluate polynomial at t
    float at(float t)
    {
    #if SELECTED_BASIS == BASIS_ID_MONOMIAL
        #if EVALUATION_SCHEME_MONOMIAL == MONOMIAL_EVAL_HORNER
            return horner(t);
        #elif EVALUATION_SCHEME_MONOMIAL == MONOMIAL_EVAL_COMP_HORNER
            return compHorner(t);
        #endif
    #elif SELECTED_BASIS == BASIS_ID_BERNSTEIN
        return deCasteljau(t);
    #endif
    }
}

#endif // POLYNOMIAL
