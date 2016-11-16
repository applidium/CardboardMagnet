
//
//  VRM3DVector.m
//  VRMagnet
//
//  Created by Thibault Farnier on 30/03/2016.
//
//

#import "VRM3DVector.h"

@implementation VRM3DVector
- (instancetype)init {
    return [self initWithX:0.0f andY:0.0f andZ:0.0f];
}

- (instancetype)initWithMagneticField:(CMMagneticField)field {
    return [self initWithX:field.x andY:field.y andZ:field.z];
}

- (instancetype)initWithX:(double)x andY:(double)y andZ:(double)z {
    if (self = [super init]) {
        _x = x;
        _y = y;
        _z = z;
    }
    return self;
}

- (double)norm {
    return sqrt(pow(_x, 2.0f) + pow(_y, 2.0f) + pow(_z, 2.0f));
}

- (double)euclidianDistanceWithVect:(NSObject<VRMVector> *)vect {
    VRM3DVector * vect3D = (VRM3DVector *) vect;
    return sqrt(pow(_x-vect3D.x, 2.0f) + pow(_y-vect3D.y, 2.0f) + pow(_z-vect3D.z, 2.0f));
}
@end
