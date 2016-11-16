//
//  MERadialMovement.m
//  MagnetExperiment
//
//  Created by Thibault Farnier on 19/05/2016.
//
//

#import "MERadialMovement.h"

static const CGFloat MEDisplacementPercentagePerMove = 0.10f;

@implementation MERadialMovement
+ (vector_float2)newPositionFrom:(vector_float2)initialPosition withInput:(CGFloat)input andRadius:(CGFloat)radius {
    CGFloat deltaTheta = M_2_PI * MEDisplacementPercentagePerMove * [self roundToOne:input];
    CGFloat theta = 0.0f;
    if (initialPosition[0] != 0) {
        theta = atan(initialPosition[1]/initialPosition[0]);
    } else {
        theta = (initialPosition[1] > 0) ? M_PI_2 : -M_PI_2;
    }
    if (initialPosition[0] < 0) {
        theta -= M_PI;
    }
    if ((theta > 0 && deltaTheta > 0) || (deltaTheta < 0 && theta < - M_PI)) {
        deltaTheta = 0;
    }
    vector_float2 res = {radius * cos(theta + deltaTheta), radius * sin(theta + deltaTheta)};
    return res;
}

+ (float)newAngleFrom:(vector_float2)initialPosition withInput:(CGFloat)input andRadius:(CGFloat)radius {
    CGFloat theta = 0.0f;
    if (initialPosition[0] != 0) {
        theta = atan(initialPosition[1]/initialPosition[0]);
    } else {
        theta = (initialPosition[1] > 0) ? M_PI_2 : -M_PI_2;
    }
    if (initialPosition[0] < 0) {
        theta -= M_PI;
    }
    return theta + M_PI_2;
}

+ (CGFloat)roundToOne:(CGFloat)value {
    if (value == 0) {
        return value;
    }
    return value > 0 ? 1.0f : -1.0f;
}
@end
