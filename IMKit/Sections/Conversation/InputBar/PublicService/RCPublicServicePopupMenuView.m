//
//  RCPublicServicePopupMenuView.m
//  RongExtensionKit
//
//  Created by litao on 15/6/17.
//  Copyright (c) 2015年 RongCloud. All rights reserved.
//

#import "RCPublicServicePopupMenuView.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"
#import <RongPublicService/RongPublicService.h>
@interface RCPublicServicePopupMenuView () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) NSArray *menuItems;        // RCPublicServiceMenuItem
@property (nonatomic, strong) NSMutableArray *itemViews; // UILabel
@property (nonatomic, strong) UIImageView *backgroundImageView;
@end

#define RC_PUBLIC_SERVICE_MENU_ITEM_HEIGHT 44
#define RC_PUBLIC_SERVICE_MENU_MARGIN_BOTTOM (3 + 6) //按钮区域底部与绘制边框间距离加尖头高度
#define RC_PUBLIC_SERVICE_MENU_MARGIN_TOP 3          //按钮区域顶部与绘制边框间距离
#define RC_PUBLIC_SERVICE_MENU_ITEM_PENDING_LEFT 8
#define RC_PUBLIC_SERVICE_MENU_ITEM_PENDING_RIGHT 8
#define RC_PUBLIC_SERVICE_MENU_PADDING_BOTTOM 4
#define RC_PUBLIC_SERVICE_MENU_ITEM_SEPARATE_PENDING_LEFT 6
#define RC_PUBLIC_SERVICE_MENU_ITEM_SEPARATE_PENDING_RIGHT 6
#define RC_PUBLIC_SERVICE_MENU_ITEM_WIDTH 166
#define RC_PUBLIC_SERVICE_MENU_SEPARATOR_HEIGHT 0.5

@implementation RCPublicServicePopupMenuView
#pragma mark - Life Cycle
- (void)awakeFromNib {
    [super awakeFromNib];
    if (self) {
        [self setup];
    }
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    self.backgroundImageView.frame = self.bounds;
}

#pragma mark - Gesture Selector
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    CGPoint point = [touch locationInView:self];
    if (CGRectContainsPoint(self.backgroundImageView.frame, point)) {
        return NO;
    }
    return YES;
}

- (void)tapAction:(UITapGestureRecognizer *)recognizer {
    [self resignFirstResponder];
}

#pragma mark - Private Methods

