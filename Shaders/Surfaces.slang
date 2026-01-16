#ifndef SURFACES
#define SURFACES

//
// Functions representing algebraic surfaces
// The surface is defined where the functions return 0
//

#include "Settings.slang"


// Calculates the surface normal using Forward Differences

float3 calculateSurfaceNormal(float3 p)
{
    float valCenter = SURFACE_FUNCTION(p);
    float2 h = float2(NORMAL_EPSILON, 0.0);
    
    // Gradient ~ [f(x+h)-f(x), f(y+h)-f(y), f(z+h)-f(z)]
    // We reuse valCenter (f(p)) to save 1 evaluation
    return normalize(float3(
        SURFACE_FUNCTION(p + h.xyy) - valCenter,
        SURFACE_FUNCTION(p + h.yxy) - valCenter,
        SURFACE_FUNCTION(p + h.yyx) - valCenter
    ));
}


// Surfaces from https://mathworld.wolfram.com/AlgebraicSurface.html

// (-2 ϕ - 1) (x^2 + y^2 + z^2 - 1)^2 + 4 (x^2 ϕ^2 - y^2) (z^2 ϕ^2 - x^2) (y^2 ϕ^2 - z^2) = 0
float barthSextic(float3 p)
{
    p *= 2.0; // Scale to fit in unified bounding sphere

    // Constants specific to Barth Sextic
    const float PHI = 1.61803398;
    const float PHI2 = 2.61803398;   // PHI^2
    const float BARTH_K = 4.23606798; // (1 + 2*PHI)

    float x2 = p.x * p.x;
    float y2 = p.y * p.y;
    float z2 = p.z * p.z;

    // 4 * (phi^2*x^2 - y^2)(phi^2*y^2 - z^2)(phi^2*z^2 - x^2)
    float term1 = 4 * (PHI2 * x2 - y2) * (PHI2 * y2 - z2) * (PHI2 * z2 - x2);

    // (1 + 2phi) * (x^2 + y^2 + z^2 - 1)^2
    float r2 = x2 + y2 + z2;
    float term2 = BARTH_K * (r2 - 1) * (r2 - 1);

    return term1 - term2;
}

// 64 (x^2 - 1) (y^2 - 1) ((x - y)^2 - 2) ((x + y)^2 - 2) -
// - ((8 (2 + sqrt(2)) z^2 + 2 (2 + 7 sqrt(2))) (x^2 + y^2) - 4 (1 + sqrt(2)) (x^2 + y^2)^2 - 16 z^4 + 8 (1 - 2 sqrt(2)) z^2 - 12 sqrt(2) - 1)^2 = 0
float endrassOctic(float3 p)
{
    p *= 3; // Scale

    const float S2 = sqrt(2);
    float x2 = p.x * p.x;
    float y2 = p.y * p.y;
    float z2 = p.z * p.z;
    float R = x2 + y2;

    // Term A: ((x - y)^2 - 2)((x + y)^2 - 2) becomes ((R - 2)^2 - 4x^2y^2)
    float termA = 64.0 * (x2 - 1.) * (y2 - 1.) * ((R - 2.) * (R - 2.) - 4. * x2 * y2);

    // Term B: The large polynomial inside the square
    float inner = (8. * (2. + S2) * z2 + 2. * (2. + 7. * S2)) * R - 4. * (1. + S2) * R * R 
                - 16. * z2 * z2 + 8. * (1. - 2. * S2) * z2 - 12. * S2 - 1.;

    return termA - inner * inner;
}

