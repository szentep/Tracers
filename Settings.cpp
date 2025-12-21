#include "Settings.h"

Settings::Settings() {}

void Settings::renderUI(Gui* pGui) {
    Falcor::Gui::Window w(pGui, "Settings", guiSize, guiPos);

    renderCameraUI(pGui);
    renderShadingUI(pGui);
}

void Settings::uploadData(const Falcor::ShaderVar& vars)
{
    uploadLightData(vars["LightCB"]);
}

void Settings::uploadLightData(const Falcor::ShaderVar& vars)
{
    vars["lightPos"] = lightingSettings.lightPos;
    vars["colAmbient"] = lightingSettings.colAmbient;
    vars["colDiffuse"] = lightingSettings.colDiffuse;
    vars["colSpecular"] = lightingSettings.colSpecular;
    vars["shininess"] = lightingSettings.shininess;
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
