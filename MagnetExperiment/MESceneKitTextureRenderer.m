//
//  SceneKitTextureRenderer.m
//  TestVR
//
//  Created by Andy Qua on 21/09/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "MESceneKitTextureRenderer.h"

#import "MagnetExperiment.h"
#import "MEMenuSceneHandler.h"
#import "MEPipeSceneHandler.h"
#import "MERadialMovement.h"
#import <GLKit/GLKit.h>
#import "UIColor+MEColor.h"

@import SceneKit;

typedef NS_ENUM(NSInteger, CGMovementStyle) {
    CGMovementStyleNone,
    CGMovementStyleHorizontal,
    CGMovementStyleMenu,
    CGMovementStyleRadial
};


@interface MESceneKitTextureRenderer () <SCNSceneRendererDelegate, MEMenuSceneHandlerDelegate, SCNPhysicsContactDelegate>
{
    float rotate;
    SCNScene *scene;
    float hrx, hry, hrz;  // head rotation angles in radians

    SCNNode *headPositionNode;
    SCNNode *headRotationNode;

    CGMovementStyle movementStyle;
    SCNVector3 startPosition;
}
@property (strong, nonatomic) MEMenuSceneHandler * menuSceneHandler;
@property (strong, nonatomic) MEPipeSceneHandler * pipeSceneHandler;
@property (nonatomic) NSUInteger drawnPipes;
@end

@implementation MESceneKitTextureRenderer
{
    SCNRenderer *leftEyeRenderer, *rightEyeRenderer;
    
    BOOL leftSceneReady, rightSceneReady;
    SCNNode *leftEyeCameraNode, *rightEyeCameraNode;
   	CGFloat interpupillaryDistance;

}

- (instancetype)initWithFrameSize:(CGSize)frameSize andSceneNamed:(NSString *)sceneName {
    self = [super initWithFrameSize:frameSize];
    if (self) {
        interpupillaryDistance = 0.3;

        // create a renderer for each eye
        SCNRenderer *(^makeEyeRenderer)() = ^
        {
            SCNRenderer *renderer = [SCNRenderer rendererWithContext:(__bridge EAGLContext * _Nonnull)((__bridge void *)([EAGLContext currentContext])) options:nil];
            renderer.delegate = self;
            return renderer;
        };
        leftEyeRenderer  = makeEyeRenderer();
        rightEyeRenderer = makeEyeRenderer();


        if ([sceneName isEqualToString:MEMenuSceneName]) {
            [self setScene:[self createMenuScene]];
        } else if ([sceneName isEqualToString:MEWalkSceneName]) {
            [self setScene:[self createScene]];
            self.selectedIndex = -1;
        } else if ([sceneName isEqualToString:MEBobsleighSceneName]) {
            [self setScene:[self createScene2]];
            self.selectedIndex = -1;
        }
        [scene.rootNode addChildNode:headPositionNode];
    }
    return self;
}

- (void) updateFrameAtTime:(NSTimeInterval)timeSinceLastUpdate;
{
    [super updateFrameAtTime:timeSinceLastUpdate];
}

- (void) renderLeftTexture
{
    [leftEyeRenderer render];
}

- (void) renderRightTexture
{
    [rightEyeRenderer render];
}

- (void) updateDevicePositionWithRoll:(float)roll  yaw:(float)yaw pitch:(float)pitch
{
    [super updateDevicePositionWithRoll:roll yaw:yaw pitch:pitch];

    rotate += 20;
    [self setHeadRotationX:-(refYaw-yaw) Y:(refRoll - roll) Z:refPitch - pitch];
}

- (void) updateCameraPositionsWithDirectionAhead:(float)ahead side:(float)side {
    [super updateCameraPositionsWithDirectionAhead:ahead side:side];

    switch (movementStyle) {
        case CGMovementStyleHorizontal:
            [self manageHorizontalMoveAhead:ahead side:side];
            break;
        case CGMovementStyleRadial:
            [self.pipeSceneHandler manageRadialMoveAhead:ahead side:side headPositionNode:headPositionNode headRotationNode:headRotationNode];
            break;
        case CGMovementStyleMenu:
            [self.menuSceneHandler handleInputAhead:ahead side:side];
            break;
        case CGMovementStyleNone:
            return;
            break;
        default:
            NSLog(@"Not managed movement syle");
            break;
    }

}

- (void) manageHorizontalMoveAhead:(float)ahead side:(float)side {
    GLKVector3 position = GLKVector3Make(0, side*0.1f, -ahead*0.1f);
    GLKMatrix4 rot = GLKMatrix4MakeRotation(headRotationNode.rotation.w, headRotationNode.rotation.x, headRotationNode.rotation.y, headRotationNode.rotation.z);
    SCNVector3 r = SCNVector3FromGLKVector3(GLKMatrix4MultiplyVector3(rot, position));

    // NaN handling, usually at start
    if (isnan(r.x)) {
        return;
    }

    // y set at 0 to move on a floor
    SCNMatrix4 transform = SCNMatrix4Translate(headPositionNode.transform, r.x, r.y, r.z);
    headPositionNode.transform = transform;
}

#pragma mark - SCNPhysicsContactDelegate
- (void)physicsWorld:(SCNPhysicsWorld *)world didBeginContact:(SCNPhysicsContact *)contact {
    SCNNode * coinNode = [contact.nodeA.name isEqualToString:@"coin"] ? contact.nodeA : contact.nodeB;
    [coinNode removeFromParentNode];
}

