//
//  RCMenuItem.m
//  PopMenu
//
//  Created by RobinCui on 2025/10/18.
//

#import "RCMenuItem.h"

@implementation RCMenuItem

- (instancetype)initWithTitle:(NSString *)title image:(UIImage *)image action:(SEL)action {
    self = [super initWithTitle:title action:action];
    if (self) {
        _image = image;
    }
    return self;
}

+ (instancetype)menuItemWithItem:(UIMenuItem *)item {
    return [[self alloc] initWithTitle:item.title image:nil action:item.action];
}
@end

