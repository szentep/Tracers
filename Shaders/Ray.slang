
#ifndef RAY
#define RAY

#include "Settings.slang"

//
// Struct defining a ray and helper functions
//


struct Ray
{
    float3 origin = float3(0.0);
    float tMin = 0.0;
    float3 dir = float3(1.0, 0.0, 0.0);
    float tMax = 0.0;

    // Get point along ray at distance dist
    float3 at(float dist)
    {
        return origin + dir * dist;
    }

    // Get point along a ray at a normalized parameter. tMin and tMax must be set!
    float3 atNormalized(float t)
    {
        #if NODE_TYPE_FOR_FITTING == CHEBYSHEV_NODES
        t = 0.5 * t + 0.5; // Chebyshev nodes are in [-1,1], remap to [0,1]
        #endif
        return at(lerp(tMin, tMax, t));
    }
};

/**
 * Ray-Sphere Intersection Test
 * Returns distance to intersection or -1.0 if no intersection. Inside the sphere returns 0.
 * ro: ray origin
 * rd: normalized ray direction
 * s0: sphere center
 * sr: sphere radius
 */
float raySphereIntersect(inout Ray r, float3 s0, float sr)
{
    float3 s0_r0 = r.origin - s0;
    float b = 2.0 * dot(r.dir, s0_r0);
    float c = dot(s0_r0, s0_r0) - (sr * sr);
    float D = b * b - 4.0 * c;
    if (D <= 0.0 || -b + sqrt(D) <= 0.0) {
        return -1.0;
    }
    r.tMin = max((-b - sqrt(D)) / 2.0, 0.0);
    r.tMax = max((-b + sqrt(D)) / 2.0, 0.0);
    return r.tMin;
}

#endif // RAY
