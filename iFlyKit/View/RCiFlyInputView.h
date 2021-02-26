//
//  RCiFlyInputView.h
//  RongiFlyKit
//
//  Created by Sin on 16/11/16.
//  Copyright © 2016年 Sin. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol RCiFlyInputViewDelegate;
@interface RCiFlyInputView : UIView
+ (instancetype)iFlyInputViewWithFrame:(CGRect)frame;

@property (nonatomic, weak) id<RCiFlyInputViewDelegate> delegate;

- (void)show:(BOOL)isShow inputBarWidth:(CGFloat)inputBarWidth;

- (void)showBottom:(BOOL)isShow;

- (void)stopListening;

@end
@protocol RCiFlyInputViewDelegate <NSObject>

- (void)clearText;

- (void)sendText;

- (void)voiceTransferToText:(NSString *)text;

- (void)onError:(NSString *)errDesc;

@end
