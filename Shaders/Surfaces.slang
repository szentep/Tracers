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
    const float PHI2 = 2.61803398;    // PHI^2
    const float BARTH_K = 4.23606798; // (1 + 2*PHI)

    float x2 = p.x * p.x;
    float y2 = p.y * p.y;
    float z2 = p.z * p.z;

    // 4 * (phi^2*x^2 - y^2)(phi^2*y^2 - z^2)(phi^2*z^2 - x^2)
    float term1 = 4.0 * (PHI2 * x2 - y2) * (PHI2 * y2 - z2) * (PHI2 * z2 - x2);

    // (1 + 2phi) * (x^2 + y^2 + z^2 - 1)^2
    float r2 = x2 + y2 + z2;
    float term2 = BARTH_K * (r2 - 1.0) * (r2 - 1.0);

    return term1 - term2;
}

// 64 (x^2 - 1) (y^2 - 1) ((x - y)^2 - 2) ((x + y)^2 - 2) -
// - ((8 (2 + sqrt(2)) z^2 + 2 (2 + 7 sqrt(2))) (x^2 + y^2) - 4 (1 + sqrt(2)) (x^2 + y^2)^2 - 16 z^4 + 8 (1 - 2 sqrt(2)) z^2 - 12 sqrt(2) - 1)^2 = 0
float endrassOctic(float3 p)
{
    p *= 5.0; // Scale
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

// Surfaces from https://homepage.univie.ac.at/herwig.hauser/bildergalerie/gallery.html

// x2 + y2 z3 = z4
float calyx(float3 p)
{
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
    return p.x * p.x * (1. - p.x) + p.y * p.y * (1. + p.y * p.y) + p.z * p.z * p.z * (1. - 10.*p.z);
}

// x2 yz + x2 z2 = y3 z + y3
float geisha(float3 p)
{
    p = 2.0 * p.xzy; // rotate and scale
    return p.x * p.x * p.z * (p.y + p.z) - p.y * p.y * p.y * (1. + p.z);
}

// 
float a(float3 p)
{
    
    return 0;
}

#endif // SURFACES
