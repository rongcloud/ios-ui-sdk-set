//
//  RCStreamMessageMarkdownCellViewModel.m
//  RongIMKit
//
//  Created by zgh on 2025/3/5.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCStreamMarkdownContentViewModel.h"
#import "RCStreamMessageCellViewModel+internal.h"
#import "RCMessageCellTool.h"
#import "RCMMMarkdown.h"
#import "RCStreamMarkdownContentView.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"

@interface RCStreamMarkdownContentViewModel ()

@end
@implementation RCStreamMarkdownContentViewModel
- (void)reloadContentHeight:(CGFloat)height {
    if (height == self.contentSize.height) {
        return;
    }
    // 更新 webView 的高度
    self.contentSize = CGSizeMake([self contentMaxWidth], height);
    if ([self.delegate respondsToSelector:@selector(streamContentLayoutWillUpdate)]) {
        [self.delegate streamContentLayoutWillUpdate];
    }
}

#pragma mark -- RCStreamViewModelProtocol

- (CGSize)calculateContentSize {
    if (self.contentSize.height == 0) {
        return [self quickCoreText];
    }
    return self.contentSize;
}

- (void)streamContentDidUpdate:(nonnull NSString *)content {
    if ([self.content isEqualToString:content]) {
        return;
    }
    self.content = content;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *htmlContent = [weakSelf coverHtmlContent];
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.htmlContent = htmlContent;
            if ([weakSelf.delegate respondsToSelector:@selector(streamContentLayoutWillUpdate)]) {
                [weakSelf.delegate streamContentLayoutWillUpdate];
            }
        });
    });
}

- (RCStreamContentView *)streamContentView{
    return [RCStreamMarkdownContentView new];
}

- (NSString *)javascriptStringForHeight {
    NSString *js = @"(function() { return Math.max(document.body.scrollHeight, document.body.offsetHeight); })();";
    return js;
}
#pragma mark -- private

- (CGSize)quickCoreText {
    CGFloat maxWidth = [self contentMaxWidth];
    NSString *content = self.content;
    if (!content) {
        return CGSizeMake(maxWidth, RCKitConfigCenter.ui.globalMessagePortraitSize.height);
    }
    CGSize maxSize = CGSizeMake(maxWidth, CGFLOAT_MAX); // 最大高度为无限大
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:self.content];
    // 使用 boundingRectWithSize 计算所需的高度
    CGRect textRect = [attributedString boundingRectWithSize:maxSize options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil];
    CGFloat height = MAX(ceilf(textRect.size.height), RCKitConfigCenter.ui.globalMessagePortraitSize.height);
    return CGSizeMake(maxWidth, height);
}

- (NSString *)coverHtmlContent {
    NSString *content = self.content;
    if (!content) {
        return nil;
    }
    NSString *str = [RCMMMarkdown HTMLStringWithMarkdown:content extensions:MMMarkdownExtensionsGitHubFlavored error:NULL];
    NSString *cssFileName = @"markdown-white.css";
    if ([RCKitUtility isDarkMode]) {
        cssFileName = @"markdown-dark.css";
    }
    NSString *htmlBase = @"<!DOCTYPE html>"
                         "<html>"
                         "<head>"
                         "<link href='%@' rel='stylesheet' type='text/css'>"
                         "</head>"
                         "<body>"
                         "%@"
                         "<script>"
                         "   document.addEventListener('DOMContentLoaded', function() {"
                         "      var noSelectElements = document.querySelectorAll('.no-select');"
                         "      noSelectElements.forEach(function(element) {"
                         "          element.addEventListener('contextmenu', function(e) {"
                         "              e.preventDefault();"
                         "          }, false);"
                         "          element.addEventListener('selectstart', function(e) {"
                         "              e.preventDefault();"
                         "          }, false);"
                         "          element.addEventListener('touchstart', function(e) {"
                         "              this.touchStartTime = Date.now();"
                         "          }, false);"
                         "          element.addEventListener('touchend', function(e) {"
                         "              var touchEndTime = Date.now();"
                         "              if (touchEndTime - this.touchStartTime > 500) {"
                         "                  e.preventDefault();"
                         "              }"
                         "          }, false);"
                         "      });"
                         "  });"
                         "</script>"
                         "</body>"
                         "</html>";
    NSString *htmlContent = [NSString stringWithFormat:htmlBase, cssFileName, str];
    return htmlContent;

}

- (CGSize)coreText:(NSAttributedString *)attributedContent {
    CGFloat maxWidth = [self contentMaxWidth];
    CGSize maxSize = CGSizeMake(maxWidth, CGFLOAT_MAX); // 最大高度为无限大
    
    // 使用 boundingRectWithSize 计算所需的高度
    CGRect textRect = [attributedContent boundingRectWithSize:maxSize
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                   context:nil];
    return CGSizeMake(maxWidth, ceilf(textRect.size.height));
}

@end
