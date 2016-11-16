//
//  VRMBicubicInterpolator.h
//  VRMagnet
//
//  Created by Thibault Farnier on 01/04/2016.
//
//

#import <Foundation/Foundation.h>
#import "YCMatrix.h"
#import "VRM3DVector.h"
#import "VRM2DVector.h"
@import CoreMotion;

@interface VRMBicubicInterpolator : NSObject

// Designated initializer
// This method takes points on a 9-point grid, in the following order:
// | 1  2  3 |
// | 4  5  6 |
// | 7  8  9 |
// [5] is to be located at the center position (0,0)
- (instancetype)initWith9Points:(NSArray<VRM3DVector *>*)points;

- (VRM2DVector *)positionForMagneticField:(CMMagneticField)field;
@end
