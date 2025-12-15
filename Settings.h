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

private:
    void renderCameraUI(Gui* pGui);
    void renderShadingUI(Gui* pGui);

    Falcor::uint2 guiSize = {300, 720};
    Falcor::uint2 guiPos = {0, 0};

    struct CameraSettings
    {
        bool orbit = true;
    } cameraSettings;
};
