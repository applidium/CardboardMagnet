//
//  MEViewController.m
//  MagnetExperiment
//
//  Created by Thibault Farnier on 25/07/2016.
//  Copyright © 2016 Thibault Farnier. All rights reserved.
//

#import "MEGameViewController.h"
#import "MagnetExperiment.h"
#import "MESceneKitTextureRenderer.h"
#import "MEGLProgram.h"
#import "VRMBicubicInterpolator.h"
@import CoreMotion;

@interface MEGameViewController ()
{
    GLint displayPositionAttribute, displayTextureCoordinateAttribute;
    GLint displayInputTextureUniform;

    GLint lensCenterUniform, screenCenterUniform, scaleUniform, scaleInUniform, hmdWarpParamUniform;

    GLuint leftEyeTexture, rightEyeTexture;
    GLuint leftEyeFramebuffer, rightEyeFramebuffer;
    GLuint leftEyeDepthBuffer, rightEyeDepthBuffer;
}
@property (strong, nonatomic) EAGLContext * context;
@property (strong, nonatomic) MESceneKitTextureRenderer * renderer;
@property (strong, nonatomic) NSString * sceneName;
@property (strong, nonatomic) MEGLProgram * displayProgram;
@property (strong, nonatomic) CMMotionManager * motionManager;

@property (strong, nonatomic) NSMutableArray<VRM3DVector *> * magnetometerData;
@property (strong, nonatomic) VRMBicubicInterpolator * interpolator;

- (void)setupGL;
- (void)tearDownGL;
- (void)setupCoreMotion;
@end

@implementation MEGameViewController

#pragma mark - UIViewController

- (instancetype)initWithSceneNamed:(NSString *)sceneName andInterpolator:(VRMBicubicInterpolator *)interpolator {
    if (self = [super init]) {
        _sceneName = sceneName;
        _interpolator = interpolator;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];

    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }

    GLKView * view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    view.enableSetNeedsDisplay = NO;

    [self setupGL];
    [self setupCoreMotion];

    self.navigationController.navigationBar.hidden = YES;

    UITapGestureRecognizer * singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:singleTap];
}

- (void)dealloc
{
    [self tearDownGL];

    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;

        [self tearDownGL];

        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }
}

#pragma mark - GLKView[VC] delegate

- (void)update {
    [self updateDeviceMotion];
    [self.renderer updateFrameAtTime:self.timeSinceLastUpdate];
    [self _updatePhysics];

    glBindFramebuffer(GL_FRAMEBUFFER, leftEyeFramebuffer);

    glViewport(0, 0, ME_EYE_RENDER_RESOLUTION_X, ME_EYE_RENDER_RESOLUTION_Y);
    glClearColor(0, 1, 1, 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    [self.renderer renderLeftTexture];


    glBindFramebuffer(GL_FRAMEBUFFER, rightEyeFramebuffer);
    glViewport(0, 0, ME_EYE_RENDER_RESOLUTION_X, ME_EYE_RENDER_RESOLUTION_Y);
    glClearColor(0, 1, 1, 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    [self.renderer renderRightTexture];

    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

- (void)_updatePhysics {

}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [self renderStereoscopicScene];  // apply distortion
}

#pragma mark - OpenGL

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];

    glEnable(GL_DEPTH_TEST);
    [self commonInit];

    glUniform4f(hmdWarpParamUniform, 1.0, 0.22, 0.24, 0.20);

    if (_sceneName) {
        self.renderer = [[MESceneKitTextureRenderer alloc] initWithFrameSize:self.view.bounds.size andSceneNamed:_sceneName];
    } else {
        self.renderer = [[MESceneKitTextureRenderer alloc] initWithFrameSize:self.view.bounds.size andSceneNamed:MEMenuSceneName];
    }

}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];

    glDeleteFramebuffers(1, &leftEyeFramebuffer);
    glDeleteRenderbuffers(1, &leftEyeDepthBuffer);
    glDeleteTextures(1, &leftEyeTexture);
    glDeleteFramebuffers(1, &rightEyeFramebuffer);
    glDeleteRenderbuffers(1, &rightEyeDepthBuffer);
    glDeleteTextures(1, &rightEyeTexture);
}

