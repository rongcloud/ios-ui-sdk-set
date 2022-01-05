//
//  RCEmoticonTabSource.h
//  RongExtensionKit
//
//  Created by litao on 16/9/13.
//  Copyright © 2016 RongCloud. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 *  \~chinese
 自定义表情view数据源代理
 
 *  \~english
 Custom emoji view data source agent 
 */
@protocol RCEmoticonTabSource <NSObject>

/*!
 *  \~chinese
 表情tab的标识符
 @return 表情tab的标识符，请勿重复
 
 *  \~english
 Identifier of the emoji tab.
 @ return the identifier of the emoji tab. Do not repeat it.
 */
- (NSString *)identify;

/*!
 *  \~chinese
 表情tab的图标
 @return 表情tab的图标
 
 *  \~english
 Emoji tab icon.
 @ return emoji tab icon
 */
- (UIImage *)image;

/*!
 *  \~chinese
 表情tab的页数
 @return 表情tab的页数
 
 *  \~english
 Number of pages of emoji tab.
 @ return the number of pages of the emoji tab
 */
- (int)pageCount;
/*!
 *  \~chinese
 表情tab的index页的表情View

 @return 表情tab的index页的表情View
 @discussion 返回的 view 大小必须等于 contentViewSize （宽度 = 屏幕宽度，高度 = 186）
 
 *  \~english
 The emoji View of the index page of the emoji tab.

 @ return emoji View on tab's index page.
 @ discussion The returned view size  must be equal to contentViewSize (width = screen width, height = 186).
 */
- (UIView *)loadEmoticonView:(NSString *)identify index:(int)index;
@end
