
#include "TracersApp.h"
#include <imgui.h>

FALCOR_EXPORT_D3D12_AGILITY_SDK

void TracersApp::onLoad(RenderContext* pRenderContext)
{
    // create rasterizer state
    RasterizerState::Desc rsDesc;
    mpNoCullRastState = RasterizerState::create(rsDesc);

    // Depth test
    DepthStencilState::Desc dsDesc;
    dsDesc.setDepthEnabled(false);
    mpNoDepthDS = DepthStencilState::create(dsDesc);

    // Blend state
    BlendState::Desc blendDesc;
    mpOpaqueBS = BlendState::create(blendDesc);

    // Texture sampler
    Sampler::Desc samplerDesc;
    samplerDesc.setFilterMode(TextureFilteringMode::Linear, TextureFilteringMode::Linear, TextureFilteringMode::Linear).setMaxAnisotropy(8);
    mpLinearSampler = getDevice()->createSampler(samplerDesc);

    // Load shaders
    mpMainPass = FullScreenPass::create(getDevice(), "Samples/Tracers/Shaders/Main.ps.slang");

    // camera
    resetCamera();
}

void TracersApp::updateCamera(Falcor::ShaderVar PsCB)
{
    fpCameraController.update();
    camera->beginFrame();

    if (settings.cameraSettings.cameraMode == CameraMode::Free)
    {
        PsCB["iEyePos"] = camera->getPosition();
        PsCB["iEyeTarget"] = camera->getTarget();
        PsCB["iEyeUp"] = camera->getUpVector();
    }

    if (settings.cameraSettings.cameraMode == CameraMode::Measurement)
    {
        camera->setPosition(settings.surfaceProperties[settings.surfaceType].cameraPosition);
        camera->setTarget(settings.surfaceProperties[settings.surfaceType].cameraTarget);
        PsCB["iEyePos"] = camera->getPosition();
        PsCB["iEyeTarget"] = camera->getTarget();
        PsCB["iEyeUp"] = camera->getUpVector();
    }

    if (settings.cameraSettings.cameraMode == CameraMode::Orbit)
        mpMainPass->getProgram()->addDefine("ORBIT_CAMERA");
    else
        mpMainPass->getProgram()->removeDefine("ORBIT_CAMERA");
}

void TracersApp::onFrameRender(RenderContext* pRenderContext, const ref<Fbo>& pTargetFbo)
{
    auto vars = mpMainPass->getRootVar();
    auto PsCB = vars["PsCB"];
    // iResolution
    float width = (float)pTargetFbo->getWidth();
    float height = (float)pTargetFbo->getHeight();
    PsCB["iResolution"] = float2(width, height);
    PsCB["iGlobalTime"] = (float)getGlobalClock().getTime();
    // Camera
    updateCamera(PsCB);

    // Upload settings
    settings.uploadData(mpMainPass->getRootVar(), mpMainPass->getProgram());

    // run render pass
    mpMainPass->execute(pRenderContext, pTargetFbo);

    // Print GPU time
    auto& events = getDevice()->getProfiler()->getEvents();
    if (!events.empty())
    {
        float GPUTime = events[0]->getGpuTimeAverage();
        std::cout << GPUTime << std::endl;
    }
}

void TracersApp::onGuiRender(Gui* pGui)
{
    Falcor::Gui::Window w(pGui, "Settings", settings.guiSize, settings.guiPos);
    renderGlobalUI(pGui);

    // complete gui
    settings.renderUI(pGui);

    // camera at the end
    settings.renderCameraUI(pGui, camera);
}

void TracersApp::onResize(uint32_t width, uint32_t height)
{
    mAspectRatio = (float(width) / float(height));
}

bool TracersApp::onKeyEvent(const KeyboardEvent& keyEvent)
{
    if (fpCameraController.onKeyEvent(keyEvent))
    {
        settings.cameraSettings.cameraMode = CameraMode::Free;
        return true;
    }

    return false;
}

bool TracersApp::onMouseEvent(const MouseEvent& mouseEvent)
{
    return fpCameraController.onMouseEvent(mouseEvent);
}

void TracersApp::resetCamera()
{
    camera->setPosition(settings.cameraSettings.startPosition);
    camera->setTarget(settings.cameraSettings.startTarget);
    camera->setNearPlane(0.001f);
    camera->beginFrame();
}

static int runMain(int argc, char** argv)
{
    SampleAppConfig config;
    config.windowDesc.width = ::Settings::windowWidth;
    config.windowDesc.height = ::Settings::windowHeight;
    config.windowDesc.resizableWindow = true;
    config.windowDesc.enableVSync = true;
    config.windowDesc.title = "Tracers App";

    TracersApp tracersAppp(config);
    return tracersAppp.run();
}

int main(int argc, char** argv)
{
    return catchAndReportAllExceptions([&]() { return runMain(argc, argv); });
}
