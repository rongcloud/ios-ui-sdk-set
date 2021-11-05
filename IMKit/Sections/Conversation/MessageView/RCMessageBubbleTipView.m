//
//  RCMessageBubbleTipView.m
//  RCIM
//
//  Created by Heq.Shinoda on 14-6-20.
//  Copyright (c) 2014年 Heq.Shinoda. All rights reserved.
//

#import "RCMessageBubbleTipView.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"

#define kDefaultbubbleTipTextColor [UIColor whiteColor]
#define kDefaultbubbleTipBackgroundColor [UIColor redColor]

#define kDefaultbubbleTipTextFont [UIFont systemFontOfSize:[UIFont smallSystemFontSize]]

#define kDefaultbubbleTipShadowColor [UIColor clearColor]

#define kbubbleTipStrokeColor [UIColor whiteColor]
#define kbubbleTipStrokeWidth 0.0f

#define kMarginToDrawInside (kbubbleTipStrokeWidth * 2)

#define kShadowOffset CGSizeMake(0.0f, 3.0f)
#define kShadowOpacity 0.2f
#define kShadowColor [UIColor colorWithWhite:0.0f alpha:kShadowOpacity]
#define kShadowRadius 1.0f

#define kbubbleTipHeight 16.0f
#define kbubbleTipTextSideMargin 6.0f

#define kbubbleTipCornerRadius 10.0f

#define kDefaultbubbleTipAlignment RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_TOP_RIGHT

@interface RCMessageBubbleTipView ()
@property (NS_NONATOMIC_IOSONLY, readonly) CGSize sizeOfTextForCurrentSettings;
@property (nonatomic, assign) int msgCount;
@end

@implementation RCMessageBubbleTipView
#pragma mark - Life Cycle
- (void)awakeFromNib {
    [super awakeFromNib];
    [self _init];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self _init];
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    BOOL anyTextToDraw = (self.bubbleTipText.length > 0);

    if (!self.isShowNotificationNumber)
        [self setBubbleTipText:@" "];

    if (anyTextToDraw) {
        CGContextRef ctx = UIGraphicsGetCurrentContext();

        CGRect rectToDraw = CGRectInset(rect, kMarginToDrawInside, kMarginToDrawInside);

        UIBezierPath *borderPath =
            [UIBezierPath bezierPathWithRoundedRect:rectToDraw
                                  byRoundingCorners:(UIRectCorner)UIRectCornerAllCorners
                                        cornerRadii:CGSizeMake(kbubbleTipCornerRadius, kbubbleTipCornerRadius)];

        /* Background and shadow */
        CGContextSaveGState(ctx);
        {
            CGContextAddPath(ctx, borderPath.CGPath);

            CGContextSetFillColorWithColor(ctx, self.bubbleTipBackgroundColor.CGColor);
            // CGContextSetShadowWithColor(ctx, kShadowOffset, kShadowRadius, kShadowColor.CGColor);

            CGContextDrawPath(ctx, kCGPathFill);
        }
        CGContextRestoreGState(ctx);

        /* Stroke */
        CGContextSaveGState(ctx);
        {
            CGContextAddPath(ctx, borderPath.CGPath);

            CGContextSetLineWidth(ctx, kbubbleTipStrokeWidth);
            CGContextSetStrokeColorWithColor(ctx, kbubbleTipStrokeColor.CGColor);

            CGContextDrawPath(ctx, kCGPathStroke);
        }
        CGContextRestoreGState(ctx);

        /* Text */
        CGContextSaveGState(ctx);
        {
            CGContextSetFillColorWithColor(ctx, self.bubbleTipTextColor.CGColor);
            CGContextSetShadowWithColor(ctx, self.bubbleTipTextShadowOffset, 1.0,
                                        self.bubbleTipTextShadowColor.CGColor);
            
            CGRect textFrame = rectToDraw;
            CGSize textSize = [self sizeOfTextForCurrentSettings];
            
            textFrame.size.height = textSize.height;
            textFrame.origin.y = rectToDraw.origin.y + (rectToDraw.size.height - textFrame.size.height) / 2.0f;
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            paragraphStyle.lineBreakMode = NSLineBreakByCharWrapping;
            paragraphStyle.alignment = NSTextAlignmentCenter;
            
            [self.bubbleTipText drawInRect:textFrame
                            withAttributes:@{
                                NSFontAttributeName : self.bubbleTipTextFont,
                                NSForegroundColorAttributeName : self.bubbleTipTextColor,
                                NSParagraphStyleAttributeName : paragraphStyle
                            }];
        }
        CGContextRestoreGState(ctx);
    }
}

