//
//  RCTextView.h
//  RongExtensionKit
//
//  Created by Liv on 14/10/30.
//  Copyright (c) 2014 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RCTextView;

@protocol RCTextViewDelegate <NSObject>

@optional
- (void)rctextView:(RCTextView *)textView textDidChange:(NSString *)text;

@end

/*!
 *  \~chinese
 文本输入框的View
 
 *  \~english
 View of the text input box 
 */
@interface RCTextView : UITextView

/*!
 *  \~chinese
 是否关闭菜单

 @discussion 默认值为NO。
 
 *  \~english
 Whether to close the menu.

 @ discussion The default value is NO.
 */
@property (nonatomic, assign) BOOL disableActionMenu;

@property (nonatomic, weak) id<RCTextViewDelegate> textChangeDelegate;

@end