#pragma mark - CGMenuSceneHandlerDelegate

- (void)didChangeToIndex:(NSUInteger)index {
    self.selectedIndex = index;
}

#pragma mark -
#pragma mark Accessors

- (SCNMatrix4)getCameraTranslationForEye:(int)eye
{
    // TODO: read IPD from HMD?
    float x = (-1 * eye) * (interpupillaryDistance/-2.0);
    return SCNMatrix4MakeTranslation(x, 0, 0 );
}
- (void)setInterpupillaryDistance:(CGFloat)ipd;
{
    interpupillaryDistance = ipd;
    leftEyeCameraNode.transform = [self getCameraTranslationForEye:LEFT];
    rightEyeCameraNode.transform = [self getCameraTranslationForEye:RIGHT];
}


- (SCNVector3) headPosition
{
    return headPositionNode.position;
}

// position is public, node is private
- (void)setHeadPosition:(SCNVector3) position
{
    headPositionNode.position = position;
}

- (void)setHeadRotationX:(float)x Y:(float)y Z:(float)z
{
    hrx = x;
    hry = y;
    hrz = z;
    
    SCNMatrix4 transform       = SCNMatrix4Identity;
    transform                  = SCNMatrix4Rotate(transform, y, 1, 0, 0);
    transform                  = SCNMatrix4Rotate(transform, x, 0, 1, 0);
    headRotationNode.transform = SCNMatrix4Rotate(transform, z, 0, 0, 1);
}

- (void)linkNodeToHeadPosition:(SCNNode*)node
{
    [headPositionNode addChildNode:node];
}

- (void)linkNodeToHeadRotation:(SCNNode*)node
{
    [headRotationNode addChildNode:node];
}

- (void)resetDevicePosition {
    [super resetDevicePosition];
    headPositionNode.position = startPosition;
}

#pragma mark - create scenekit scene

- (void)setScene:(SCNScene *)newScene
{
    scene = newScene;
    
    leftEyeRenderer.scene = newScene;
    rightEyeRenderer.scene = newScene;
    
    
    // create cameras
    SCNNode *(^addNodeforEye)(int) = ^(int eye)
    {
        // TODO: read these from the HMD?
        CGFloat verticalFOV = 97.5;
        CGFloat horizontalFOV = 0.1; //80.8;
        
        SCNCamera *camNode = [SCNCamera camera];
        camNode.xFov = 120;
        camNode.yFov = verticalFOV;
        camNode.zNear = horizontalFOV;
        camNode.zFar = 10000;
        
        SCNNode *node = [SCNNode node];
        node.camera = camNode;
        node.transform = [self getCameraTranslationForEye:eye];
        
        return node;
    };
    leftEyeRenderer.pointOfView = addNodeforEye(LEFT);
    rightEyeRenderer.pointOfView = addNodeforEye(RIGHT);
    
    headPositionNode = [SCNNode node];
    SCNVector3 initialPosition = [[newScene rootNode] childNodeWithName:@"initialPosition" recursively:YES].position;
    headPositionNode.position = startPosition = initialPosition;
    headRotationNode = [SCNNode node];
    [headPositionNode addChildNode:headRotationNode];
    [self linkNodeToHeadRotation:leftEyeRenderer.pointOfView];
    [self linkNodeToHeadRotation:rightEyeRenderer.pointOfView];

    SCNNode * characterNode = [[newScene rootNode] childNodeWithName:@"character" recursively:YES];
    [headPositionNode addChildNode:characterNode];
}

- (SCNScene *)createScene {
    SCNScene * newScene = [SCNScene sceneNamed:@"game.scnassets/MainScene.scn"];
    newScene.physicsWorld.contactDelegate = self;
    movementStyle = CGMovementStyleHorizontal;

    return newScene;
}

- (SCNScene *)createScene2 {
    SCNScene * newScene = [SCNScene scene];
    self.pipeSceneHandler = [[MEPipeSceneHandler alloc] initWithScene:newScene];
    SCNNode * pipeNode = [self.pipeSceneHandler drawPipe];
    pipeNode.position = SCNVector3Make(0, 0, -CGDefaultExtrudeDepth/2);
    [newScene.rootNode addChildNode:pipeNode];

    SCNNode * initialPosition = [SCNNode node];
    initialPosition.name = @"initialPosition";
    initialPosition.position = SCNVector3Make(0,-CGPlayerRadius,0);
    [newScene.rootNode addChildNode:initialPosition];

    SCNLight * ambient = [SCNLight light];
    ambient.type = SCNLightTypeAmbient;
    SCNNode * lightNode = [SCNNode node];
    lightNode.light = ambient;
    [newScene.rootNode addChildNode:lightNode];

    newScene.background.contents = [UIImage imageNamed:@"game.scnassets/skybox01_cube.png"];
    movementStyle = CGMovementStyleRadial;

    return newScene;
}

- (SCNScene *)createMenuScene {
    SCNScene * menuScene = [SCNScene sceneNamed:@"game.scnassets/MenuScene.scn"];
    movementStyle = CGMovementStyleMenu;
    self.menuSceneHandler = [[MEMenuSceneHandler alloc] initWithScene:menuScene];
    self.menuSceneHandler.delegate = self;

    return menuScene;
}
@end
