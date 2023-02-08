//
//  RCAsyncLabel.m
//  CartoonTest
//
//  Created by RobinCui on 2022/5/19.
//

#import "RCAsyncLabel.h"
#import "RCYYAsyncLayer.h"
#import <CoreText/CoreText.h>
#import <CoreGraphics/CoreGraphics.h>


@interface RCAsyncLabel() {
    CTFrameRef _currentFrame;
}
@property (nonatomic, strong) NSDataDetector *dataDetector;
@property (nonatomic, strong) NSArray *checkingResults;
@end


@implementation RCAsyncLabel


- (void)setText:(NSString *)text {
    _text = text.copy;
    [[RCYYTransaction transactionWithTarget:self selector:@selector(contentsNeedUpdated)] commit];
}

- (void)setFont:(UIFont *)font {
    _font = font;
    [[RCYYTransaction transactionWithTarget:self selector:@selector(contentsNeedUpdated)] commit];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [[RCYYTransaction transactionWithTarget:self selector:@selector(contentsNeedUpdated)] commit];
}

- (void)contentsNeedUpdated {
    // do update
    [self.layer setNeedsDisplay];
}
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:CGRectZero];
    if (!self) return nil;
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;
    self.layer.contentsScale = [UIScreen mainScreen].scale;
    self.frame = frame;
    return self;
}

+ (Class)layerClass {
    return RCYYAsyncLayer.class;
}


- (void)dealloc {
    [self resetCurrentFrameWith:NULL];
}
#pragma mark - Private


/// Returns whether the text should be detected by the data detector.
- (BOOL)shouldDetectText {
    if([self.delegate respondsToSelector:@selector(shouldDetectText)]) {
        return [self.delegate shouldDetectText];;
    }
    return NO;
}

/// Detect the data in text and add highlight to the data range.
/// @return Whether detected.
- (BOOL)detectText:(NSMutableAttributedString *)text withAttributes:(NSDictionary *)textAttributes{
    // 清空之前的数据
    self.checkingResults = @[];
    if (![self shouldDetectText]) return NO;
    if (text.length == 0) return NO;
    if (![textAttributes isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    __block BOOL detected = NO;
    __weak __typeof(self)weakSelf = self;
    NSMutableArray *array = [NSMutableArray array];
    [self.dataDetector enumerateMatchesInString:text.string
                                        options:kNilOptions
                                          range:NSMakeRange(0, text.length)
                                     usingBlock: ^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        
        switch (result.resultType) {
            case NSTextCheckingTypeLink:
            case NSTextCheckingTypePhoneNumber: {
                detected = YES;
                NSDictionary *dic = textAttributes[@(result.resultType)];
                if (![dic isKindOfClass:[NSDictionary class]]) {
                    break;
                }
                if (dic.count) {
                    [dic enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                        [weakSelf setAttributeOf:text name:key value:obj range:result.range];
                    }];
                }
                if (result) {
                    [array addObject:result];
                }
            }
                break;
            default:
                break;
        }
    }];
    self.checkingResults = array;
    return detected;
}

- (void)setAttributeOf:(NSMutableAttributedString *)text
                  name:(NSString *)name
                 value:(id)value {
    [self setAttributeOf:text name:name value:value range:NSMakeRange(0, text.length)];
}

- (void)setAttributeOf:(NSMutableAttributedString *)text
                  name:(NSString *)name
                 value:(id)value
                 range:(NSRange)range {
    if (!text) {
        return;
    }
    if (!name || [NSNull isEqual:name]) return;
    if (value && ![NSNull isEqual:value]) {
        [text addAttribute:name value:value range:range];
    }
    else {
        [text setAttributes:nil range:range];
    }
}

/// 创建 NSMutableAttributedString
/// @param text 原始文本
/// @param font 字体
- (NSMutableAttributedString *)attibuteStringWith:(NSString *)text font:(UIFont *)font {
    NSMutableAttributedString *attibuteStr = [[NSMutableAttributedString alloc] initWithString:text];
    [attibuteStr addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, text.length)];
    NSDictionary *textAttributes = nil;
    if ([self.delegate respondsToSelector:@selector(textAttributesInfo)]) {
        textAttributes = [self.delegate textAttributesInfo];
    }
    UIColor *textColor = textAttributes[NSForegroundColorAttributeName];
    if (textColor) {
        [attibuteStr addAttribute:NSForegroundColorAttributeName value:textColor range:NSMakeRange(0, text.length)];
    }
    [self detectText:attibuteStr withAttributes:textAttributes];
    
    return attibuteStr;
}

- (CTFrameRef)createFrameWith:(NSMutableAttributedString *)attrString size:(CGSize)size {
    // 步骤3：创建绘制区域
    CGMutablePathRef path = CGPathCreateMutable();
    CGRect bounds = CGRectMake(0, 0, size.width, size.height);
    CGPathAddRect(path, NULL, bounds);
    
    // 步骤5：根据AttributedString生成CTFramesetterRef
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attrString);
    CTFrameRef frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, [attrString length]), path, NULL);
    CFRelease(frameSetter);
    CFRelease(path);
    return frame;
}

- (CFArrayRef)createLinesFromFrame:(CTFrameRef)frame {
    //获取frame中CTLineRef数组
    CFArrayRef Lines = CTFrameGetLines(frame);
    CFRetain(Lines);
    return Lines;
}

