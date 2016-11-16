//
//  MEMenuSceneHandler.h
//  MagnetExperiment
//
//  Created by Thibault Farnier on 20/05/2016.
//
//

#import <Foundation/Foundation.h>
@import SceneKit;

@protocol MEMenuSceneHandlerDelegate <NSObject>
- (void)didChangeToIndex:(NSUInteger)index;
@end

@interface MEMenuSceneHandler : NSObject
@property (strong, nonatomic) SCNScene * menuScene;
@property (weak, nonatomic) id<MEMenuSceneHandlerDelegate> delegate;
@property (nonatomic) BOOL immediateRotation;

- (instancetype)initWithScene:(SCNScene *)scene;
- (void)handleInputAhead:(CGFloat)ahead side:(CGFloat)side;
@end
