//
//  PostContextView.m
//  Pulse
//
//  Created by Austin Valleskey on 1/8/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "PostContextView.h"

@implementation PostContextView

- (id)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.05];
        
        self.contextIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 10, self.frame.size.height)];
        self.contextIcon.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
        
        self.contextLabel.frame = CGRectMake(0, 0, self.frame.size.width, postContextHeight);
        self.contextLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1];
        self.contextLabel.font = [UIFont systemFontOfSize:12.f];
        self.contextLabel.textAlignment = NSTextAlignmentLeft;
        
        [self addSubview:self.contextLabel];
    }
    return self;
}

- (void)setType:(PostContextViewType)type {
    if (type != _type) {
        _type = type;
        
        switch (type) {
            case PostContextViewTypeReply:
                
                break;
            case PostContextViewTypeReplied:
                
                break;
            case PostContextViewTypeRespark:
                
                break;
                
            default:
                break;
        }
    }
}

@end
