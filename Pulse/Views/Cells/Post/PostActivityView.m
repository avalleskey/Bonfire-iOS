//
//  PostActivityView.m
//  Pulse
//
//  Created by Austin Valleskey on 2/28/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "PostActivityView.h"
#import "UIColor+Palette.h"

#define postActivityFontSize 12.f
#define postActivityTextColor [UIColor colorWithWhite:0.6 alpha:1]

@interface PostActivityView () {
    NSTimer *timer;
    int step;
}

@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UILabel *firstToReplyLabel;
@property (nonatomic, strong) UIButton *liveCountButton;

@end

@implementation PostActivityView

- (id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.backgroundColor = [UIColor bonfireDetailColor];
    self.tintColor = self.superview.tintColor;
    
    self.clipsToBounds = true;
    [self initViews];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    for (UIView *view in self.views) {
        view.frame = CGRectMake(0, view.frame.origin.y, self.frame.size.width, self.frame.size.height);
    }
}

- (void)initViews {
    self.views = [[NSMutableArray alloc] init];
    
    [self createDateLabel];
    [self createFirstToReplyLabel];
    [self createLiveCountButton];
}

- (void)setLink:(BFLink *)link {
    if (link != _link) {
        _link = link;
                
        [self updateViews];
    }
}

- (void)setPost:(Post *)post {
    if (post != _post) {
        _post = post;
                        
        [self updateViews];
    }
}

- (void)updateViews {
    [self updateDateLabelText];
    [self updateFirstToReplyLabel];
    [self updateLiveCountText];
}

- (UILabel *)createDateLabel {
    if (!self.dateLabel) {
        self.dateLabel = [[UILabel alloc] initWithFrame:self.bounds];
        self.dateLabel.textColor = self.tintColor;
        self.dateLabel.textAlignment = NSTextAlignmentCenter;
        self.dateLabel.font = [UIFont systemFontOfSize:postActivityFontSize weight:UIFontWeightBold];
        
        [self updateDateLabelText];
    }
    
    return self.dateLabel;
}
- (void)updateDateLabelText {
    BOOL show = false;
    if (self.link) {
        show = true;
        
        self.dateLabel.text = @"Share this link to help it go viral!";
    }
    else if (self.post) {
        show = true;
        
        NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
        [inputFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
        NSDate *date = [inputFormatter dateFromString:self.post.attributes.createdAt];
        if (date) {
            // iMessage like date
            NSDateFormatter *outputFormatter_part1 = [[NSDateFormatter alloc] init];
            [outputFormatter_part1 setDateFormat:@"EEE, MMM d, yyyy"];
            NSDateFormatter *outputFormatter_part2 = [[NSDateFormatter alloc] init];
            [outputFormatter_part2 setDateFormat:@" h:mm a"];
            NSMutableAttributedString *dateString = [[NSMutableAttributedString alloc] initWithString:[outputFormatter_part1 stringFromDate:date]];
            [dateString addAttribute:NSForegroundColorAttributeName value:self.dateLabel.textColor range:NSMakeRange(0, dateString.length)];
            [dateString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:postActivityFontSize weight:UIFontWeightBold] range:NSMakeRange(0, dateString.length)];
            NSMutableAttributedString *timeString = [[NSMutableAttributedString alloc] initWithString:[outputFormatter_part2 stringFromDate:date]];
            [timeString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:postActivityFontSize weight:UIFontWeightRegular] range:NSMakeRange(0, timeString.length)];
            [dateString appendAttributedString:timeString];
            [dateString addAttribute:NSForegroundColorAttributeName value:self.dateLabel.textColor range:NSMakeRange(0, dateString.length)];
            self.dateLabel.attributedText = dateString;
        }
        else {
            self.dateLabel.text = @"";
        }
    }
    
    if (show) {
        if (![self.views containsObject:self.dateLabel]) {
            [self.views addObject:self.dateLabel];
            [self addSubview:self.dateLabel];
        }
    }
    else {
        [self.views removeObject:self.dateLabel];
        [self.dateLabel removeFromSuperview];
        return;
    }
}
- (UILabel *)createFirstToReplyLabel {
    if (!self.firstToReplyLabel) {
        self.firstToReplyLabel = [[UILabel alloc] initWithFrame:self.bounds];
        self.firstToReplyLabel.tag = PostActivityViewTagAddReply;
        self.firstToReplyLabel.textColor = self.tintColor;
        self.firstToReplyLabel.textAlignment = NSTextAlignmentCenter;
        self.firstToReplyLabel.font = [UIFont systemFontOfSize:postActivityFontSize weight:UIFontWeightBold];
        
        self.firstToReplyLabel.transform = CGAffineTransformMakeTranslation(0, self.frame.size.height);
        self.firstToReplyLabel.alpha = 0;
        
        [self updateFirstToReplyLabel];
    }
    
    return self.firstToReplyLabel;
}
- (void)updateFirstToReplyLabel {
    BOOL show = false;
    if (self.link) {
        show = false;
    }
    else if (self.post && self.post.attributes.summaries.counts.replies == 0 && [self.post.attributes.context.post.permissions canReply]) {
        show = true;
        self.firstToReplyLabel.text = @"Be the first to reply!";
    }
    
    if (show) {
        if (![self.views containsObject:self.firstToReplyLabel]) {
            [self.views addObject:self.firstToReplyLabel];
            [self addSubview:self.firstToReplyLabel];
            return;
        }
    }
    else {
        [self.views removeObject:self.firstToReplyLabel];
        [self.firstToReplyLabel removeFromSuperview];
        return;
    }
}
- (UIButton *)createLiveCountButton {
    if (!self.liveCountButton) {
        self.liveCountButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.liveCountButton setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
        
        [self updateLiveCountText];
    }
    
    self.liveCountButton.transform = CGAffineTransformMakeTranslation(0, self.frame.size.height);
    self.liveCountButton.alpha = 0;

    return self.liveCountButton;
}
- (void)updateLiveCountText {
    NSInteger scoreCount = 0;
    
    BOOL show = false;
    if (self.link) {
        show = false;
    }
    else if (self.post && self.post.attributes.summaries.counts.score > 0) {
        show = true;
        scoreCount = self.post.attributes.summaries.counts.score;
    }
    
    if (show) {
        if (scoreCount == 0) {
            if (self.link) {
                [self.liveCountButton setTitle:@"Share this link to help it go viral!" forState:UIControlStateNormal];
            }
            else {
                [self.liveCountButton setTitle:@"Spark this post to help it go viral!" forState:UIControlStateNormal];
            }
            [self.liveCountButton.titleLabel setFont:[UIFont systemFontOfSize:postActivityFontSize weight:UIFontWeightBold]];
            [self.liveCountButton setTitleColor:self.tintColor forState:UIControlStateNormal];
        }
        else {
            NSMutableAttributedString *liveString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"This conversation is hot 🔥"]];
            [liveString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:postActivityFontSize weight:UIFontWeightBold] range:NSMakeRange(0, liveString.length)];
            [liveString addAttribute:NSForegroundColorAttributeName value:[UIColor bonfireBrand] range:NSMakeRange(0, liveString.length)];
            [self.liveCountButton setAttributedTitle:liveString forState:UIControlStateNormal];
        }
        
        if (![self.views containsObject:self.liveCountButton]) {
            [self.views addObject:self.liveCountButton];
            [self addSubview:self.liveCountButton];
        }
    }
    else {
        [self.views removeObject:self.liveCountButton];
        [self.liveCountButton removeFromSuperview];
        return;
    }
}

