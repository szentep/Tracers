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
    program->addDefine("EVALUATION_SCHEME_BERNSTEIN", std::string(magic_enum::enum_name(evalScemeBernstein)));
    program->addDefine("SELECTED_BASIS", std::to_string(magic_enum::enum_integer(selectedBasis)));
    program->addDefine("NODE_TYPE_FOR_FITTING", std::to_string(magic_enum::enum_integer(nodeType)));

    // Raymarching Control
    program->addDefine("MAX_RAYMARCHING_STEPS", std::to_string(traceSettings.maxRaymarchingSteps));
    program->addDefine("BINARY_SEARCH_ITERATIONS", std::to_string(traceSettings.binarySearchIterations));
    program->addDefine("MAX_LU_ITERATIONS", std::to_string(traceSettings.maxLUIterations));
    program->addDefine("EARLY_OUT", std::to_string(traceSettings.earlyOutOptimizationLevel));

    // Root finder
    program->addDefine("POLY_ROOTFINDER", std::string(magic_enum::enum_name(polynomialRootFinder)));
}

// Settings for ray marching polynomial root finder
void Settings::renderRayMarchUI(Gui* pGui)
{
    ImGui::InputInt("Maximum steps", &traceSettings.maxRaymarchingSteps, 100);
    ImGui::InputInt("Binary search iterations", &traceSettings.binarySearchIterations);

    imGuiEnumSelector("Fitting Basis", selectedBasis);

    if (selectedBasis == FittingBasis::MONOMIAL)
    {
        imGuiEnumSelector("Eval.Sceme", evalSchemeMonomial);
        // Type of nodes used for fitting
        imGuiEnumSelector("Node type", nodeType);
    }
    else if (selectedBasis == FittingBasis::BERNSTEIN)
    {
        imGuiEnumSelector("Eval.Sceme", evalScemeBernstein);
        // Nodes must be on [0,1]
        ImGui::Text("Node type: Normalized Chebyshev");
        nodeType = NodeType::NORMALIZED_CHEBYSHEV;
    }
}

// Settings for Yuksel's bracketed root finder
void Settings::renderYukselUI(Gui* pGui)
{
    ImGui::Text("Fitting Basis: Monomial");
    selectedBasis = FittingBasis::MONOMIAL;

    ImGui::InputFloat("Error tolerance", &rootfinderSettings.errorTolerance, 1e-5f, 1e-3f, "%.5f");
}

void Settings::renderLUTraceUI(Gui* pGui)
{
    ImGui::InputInt("Maximum steps", &traceSettings.maxLUIterations, 100);

    static const char* earlyOutItems[] = { "None", "Absolute bound", "Bound extrema" };
    ImGui::ListBox("Early out optimization", &traceSettings.earlyOutOptimizationLevel, earlyOutItems, 3);

    ImGui::Text("Fitting Basis: Bernstein");
    selectedBasis = FittingBasis::BERNSTEIN;

    // Nodes must be on [0,1]
    ImGui::Text("Node type: Normalized Chebyshev");
    nodeType = NodeType::NORMALIZED_CHEBYSHEV;

    // Use fast evaluation
    ImGui::Text("Eval.Sceme: Chudy's geometric");
    evalScemeBernstein = EvaluationScemeBernstein::ChudySimple;

    ImGui::InputFloat("Error tolerance", &rootfinderSettings.errorTolerance, 1e-5f, 1e-3f, "%.7f");
}

void Settings::renderProgramUI(Gui* pGui)
{
    auto programGroup = Gui::Group(pGui, "Program settings", true);
    if (programGroup.open())
    {
        imGuiEnumSelector("Render mode", renderMode);
        if (renderMode == RenderMode::polynomialFitting)
        {
            // Root finder specific settings
            imGuiEnumSelector("Root finder", polynomialRootFinder);
            if (polynomialRootFinder == PolynomialRootFinder::rayMarch)
            {
                renderRayMarchUI(pGui);
            }
            else if (polynomialRootFinder == PolynomialRootFinder::YukselBracketed)
            {
                renderYukselUI(pGui);
            }
            else if (polynomialRootFinder == PolynomialRootFinder::LUTrace)
            {
                renderLUTraceUI(pGui);
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