- (void)layoutSubviews{
    [super layoutSubviews];
    if (self.msgCount == 0) {
        [self setHidden:YES];
        return;
    }
    // return;
    CGRect newFrame = self.frame;
    CGRect superviewFrame =
        CGRectIsEmpty(_frameToPositionInRelationWith) ? self.superview.frame : _frameToPositionInRelationWith;

    CGFloat textWidth = [self sizeOfTextForCurrentSettings].width;

    CGFloat viewWidth = textWidth + kbubbleTipTextSideMargin + (kMarginToDrawInside * 2);
    CGFloat viewHeight = kbubbleTipHeight + (kMarginToDrawInside * 2);
    // viewWidth = viewWidth;

    CGFloat superviewWidth = superviewFrame.size.width;
    CGFloat superviewHeight = superviewFrame.size.height;

    if (self.isShowNotificationNumber) {
        newFrame.size.width = viewWidth;
        newFrame.size.height = viewHeight;
    } else {
        newFrame.size.width = 10;
        newFrame.size.height = 10;
        viewHeight = 14;
        viewWidth = 10;
    }
    switch (self.bubbleTipAlignment) {
    case RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_TOP_LEFT:
        newFrame.origin.x = -viewWidth / 2.0f;
        newFrame.origin.y = -viewHeight / 2.0f;
        break;
    case RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_TOP_RIGHT:
        newFrame.origin.y = 0;
        newFrame.origin.x = superviewWidth - viewWidth + 6;
        break;
    case RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_TOP_CENTER:
        newFrame.origin.x = (superviewWidth - viewWidth) / 2.0f;
        newFrame.origin.y = -viewHeight / 2.0f;
        break;
    case RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_CENTER_LEFT:
        newFrame.origin.x = -viewWidth / 2.0f;
        newFrame.origin.y = (superviewHeight - viewHeight) / 2.0f;
        break;
    case RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_CENTER_RIGHT:
        newFrame.origin.x = superviewWidth - (viewWidth / 2.0f);
        newFrame.origin.y = (superviewHeight - viewHeight) / 2.0f;
        break;
    case RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_BOTTOM_LEFT:
        newFrame.origin.x = -textWidth / 2.0f;
        newFrame.origin.y = superviewHeight - (viewHeight / 2.0f);
        break;
    case RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_BOTTOM_RIGHT:
        newFrame.origin.x = superviewWidth - (viewWidth / 2.0f);
        newFrame.origin.y = superviewHeight - (viewHeight / 2.0f);
        break;
    case RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_BOTTOM_CENTER:
        newFrame.origin.x = (superviewWidth - viewWidth) / 2.0f;
        newFrame.origin.y = superviewHeight - (viewHeight / 2.0f);
        break;
    case RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_CENTER:
        newFrame.origin.x = (superviewWidth - viewWidth) / 2.0f;
        newFrame.origin.y = (superviewHeight - viewHeight) / 2.0f;
        break;
    default:
        NSAssert(NO, @"Unimplemented JSbubbleTipAligment type %d", (int)self.bubbleTipAlignment);
    }

    newFrame.origin.x += _bubbleTipPositionAdjustment.x;
    newFrame.origin.y += _bubbleTipPositionAdjustment.y;
    
    if(RCKitConfigCenter.ui.globalConversationAvatarStyle == RC_USER_AVATAR_RECTANGLE) {
        newFrame.origin.y -= 5;
    }

    self.frame = CGRectIntegral(newFrame);

    [self setNeedsDisplay];
}

#pragma mark - Public Methods

- (instancetype)initWithParentView:(UIView *)parentView alignment:(RCMessageBubbleTipViewAlignment)alignment {
    if ((self = [self initWithFrame:CGRectZero])) {
        [self _init];
        self.bubbleTipAlignment = alignment;
        [parentView addSubview:self];
    }
    return self;
}

- (void)setBubbleTipNumber:(int)msgCount {
    self.msgCount = msgCount;
    if (msgCount < 100 && msgCount > 0) {
        if (self.isShowNotificationNumber)
            [self setBubbleTipText:[NSString stringWithFormat:@"%d", msgCount]];
        else
            [self setBubbleTipText:@" "];
    } else if (msgCount >= 100 && msgCount < 1000) {
        if (self.isShowNotificationNumber)
            [self setBubbleTipText:@"99+ "];
        else
            [self setBubbleTipText:@" "];
    } else if (msgCount >= 1000) {
        if (self.isShowNotificationNumber)
            [self setBubbleTipText:@"⋯"];
        else
            [self setBubbleTipText:@" "];
    } else {
        [self setHidden:YES];
    }
}

