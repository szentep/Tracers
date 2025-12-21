#include "PolynomialFitting.slang"
#include "Lights.slang"

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
#define MAX_STEPS 2000
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
    float3 origin;
    float3 dir;

    // Get point along ray at distance dist
    float3 at(float dist)
    {
        return origin + dir * dist;
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
float raySphereIntersect(Ray r, float3 s0, float sr) {
    float3 s0_r0 = r.origin - s0;
    float b = 2.0 * dot(r.dir, s0_r0);
    float c = dot(s0_r0, s0_r0) - (sr * sr);
    float D = b * b - 4.0 * c;
    if (D < 0.0) {
        return -1.0;
    }
    float res = (-b - sqrt(D)) / 2.0;
    if (res < 0.0) return 0.0;
    return res;
}

/**
 * Refines the hit location using the Bisection Method
 */
float refineIntersection(Ray ray, float t, float lastStep)
{
    float tMin = t - lastStep;
    float tMax = t;
    
    for (int i = 0; i < BINARY_SEARCH_ITERATIONS; i++)
    {
        float tMid = (tMin + tMax) * 0.5;
        float f_val = evaluateBarthSextic(ray.at(tMid));

        // We assume the raymarch stopped past the boundary and positive is outside
        if (f_val < 0.0) tMin = tMid;
        else tMax = tMid;
    }
    return tMax;
}

float rayMarchScene(Ray ray, out bool hit)
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
    
    // Optional: Refine the root if we hit
    if (hit)
    {
        dist = refineIntersection(ray, dist, STEP_SIZE);
    }

    return dist;
}

// --- Shading ---



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
    
    // Raymarch
    bool hit;
    float dist = rayMarchScene(ray, hit);
    
    float3 finalColor = float3(0.1, 0.1, 0.15); // Background Color
    
    if(hit)
    {
        float3 hitPos = ray.at(dist);

        // Normal calculation
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
