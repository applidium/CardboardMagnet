//
//  MEViewController.h
//  MagnetExperiment
//
//  Created by Thibault Farnier on 25/07/2016.
//  Copyright © 2016 Thibault Farnier. All rights reserved.
//

#import <GLKit/GLKit.h>
@class VRMBicubicInterpolator;

@interface MEGameViewController : GLKViewController
- (instancetype)initWithSceneNamed:(NSString *)sceneName andInterpolator:(VRMBicubicInterpolator *)interpolator;
@end

