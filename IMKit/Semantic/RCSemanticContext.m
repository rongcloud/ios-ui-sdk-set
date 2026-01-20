//
//  RCSemanticContext.m
//  RongIMKit
//
//  Created by RobinCui on 2022/9/6.
//  Copyright © 2022 RongCloud. All rights reserved.
//

#import "RCSemanticContext.h"
#import <UIKit/UIKit.h>
#import "RCKitUtility.h"
@implementation RCSemanticContext

+ (BOOL)isRTL {
    return [RCKitUtility isRTL];
}

+ (void)configureAttributeForNavigationController:(UINavigationController *)navi {
    if (@available(iOS 9.0, *)) {
        if ([self isRTL]) {
            navi.navigationBar.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;;
            navi.view.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
        } else {
            navi.navigationBar.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;;
            navi.view.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
        }
    }
}

+ (UIImage *)imageflippedForRTL:(UIImage *)image
{
    if (@available(iOS 9.0, *)) {
        if ([self isRTL]) {
            return [UIImage imageWithCGImage:image.CGImage
                                       scale:image.scale
                                 orientation:UIImageOrientationUpMirrored];
        }
    }
    return image;
}

+ (CGRect)modifyFrameForRTL:(CGRect)frame toX:(CGFloat)x {
    if (@available(iOS 9.0, *)) {
        if ([self isRTL]) {
            CGRect rect = CGRectMake(x,
                                     frame.origin.y,
                                     frame.size.width,
                                     frame.size.height);
            return rect;
        }
    }
    return frame;
}

+ (void)swapFrameForRTL:(UIView *)firstView withView:(UIView *)secondView {
    
    if (@available(iOS 9.0, *)) {
        if ([self isRTL]) {
            CGRect rect = firstView.frame;
            
            firstView.frame =  CGRectMake(secondView.frame.origin.x,
                                          firstView.frame.origin.y,
                                          firstView.frame.size.width,
                                          firstView.frame.size.height);
            secondView.frame =  CGRectMake(rect.origin.x,
                                          secondView.frame.origin.y,
                                          secondView.frame.size.width,
                                          secondView.frame.size.height);
        }
    }
}
@end
