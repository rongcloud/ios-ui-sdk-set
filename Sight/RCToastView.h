//
//  RCToastView.h
//  RongExtensionKit
//
//  Created by chinaspx on 2022/5/19.
//  Copyright © 2022 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RCToastView : UIView

/**
 *  展示Toast,传入字符串
 *  @param toastString 显示的字符串
 *  @param rootView 显示的父视图
 */
+ (void)showToast:(NSString *)toastString rootView:(UIView *)rootView;

@end