- (void)commonInit
{
    // create storage space for OpenGL textures
    glActiveTexture(GL_TEXTURE0);

    void (^setupBufferWithTexture)(GLuint*, GLuint*, GLuint*) = ^(GLuint* texture, GLuint* frameBuffer, GLuint* depthBuffer)
    {
        glGenTextures(1, texture);
        glBindTexture(GL_TEXTURE_2D, *texture);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

        glGenFramebuffers(1, frameBuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, *frameBuffer);

        glGenRenderbuffers(1, depthBuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, *depthBuffer);

        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24_OES, ME_EYE_RENDER_RESOLUTION_X, ME_EYE_RENDER_RESOLUTION_Y);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, *depthBuffer);

        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, ME_EYE_RENDER_RESOLUTION_X, ME_EYE_RENDER_RESOLUTION_Y, 0, GL_BGRA, GL_UNSIGNED_BYTE, 0);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, *texture, 0);

        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete eye FBO: %d", status);

        glBindTexture(GL_TEXTURE_2D, 0);
    };

    setupBufferWithTexture(&leftEyeTexture, &leftEyeFramebuffer, &leftEyeDepthBuffer);
    setupBufferWithTexture(&rightEyeTexture, &rightEyeFramebuffer, &rightEyeDepthBuffer);

    glBindFramebuffer(GL_FRAMEBUFFER, 0);

    self.displayProgram = [[MEGLProgram alloc] initWithVertexShaderFilename:@"Shader"
                                                     fragmentShaderFilename:@"Shader"];
    [self.displayProgram addAttribute:@"position"];
    [self.displayProgram addAttribute:@"inputTextureCoordinate"];

    if (![self.displayProgram link])
    {
        NSLog(@"Link failed");
        NSString *progLog = [self.displayProgram programLog];
        NSLog(@"Program Log: %@", progLog);
        NSString *fragLog = [self.displayProgram fragmentShaderLog];
        NSLog(@"Frag Log: %@", fragLog);
        NSString *vertLog = [self.displayProgram vertexShaderLog];
        NSLog(@"Vert Log: %@", vertLog);
        self.displayProgram = nil;
    }

    displayPositionAttribute = [self.displayProgram attributeIndex:@"position"];
    displayTextureCoordinateAttribute = [self.displayProgram attributeIndex:@"inputTextureCoordinate"];
    displayInputTextureUniform = [self.displayProgram uniformIndex:@"inputImageTexture"];

    screenCenterUniform = [self.displayProgram uniformIndex:@"ScreenCenter"];
    scaleUniform = [self.displayProgram uniformIndex:@"Scale"];
    scaleInUniform = [self.displayProgram uniformIndex:@"ScaleIn"];
    hmdWarpParamUniform = [self.displayProgram uniformIndex:@"HmdWarpParam"];
    lensCenterUniform = [self.displayProgram uniformIndex:@"LensCenter"];

    [self.displayProgram use];

    glEnableVertexAttribArray(displayPositionAttribute);
    glEnableVertexAttribArray(displayTextureCoordinateAttribute);

    // Depth test will always be enabled
    glEnable(GL_DEPTH_TEST);

}

