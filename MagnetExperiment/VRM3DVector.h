//
//  VRM3DVector.h
//  VRMagnet
//
//  Created by Thibault Farnier on 30/03/2016.
//
//

#import <Foundation/Foundation.h>
#import "VRMVector.h"
@import CoreMotion;

@interface VRM3DVector : NSObject <VRMVector>
@property (nonatomic) double x;
@property (nonatomic) double y;
@property (nonatomic) double z;

- (instancetype)initWithMagneticField:(CMMagneticField)field;
// designated
- (instancetype)initWithX:(double)x andY:(double)y andZ:(double)z;
@end