#pragma mark - Private Methods
- (void)_init {
    self.backgroundColor = [UIColor clearColor];

    self.bubbleTipAlignment = kDefaultbubbleTipAlignment;

    self.bubbleTipBackgroundColor = kDefaultbubbleTipBackgroundColor;
    self.bubbleTipTextColor = kDefaultbubbleTipTextColor;
    self.bubbleTipTextShadowColor = kDefaultbubbleTipShadowColor;
    self.bubbleTipTextFont = kDefaultbubbleTipTextFont;
}

- (CGSize)sizeOfTextForCurrentSettings {
    CGSize __size = [self.bubbleTipText sizeWithAttributes:@{NSFontAttributeName : self.bubbleTipTextFont}];
    if (self.bubbleTipText.length == 1) {
        __size.width = 10;
    }
    if (self.bubbleTipText.length == 2) {
        __size.width = 16;
    }
    if (self.bubbleTipText.length == 3) {
        __size.width = 18;
    }

    return CGSizeMake(ceilf(__size.width), ceilf(__size.height));
}

#pragma mark - Setters
- (void)setIsShowNotificationNumber:(BOOL)isShowNotificationNumber {
    _isShowNotificationNumber = isShowNotificationNumber;
    [self setBubbleTipNumber:self.msgCount];
}

- (void)setBubbleTipAlignment:(RCMessageBubbleTipViewAlignment)bubbleTipAlignment {
    if (bubbleTipAlignment != _bubbleTipAlignment) {
        _bubbleTipAlignment = bubbleTipAlignment;

        switch (bubbleTipAlignment) {
        case RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_TOP_LEFT:
            self.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
            break;
        case RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_TOP_RIGHT:
            self.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin;
            break;
        case RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_TOP_CENTER:
            self.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin |
                                    UIViewAutoresizingFlexibleRightMargin;
            break;
        case RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_CENTER_LEFT:
            self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin |
                                    UIViewAutoresizingFlexibleRightMargin;
            break;
        case RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_CENTER_RIGHT:
            self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin |
                                    UIViewAutoresizingFlexibleLeftMargin;
            break;
        case RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_BOTTOM_LEFT:
            self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin;
            break;
        case RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_BOTTOM_RIGHT:
            self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;
            break;
        case RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_BOTTOM_CENTER:
            self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin |
                                    UIViewAutoresizingFlexibleRightMargin;
            break;
        case RC_MESSAGE_BUBBLE_TIP_VIEW_ALIGNMENT_CENTER:
            self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin |
                                    UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
            break;
        default:
            NSAssert(NO, @"Unimplemented JSbubbleTipAligment type %d", (int)self.bubbleTipAlignment);
        }

        [self setNeedsLayout];
    }
}

- (void)setBubbleTipPositionAdjustment:(CGPoint)bubbleTipPositionAdjustment {
    _bubbleTipPositionAdjustment = bubbleTipPositionAdjustment;

    [self setNeedsLayout];
}

- (void)setBubbleTipText:(NSString *)bubbleTipText {
    [self setHidden:NO];
    _bubbleTipText = [bubbleTipText copy];
    [self layoutSubviews];
}

- (void)setBubbleTipTextColor:(UIColor *)bubbleTipTextColor {
    if (bubbleTipTextColor != _bubbleTipTextColor) {
        _bubbleTipTextColor = bubbleTipTextColor;

        [self setNeedsDisplay];
    }
}

- (void)setBubbleTipTextShadowColor:(UIColor *)bubbleTipTextShadowColor {
    if (bubbleTipTextShadowColor != _bubbleTipTextShadowColor) {
        _bubbleTipTextShadowColor = bubbleTipTextShadowColor;

        [self setNeedsDisplay];
    }
}

- (void)setBubbleTipTextShadowOffset:(CGSize)bubbleTipTextShadowOffset {
    _bubbleTipTextShadowOffset = bubbleTipTextShadowOffset;

    [self setNeedsDisplay];
}

- (void)setBubbleTipTextFont:(UIFont *)bubbleTipTextFont {
    if (bubbleTipTextFont != _bubbleTipTextFont) {
        _bubbleTipTextFont = bubbleTipTextFont;

        [self setNeedsDisplay];
    }
}

- (void)setBubbleTipBackgroundColor:(UIColor *)bubbleTipBackgroundColor {
    if (bubbleTipBackgroundColor != _bubbleTipBackgroundColor) {
        _bubbleTipBackgroundColor = bubbleTipBackgroundColor;

        [self setNeedsDisplay];
    }
}


@end
