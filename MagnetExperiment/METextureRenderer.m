//
//  TextureRenderer.m
//  TestVR
//
//  Created by Andy Qua on 21/09/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "METextureRenderer.h"

@implementation METextureRenderer

- (instancetype)initWithFrameSize:(CGSize)frameSize;
{
    self = [super init];
    if (self) {
        refRoll = -1;
        refYaw = -1;
        refPitch = -1;
    }
    return self;
}

- (void) renderLeftTexture;
{
    
}

- (void) renderRightTexture;
{
    
}

- (void) updateFrameAtTime:(NSTimeInterval)timeSinceLastUpdate;
{
    
}

- (void) resetDevicePosition;
{
    refRoll = -1;
}

- (void) updateDevicePositionWithRoll:(float)roll  yaw:(float)yaw pitch:(float)pitch;
{
   if ( refRoll == -1 )
   {
       refRoll = roll;
       refYaw = yaw;
       refPitch = pitch;
   }
}

- (void) updateCameraPositionsWithDirectionAhead:(float)ahead side:(float)side {
    
}
@end
