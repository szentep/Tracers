#pragma once
#include "Falcor.h"
#include <imgui.h>
#include "Utils/magic_enum.hpp"
#include <map>

enum class RenderMode
{
    rayMarchScene = 0,     // Direct raytracing on the function
    polynomialFitting = 1, // Fit a polynomial and use a rootfinder
};

enum class FittingBasis
{
    MONOMIAL = 0,  // Monomial basis
    BERNSTEIN = 1, // Bernstein basis
};

enum class EvaluationScemeMonomial
{
    Horner,            // Horner's method
    compensatedHorner, // Compensated Horner's method
};

enum class EvaluationScemeBernstein
{
    deCasteljau, // De Casteljau's algorithm
    ChudySimple, // Chudy's geometric algorithm
};

enum class PolynomialRootFinder
{
    rayMarch,        // Raymarching on the polynomial
    YukselBracketed, // Yuksel's method
    LUTrace,         // Trace the polynomial by determining Lipschitz constant using the LU approximatiton
};

enum class NodeType
{
    CHEBYSHEV = 0,            // Chebyshev nodes on [-1,1]
    NORMALIZED_CHEBYSHEV = 1, // Chebyshev nodes normalized to [0,1]
};

enum class SurfaceType
{
    barthSextic,
    endrassOctic,
    barthDecic,
    calyx,
    geisha,
    calypso,
    distel,
    flirt,
};

struct SurfaceProperties
{
    uint32_t degree;
};

enum class DebugMode
{
    DEBUG_OFF = 0,               // Disable everythinig
    DEBUG_POLY_AT_SAMPLES = 1,   // Show error of polynomial values at sample points
    DEBUG_POLY_AT_INTERSECT = 2, // Compare function values at the intersection points
};

class Settings
{
    using Gui = Falcor::Gui;

public:
    Settings();
    ~Settings() {};

    void renderUI(Gui* pGui);

    void uploadData(const Falcor::ShaderVar& vars, Falcor::ref<Falcor::Program> program) const;
    void uploadRootFinderData(const Falcor::ShaderVar& vars) const;
    void uploadLightData(const Falcor::ShaderVar& vars) const;
    void uploadSettingsData(const Falcor::ShaderVar& vars) const;
    void addDefines(Falcor::ref<Falcor::Program> program) const;

    // Render settings
    RenderMode renderMode = RenderMode::polynomialFitting;
    bool useEFTFitting = true;
    FittingBasis selectedBasis = FittingBasis::BERNSTEIN;
    EvaluationScemeMonomial evalSchemeMonomial = EvaluationScemeMonomial::Horner;
    EvaluationScemeBernstein evalScemeBernstein = EvaluationScemeBernstein::ChudySimple;
    NodeType nodeType = NodeType::NORMALIZED_CHEBYSHEV;
    PolynomialRootFinder polynomialRootFinder = PolynomialRootFinder::YukselBracketed;
        // Yuksel
        bool useSurfaceEvaluationInYuksel = true;
    // Debug settings
    DebugMode debugMode = DebugMode::DEBUG_OFF;
    float errorThreshold = 0.001f;

    // Surface settings
    SurfaceType surfaceType = SurfaceType::endrassOctic;
    std::map<SurfaceType, SurfaceProperties> surfaceProperties = {
        {SurfaceType::barthSextic, {6}},
        {SurfaceType::endrassOctic, {8}},
        {SurfaceType::barthDecic, {10}},
        {SurfaceType::calyx, {5}},
        {SurfaceType::geisha, {4}},
        {SurfaceType::calypso, {3}},
        {SurfaceType::distel, {6}},
        {SurfaceType::flirt, {4}},
    };

    const static uint32_t windowWidth = 1280;
    const static uint32_t windowHeight = 720;

    Falcor::uint2 guiSize = {300, windowHeight - 150};
    Falcor::uint2 guiPos = {0, 0};

    struct TraceSettings
    {
        int32_t maxRaymarchingSteps = 1000;
        int32_t binarySearchIterations = 8;
        int32_t maxLUIterations = 10000;
        int32_t earlyOutOptimizationLevel = 0; // 0: none; 1: convex hull; 2: bounder
    } traceSettings;

    struct RootFinderSettings
    {
        float errorTolerance = 1e-5f;
    } rootfinderSettings;

    struct CameraSettings
    {
        bool orbit = true;
        Falcor::float3 startPosition = Falcor::float3(0.f, 0.f, -3.f);
        Falcor::float3 startTarget = Falcor::float3(0.f, 0.f, 0.f);
    } cameraSettings;

    struct LightingSettings
    {
        Falcor::float3 lightPos = Falcor::float3(2.0, 5.0, -3.0);
        Falcor::float3 colAmbient = Falcor::float3(.05, .02, .01);
        Falcor::float3 colDiffuse = Falcor::float3(.7, .5, .1);
        Falcor::float3 colSpecular = Falcor::float3(.9);
        float shininess = 64;
    } lightingSettings;

private:
    void renderProgramUI(Gui* pGui);
    void renderRayMarchUI(Gui* pGui);
    void renderYukselUI(Gui* pGui);
    void renderLUTraceUI(Gui* pGui);

    void renderSceneUI(Gui* pGui);
    void renderCameraUI(Gui* pGui);
    void renderShadingUI(Gui* pGui);

    // Draw an ImGui combo box for selecting enum values using magic_enum
    template<typename T>
    void imGuiEnumSelector(const char* label, T& selected_value)
    {
        static_assert(std::is_enum_v<T>, "T must be an enum");

        std::string current_name = std::string(magic_enum::enum_name(selected_value));

        if (ImGui::BeginCombo(label, current_name.c_str()))
        {
            for (auto& [value, name] : magic_enum::enum_entries<T>())
            {
                if (ImGui::Selectable(name.data(), selected_value == value))
                {
                    selected_value = value;
                }
            }
            ImGui::EndCombo();
        }
    }
};
