#pragma once
#include "Falcor.h"
#include "Core/SampleApp.h"
#include "Core/Pass/FullScreenPass.h"

#include "Settings.h"

using namespace Falcor;

class TracersApp : public SampleApp
{
public:
    TracersApp(const SampleAppConfig& config) : SampleApp(config), camera(Camera::create("Main Camera")), fpCameraController(camera) {
        fpCameraController.setCameraSpeed(2.0);
    };
    ~TracersApp() {};

    void onLoad(RenderContext* pRenderContext) override;
    void onFrameRender(RenderContext* pRenderContext, const ref<Fbo>& pTargetFbo) override;
    // Input
    void onGuiRender(Gui* pGui) override;
    void onResize(uint32_t width, uint32_t height) override;
    bool onKeyEvent(const KeyboardEvent& keyEvent) override;
    bool onMouseEvent(const MouseEvent& mouseEvent) override;

private:
    ref<Sampler> mpLinearSampler;
    float mAspectRatio = 0;
    ref<RasterizerState> mpNoCullRastState;
    ref<DepthStencilState> mpNoDepthDS;
    ref<BlendState> mpOpaqueBS;
    ref<FullScreenPass> mpMainPass;

    ::Settings settings;

    // camera
    ref<Camera> camera = nullptr;
    FirstPersonCameraController fpCameraController;
    void resetCamera();
};
