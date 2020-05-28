//
//  BFVideoPlayerViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 5/18/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import "BFSwippableViewController.h"
#import "BFActivityIndicatorView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BFVideoPlayerViewController : BFSwippableViewController

// Settings
@property (nonatomic) NSString *videoURL;
@property (nonatomic) BOOL loop;
@property (nonatomic) BOOL showControls;

typedef enum {
    BFVideoPlayerFormatVideo,
    BFVideoPlayerFormatStory
} BFVideoPlayerFormat;
@property (nonatomic) BFVideoPlayerFormat format;

// Views

@end

NS_ASSUME_NONNULL_END
