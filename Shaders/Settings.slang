#ifndef SETTINGS
#define SETTINGS

//
// GPU-side implementation of the Settings class
//

cbuffer SettingsCB
{
    float errorThreshold;
};

#ifndef POLYNOMIAL_DEGREE
#define POLYNOMIAL_DEGREE 6
#endif

// Render mode
#ifndef RENDER_MODE
#define RENDER_MODE polynomialFitting
#endif

// --- Configuration Constants ---
#define BOUNDING_SPHERE_RADIUS 1.0
#define NORMAL_EPSILON 0.0001
#define MAX_DIST (BOUNDING_SPHERE_RADIUS * 2.0)

// Raymarching Control
#ifndef MAX_RAYMARCHING_STEPS
#define MAX_RAYMARCHING_STEPS 1000
#endif
#ifndef BINARY_SEARCH_ITERATIONS
#define BINARY_SEARCH_ITERATIONS 8
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

// Type of nodes to use for fitting
#ifndef CHEBYSHEV_NODES
#define CHEBYSHEV_NODES 0
#endif
#ifndef NORMALIZED_CHEBYSHEV_NODES
#define NORMALIZED_CHEBYSHEV_NODES 1
#endif

#ifndef NODE_TYPE_FOR_FITTING
#define NODE_TYPE_FOR_FITTING NORMALIZED_CHEBYSHEV_NODES
#endif

// Surface to render
#ifndef SURFACE_FUNCTION
#define SURFACE_FUNCTION barthSextic
#endif

// Type of rootfinding method for polynomials
#ifndef POLY_ROOTFINDER
#define POLY_ROOTFINDER rayMarch
#endif

// Debug modes
#define DEBUG_OFF 0
#define DEBUG_POLY_AT_SAMPLES 1
#define DEBUG_POLY_AT_INTERSECT 2

#ifndef DEBUG_MODE
#define DEBUG_MODE DEBUG_OFF
#endif

static float3 DEBUG_COLOR = float3(0); // TODO this hould be somewhere else?

#endif // SETTINGS
