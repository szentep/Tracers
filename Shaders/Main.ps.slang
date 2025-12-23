#include "Lights.slang"
#include "Polynomial.slang"
#include "PolynomialFitting.slang"


// Render mode
#define DIRECT_RAYTRACE 0
#define POLYNOMIAL_FITTING_RAYTRACE 1

#ifndef RENDER_MODE
#define RENDER_MODE DIRECT_RAYTRACE
#endif

cbuffer PsCB
{
    float2 iResolution;
    float iGlobalTime;
    // camera
    float3 iEyePos;
    float3 iEyeTarget;
    float3 iEyeUp;
};

// --- Configuration Constants ---
#define BOUNDING_SPHERE_RADIUS 2.0
#define NORMAL_EPSILON 0.0001

// Raymarching Control
#define MAX_STEPS 1000
#define MAX_DIST (BOUNDING_SPHERE_RADIUS * 2.0)
#define STEP_SIZE (MAX_DIST / MAX_STEPS)
#define BINARY_SEARCH_ITERATIONS 8

// --- Implicit Surface Definition ---

/**
 * Evaluates the Barth Sextic polynomial at point p.
 * The surface is defined where this function returns 0.
 */
float evaluateBarthSextic(float3 p)
{
    // return length(p) - BOUNDING_SPHERE_RADIUS;

    // Constants specific to Barth Sextic
    const float PHI = 1.61803398;
    const float PHI2 = 2.61803398; // PHI^2
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

/**
 * Calculates the surface normal using Forward Differences
 */
float3 calculateNormalBarthSextic(float3 p)
{
    float valCenter = evaluateBarthSextic(p);
    float2 h = float2(NORMAL_EPSILON, 0.0);
    
    // Gradient ~ [f(x+h)-f(x), f(y+h)-f(y), f(z+h)-f(z)]
    // We reuse valCenter (f(p)) to save 1 evaluation
    return normalize(float3(
        evaluateBarthSextic(p + h.xyy) - valCenter,
        evaluateBarthSextic(p + h.yxy) - valCenter,
        evaluateBarthSextic(p + h.yyx) - valCenter
    ));
}

// --- Intersection Logic ---

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

/**
 * Refines the hit location using the Bisection Method
 */
float refineIntersection(Ray ray, float t, float fMin, float lastStep)
{
    float tMin = t - lastStep;
    float tMax = t;
    
    for (int i = 0; i < BINARY_SEARCH_ITERATIONS; i++)
    {
        float tMid = (tMin + tMax) * 0.5;
        float f_val = evaluateBarthSextic(ray.at(tMid));

        if (f_val * fMin > 0.0) tMin = tMid;
        else tMax = tMid;
    }
    return tMax;
}

/**
 * Refines the hit location using the Bisection Method
 */
float refinePolynomialIntersection(Polynomial p, float t, float fMin, float lastStep)
{
    float tMin = t - lastStep;
    float tMax = t;
    
    for (int i = 0; i < BINARY_SEARCH_ITERATIONS; i++)
    {
        float tMid = (tMin + tMax) * 0.5;
        float f_val = p.at(tMid);

        if (f_val * fMin > 0.0) tMin = tMid;
        else tMax = tMid;
    }
    return tMax;
}

float rayMarchScene(Ray ray, inout bool hit)
{
    hit = false;
    float dist = raySphereIntersect(ray, float3(0.0), BOUNDING_SPHERE_RADIUS);
    if (dist < 0.0) return 0.0; // No intersection with bounding sphere

    // Step to bounding sphere first for efficiency
    float dist0 = dist;
    float f_val = evaluateBarthSextic(ray.origin);
    float prev_f = 0.0;

    for(int i = 0; i < MAX_STEPS; i++)
    {
        dist += STEP_SIZE;
        float3 p = ray.at(dist);
        if (length(p) > BOUNDING_SPHERE_RADIUS) break;
        float f_val = evaluateBarthSextic(p);

        if (prev_f * f_val < 0.0) 
        {
            hit = true;
            break;
        }

        if (dist - dist0 > MAX_DIST) break;

        prev_f = f_val;
    }
    
    // Refine the root if we hit
    if (hit)
    {
        dist = refineIntersection(ray, dist, prev_f, STEP_SIZE);
    }

    return dist;
}

float rayMarchPolynomial(Ray ray, inout bool hit)
{
    // Fit polynomial
    float samples[POLYNOMIAL_DEGREE + 1];
    float maxSample = 1.0;
    [[unroll]]
    for (int i = 0; i <= POLYNOMIAL_DEGREE; ++i) {
        float node = GetNode(i);
        samples[i] = evaluateBarthSextic(ray.atNormalized(node));
    }

    Polynomial p = interpolate_polynomial(samples);

    // Find first root on the interval using raymarch
    #if NODE_TYPE_FOR_FITTING == NORMALIZED_CHEBYSHEV_NODES
        float t = 0.0;
        const float stepSize = 1.0 / MAX_STEPS;
    #elif NODE_TYPE_FOR_FITTING == CHEBYSHEV_NODES
        float t = -1.0;
        const float stepSize = 2.0 / MAX_STEPS;
    #endif
    float f_val = p.at(t);
    float prev_f = 0.0;

    for (int i = 0; i < MAX_STEPS; i++)
    {
        t += stepSize;
        float f_val = p.at(t);

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
        t = refinePolynomialIntersection(p, t, prev_f, stepSize);
    }

    // scale back t to world coordinates
    #if NODE_TYPE_FOR_FITTING == CHEBYSHEV_NODES
        t = 0.5 * t + 0.5; // Chebyshev nodes are in [-1,1], remap to [0,1]
    #endif
    return lerp(ray.tMin, ray.tMax, t);
}

// returns distance to intersection along ray, sets hit to true if intersection occurs
float raySurfaceIntersection(Ray ray, inout bool hit)
{
    // Bounding volume check
    float dist = raySphereIntersect(ray, float3(0.0), BOUNDING_SPHERE_RADIUS);
    if (dist < 0.0) return 0.0; // No intersection with bounding sphere
    // Render mode switch
    #if RENDER_MODE == DIRECT_RAYTRACE // Raymarch the scene directly
        return rayMarchScene(ray, hit);
    #elif RENDER_MODE == POLYNOMIAL_FITTING_RAYTRACE // Use Polynomial Fitting Raytracer
        return rayMarchPolynomial(ray, hit);
    #endif
}

// --- Camera Tools ---

float3x3 rotateY(float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return float3x3(c, 0, s, 0, 1, 0, -s, 0, c);
}

float3x3 rotateX(float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    return float3x3(1, 0, 0, 0, c, -s, 0, s, c);
}

Ray generateRay(float2 uv)
{
    Ray ray;
    #ifdef ORBIT_CAMERA
        float3 camPos = float3(0.0, 0.0, -3.0);
        float3 rayDir = normalize(float3(uv, 1.5)); // 1.5 is the (FOV)
        // Animation
        float time = iGlobalTime * 0.2;
        float3x3 camRot = rotateY(time); // mul(rotateY(time), rotateX(time * 0.7));
        ray.origin = mul(camPos, camRot);
        ray.dir = mul(rayDir, camRot);
    #else // camera setup from input parameters
        ray.origin = iEyePos;
        float3 eyeCenterDir = normalize(iEyeTarget - iEyePos);
        float3 right = normalize(cross(eyeCenterDir, iEyeUp));
        ray.dir = normalize(1.0 * eyeCenterDir - uv.y * iEyeUp + uv.x * right);
    #endif
    return ray;
}

// --- Main ---

float4 mainImage(float2 fragCoord)
{
    // Normalized pixel coordinates (from 0 to 1)
    float2 uv = (fragCoord - 0.5 * iResolution) / iResolution.y;

    // Camera Setup
    Ray ray = generateRay(uv);

    // Ray-Surface Intersection
    bool hit = false;
    float dist = raySurfaceIntersection(ray, hit);
    
    float3 finalColor = float3(0.1, 0.1, 0.15); // Background Color
    
    if(hit)
    {
        float3 hitPos = ray.at(dist);
        float3 normal = calculateNormalBarthSextic(hitPos);
        finalColor = CalculateBlinnPhong(hitPos, normal, -ray.dir); // View direction is ray direction
    }

    // Gamma Correction
    finalColor = pow(finalColor, float3(.5));

    return float4(finalColor, 1.0);
}

float4 main(float2 texC: TEXCOORD) : SV_TARGET
{
    return mainImage(texC * iResolution);
}
