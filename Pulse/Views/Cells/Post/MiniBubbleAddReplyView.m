//
//  MiniBubbleAddReplyView.m
//  Pulse
//
//  Created by Austin Valleskey on 1/5/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "MiniBubbleAddReplyView.h"
#import "Session.h"

@implementation MiniBubbleAddReplyView

- (id)init {
    self = [super init];
    if (self) {
        _profilePicture = [[BFAvatarView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
        _profilePicture.user = [Session sharedInstance].currentUser;
        [self addSubview:_profilePicture];
        
        _messageBubble = [[UIView alloc] initWithFrame:CGRectMake(_profilePicture.frame.size.width + 8, 0, 0, _profilePicture.frame.size.height)];
        _messageBubble.layer.masksToBounds = true;
        _messageBubble.layer.cornerRadius = _messageBubble.frame.size.height / 2;
        
        _messageBubble.backgroundColor = [UIColor colorWithWhite:0.97 alpha:1];
        _messageBubble.layer.borderWidth = 1;
        _messageBubble.layer.borderColor = [UIColor colorWithWhite:0.87 alpha:1].CGColor;
        
        [self addSubview:_messageBubble];
        
        _messageBubbleText = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 120, _messageBubble.frame.size.height)];
        _messageBubbleText.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightRegular];
        _messageBubbleText.textColor = [UIColor colorWithWhite:0.07 alpha:0.25];
        _messageBubbleText.textAlignment = NSTextAlignmentLeft;
        _messageBubbleText.text = @"Add a Reply...";
        [_messageBubble addSubview:_messageBubbleText];
    }
    return self;
}

@end
