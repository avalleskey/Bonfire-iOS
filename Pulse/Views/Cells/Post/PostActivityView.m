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
    self.backgroundColor = [UIColor tableViewBackgroundColor];
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

- (void)setLink:(PostAttachmentsLink *)link {
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
        [self addSubview:self.dateLabel];
        
        [self updateDateLabelText];
    }
    
    return self.dateLabel;
}
- (void)updateDateLabelText {
    if (![self.views containsObject:self.dateLabel]) {
        [self.views addObject:self.dateLabel];
    }
    
    NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
    [inputFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    NSDate *date = [inputFormatter dateFromString:self.post.attributes.status.createdAt];
    if (date) {
        // iMessage like date
        NSDateFormatter *outputFormatter_part1 = [[NSDateFormatter alloc] init];
        [outputFormatter_part1 setDateFormat:@"EEE, MMM d, yyyy"];
        NSDateFormatter *outputFormatter_part2 = [[NSDateFormatter alloc] init];
        [outputFormatter_part2 setDateFormat:@" h:mm a"];
        NSMutableAttributedString *dateString = [[NSMutableAttributedString alloc] initWithString:[outputFormatter_part1 stringFromDate:date]];
        [dateString addAttribute:NSForegroundColorAttributeName value:self.dateLabel.textColor range:NSMakeRange(0, dateString.length)];
        [dateString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:postActivityFontSize weight:UIFontWeightSemibold] range:NSMakeRange(0, dateString.length)];
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
- (UILabel *)createFirstToReplyLabel {
    self.firstToReplyLabel = [[UILabel alloc] initWithFrame:self.bounds];
    self.firstToReplyLabel.tag = PostActivityViewTagAddReply;
    if (self.link) {
        self.firstToReplyLabel.text = @"Be the first to talk about it!";
    }
    else if (self.post) {
        self.firstToReplyLabel.text = @"Be the first to reply!";
    }
    self.firstToReplyLabel.textColor = self.tintColor;
    self.firstToReplyLabel.textAlignment = NSTextAlignmentCenter;
    self.firstToReplyLabel.font = [UIFont systemFontOfSize:postActivityFontSize weight:UIFontWeightSemibold];
    
    self.firstToReplyLabel.transform = CGAffineTransformMakeTranslation(0, self.frame.size.height);
    self.firstToReplyLabel.alpha = 0;
    
    return self.firstToReplyLabel;
}
- (void)updateFirstToReplyLabel {
    if (self.post.attributes.summaries.counts.replies > 0) {
        [self.views removeObject:self.firstToReplyLabel];
        [self.firstToReplyLabel removeFromSuperview];
        return;
    }
    else {
        if (![self.views containsObject:self.firstToReplyLabel]) {
            [self.views addObject:self.firstToReplyLabel];
            [self addSubview:self.firstToReplyLabel];
            return;
        }
    }
}
- (UIButton *)createLiveCountButton {
    if (!self.liveCountButton) {
        self.liveCountButton = [UIButton buttonWithType:UIButtonTypeCustom];
        
        [self updateLiveCountText];
    }
    
    self.liveCountButton.transform = CGAffineTransformMakeTranslation(0, self.frame.size.height);
    self.liveCountButton.alpha = 0;

    return self.liveCountButton;
}
- (void)updateLiveCountText {
    if (self.post.attributes.summaries.counts.live == 0) {
        [self.views removeObject:self.liveCountButton];
        [self.liveCountButton removeFromSuperview];
        return;
    }
    else if (![self.views containsObject:self.liveCountButton]) {
        [self.views addObject:self.liveCountButton];
        [self addSubview:self.liveCountButton];
    }
    
    // use button so we can easily add the live dot to the left
    NSInteger liveCount = self.post.attributes.summaries.counts.live;
    
    if (liveCount == 0) {
        [self.liveCountButton setTitle:@"Spark this post to help it go viral!" forState:UIControlStateNormal];
        [self.liveCountButton.titleLabel setFont:[UIFont systemFontOfSize:postActivityFontSize weight:UIFontWeightSemibold]];
        [self.liveCountButton setTitleColor:self.tintColor forState:UIControlStateNormal];
    }
    else {
        NSMutableAttributedString *liveString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld active", (long)liveCount]];
        [liveString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:postActivityFontSize weight:UIFontWeightSemibold] range:NSMakeRange(0, liveString.length)];
        NSMutableAttributedString *timeString = [[NSMutableAttributedString alloc] initWithString:@" in the last 24hr 🔥"];
        [timeString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:postActivityFontSize weight:UIFontWeightRegular] range:NSMakeRange(0, timeString.length)];
        [liveString appendAttributedString:timeString];
        [liveString addAttribute:NSForegroundColorAttributeName value:[UIColor bonfireBrand] range:NSMakeRange(0, liveString.length)];
        [self.liveCountButton setAttributedTitle:liveString forState:UIControlStateNormal];
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
    NSLog(@"next view ? %@", nextView);
    
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
    return (PostActivityViewTag)((UIView *)self.views[step]).tag;
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
