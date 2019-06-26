//
//  PostActivityView.m
//  Pulse
//
//  Created by Austin Valleskey on 2/28/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "PostActivityView.h"
#import "UIColor+Palette.h"

#define postActivityFontSize 11.f
#define postActivityTextColor [UIColor colorWithWhite:0.6 alpha:1]

@interface PostActivityView () {
    NSTimer *timer;
    int step;
    BOOL active;
}

@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UILabel *firstToReplyLabel;
@property (nonatomic, strong) UIButton *liveCountButton;

typedef enum {
    PostActivityViewTagDate,
    PostActivityViewTagAddReply,
    PostActivityViewTagLive
} PostActivityViewTag;

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
    self.backgroundColor = [UIColor headerBackgroundColor];
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
    
    [self addSubview:[self createDateLabel]];
    [self addSubview:[self createFirstToReplyLabel]];
    [self addSubview:[self createLiveCountButton]];
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
    self.firstToReplyLabel.text = @"Be the first to reply!";
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
        
        return;
    }
    else {
        if (![self.views containsObject:self.firstToReplyLabel]) {
            [self.views addObject:self.firstToReplyLabel];
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
        return;
    }
    else {
        if (![self.views containsObject:self.liveCountButton]) {
            [self.views addObject:self.liveCountButton];
            return;
        }
    }
    
    // use button so we can easily add the live dot to the left
    NSInteger liveCount = self.post.attributes.summaries.counts.live;
    
    if (liveCount == 0) {
        [self.liveCountButton setTitle:@"Spark this post to help it go viral!" forState:UIControlStateNormal];
        [self.liveCountButton.titleLabel setFont:[UIFont systemFontOfSize:postActivityFontSize weight:UIFontWeightSemibold]];
        [self.liveCountButton setTitleColor:postActivityTextColor forState:UIControlStateNormal];
    }
    else {
        [self.liveCountButton setImage:[UIImage imageNamed:@"postLiveDot"] forState:UIControlStateNormal];
        
        CABasicAnimation *pulseAnimation;
        pulseAnimation=[CABasicAnimation animationWithKeyPath:@"opacity"];
        pulseAnimation.duration = 1.0;
        pulseAnimation.repeatCount=HUGE_VALF;
        pulseAnimation.autoreverses = YES;
        pulseAnimation.fromValue=[NSNumber numberWithFloat:1.0];
        pulseAnimation.toValue=[NSNumber numberWithFloat:0.6];
        [self.liveCountButton.imageView.layer addAnimation:pulseAnimation forKey:@"animateOpacity"];
        
        [self.liveCountButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 6, 0, 0)];
        [self.liveCountButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 6)];
        NSMutableAttributedString *liveString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld LIVE", (long)liveCount]];
        [liveString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:postActivityFontSize weight:UIFontWeightSemibold] range:NSMakeRange(0, liveString.length)];
        NSMutableAttributedString *timeString = [[NSMutableAttributedString alloc] initWithString:@" in the last 24hr"];
        [timeString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:postActivityFontSize weight:UIFontWeightRegular] range:NSMakeRange(0, timeString.length)];
        [liveString appendAttributedString:timeString];
        [liveString addAttribute:NSForegroundColorAttributeName value:[UIColor bonfireRed] range:NSMakeRange(0, liveString.length)];
        [self.liveCountButton setAttributedTitle:liveString forState:UIControlStateNormal];
    }
}

- (void)start {
    if (!active) {
        active = true;
        
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
    active = false;
    
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
