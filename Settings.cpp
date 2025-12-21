#include "Settings.h"

Settings::Settings() {}

void Settings::renderUI(Gui* pGui) {
    Falcor::Gui::Window w(pGui, "Settings", guiSize, guiPos);

    renderProgramUI(pGui);
    renderCameraUI(pGui);
    renderShadingUI(pGui);
}

void Settings::uploadData(const Falcor::ShaderVar& vars, Falcor::ref<Falcor::Program> program) const
{
    uploadLightData(vars["LightCB"]);
    addDefines(program);
}

void Settings::uploadLightData(const Falcor::ShaderVar& vars) const
{
    vars["lightPos"] = lightingSettings.lightPos;
    vars["colAmbient"] = lightingSettings.colAmbient;
    vars["colDiffuse"] = lightingSettings.colDiffuse;
    vars["colSpecular"] = lightingSettings.colSpecular;
    vars["shininess"] = lightingSettings.shininess;
}

void Settings::addDefines(Falcor::ref<Falcor::Program> program) const
{
    program->addDefine("POLYNOMIAL_FIT_DEGREE", std::to_string(6));
    program->addDefine("RENDER_MODE", std::to_string(magic_enum::enum_integer(renderMode)));
    program->addDefine("SELECTED_BASIS", std::to_string(magic_enum::enum_integer(selectedBasis)));
}

void Settings::renderProgramUI(Gui* pGui)
{
    auto programGroup = Gui::Group(pGui, "Program settings", true);
    if (programGroup.open())
    {
        imGuiEnumSelector("Render Mode", renderMode);
        // imGuiEnumSelector("Fitting Basis", selectedBasis);

        programGroup.release();
    }
}

void Settings::renderCameraUI(Gui* pGui)
{
    auto cameraGroup = Gui::Group(pGui, "Camera settings");
    if (cameraGroup.open())
    {
        cameraGroup.checkbox("Orbit camera", cameraSettings.orbit);

        cameraGroup.release();
    }
}

void Settings::renderShadingUI(Gui* pGui) {

}
