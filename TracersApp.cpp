
#include "TracersApp.h"

FALCOR_EXPORT_D3D12_AGILITY_SDK

TracersApp::TracersApp(const SampleAppConfig& config) : SampleApp(config), camera(Camera::create("Main Camera")), fpCameraController(camera)
{}

TracersApp::~TracersApp() {}

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

void TracersApp::onFrameRender(RenderContext* pRenderContext, const ref<Fbo>& pTargetFbo)
{
    // iResolution
    float width = (float)pTargetFbo->getWidth();
    float height = (float)pTargetFbo->getHeight();
    auto PsCB = mpMainPass->getRootVar()["PsCB"];
    PsCB["iResolution"] = float2(width, height);
    PsCB["iGlobalTime"] = (float)getGlobalClock().getTime();
    PsCB["iEyePos"] = camera->getPosition();

    // camera
    fpCameraController.update();
    camera->beginFrame();

    // run final pass
    mpMainPass->execute(pRenderContext, pTargetFbo);
}

void TracersApp::onResize(uint32_t width, uint32_t height)
{
    mAspectRatio = (float(width) / float(height));
}

bool TracersApp::onKeyEvent(const KeyboardEvent& keyEvent)
{
    if (fpCameraController.onKeyEvent(keyEvent))
        return true;

    return false;
}

bool TracersApp::onMouseEvent(const MouseEvent& mouseEvent)
{
    return fpCameraController.onMouseEvent(mouseEvent);
}

void TracersApp::resetCamera()
{
    camera->setPosition({0.f, 0.f, -3.f});
    camera->setTarget({0.f, 0.f, 0.f});
    // camera->setTarget({-4.f, .7f, .5f}); // do not look at the surface
    camera->setNearPlane(0.001f);
    camera->beginFrame();
}

static int runMain(int argc, char** argv)
{
    SampleAppConfig config;
    config.windowDesc.width = 1280;
    config.windowDesc.height = 720;
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
