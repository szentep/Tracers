#include "Settings.h"

Settings::Settings() {}

void Settings::renderUI(Gui* pGui) {
    Falcor::Gui::Window w(pGui, "Settings", guiSize, guiPos);

    renderCameraUI(pGui);
    renderShadingUI(pGui);
}

void Settings::renderCameraUI(Gui* pGui) {
    auto cameraGroup = Gui::Group(pGui, "Camera settings");
    if (cameraGroup.open())
    {
        cameraGroup.checkbox("Orbit camera", cameraSettings.orbit);

        cameraGroup.release();
    }
}

void Settings::renderShadingUI(Gui* pGui) {

}
