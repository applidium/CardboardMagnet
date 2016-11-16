//
//  VRM2DVector.m
//  VRMagnet
//
//  Created by Thibault Farnier on 31/03/2016.
//
//

#import "VRM2DVector.h"

@implementation VRM2DVector
- (instancetype)init {
    return [self initWithX:0.0f andY:0.0f];
}

- (instancetype)initWithX:(double)x andY:(double)y {
    if (self = [super init]) {
        _x = x;
        _y = y;
    }
    return self;
}

- (double)norm {
    return sqrt(pow(_x, 2.0f) + pow(_y, 2.0f));
}

- (double)euclidianDistanceWithVect:(NSObject<VRMVector> *)vect {
    return sqrt(pow(_x-vect.x, 2.0f) + pow(_y-vect.y, 2.0f));
}
@end
