//
//  VRMVector.h
//  VRMagnet
//
//  Created by Thibault Farnier on 31/03/2016.
//
//

#import <Foundation/Foundation.h>

@protocol VRMVector <NSObject>
- (double)norm;
- (double)euclidianDistanceWithVect:(NSObject<VRMVector> *)vect;
- (double)x;
- (double)y;
@optional
- (double)z;
@end
