//
//  RCSightModel.m
//  RongIMKit
//
//  Created by 张改红 on 2021/5/8.
//  Copyright © 2021 RongCloud. All rights reserved.
//

#import "RCSightModel.h"
#import "RCSightPlayerController+imkit.h"

@interface RCSightModel()
@property (nonatomic, strong) RCSightPlayerController *playerController;
@end

@implementation RCSightModel
- (instancetype)initWithMessage:(RCMessage *)rcMessage {
    self = [super init];
    if (self) {
        self.message = rcMessage;
        RCSightMessage *sightMessage = (RCSightMessage *)rcMessage.content;
        Class playerType = NSClassFromString(@"RCSightPlayerController");
        if (playerType) {
            self.playerController = [[playerType alloc] init];
            [self.playerController setFirstFrameThumbnail:sightMessage.thumbnailImage];
            //判断如果 localPath 有效，优先使用。之前的逻辑无法使用本地路径插入小视频消息。
            NSString *localPath = nil;
            if (sightMessage.localPath != nil && sightMessage.localPath.length > 0) {
                localPath = sightMessage.localPath;
            } else if (sightMessage.sightUrl != nil && sightMessage.sightUrl.length > 0) {
                localPath = [RCFileUtility getSightCachePath:sightMessage.sightUrl];
            } else {
                RCLogV(@"LocalPath and sightUrl are nil");
            }
            if ([[NSFileManager defaultManager] fileExistsAtPath:localPath]) {
                self.playerController.rcSightURL = [[NSURL alloc] initFileURLWithPath:localPath];
                [self.playerController setFirstFrameThumbnail:self.playerController.firstFrameImage];
            } else if(sightMessage.sightUrl.length > 0){
                self.playerController.rcSightURL = [NSURL URLWithString:sightMessage.sightUrl];
            }
        }
    }
    return self;
}
@end
