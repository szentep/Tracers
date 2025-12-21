#pragma once
#include "Falcor.h"
#include <imgui.h>
#include "Utils/magic_enum.hpp"

enum class RenderMode
{
    DIRECT_RAYTRACE = 0,             // Direct raytracing on the function
    POLYNOMIAL_FITTING_RAYTRACE = 1, // Raytracing on the polynomial fitting of the function
};

enum class FittingBasis
{
    MONOMIAL = 0,  // Monomial basis
    BERNSTEIN = 1, // Bernstein basis
};

class Settings
{
    using Gui = Falcor::Gui;

public:
    Settings();
    ~Settings() {};

    void renderUI(Gui* pGui);

    void uploadData(const Falcor::ShaderVar& vars, Falcor::ref<Falcor::Program> program) const;
    void uploadLightData(const Falcor::ShaderVar& vars) const;
    void addDefines(Falcor::ref<Falcor::Program> program) const;

    RenderMode renderMode = RenderMode::DIRECT_RAYTRACE;
    FittingBasis selectedBasis = FittingBasis::MONOMIAL;

    const static uint32_t windowWidth = 1280;
    const static uint32_t windowHeight = 720;

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
    void renderCameraUI(Gui* pGui);
    void renderShadingUI(Gui* pGui);

    Falcor::uint2 guiSize = {300, 720};
    Falcor::uint2 guiPos = {0, 0};

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
