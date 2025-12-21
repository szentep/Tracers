#ifndef LIGHTS
#define LIGHTS

//
// Functions and data for lights
//

cbuffer LightCB
{
    float3 lightPos;
    float3 colAmbient;
    float3 colDiffuse;
    float3 colSpecular;
    float shininess;
};

float3 CalculateBlinnPhong(
    float3 p,
    float3 n,
    float3 viewDir)
{
    float3 lightDir = normalize(lightPos - p);

    // Diffuse
    float diff = max(dot(n, lightDir), 0.0);

    // Specular
    float3 halfVec = normalize(lightDir - viewDir);
    float spec = pow(max(dot(n, halfVec), 0.0), shininess);

    return colAmbient + (colDiffuse * diff) + (colSpecular * spec);
}

#endif // LIGHTS
