//
//  CGMenuSceneHandler.m
//  MagnetExperiment
//
//  Created by Thibault Farnier on 20/05/2016.
//
//

#import "MEMenuSceneHandler.h"

@interface MEMenuSceneHandler ()
@property (strong, nonatomic) NSArray<SCNNode *> * availableItems;
@property (strong, nonatomic) SCNNode * selectedItem;
@property (strong, nonatomic) SCNNode * spotlight;
@property (strong, nonatomic) SCNMaterial * unselectedMaterial;
@property (strong, nonatomic) SCNMaterial * selectedMaterial;

- (void)_moveSpotlightToShowSelectedItem;
@end

typedef NS_ENUM(NSInteger, CGDirection) {
    CGDirectionLeft,
    CGDirectionRight
};

static NSString * const MEWalkSceneName = @"game.scnassets/MainScene.scn";
static NSString * const MEWalkNode = @"walkNode";
static NSString * const MEBobsleighSceneName = @"game.scnassets/Bobsleigh.scn";
static NSString * const MEBobsleighNode = @"bobsleighNode";
static NSString * const MESpotlightNode = @"spotSelector";

static const CGFloat MEDeltaRot = 0.05f * M_PI_4/2;
static const CGFloat MERotLimit = M_PI_4/2;

@implementation MEMenuSceneHandler
- (instancetype)init {
    NSAssert(NO, @"Use designated initializer");
    return nil;
}

- (instancetype)initWithScene:(SCNScene *)scene {
    if (self = [super init]) {
        _menuScene = scene;
        _selectedItem = [scene.rootNode childNodeWithName:MEWalkNode recursively:YES];
        _selectedMaterial = ((SCNText *)_selectedItem.childNodes[0].geometry).firstMaterial;
        _availableItems = @[_selectedItem, [scene.rootNode childNodeWithName:MEBobsleighNode recursively:YES]];
        _unselectedMaterial = ((SCNText *)_availableItems[1].childNodes[0].geometry).firstMaterial;
        _spotlight = [scene.rootNode childNodeWithName:MESpotlightNode recursively:YES];
    }
    return self;
}

- (void)setSelectedItem:(SCNNode *)selectedItem {
    ((SCNText *)_selectedItem.childNodes[0].geometry).firstMaterial = _unselectedMaterial;
    ((SCNText *)selectedItem.childNodes[0].geometry).firstMaterial = _selectedMaterial;
    _selectedItem = selectedItem;
    [self.delegate didChangeToIndex:[_availableItems indexOfObject:_selectedItem]];
    [self _moveSpotlightToShowSelectedItem];
}

- (void)handleInputAhead:(CGFloat)ahead side:(CGFloat)side {
    NSInteger currentIndex = [_availableItems indexOfObject:_selectedItem];
    if (ahead) {
        if (fabs(_selectedItem.rotation.w) < MERotLimit) {
            [self rotateWithFactor:ahead];
        } else if ((currentIndex != 0 && ahead < 0) ||
                   (currentIndex != _availableItems.count-1 && ahead > 0)) {
            [self animateBackToInitialStateNode:_selectedItem withDuration:0.66f];
            self.selectedItem = [_availableItems objectAtIndex:ahead > 0 ? currentIndex+1 : currentIndex-1];
        }
    } else {
        [self animateBackToInitialStateNode:_selectedItem withDuration:0.1f];
    }
}

- (void)animateBackToInitialStateNode:(SCNNode *)node withDuration:(NSTimeInterval)duration {
    SCNAction * rotateAction = [SCNAction rotateToAxisAngle:SCNVector4Make(0, 1, 0, 0) duration:duration];
    [node runAction:rotateAction];
}

- (void)rotateWithFactor:(CGFloat)factor {
    if (self.immediateRotation) {
        _selectedItem.rotation = SCNVector4Make(0, 1, 0, MERotLimit*factor*1.1f);
    } else {
        _selectedItem.rotation = SCNVector4Make(0, 1, 0, _selectedItem.rotation.w + MEDeltaRot*factor);
    }
}

- (void)_moveSpotlightToShowSelectedItem {
    SCNAction * translateAction = [SCNAction moveTo:SCNVector3Make(_selectedItem.position.x, _spotlight.position.y, _spotlight.position.z) duration:0.3f];
    [_spotlight runAction:translateAction];
}
@end
