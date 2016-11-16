//
//  MEPipeSceneHandler.h
//  MagnetExperiment
//
//  Created by Thibault Farnier on 24/05/2016.
//
//

#import <UIKit/UIKit.h>
@class SCNNode;
@class SCNScene;

static const CGFloat CGPlayerRadius = 20.0f;
static const CGFloat CGDefaultStep = 0.5f;
static const CGFloat CGDefaultExtrudeDepth = 100.0f;

@interface MEPipeSceneHandler : NSObject
- (instancetype)initWithScene:(SCNScene *)scene;
- (SCNNode *)drawPipe;
- (void)manageRadialMoveAhead:(float)ahead side:(float)side headPositionNode:(SCNNode *)headPositionNode headRotationNode:(SCNNode *)headRotationNode;
@end
