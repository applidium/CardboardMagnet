//
//  VRMBicubicInterpolator.m
//  VRMagnet
//
//  Created by Thibault Farnier on 01/04/2016.
//
//

#import "VRMBicubicInterpolator.h"
#import "VRM3DVector.h"
#import "MagnetExperiment.h"

@interface VRMBicubicInterpolator ()
@property (strong, nonatomic) NSArray<NSArray <VRM3DVector *>*> * gridData;
@property (nonatomic) NSInteger lastMatrixPosition1;
@property (nonatomic) NSInteger lastMatrixPosition2;

+ (Matrix *)_bicubicInterpolationFromData:(Matrix *)input toXRes:(int)xRes andToYRes:(int)yRes;
- (VRM2DVector *)_vectorFromGridIndex1:(double)idx1 andIndex2:(double)idx2;
@end

@implementation VRMBicubicInterpolator

- (instancetype)init {
    if (self = [super init]) {
        // iPhone 6 defaults
        NSArray * points = @[[[VRM3DVector alloc] initWithX:490 andY:-144 andZ:-258],
                             [[VRM3DVector alloc] initWithX:371 andY:-139 andZ:-259],
                             [[VRM3DVector alloc] initWithX:317 andY:-125 andZ:-282],
                             [[VRM3DVector alloc] initWithX:805 andY:-24 andZ:-18],
                             [[VRM3DVector alloc] initWithX:436 andY:-135 andZ:-137],
                             [[VRM3DVector alloc] initWithX:323 andY:-135 andZ:-242],
                             [[VRM3DVector alloc] initWithX:803 andY:585 andZ:770],
                             [[VRM3DVector alloc] initWithX:368 andY:-105 andZ:68],
                             [[VRM3DVector alloc] initWithX:291 andY:-142 andZ:-189]];
        self = [self initWith9Points:points];
    }
    return self;
}

- (instancetype)initWith9Points:(NSArray<VRM3DVector *> *)points {
    if (points.count != 9) {
        return nil;
    }
    if (self = [super init]) {
        double xData[9];
        double yData[9];
        double zData[9];
        for (int i=0;i<points.count;++i) {
            xData[i]=points[i].x;
            yData[i]=points[i].y;
            zData[i]=points[i].z;
        }
        Matrix * X = [Matrix matrixFromArray:xData rows:3 columns:3];
        Matrix * Xs = [VRMBicubicInterpolator _bicubicInterpolationFromData:X toXRes:XRes andToYRes:YRes];
        Matrix * Y = [Matrix matrixFromArray:yData rows:3 columns:3];
        Matrix * Ys = [VRMBicubicInterpolator _bicubicInterpolationFromData:Y toXRes:XRes andToYRes:YRes];
        Matrix * Z = [Matrix matrixFromArray:zData rows:3 columns:3];
        Matrix * Zs = [VRMBicubicInterpolator _bicubicInterpolationFromData:Z toXRes:XRes andToYRes:YRes];

        _gridData = [self _createGridWithXs:Xs andYs:Ys andZs:Zs];
        _lastMatrixPosition1 = XRes/2;
        _lastMatrixPosition2 = YRes/2;
    }
    return self;
}

- (VRM2DVector *)positionForMagneticField:(CMMagneticField)field {
    VRM3DVector * magnVect = [[VRM3DVector alloc] initWithMagneticField:field];
    __block VRM2DVector * bestVect = [[VRM2DVector alloc] init];
    __block double bestDist = MAXFLOAT;

    NSInteger interval = 40;
    NSInteger minIdx1 = _lastMatrixPosition1-interval <= 0 ? 0 : _lastMatrixPosition1-interval;
    NSInteger minIdx2 = _lastMatrixPosition2-interval <= 0 ? 0 : _lastMatrixPosition2-interval;
    NSInteger maxIdx1 = _lastMatrixPosition1+interval>_gridData.count ? _gridData.count : _lastMatrixPosition1+interval;
    NSInteger maxIdx2 = _lastMatrixPosition2+interval>_gridData.count ? _gridData.count : _lastMatrixPosition2+interval;

    for (NSInteger idx1=minIdx1; idx1<maxIdx1; ++idx1) {
        for (NSInteger idx2=minIdx2; idx2<maxIdx2; ++idx2) {
            double currDist = [magnVect euclidianDistanceWithVect:_gridData[idx1][idx2]];
            if (currDist < bestDist) {
                bestDist = currDist;
                bestVect = [self _vectorFromGridIndex1:idx1 andIndex2:idx2];
                _lastMatrixPosition1 = idx1;
                _lastMatrixPosition2 = idx2;
            }
        }
    }
    
    return bestVect;
}