- (void)renderStereoscopicScene
{
    static const GLfloat leftEyeVertices[] = {
        -1.0f, -1.0f,
        0.0f, -1.0f,
        -1.0f,  1.0f,
        0.0f,  1.0f,
    };

    static const GLfloat rightEyeVertices[] = {
        0.0f, -1.0f,
        1.0f, -1.0f,
        0.0f,  1.0f,
        1.0f,  1.0f,
    };

    static const GLfloat textureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };

    [self.displayProgram use];

    glClearColor(0.0, 0.0, 0.0, 0.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);

    glEnableVertexAttribArray(displayPositionAttribute);
    glEnableVertexAttribArray(displayTextureCoordinateAttribute);

    float w = 1.0;
    float h = 1.0;
    float x = 0.0;
    float y = 0.0;

    // Left eye
    float distortion = 0.151976 * 2.0;
    float scaleFactor = 0.583225;
    float as = 640.0 / 800.0;
    glUniform2f(scaleUniform, (w/2) * scaleFactor, (h/2) * scaleFactor * as);
    glUniform2f(scaleInUniform, (2/w), (2/h) / as);
    glUniform4f(hmdWarpParamUniform, 1.0, 0.30, 0.20, 0.10);
    glUniform2f(lensCenterUniform, x + (w + distortion * 0.5f)*0.5f, y + h*0.5f);
    glUniform2f(screenCenterUniform, x + w*0.5f, y + h*0.5f);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, leftEyeTexture);
    glUniform1i(displayInputTextureUniform, 0);
    glVertexAttribPointer(displayPositionAttribute, 2, GL_FLOAT, 0, 0, leftEyeVertices);
    glVertexAttribPointer(displayTextureCoordinateAttribute, 2, GL_FLOAT, 0, 0, textureCoordinates);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glBindTexture(GL_TEXTURE_2D, 0);

    // Right eye
    distortion = -0.151976 * 2.0;
    glUniform2f(lensCenterUniform, x + (w + distortion * 0.5f)*0.5f, y + h*0.5f);
    glUniform2f(screenCenterUniform, 0.5f, 0.5f);

    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, rightEyeTexture);
    glUniform1i(displayInputTextureUniform, 1);
    glVertexAttribPointer(displayPositionAttribute, 2, GL_FLOAT, 0, 0, rightEyeVertices);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    glBindTexture(GL_TEXTURE_2D, 0);
}

#pragma mark - CoreMotion

- (void) setupCoreMotion {
    self.motionManager = [[CMMotionManager alloc] init];
    [self.motionManager startDeviceMotionUpdates];
    [self.motionManager startMagnetometerUpdates];
}

-(void) updateDeviceMotion
{
    CMDeviceMotion *deviceMotion = self.motionManager.deviceMotion;
    if ( deviceMotion == nil )
        return;

    CMAttitude *attitude = deviceMotion.attitude;

    [self.renderer updateDevicePositionWithRoll:attitude.roll yaw:attitude.yaw pitch:attitude.pitch];

    if (self.interpolator) {
        VRM2DVector * pos = [self.interpolator positionForMagneticField:self.motionManager.magnetometerData.magneticField];
        CGFloat x = fabs(pos.x) > 0.6f ? pos.x : 0.0f;
        CGFloat y = fabs(pos.y) > 0.6f ? pos.y : 0.0f;
        vector_float2 direction = vector_clamp((vector_float2){x,y},-1,1);
        [self.renderer updateCameraPositionsWithDirectionAhead:-direction[0] side:direction[1]];
    }
}

#pragma mark - Touch event
- (void)handleSingleTap:(id)sender
{
    if (!self.interpolator) {
        if (!self.magnetometerData) {
            self.magnetometerData = [NSMutableArray new];
        }
        if (self.magnetometerData.count < 9) {
            [self.magnetometerData addObject:[[VRM3DVector alloc] initWithMagneticField:self.motionManager.magnetometerData.magneticField]];
            NSLog(@"mag field %f %f %f", self.motionManager.magnetometerData.magneticField.x, self.motionManager.magnetometerData.magneticField.y, self.motionManager.magnetometerData.magneticField.z);
            if (self.magnetometerData.count == 9) {
                self.interpolator = [[VRMBicubicInterpolator alloc] initWith9Points:self.magnetometerData];
            }
        }
    } else {
        UIViewController * viewToPush;
        switch (self.renderer.selectedIndex) {
            case -1:
                [self.navigationController popViewControllerAnimated:YES];
                break;
            case 0:
                viewToPush = [[MEGameViewController alloc] initWithSceneNamed:MEWalkSceneName andInterpolator:self.interpolator];
                break;
            case 1:
                viewToPush = [[MEGameViewController alloc] initWithSceneNamed:MEBobsleighSceneName andInterpolator:self.interpolator];
                break;
            default:
                break;
        }
        if (viewToPush) {
            [self.navigationController pushViewController:viewToPush animated:YES];
        } else {
            
        }
        [self.renderer resetDevicePosition];
    }
}

- (void)handleDoubleTap:(id)sender
{
    [self.renderer resetDevicePosition];
}

@end