- (void)setup {
    self.layer.cornerRadius = 5;
    self.layer.masksToBounds = YES;
    self.backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    [self addSubview:self.backgroundImageView];
    self.backgroundImageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture =
        [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    tapGesture.delegate = self;
    [self addGestureRecognizer:tapGesture];
}

- (void)removeAllSubItems {
    for (UIView *subView in self.itemViews) {
        [subView removeFromSuperview];
    }
    [self.itemViews removeAllObjects];
    CGRect frame = self.frame;
    frame.size.height = 0;
    self.frame = frame;
}
- (void)displayMenuItems:(NSArray *)menuItems atPoint:(CGPoint)point withWidth:(CGFloat)width {
    self.menuItems = menuItems;
    if (![menuItems count]) {
        return;
    }
    CGFloat superviewWidth = self.superview.frame.size.width;
    CGFloat selfHeight = point.y;
    CGFloat maxWidth = RC_PUBLIC_SERVICE_MENU_ITEM_WIDTH;
    if (maxWidth > RC_PUBLIC_SERVICE_MENU_ITEM_WIDTH)
        maxWidth = RC_PUBLIC_SERVICE_MENU_ITEM_WIDTH;
    point.y -= RC_PUBLIC_SERVICE_MENU_PADDING_BOTTOM;
    CGFloat height = menuItems.count * RC_PUBLIC_SERVICE_MENU_ITEM_HEIGHT +
                     (menuItems.count - 1) * RC_PUBLIC_SERVICE_MENU_SEPARATOR_HEIGHT +
                     RC_PUBLIC_SERVICE_MENU_MARGIN_TOP + RC_PUBLIC_SERVICE_MENU_MARGIN_BOTTOM;
    CGRect frame = CGRectMake(point.x + (width - maxWidth) / 2, point.y, maxWidth, height);
    self.frame = CGRectMake(0, 0, superviewWidth, selfHeight);
    self.backgroundImageView.frame = frame;
    CGFloat arrowOffset = frame.size.width / 2 - 6;
    if (CGRectGetMaxX(self.backgroundImageView.frame) >= superviewWidth) {
        CGFloat originX = frame.origin.x;
        frame.origin.x = superviewWidth - maxWidth - 8;
        self.backgroundImageView.frame = frame;
        arrowOffset = arrowOffset + originX - frame.origin.x;
    }
    UIImage *image = [self drawPopoverImage:frame.size arrowOffset:arrowOffset];
    self.backgroundImageView.image = image;

    frame.origin.y -= height;
    self.backgroundImageView.frame = frame;

    for (UIView *subView in self.itemViews) {
        [subView removeFromSuperview];
    }
    [self.itemViews removeAllObjects];

    for (int i = 0; i < self.menuItems.count; i++) {
        if (i != 0) {
            UIView *line = [self newLine];
            line.frame = CGRectMake(RC_PUBLIC_SERVICE_MENU_ITEM_SEPARATE_PENDING_LEFT,
                                    (i * RC_PUBLIC_SERVICE_MENU_ITEM_HEIGHT) + RC_PUBLIC_SERVICE_MENU_MARGIN_TOP,
                                    maxWidth - RC_PUBLIC_SERVICE_MENU_ITEM_SEPARATE_PENDING_LEFT -
                                        RC_PUBLIC_SERVICE_MENU_ITEM_SEPARATE_PENDING_RIGHT,
                                    RC_PUBLIC_SERVICE_MENU_SEPARATOR_HEIGHT);
            [self.backgroundImageView addSubview:line];
        }
        RCPublicServiceMenuItem *menuItem = self.menuItems[i];
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(RC_PUBLIC_SERVICE_MENU_ITEM_PENDING_LEFT,
                                                                   (i * RC_PUBLIC_SERVICE_MENU_ITEM_HEIGHT) +
                                                                       RC_PUBLIC_SERVICE_MENU_SEPARATOR_HEIGHT * i +
                                                                       RC_PUBLIC_SERVICE_MENU_MARGIN_TOP,
                                                                   maxWidth - RC_PUBLIC_SERVICE_MENU_ITEM_PENDING_LEFT -
                                                                       RC_PUBLIC_SERVICE_MENU_ITEM_PENDING_RIGHT,
                                                                   RC_PUBLIC_SERVICE_MENU_ITEM_HEIGHT)];
        [btn setTitle:menuItem.name forState:UIControlStateNormal];
        UIColor *titleColor = [RCKitUtility generateDynamicColor:HEXCOLOR(0x5f5f5f) darkColor:RCMASKCOLOR(0xffffff, 0.8)];
        [btn setTitleColor:titleColor forState:UIControlStateNormal];
        [btn.titleLabel setFont:[[RCKitConfig defaultConfig].font fontOfFourthLevel]];
        btn.tag = i;
        [self.itemViews addObject:btn];
        [btn setBackgroundColor:RCDYCOLOR(0xffffff, 0x1c1c1c)];
        [self.backgroundImageView addSubview:btn];
        [btn addTarget:self action:@selector(onMenuButtonPressed:) forControlEvents:UIControlEventTouchDown];
    }
}

- (BOOL)resignFirstResponder {
    [super resignFirstResponder];
    [self removeAllSubItems];
    CGRect frame = self.frame;
    frame.origin.y += frame.size.height;
    self.frame = frame;
    return YES;
}
- (void)onMenuButtonPressed:(id)sender {
    UIButton *btn = sender;
    RCPublicServiceMenuItem *selectedItem = self.menuItems[btn.tag];
    [self resignFirstResponder];
    if ([self.delegate respondsToSelector:@selector(onPublicServiceMenuItemSelected:)]) {
        [self.delegate onPublicServiceMenuItemSelected:selectedItem];
    }
}