// thanks to http://www.giassa.net/?page_id=371
+ (Matrix *)_bicubicInterpolationFromData:(Matrix *)I toXRes:(int)xRes andToYRes:(int)yRes {
    static double M_Inv[256]=
    { 1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,
        -3,3,0,0,-2,-1,0,0,0,0,0,0,0,0,0,0,
        2,-2,0,0,1,1,0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,
        0,0,0,0,0,0,0,0,-3,3,0,0,-2,-1,0,0,
        0,0,0,0,0,0,0,0,2,-2,0,0,1,1,0,0,
        -3,0,3,0,0,0,0,0,-2,0,-1,0,0,0,0,0,
        0,0,0,0,-3,0,3,0,0,0,0,0,-2,0,-1,0,
        9,-9,-9,9,6,3,-6,-3,6,-6,3,-3,4,2,2,1,
        -6,6,6,-6,-3,-3,3,3,-4,4,-2,2,-2,-2,-1,-1,
        2,0,-2,0,0,0,0,0,1,0,1,0,0,0,0,0,
        0,0,0,0,2,0,-2,0,0,0,0,0,1,0,1,0,
        -6,6,6,-6,-4,-2,4,2,-3,3,-3,3,-2,-1,-2,-1,
        4,-4,-4,4,2,2,-2,-2,2,-2,2,-2,1,1,1,1};
    Matrix * MInv =[Matrix matrixFromArray:M_Inv rows:16 columns:16];

    int j = I.rows;
    int k = I.columns;

    double xScale = xRes/(j-1);
    double yScale = yRes/(k-1);

    // result matrix
    Matrix * temp = [Matrix matrixOfRows:xRes columns:yRes value:0.0f];

    // derivatives
    Matrix * Ix = [Matrix matrixOfRows:j columns:k value:0.0f];
    for (int count1=0;count1<j;++count1) {
        for (int count2=0;count2<k;++count2) {
            // border case
            if (count1==0 || count1==j-1) {
                [Ix setValue:0.0f row:count1 column:count2];
            } else {
                [Ix setValue:0.5f*([I valueAtRow:count1+1 column:count2]-[I valueAtRow:count1-1 column:count2]) row:count1 column:count2];
            }
        }
    }

    Matrix * Iy = [Matrix matrixOfRows:j columns:k value:0.0f];
    for (int count1=0;count1<j;++count1) {
        for (int count2=0;count2<k;++count2) {
            // border case
            if (count2==0 || count2==k-1) {
                [Iy setValue:0.0f row:count1 column:count2];
            } else {
                [Iy setValue:0.5f*([I valueAtRow:count1 column:count2+1]-[I valueAtRow:count1 column:count2-1]) row:count1 column:count2];
            }
        }
    }

    // cross derivatives
    Matrix * Ixy = [Matrix matrixOfRows:j columns:k value:0.0f];
    for (int count1=0;count1<j;++count1) {
        for (int count2=0;count2<k;++count2) {
            // border case
            if (count1==0 || count1==j-1 || count2==0 || count2==k-1) {
                [Ixy setValue:0.0f row:count1 column:count2];
            } else {
                [Ixy setValue: 0.25f*(([I valueAtRow:count1+1 column:count2+1]+[I valueAtRow:count1-1 column:count2-1])
                                    - ([I valueAtRow:count1+1 column:count2-1]+[I valueAtRow:count1-1 column:count2+1]))
                         row:count1 column:count2];
            }
        }
    }

    // output generation
    for (int count1=0; count1<=xRes-1; ++count1) {
        for (int count2=0; count2<=yRes-1; ++count2) {
            double w = -(((count1/xScale)-floor(count1/xScale))-1);
            double h = -(((count2/yScale)-floor(count2/yScale))-1);

            // DBL_EPSILON is used because ceil(0)==0
            double I11_index[2] = {floor(count1/xScale),floor(count2/yScale)};
            double I21_index[2] = {floor(count1/xScale),ceil(count2/yScale+DBL_EPSILON)};
            double I12_index[2] = {ceil(count1/xScale+DBL_EPSILON),floor(count2/yScale)};
            double I22_index[2] = {ceil(count1/xScale+DBL_EPSILON),ceil(count2/yScale+DBL_EPSILON)};

            double I11 = [I valueAtRow:I11_index[0] column:I11_index[1]];
            double I21 = [I valueAtRow:I21_index[0] column:I21_index[1]];
            double I12 = [I valueAtRow:I12_index[0] column:I12_index[1]];
            double I22 = [I valueAtRow:I22_index[0] column:I22_index[1]];

            double Ix11 = [Ix valueAtRow:I11_index[0] column:I11_index[1]];
            double Ix21 = [Ix valueAtRow:I21_index[0] column:I21_index[1]];
            double Ix12 = [Ix valueAtRow:I12_index[0] column:I12_index[1]];
            double Ix22 = [Ix valueAtRow:I22_index[0] column:I22_index[1]];

            double Iy11 = [Iy valueAtRow:I11_index[0] column:I11_index[1]];
            double Iy21 = [Iy valueAtRow:I21_index[0] column:I21_index[1]];
            double Iy12 = [Iy valueAtRow:I12_index[0] column:I12_index[1]];
            double Iy22 = [Iy valueAtRow:I22_index[0] column:I22_index[1]];

            double Ixy11 = [Ixy valueAtRow:I11_index[0] column:I11_index[1]];
            double Ixy21 = [Ixy valueAtRow:I21_index[0] column:I21_index[1]];
            double Ixy12 = [Ixy valueAtRow:I12_index[0] column:I12_index[1]];
            double Ixy22 = [Ixy valueAtRow:I22_index[0] column:I22_index[1]];

            double beta_array[16] = {I11,I21,I12,I22,Ix11,Ix21,Ix12,Ix22,Iy11,Iy21,Iy12,Iy22,Ixy11,Ixy21,Ixy12,Ixy22};
            Matrix * beta = [Matrix matrixFromArray:beta_array rows:16 columns:1];
            Matrix * alpha = [MInv matrixByMultiplyingWithRight:beta];

            double temp_p = 0.0f;
            for (int count3=0; count3<16; ++count3) {
                double w_temp = floor(count3/4);
                double h_temp = count3 % 4;
                temp_p += [alpha valueAtRow:count3 column:0] * (pow(1-w,w_temp))*pow(1-h,h_temp);
            }
            [temp setValue:temp_p row:count1 column:count2];
        }
    }
    
    return temp;
}

- (NSArray<NSArray *> *)_createGridWithXs:(Matrix *)Xs
                                    andYs:(Matrix *)Ys
                                    andZs:(Matrix *)Zs {
    NSMutableArray<NSMutableArray *> * grid = [NSMutableArray arrayWithCapacity:Xs.rows];
    for (int i=0;i<Xs.rows;++i) {
        grid[i] = [NSMutableArray arrayWithCapacity:Xs.rows];
        for (int j=0;j<Xs.rows;++j) {
            grid[i][j] = [[VRM3DVector alloc] initWithX:[Xs valueAtRow:i column:j] andY:[Ys valueAtRow:i column:j] andZ:[Zs valueAtRow:i column:j]];
        }
    }
    return grid;
}

- (VRM2DVector *)_vectorFromGridIndex1:(double)idx1 andIndex2:(double)idx2 {
    double x = -1 + idx2 * 2.0f/((double)_gridData.count-1.0f);
    double y = 1 - idx1 * 2.0f/((double)_gridData.count-1.0f);
    return [[VRM2DVector alloc] initWithX:x andY:y];
}
@end
