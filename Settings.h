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

    const static uint32_t windowWidth = 1280;
    const static uint32_t windowHeight = 720;

    struct CameraSettings
    {
        bool orbit = true;
        Falcor::float3 startPosition = Falcor::float3(0.f, 0.f, -3.f);
        Falcor::float3 startTarget = Falcor::float3(0.f, 0.f, 0.f);
    } cameraSettings;

private:
    void renderCameraUI(Gui* pGui);
    void renderShadingUI(Gui* pGui);

    Falcor::uint2 guiSize = {300, 720};
    Falcor::uint2 guiPos = {0, 0};
};
