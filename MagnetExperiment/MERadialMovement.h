//
//  MERadialMovement.h
//  MagnetExperiment
//
//  Created by Thibault Farnier on 19/05/2016.
//
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface MERadialMovement : NSObject
+ (vector_float2)newPositionFrom:(vector_float2)initialPosition withInput:(CGFloat)input andRadius:(CGFloat)radius;
+ (float)newAngleFrom:(vector_float2)initialPosition withInput:(CGFloat)input andRadius:(CGFloat)radius;
@end
