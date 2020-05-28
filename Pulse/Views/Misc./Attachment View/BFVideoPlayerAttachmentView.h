//
//  BFVideoPlayerAttachmentView.h
//  Pulse
//
//  Created by Austin Valleskey on 8/3/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFAttachmentView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BFVideoPlayerAttachmentView : BFAttachmentView

@property (nonatomic, strong) NSString *videoURL;

@property (nonatomic) BOOL looping;
@property (nonatomic) BOOL isPlaying;

- (void)pause;
- (void)play;

- (void)startSpinnersAsNeeded;

@end

NS_ASSUME_NONNULL_END
