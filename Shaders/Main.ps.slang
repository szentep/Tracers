#include "Lights.slang"
#include "Polynomial.slang"
#include "PolynomialFitting.slang"
#include "Rootfinders/Rootfinders.slang"
#include "Surfaces.slang"
#include "Ray.slang"
#include "Settings.slang"

cbuffer PsCB
{
    float2 iResolution;
    float iGlobalTime;
    // camera
    float3 iEyePos;
    float3 iEyeTarget;
    float3 iEyeUp;
};

// --- Intersection Logic ---

// Refines the hit location on the surface using the Bisection Method
float refineIntersection(Ray ray, float t, float fMin, float lastStep)
{
    float tMin = t - lastStep;
    float tMax = t;
    
    for (int i = 0; i < BINARY_SEARCH_ITERATIONS; i++)
    {
        float tMid = (tMin + tMax) * 0.5;
        float f_val = SURFACE_FUNCTION(ray.at(tMid));

        if (f_val * fMin > 0.0) tMin = tMid;
        else tMax = tMid;
    }
    return tMax;
}

// Ray march the scene directly
float rayMarchScene(Ray ray, inout bool hit)
{
    hit = false;
    float dist = raySphereIntersect(ray, float3(0.0), BOUNDING_SPHERE_RADIUS);
    if (dist < 0.0) return 0.0; // No intersection with bounding sphere

    // Step to bounding sphere first for efficiency
    float dist0 = dist;
    float f_val = SURFACE_FUNCTION(ray.origin);
    float prev_f = 0.0;

    float stepSize = MAX_DIST / MAX_RAYMARCHING_STEPS;
    for(int i = 0; i < MAX_RAYMARCHING_STEPS; i++)
    {
        dist += stepSize;
        float3 p = ray.at(dist);
        if (length(p) > BOUNDING_SPHERE_RADIUS) break;
        float f_val = SURFACE_FUNCTION(p);

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
        dist = refineIntersection(ray, dist, prev_f, stepSize);
    }

    return dist;
}

float polynomialFitting(Ray ray, inout bool hit)
{
    Polynomial poly = fitPolynomial(ray);

    #if NODE_TYPE_FOR_FITTING == NORMALIZED_CHEBYSHEV_NODES
        float begin = 0.0;
    #elif NODE_TYPE_FOR_FITTING == CHEBYSHEV_NODES
        float begin = -1.0;
    #endif

    // Find first root on the interval using raymarch
    float intersect = POLY_ROOTFINDER(poly, begin, 1.0, hit);

    // scale back t to world coordinates
    #if NODE_TYPE_FOR_FITTING == CHEBYSHEV_NODES
        intersect = 0.5 * intersect + 0.5; // Chebyshev nodes are in [-1,1], remap to [0,1]
    #endif
    return lerp(ray.tMin, ray.tMax, intersect);
}

// returns distance to intersection along ray, sets hit to true if intersection occurs
float raySurfaceIntersection(Ray ray, inout bool hit)
{
    // Bounding volume check
    float dist = raySphereIntersect(ray, float3(0.0), BOUNDING_SPHERE_RADIUS);
    if (dist < 0.0) return 0.0; // No intersection with bounding sphere
    // Render mode switch
    return RENDER_MODE(ray, hit);
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
        float3 camPos = float3(0.0, 0.0, -2.0 * BOUNDING_SPHERE_RADIUS);
        float3 rayDir = normalize(float3(uv, 1.0)); // 1.5 is the (FOV)
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
        float3 normal = calculateSurfaceNormal(hitPos);
        if (dot(normal, ray.dir) > 0) normal *= -1;
        finalColor = CalculateBlinnPhong(hitPos, normal, -ray.dir); // View direction is ray direction
    }

    // Gamma Correction
    finalColor = pow(finalColor, float3(.5));

    if (any(DEBUG_COLOR != 0.xxx)) finalColor = DEBUG_COLOR;

    return float4(finalColor, 1.0);
}

float4 main(float2 texC: TEXCOORD) : SV_TARGET
{
    return mainImage(texC * iResolution);
}
