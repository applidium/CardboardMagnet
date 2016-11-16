//
//  SceneKitTextureRenderer.h
//  TestVR
//
//  Created by Andy Qua on 21/09/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/glext.h>

#import "METextureRenderer.h"

static NSString * const MEBobsleighSceneName = @"game.scnassets/BobsleighScene.scn";
static NSString * const MEMenuSceneName = @"game.scnassets/MenuScene.scn";
static NSString * const MEWalkSceneName = @"game.scnassets/MainScene.scn";

@interface MESceneKitTextureRenderer : METextureRenderer
@property (nonatomic) NSInteger selectedIndex;

- (instancetype)initWithFrameSize:(CGSize)frameSize andSceneNamed:(NSString *)sceneName;
@end