- (void)start {
    if (!_active) {
        _active = true;
        
        [self stop];
        if (self.views.count > 1) {
            timer = [NSTimer scheduledTimerWithTimeInterval:1.5
                                                     target: self
                                                   selector:@selector(next)
                                                   userInfo:nil repeats:NO];
        }
        else if (self.views.count == 1) {
            UIView *view = self.views[0];
            view.transform = CGAffineTransformMakeTranslation(0, 0);
        }
    }
}
- (void)stop {
    _active = false;
    
    [timer invalidate];
    timer = nil;
}

- (void)next {
    if (self.views.count <= 1) {
        [self stop];
        
        return;
    }
    
    UIView *currentView = self.views[step];
    
    step = step + 1;
    if (step >= self.views.count) {
        step = 0;
        [self updateViews];
    }
    UIView *nextView = self.views[step];
    
    // animate current one out
    if (currentView != nextView) {
        [UIView animateWithDuration:1.f delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            currentView.alpha = 0;
            currentView.transform = CGAffineTransformMakeTranslation(0, -self.frame.size.height);
        } completion:^(BOOL finished) {
            currentView.transform = CGAffineTransformMakeTranslation(0, self.frame.size.height);
        }];
        
        // animate next one in
        nextView.transform = CGAffineTransformMakeTranslation(0, self.frame.size.height);
        [UIView animateWithDuration:1.f delay:0.2f usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            nextView.alpha = 1;
            nextView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            
        }];
    }
    
    // start timer
    [timer invalidate];
    timer = nil;
    timer = [NSTimer scheduledTimerWithTimeInterval:8.f
                                             target: self
                                           selector:@selector(next)
                                           userInfo: nil repeats:NO];
}

- (PostActivityViewTag)currentViewTag {
    if (self.views && self.views.count > step) {
        return (PostActivityViewTag)(((UIView *)self.views[step]).tag);
    }
    
    return 0;
}

- (void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    
    for (UIView *view in self.views) {
        if ([view isKindOfClass:[UIButton class]]) {
            view.tintColor = self.tintColor;
        }
        else if ([view isKindOfClass:[UILabel class]]) {
            ((UILabel *)view).textColor = self.tintColor;
        }
    }
}


@end
