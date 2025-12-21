#pragma once
#include "Falcor.h"
#include <imgui.h>

class Settings
{
    using Gui = Falcor::Gui;

public:
    Settings();
    ~Settings() {};

    void renderUI(Gui* pGui);

    void uploadData(const Falcor::ShaderVar& vars);
    void uploadLightData(const Falcor::ShaderVar& vars);

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
    void renderCameraUI(Gui* pGui);
    void renderShadingUI(Gui* pGui);

    Falcor::uint2 guiSize = {300, 720};
    Falcor::uint2 guiPos = {0, 0};
};