- (void)translateCTM:(CGContextRef)context size:(CGSize)size{
//    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        CGContextSetTextMatrix(context, CGAffineTransformIdentity);
        CGContextTranslateCTM(context, 0, size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
//    }];
}

#pragma mark - Touch

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    NSArray *results = [self.checkingResults copy];
    if (!results.count) {// 没有URL和电话 直接跳过
        return;
    }
    
    UITouch * touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];
    
    //获得点击位置在CoreText坐标系上的坐标
    [self userDidClickAt:location];
}

- (void)userDidClickAt:(CGPoint)location {
    NSArray *results = [self.checkingResults copy];
    if (!results.count) {
        return;
    }
    CFIndex index = [self characterIndexBy:location];
    if (index == kCFNotFound) {
        return;
    }
    for (NSTextCheckingResult *result in results) {
        if (NSLocationInRange(index, result.range)) {
            [self reportWith:result];
            break;
        }
    }
}

- (void)reportWith:(NSTextCheckingResult *)result {
    switch (result.resultType) {
        case NSTextCheckingTypeLink: {
            if ([self.delegate respondsToSelector:@selector(asyncLabel:didSelectLinkWithURL:)]) {
                [self.delegate asyncLabel:self didSelectLinkWithURL:[result URL]];
            }
        }
            break;
        case NSTextCheckingTypePhoneNumber: {
            if ([self.delegate respondsToSelector:@selector(asyncLabel:didSelectLinkWithPhoneNumber:)]) {
                [self.delegate asyncLabel:self didSelectLinkWithPhoneNumber:[result phoneNumber]];
            }
        }
            break;
        default: {
            if ([self.delegate respondsToSelector:@selector(didTapAsyncLabel:)]) {
                [self.delegate didTapAsyncLabel:self];
            }
        }
            break;
    }
}

/// 查找文本的点击位置
/// @param location 视图中的点击位置
- (CFIndex)characterIndexBy:(CGPoint)location {
    // 翻转point
    CGPoint point = CGPointMake(location.x, self.bounds.size.height - location.y);
    
    CFIndex index = kCFNotFound;
    CFArrayRef lines = [self createLinesFromFrame:_currentFrame];
    CFIndex lineCount = CFArrayGetCount(lines);
    
    CGPoint origins[lineCount];
    CTFrameGetLineOrigins(_currentFrame, CFRangeMake(0, 0), origins);
    
    for (CFIndex i = 0; i < lineCount; i ++) {
        
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CGPoint lineOrigin = origins[i];
        //参见TTTAttributedLabel
        // Get bounding information of line
        CGFloat ascent = 0.0f, descent = 0.0f, leading = 0.0f;
        CGFloat width = (CGFloat)CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
        CGFloat yMin = (CGFloat)floor(lineOrigin.y - descent);
        CGFloat yMax = (CGFloat)ceil(lineOrigin.y + ascent);
        
        CGPoint relativePoint = CGPointMake(point.x - lineOrigin.x, point.y - lineOrigin.y);
        // Check if we've already passed the line
        if (point.y > yMax) {
            break;
        }
        // Check if the point is within this line vertically
        if (point.y >= yMin) {
            // Check if the point is within this line horizontally
            if (point.x >= lineOrigin.x && point.x <= lineOrigin.x + width) {
                index = CTLineGetStringIndexForPosition(line,relativePoint);
                NSLog(@"%ld" , (long)index);
                break;
            }
        }
    }
    CFRelease(lines);
    return index;
}

- (void)resetCurrentFrameWith:(CTFrameRef)frame {
    if (_currentFrame != NULL) {
        CFRelease(_currentFrame);
        _currentFrame = NULL;
    }
    if (frame != NULL) {
        _currentFrame = CFRetain(frame);
    }
    
}
#pragma mark - YYAsyncLayer

- (RCYYAsyncLayerDisplayTask *)newAsyncDisplayTask {
    // capture current state to display task
    NSString *text = self.text ?:@"";
    UIFont *font = self.font;
    RCYYAsyncLayerDisplayTask *task = [RCYYAsyncLayerDisplayTask new];
    
    
    task.display = ^(CGContextRef context, CGSize size, BOOL(^isCancelled)(void)) {
        [self translateCTM:context size:size];
        if (isCancelled && isCancelled()) return;
        NSMutableAttributedString *string = [self attibuteStringWith:text font:font];
        CTFrameRef frame = [self createFrameWith:string size:size];
        [self resetCurrentFrameWith:frame];
        CFArrayRef lines = [self createLinesFromFrame:frame];
        CFIndex lineCount = CFArrayGetCount(lines);
        CGPoint origins[lineCount];
        CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), origins);
        for (CFIndex i = 0; i < lineCount; i ++) {
            CTLineRef line = CFArrayGetValueAtIndex(lines, i);
            CGPoint point = origins[i];
            CGContextSetTextPosition(context, point.x, point.y);
            CTLineDraw(line, context);
        }
        CFRelease(lines);
        CFRelease(frame);
    };
    
    task.didDisplay = ^(CALayer *layer, BOOL finished) {
        if (finished) {
            // finished
        } else {
            // cancelled
        }
    };
    
    return task;
}

#pragma mark - Property

- (NSDataDetector *)dataDetector {
    if (!_dataDetector) {
        NSTextCheckingType checkingType = NSTextCheckingTypePhoneNumber | NSTextCheckingTypeLink;
        _dataDetector = [NSDataDetector dataDetectorWithTypes:checkingType
                                                        error:NULL];
    }
    return _dataDetector;
}
@end
