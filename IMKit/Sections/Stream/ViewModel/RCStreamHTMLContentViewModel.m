//
//  RCStreamHTMLContentViewModel.m
//  RongIMKit
//
//  Created by RobinCui on 2025/5/13.
//  Copyright © 2025 RongCloud. All rights reserved.
//

#import "RCStreamHTMLContentViewModel.h"
#import "RCKitCommonDefine.h"
#import "RCKitConfig.h"

@interface RCStreamMarkdownContentViewModel()
- (NSString *)coverHtmlContent;

@end

@implementation RCStreamHTMLContentViewModel

- (NSString *)coverHtmlContent {
    return self.content;
}

- (NSString *)javascriptStringForHeight {
    NSString *js = @"(function() { "
                   "var body = document.body;"
                   "var html = document.documentElement;"
                   "return Math.max("
                   "body.scrollHeight, body.offsetHeight,"
                   "html.offsetHeight"
                   ");"
                   "})();";
    return js;
}
@end