// Equation:
// (5ϕ + 3)(r^2 - 1)^2(r^2 + ϕ - 2)^2 + 8(x^4 - 2x^2y^2 - 2x^2z^2 + y^4 - 2y^2z^2 + z^4)(x^2 - y^2ϕ^4)(z^2 - x^2ϕ^4)(y^2 - z^2ϕ^4) = 0
float barthDecic(float3 p)
{
    p *= 2; // Scale to fit in unified bounding sphere

    // Constants
    const float PHI  = 1.61803398;
    const float PHI4 = pow(PHI, 4); // PHI^4
    const float K1   = 5. * PHI + 3.; // 5*PHI + 3
    
    float x2 = p.x * p.x;
    float y2 = p.y * p.y;
    float z2 = p.z * p.z;
    float x4 = x2 * x2;
    float y4 = y2 * y2;
    float z4 = z2 * z2;
    float r2 = x2 + y2 + z2;

    // First Term: (5ϕ + 3) * (r^2 - 1)^2 * (r^2 + ϕ - 2)^2
    float sphereA = r2 - 1.0;
    float sphereB = r2 + PHI - 2.0;
    float term1 = K1 * (sphereA * sphereA) * (sphereB * sphereB);

    // Second Term symmetric polynomial: (x^4 + y^4 + z^4 - 2(x^2y^2 + x^2z^2 + y^2z^2))
    // This is equivalent to r^4 - 4(x^2y^2 + y^2z^2 + z^2x^2)
    float symPart = x4 + y4 + z4 - 2.0 * (x2 * y2 + x2 * z2 + y2 * z2);

    // Second Term product part: (x^2 - y^2ϕ^4) (z^2 - x^2ϕ^4) (y^2 - z^2ϕ^4)
    float cyclicPart = (x2 - y2 * PHI4) * (z2 - x2 * PHI4) * (y2 - z2 * PHI4);

    float term2 = 8.0 * symPart * cyclicPart;

    return term1 + term2;
}

// Surfaces from https://homepage.univie.ac.at/herwig.hauser/bildergalerie/gallery.html

// x2 + y2 z3 = z4
float calyx(float3 p)
{
    p *= 1.; // Scale to fit in unified bounding sphere
    float y3 = p.y * p.y * p.y;
    return p.x * p.x + y3 * (p.z * p.z - p.y);
}

// x2 + y2 z = z2
float calypso(float3 p)
{
    return p.x * p.x + p.y * (p.z * p.z - p.y);
}

// x2 + y2 + z2 + 1000 (x2+y2)(x2+z2)(y2+z2) = 1
float distel(float3 p)
{
    p *= p;
    return p.x + p.y + p.z + 10000. * (p.x + p.y) * (p.x + p.z) * (p.y + p.z) - 1.;
}

// x2 - x3 + y2 + y4 + z3 - 10 z4 = 0
float flirt(float3 p)
{
    p = 1.2 * p.xzy; // rotate and scale
    float y2 = p.y * p.y;
    return p.x * p.x * (1. - p.x) + y2 * (1. + y2) + p.z * p.z * p.z * (1. - 10.*p.z);
}

// x2 yz + x2 z2 = y3 z + y3
float geisha(float3 p)
{
    p = 2.0 * p.xzy; // rotate and scale
    return p.x * p.x * p.z * (p.y + p.z) - p.y * p.y * p.y * (1. + p.z);
}

// (x2 + y2 + z2 + R2 - r2)^2 = 4 * R2 * (x2 + y2)
float torus(float3 p)
{
    const float R = .7, r = .2;
    const float R2 = R*R, r2 = r*r;

    float x2 = p.x * p.x;
    float y2 = p.y * p.y;
    float z2 = p.z * p.z;
    float lxy = x2 + y2;

    float term1 = lxy + z2 + R2 - r2;
    float term2 = 4 * R2 * lxy;

    return term1 * term1 - term2;
}

// x2 * y2 * (x2 + y2 - 1) + z4 = 0
float buggle(float3 p)
{
    p = 1.1 * p.xzy; // Scale to fit in unified bounding sphere

    float x2 = p.x * p.x;
    float y2 = p.y * p.y;
    float z2 = p.z * p.z;

    return x2 * y2 * (x2 + y2 - 1.) + z2 * z2;
}

// x2 + y2 + z2 = R2
float sphere(float3 p)
{
    const static float R = .9999;
    const static float R2 = R * R;

    float x2 = p.x * p.x;
    float y2 = p.y * p.y;
    float z2 = p.z * p.z;

    return (x2 + y2 + z2) - R2;
}

// x16 + y16 + z16 = R16
float sphere16(float3 p)
{
    const static int N = 16;
    const static float R = .6;
    const static float RN = pow(R, N);

    p *= p; // 2
    p *= p; // 4
    p *= p; // 8
    p *= p; //16

    return (p.x + p.y + p.z) - RN;
}

#endif // SURFACES
