//
//  MEPipeSceneHandler.m
//  MagnetExperiment
//
//  Created by Thibault Farnier on 24/05/2016.
//
//

#import "MEPipeSceneHandler.h"
#import "MERadialMovement.h"
#import "UIColor+MEColor.h"
@import SceneKit;

@interface MEPipeSceneHandler ()
@property (strong, nonatomic) SCNScene * scene;
@property (strong, nonatomic) SCNNode * tubeNode;
@property (nonatomic) NSUInteger drawnPipes;
- (void)_addPositionTubeIfNecessary ;
- (void)_drawPipeIfNecessaryWithAhead:(float)ahead side:(float)side headPositionZ:(float)zPos;
- (void)_movePositionAhead:(float)ahead side:(float)side headPositionNode:(SCNNode *)headPositionNode;
- (void)_rotateHeadSide:(float)side headPositionNode:(SCNNode *)headPositionNode headRotationNode:(SCNNode *)headRotationNode;
- (void)_drawTrees;
- (void)_drawTorus;
- (void)_removeNodesAtIndex:(NSUInteger)index;
@end

static NSString * const CGTreeSceneName = @"game.scnassets/Tree.scn";
static const CGFloat CGTubeRadius = CGPlayerRadius + 3.0f;

@implementation MEPipeSceneHandler
- (instancetype)initWithScene:(SCNScene *)scene {
    if (self = [super init]) {
        _scene = scene;
    }
    return self;
}

- (SCNNode *)drawPipe {
    UIBezierPath * halfCirclePath = [UIBezierPath bezierPath];
    [halfCirclePath addArcWithCenter:CGPointMake(0, 0) radius:CGPlayerRadius + 11.0f startAngle:0 endAngle:M_PI clockwise:NO];
    [halfCirclePath addArcWithCenter:CGPointMake(0, 0) radius:CGPlayerRadius + 10.0f startAngle:M_PI endAngle:0 clockwise:YES];
    halfCirclePath.lineWidth = 1.0f;
    SCNShape * pipe = [SCNShape shapeWithPath:halfCirclePath extrusionDepth:CGDefaultExtrudeDepth];
    pipe.firstMaterial.diffuse.contents = [UIColor me_lightBlueColor];
    SCNNode * pipeNode = [SCNNode nodeWithGeometry:pipe];
    NSString * nodeName = [NSString stringWithFormat:@"pipe%lu", (unsigned long)self.drawnPipes];
    pipeNode.name = nodeName;
    [self _drawTrees];
    [self _drawTorus];
    self.drawnPipes++;
    return pipeNode;
}

- (void)manageRadialMoveAhead:(float)ahead side:(float)side headPositionNode:(SCNNode *)headPositionNode headRotationNode:(SCNNode *)headRotationNode {
    [self _addPositionTubeIfNecessary];
    [self _movePositionAhead:ahead side:side headPositionNode:headPositionNode];
    [self _rotateHeadSide:side headPositionNode:headPositionNode headRotationNode:headRotationNode];
    [self _drawPipeIfNecessaryWithAhead:ahead side:side headPositionZ:headPositionNode.position.z];
}

#pragma mark - Private

- (void)_addPositionTubeIfNecessary {
    if (!self.tubeNode) {
        SCNTube * tube = [SCNTube tubeWithInnerRadius:0.1f outerRadius:0.5f height:CGDefaultExtrudeDepth];
        tube.firstMaterial.diffuse.contents = [UIColor greenColor];
        self.tubeNode = [SCNNode nodeWithGeometry:tube];
        [self.scene.rootNode addChildNode:self.tubeNode];
        self.tubeNode.position = SCNVector3Make(0, -CGTubeRadius, 0);
        self.tubeNode.rotation = SCNVector4Make(1, 0, 0, M_PI_2);
    }
}

- (void)_drawTrees {
    SCNNode * treeNode = [[SCNScene sceneNamed:CGTreeSceneName].rootNode clone];
    [treeNode setScale:SCNVector3Make(20.0f, 20.0f, 20.0f)];
    treeNode.position = SCNVector3Make(CGPlayerRadius + 20.0f, -10.0f, -(float)(self.drawnPipes)*CGDefaultExtrudeDepth + 30.0f);
    treeNode.name = [NSString stringWithFormat:@"tree1%lu", (unsigned long)self.drawnPipes];
    treeNode.opacity = 0.0f;
    [self.scene.rootNode addChildNode:treeNode];
    [treeNode runAction:[SCNAction fadeInWithDuration:0.3f]];

    treeNode = [treeNode clone];
    treeNode.position = SCNVector3Make(-CGPlayerRadius - 20.0f, -10.0f, -(float)(self.drawnPipes)*CGDefaultExtrudeDepth - 30.0f);
    treeNode.name = [NSString stringWithFormat:@"tree2%lu", (unsigned long)self.drawnPipes];
    treeNode.opacity = 0.0f;
    [self.scene.rootNode addChildNode:treeNode];
    [treeNode runAction:[SCNAction fadeInWithDuration:0.3f]];
}

