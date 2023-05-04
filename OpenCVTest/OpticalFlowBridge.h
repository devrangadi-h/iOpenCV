//
//  OpticalFlowBridge.h
//  OpenCVTest
//
//  Created by Hardik Devrangadi on 5/3/23.
//

#ifndef OpticalFlowBridge_h
#define OpticalFlowBridge_h

//
//  LaneDetectorBridge.h
//  SimpleLaneDetection
//
//  Created by Anurag Ajwani on 28/04/2019.
//  Copyright © 2019 Anurag Ajwani. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface LaneDetectorBridge : NSObject
    
- (UIImage *) detectLaneIn: (UIImage *) image;
    
@end

#endif /* OpticalFlowBridge_h */