- (UIImage *)drawPopoverImage:(CGSize)size arrowOffset:(NSUInteger)offset {
    const CGSize arrowSize = (CGSize){12, 6};
    const CGFloat arrowOffsetMin = 16;
    const CGFloat arrowOffsetMax = size.width - 8;
    const CGFloat radius = 6;
    CGFloat lineWidth = 0.5;
    CGFloat margin = 1;
    if (offset < arrowOffsetMin) {
        offset = arrowOffsetMin;
    } else if (offset > arrowOffsetMax) {
        offset = arrowOffsetMax;
    }

    UIColor *fillColor = RCDYCOLOR(0xffffff, 0x1c1c1c);
    UIColor *strokeColor = RCDYCOLOR(0xffffff, 0x1c1c1c);;

    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGContextBeginTransparencyLayer(context, nil);
    CGFloat startX = arrowSize.width / 2 + offset - margin;
    UIBezierPath *path = [UIBezierPath bezierPath];
    path.lineWidth = lineWidth;
    path.lineJoinStyle = kCGLineJoinMiter;
    path.lineCapStyle = kCGLineCapSquare;

    [path moveToPoint:CGPointMake(margin + lineWidth, radius + margin + lineWidth)];
    [path addArcWithCenter:CGPointMake(margin + radius + lineWidth, radius + margin + lineWidth)
                    radius:radius
                startAngle:M_PI
                  endAngle:-0.5 * M_PI
                 clockwise:YES];
    [path addLineToPoint:CGPointMake(size.width - radius - lineWidth - margin, margin + lineWidth)];
    [path addArcWithCenter:CGPointMake(size.width - radius - lineWidth - margin, radius + lineWidth + margin)
                    radius:radius
                startAngle:-0.5 * M_PI
                  endAngle:0
                 clockwise:YES];
    [path addLineToPoint:CGPointMake(size.width - margin - lineWidth,
                                     size.height - radius - margin - lineWidth - arrowSize.height)];
    [path addArcWithCenter:CGPointMake(size.width - radius - lineWidth - margin,
                                       size.height - radius - margin - lineWidth - arrowSize.height)
                    radius:radius
                startAngle:0
                  endAngle:0.5 * M_PI
                 clockwise:YES];
    [path
        addLineToPoint:CGPointMake(startX + arrowSize.width / 2, size.height - margin - lineWidth - arrowSize.height)];
    [path addLineToPoint:CGPointMake(startX, size.height - margin)];
    [path
        addLineToPoint:CGPointMake(startX - arrowSize.width / 2, size.height - margin - lineWidth - arrowSize.height)];
    [path addLineToPoint:CGPointMake(margin + radius + lineWidth, size.height - margin - lineWidth - arrowSize.height)];
    [path addArcWithCenter:CGPointMake(margin + radius + lineWidth,
                                       size.height - radius - margin - lineWidth - arrowSize.height)
                    radius:radius
                startAngle:0.5 * M_PI
                  endAngle:M_PI
                 clockwise:YES];
    [path moveToPoint:CGPointMake(margin + lineWidth, size.height - radius - margin - lineWidth - arrowSize.height)];
    [path addLineToPoint:CGPointMake(margin + lineWidth, margin + radius + lineWidth)];

    path.miterLimit = 1;
    path.usesEvenOddFillRule = YES;
    [strokeColor setStroke];
    [fillColor setFill];
    [path fill];
    [path stroke];
    [path closePath];

    CGContextSetLineCap(context, kCGLineCapSquare);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    CGContextSetShouldAntialias(context, YES);
    CGContextSetAllowsAntialiasing(context, YES);
    CGContextSetLineWidth(context, lineWidth);
    CGContextSetFlatness(context, 1);
    CGContextFillPath(context);
    CGContextStrokePath(context);
    CGContextEndTransparencyLayer(context);
    CGContextRestoreGState(context);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

#pragma mark - Getters and Setters

- (NSMutableArray *)itemViews {
    if (!_itemViews) {
        _itemViews = [[NSMutableArray alloc] init];
    }
    return _itemViews;
}

- (UIView *)newLine {
    UIView *line = [UIView new];
    line.backgroundColor = [RCKitUtility
        generateDynamicColor:[UIColor colorWithRed:216 / 255.0f green:216 / 255.0f blue:216 / 255.0f alpha:1]
                   darkColor:HEXCOLOR(0x292929)];
    return line;
}

@end
