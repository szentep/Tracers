#include "PolynomialFitting.slang"

cbuffer PsCB
{
    float2 iResolution;
    float iGlobalTime;
    float3 iEyePos;
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
float3 calculateNormalBarthSextic(float3 p, float valCenter)
{
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

/**
 * Ray-Sphere Intersection Test
 * Returns distance to intersection or -1.0 if no intersection. Inside the sphere returns 0.
 * ro: ray origin
 * rd: normalized ray direction
 * s0: sphere center
 * sr: sphere radius
 */
float raySphereIntersect(float3 ro, float3 rd, float3 s0, float sr) {
    float3 s0_r0 = ro - s0;
    float b = 2.0 * dot(rd, s0_r0);
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
float refineIntersection(float3 ro, float3 rd, float t, float lastStep)
{
    float tMin = t - lastStep;
    float tMax = t;
    
    for (int i = 0; i < BINARY_SEARCH_ITERATIONS; i++)
    {
        float tMid = (tMin + tMax) * 0.5;
        float3 p = ro + rd * tMid;
        float f_val = evaluateBarthSextic(p);

        // We assume the raymarch stopped past the boundary and positive is outside
        if (f_val < 0.0) tMin = tMid;
        else tMax = tMid;
    }
    return tMax;
}

float rayMarchScene(float3 ro, float3 rd, out bool hit)
{
    hit = false;
    float dist = raySphereIntersect(ro, rd, float3(0.0), BOUNDING_SPHERE_RADIUS);
    if (dist < 0.0) return 0.0; // No intersection with bounding sphere
    // Step to bounding sphere first for efficiency
    float dist0 = dist;
    float f_val = evaluateBarthSextic(ro);
    float prev_f = 0.0;

    for(int i = 0; i < MAX_STEPS; i++)
    {
        dist += STEP_SIZE;
        float3 p = ro + rd * dist;
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
        dist = refineIntersection(ro, rd, dist, STEP_SIZE);
    }

    return dist;
}

// --- Shading ---

float3 CalculateBlinnPhong(
    float3 p, 
    float3 viewDir, 
    float3 lightPos, 
    float3 colAmbient, 
    float3 colDiffuse, 
    float3 colSpecular, 
    float shininess)
{
    // Re-evaluate center for accurate normal calculation
    float val = evaluateBarthSextic(p);
    float3 n = calculateNormalBarthSextic(p, val);

    // If the normal points away from camera flip it.
    // if (dot(n, viewDir) > 0.0) n = -n;
    
    float3 lightDir = normalize(lightPos - p);
    
    // Diffuse
    float diff = max(dot(n, lightDir), 0.0);
    
    // Specular
    float3 halfVec = normalize(lightDir - viewDir);
    float spec = pow(max(dot(n, halfVec), 0.0), shininess);
    
    return colAmbient + (colDiffuse * diff) + (colSpecular * spec);
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

// --- Main ---

float4 mainImage(float2 fragCoord)
{
    // Normalized pixel coordinates (from 0 to 1)
    float2 uv = (fragCoord - 0.5 * iResolution) / iResolution.y;

    // Camera Setup
    float3 camPos = iEyePos;
    float3 rayDir = normalize(float3(uv, 1.5)); // 1.5 is the (FOV)
    
    // Animation
    float time = iGlobalTime * 0.2;
    float3x3 camRot = rotateY(time); // mul(rotateY(time), rotateX(time * 0.7));
    camPos = mul(camPos, camRot);
    rayDir = mul(rayDir, camRot);
    
    // Raymarch
    bool hit;
    float dist = rayMarchScene(camPos, rayDir, hit);
    
    float3 finalColor = float3(0.1, 0.1, 0.15); // Background Color
    
    if(hit)
    {
        float3 hitPos = camPos + rayDir * dist;
        
        // Lighting Parameters
        float3 lightPos = float3(2.0, 5.0, -3.0);
        
        // Gold/Yellowish Palette
        float3 ambientCol = float3(.05, .02, .01);
        float3 diffuseCol = float3(.7, .5, .1);
        float3 specCol    = float3(.9);
        float shininess   = 64.;
        
        finalColor = CalculateBlinnPhong(
            hitPos, 
            -rayDir, // View direction is ray direction
            lightPos, 
            ambientCol, 
            diffuseCol, 
            specCol, 
            shininess
        );
    }

    // Gamma Correction
    finalColor = pow(finalColor, float3(.5));

    return float4(finalColor, 1.0);
}

float4 main(float2 texC: TEXCOORD) : SV_TARGET
{
    return mainImage(texC * iResolution);
}