- (void)_drawTorus {
    SCNTorus * torus = [SCNTorus torusWithRingRadius:CGPlayerRadius*2.0f pipeRadius:5.0f];
    torus.firstMaterial.diffuse.contents = [UIColor redColor];
    SCNNode * torusNode = [SCNNode nodeWithGeometry:torus];
    torusNode.position = SCNVector3Make(0, 0, -(float)(self.drawnPipes)*CGDefaultExtrudeDepth);
    torusNode.rotation = SCNVector4Make(1, 0, 0, M_PI_2);
    torusNode.name = [NSString stringWithFormat:@"torus%lu", (unsigned long)self.drawnPipes];
    torusNode.opacity = 0.0f;
    [self.scene.rootNode addChildNode:torusNode];
    [torusNode runAction:[SCNAction fadeInWithDuration:0.3f]];

    SCNLight * spot = [SCNLight light];
    spot.type = SCNLightTypeSpot;
    spot.spotOuterAngle = 70.0f;
    SCNNode * spotNode = [SCNNode node];
    spotNode.light = spot;
    spotNode.position = SCNVector3Make(0, CGPlayerRadius*2.0f - 6.0f, -(float)(self.drawnPipes)*CGDefaultExtrudeDepth);
    spotNode.rotation = SCNVector4Make(1, 0, 0, -M_PI_2);
    [self.scene.rootNode addChildNode:spotNode];
}

- (void)_movePositionAhead:(float)ahead side:(float)side headPositionNode:(SCNNode *)headPositionNode {
    vector_float2 initPos = {headPositionNode.position.x, headPositionNode.position.y};
    vector_float2 newPos = [MERadialMovement newPositionFrom:initPos withInput:side andRadius:CGPlayerRadius];
    CGFloat factor = ahead > 0 ? 6.0f : 2.0f;
    SCNMatrix4 transform = SCNMatrix4Translate(headPositionNode.transform, newPos[0]-initPos[0], newPos[1]-initPos[1], -3.0*CGDefaultStep - ahead*factor*CGDefaultStep);
    headPositionNode.transform = transform;

    vector_float2 newInitPos = {self.tubeNode.position.x, self.tubeNode.position.y};
    vector_float2 newNewPos = [MERadialMovement newPositionFrom:initPos withInput:side andRadius:CGTubeRadius];
    transform = SCNMatrix4Translate(self.tubeNode.transform, newNewPos[0]-newInitPos[0], newNewPos[1]-newInitPos[1], -3.0*CGDefaultStep - ahead*factor*CGDefaultStep);
    self.tubeNode.transform = transform;
}

- (void)_rotateHeadSide:(float)side headPositionNode:(SCNNode *)headPositionNode headRotationNode:(SCNNode *)headRotationNode {
    vector_float2 initPos = {headPositionNode.position.x, headPositionNode.position.y};
    float newAngle = [MERadialMovement newAngleFrom:initPos withInput:side andRadius:CGPlayerRadius];
    SCNMatrix4 transform = SCNMatrix4Rotate(headRotationNode.transform, newAngle, 0, 0, 1);
    headRotationNode.transform = transform;

    vector_float2 newInitPos = {self.tubeNode.position.x, self.tubeNode.position.y};
    float oldAngle = [MERadialMovement newAngleFrom:newInitPos withInput:0 andRadius:CGTubeRadius];
    newAngle = [MERadialMovement newAngleFrom:newInitPos withInput:side andRadius:CGTubeRadius];
    transform = SCNMatrix4Rotate(self.tubeNode.transform, newAngle-oldAngle, 0, 0, 1);
    self.tubeNode.transform = transform;
}

- (void)_drawPipeIfNecessaryWithAhead:(float)ahead side:(float)side headPositionZ:(float)zPos {
    if ((int)(-zPos/CGDefaultExtrudeDepth) + 4 != self.drawnPipes) {
        SCNNode * pipeNode = [self drawPipe];
        pipeNode.position = SCNVector3Make(0, 0, -(float)(self.drawnPipes - 1)*CGDefaultExtrudeDepth - CGDefaultExtrudeDepth/2);
        pipeNode.opacity = 0.0f;
        [self.scene.rootNode addChildNode:pipeNode];
        SCNAction * fadeInAction = [SCNAction fadeInWithDuration:0.3f];
        [pipeNode runAction:fadeInAction];

        [self _removeNodesAtIndex:self.drawnPipes-6];
    }
}

- (void)_removeNodesAtIndex:(NSUInteger)index {
    void (^removeBlockNamed)(NSString *) = ^void(NSString * name) {
        SCNAction * fadeOutAction = [SCNAction fadeOutWithDuration:0.3f];
        SCNNode * nodeToRemove = [self.scene.rootNode childNodeWithName:name recursively:YES];
        [nodeToRemove runAction:fadeOutAction completionHandler:^{
            [nodeToRemove removeFromParentNode];
        }];
    };
    NSString * name = [NSString stringWithFormat:@"torus%lu", (unsigned long)index];
    removeBlockNamed(name);
    name = [NSString stringWithFormat:@"pipe%lu", (unsigned long)index-1];
    removeBlockNamed(name);
    name = [NSString stringWithFormat:@"tree1%lu", (unsigned long)index];
    removeBlockNamed(name);
    name = [NSString stringWithFormat:@"tree2%lu", (unsigned long)index];
    removeBlockNamed(name);
}
@end
