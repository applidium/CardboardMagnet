//
//  VRM2DVector.h
//  VRMagnet
//
//  Created by Thibault Farnier on 31/03/2016.
//
//

#import <Foundation/Foundation.h>
#import "VRMVector.h"

@interface VRM2DVector : NSObject <VRMVector>
@property (nonatomic) double x;
@property (nonatomic) double y;

- (instancetype)initWithX:(double)x andY:(double)y;
@end
