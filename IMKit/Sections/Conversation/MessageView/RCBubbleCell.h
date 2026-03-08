//
//  RCBubbleCell.h
//  RongCloudOpenSource
//
//  Created by jory on 2023/4/19.
//

#import <UIKit/UIKit.h>
#import <SVGAPlayer/SVGAImageView.h>

///RCBubbleCell
@interface RCBubbleCell : UIView<SVGAImageViewDelegate>

/// 是否有VIP气泡
/// - Parameter dict: 气泡配置数据
- (BOOL)updateBubble:(NSDictionary *)dict;

- (void)updateSize:(CGSize)size;

- (void)stopAllAnimation;

@end
