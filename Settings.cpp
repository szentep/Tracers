#include "Settings.h"

Settings::Settings() {}

void Settings::renderUI(Gui* pGui)
{
    renderProgramUI(pGui);
    renderSceneUI(pGui);
    renderCameraUI(pGui);
    renderShadingUI(pGui);
}

void Settings::uploadData(const Falcor::ShaderVar& vars, Falcor::ref<Falcor::Program> program) const
{
    uploadRootFinderData(vars["RootFinderCB"]);
    uploadLightData(vars["LightCB"]);
    addDefines(program);
}

void Settings::uploadRootFinderData(const Falcor::ShaderVar& vars) const
{
    vars["errorTolerance"] = rootfinderSettings.errorTolerance;
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
    // Surface
    program->addDefine("POLYNOMIAL_DEGREE", std::to_string(surfaceProperties.at(surfaceType).degree));
    program->addDefine("SURFACE_FUNCTION", std::string(magic_enum::enum_name(surfaceType)));

    // Render settings
    program->addDefine("RENDER_MODE", std::string(magic_enum::enum_name(renderMode)));
    program->addDefine("EVALUATION_SCHEME_MONOMIAL", std::string(magic_enum::enum_name(evalSchemeMonomial)));
    program->addDefine("SELECTED_BASIS", std::to_string(magic_enum::enum_integer(selectedBasis)));
    program->addDefine("NODE_TYPE_FOR_FITTING", std::to_string(magic_enum::enum_integer(nodeType)));

    // Raymarching Control
    program->addDefine("MAX_RAYMARCHING_STEPS", std::to_string(traceSettings.maxRaymarchingSteps));
    program->addDefine("BINARY_SEARCH_ITERATIONS", std::to_string(traceSettings.binarySearchIterations));

    // Root finder
    program->addDefine("POLY_ROOTFINDER", std::string(magic_enum::enum_name(polynomialRootFinder)));
}

void Settings::renderProgramUI(Gui* pGui)
{
    auto programGroup = Gui::Group(pGui, "Program settings", true);
    if (programGroup.open())
    {
        imGuiEnumSelector("Render mode", renderMode);
        if (renderMode == RenderMode::polynomialFitting)
        {
            imGuiEnumSelector("Node type", nodeType);

            // imGuiEnumSelector("Fitting Basis", selectedBasis); // TODO support bernstein basis
            if (selectedBasis == FittingBasis::MONOMIAL)
            {
                imGuiEnumSelector("Eval.Sceme", evalSchemeMonomial);
            }

            imGuiEnumSelector("Root finder", polynomialRootFinder);
            if (polynomialRootFinder == PolynomialRootFinder::rayMarch)
            {
                ImGui::InputInt("Maximum steps", &traceSettings.maxRaymarchingSteps, 100);
                ImGui::InputInt("Binary search iterations", &traceSettings.binarySearchIterations);
            }
            else if (polynomialRootFinder == PolynomialRootFinder::YukselBracketed)
            {
                ImGui::InputFloat("Error tolerance", &rootfinderSettings.errorTolerance, 1e-5f, 1e-3f, "%.5f");
            }
        }
        else if (renderMode == RenderMode::rayMarchScene)
        {
            ImGui::InputInt("Maximum steps", &traceSettings.maxRaymarchingSteps, 100);
            ImGui::InputInt("Binary search iterations", &traceSettings.binarySearchIterations);
        }

        programGroup.release();
    }
}

void Settings::renderSceneUI(Gui* pGui)
{
    auto sceneGroup = Gui::Group(pGui, "Scene settings", true);
    if (sceneGroup.open())
    {
        imGuiEnumSelector("Surface", surfaceType);
        ImGui::Text("Degree: %d", surfaceProperties.at(surfaceType).degree);

        sceneGroup.release();
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

void Settings::renderShadingUI(Gui* pGui) {}
