#include "Settings.h"

Settings::Settings() {}

void Settings::renderUI(Gui* pGui)
{
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
    program->addDefine("POLYNOMIAL_DEGREE", std::to_string(6)); // TODO change with scene
    program->addDefine("RENDER_MODE", std::to_string(magic_enum::enum_integer(renderMode)));
    program->addDefine("SELECTED_BASIS", std::to_string(magic_enum::enum_integer(selectedBasis)));
    program->addDefine("EVALUATION_SCHEME_MONOMIAL", std::string(magic_enum::enum_name(evalSchemeMonomial)));
    program->addDefine("NODE_TYPE_FOR_FITTING", std::to_string(magic_enum::enum_integer(nodeType)));
}

void Settings::renderProgramUI(Gui* pGui)
{
    auto programGroup = Gui::Group(pGui, "Program settings", true);
    if (programGroup.open())
    {
        imGuiEnumSelector("Render Mode", renderMode);
        if (renderMode == RenderMode::POLYNOMIAL_FITTING_RAYTRACE)
        {
            imGuiEnumSelector("Node Type", nodeType);

            // imGuiEnumSelector("Fitting Basis", selectedBasis); // TODO support bernstein basis
            if (selectedBasis == FittingBasis::MONOMIAL)
            {
                imGuiEnumSelector("Eval.Sceme", evalSchemeMonomial);
            }
        }
        
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
