//
//  TextureRenderer.h
//  TestVR
//
//  Created by Andy Qua on 21/09/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface METextureRenderer : NSObject
{
    float refYaw;
    float refPitch;
    float refRoll;
}
- (instancetype)initWithFrameSize:(CGSize)frameSize;

- (void) renderLeftTexture;
- (void) renderRightTexture;
- (void) updateFrameAtTime:(NSTimeInterval)timeSinceLastUpdate;
- (void) resetDevicePosition;
- (void) updateDevicePositionWithRoll:(float)roll  yaw:(float)yaw pitch:(float)pitch;
- (void) updateCameraPositionsWithDirectionAhead:(float)ahead side:(float)side;

@end
