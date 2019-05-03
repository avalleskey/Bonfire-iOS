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

@end

@implementation PostActivityView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.98 green:0.98 blue:0.99 alpha:1.00];
        self.tintColor = self.superview.tintColor;
        
        self.clipsToBounds = true;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    for (UIView *view in self.views) {
        view.frame = CGRectMake(0, view.frame.origin.y, self.frame.size.width, self.frame.size.height);
    }
}

- (void)initViewsWithPost:(Post *)post {
    if (self.views == nil) {
        self.views = [[NSMutableArray alloc] init];
        
        [self.views addObject:[self dateLabelForPost:post]];
        if (post.attributes.summaries.counts.replies == 0) {
            [self.views addObject:[self firstToReplyLabelForPost:post]];
        }
        if (post.attributes.summaries.counts.live > 0) {
            [self.views addObject:[self liveCountButtonForPost:post]];
        }
        
        for (NSInteger i = 0; i < self.views.count; i++) {
            UIView *view = self.views[i];
            if (i != 0) {
                view.transform = CGAffineTransformMakeTranslation(0, self.frame.size.height);
                view.alpha = 0;
            }
            
            [self addSubview:view];
        }
    }
}

- (UILabel *)dateLabelForPost:(Post *)post {
    UILabel *dateLabel = [[UILabel alloc] initWithFrame:self.bounds];
    dateLabel.textColor = postActivityTextColor;
    dateLabel.textAlignment = NSTextAlignmentCenter;
    
    NSDateFormatter *inputFormatter = [[NSDateFormatter alloc] init];
    [inputFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    NSDate *date = [inputFormatter dateFromString:post.attributes.status.createdAt];
    if (date) {
        // iMessage like date
        NSDateFormatter *outputFormatter_part1 = [[NSDateFormatter alloc] init];
        [outputFormatter_part1 setDateFormat:@"EEE, MMM d, yyyy"];
        NSDateFormatter *outputFormatter_part2 = [[NSDateFormatter alloc] init];
        [outputFormatter_part2 setDateFormat:@" h:mm a"];
        NSMutableAttributedString *dateString = [[NSMutableAttributedString alloc] initWithString:[outputFormatter_part1 stringFromDate:date]];
        [dateString addAttribute:NSForegroundColorAttributeName value:dateLabel.textColor range:NSMakeRange(0, dateString.length)];
        [dateString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:postActivityFontSize weight:UIFontWeightSemibold] range:NSMakeRange(0, dateString.length)];
        NSMutableAttributedString *timeString = [[NSMutableAttributedString alloc] initWithString:[outputFormatter_part2 stringFromDate:date]];
        [timeString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:postActivityFontSize weight:UIFontWeightRegular] range:NSMakeRange(0, timeString.length)];
        [dateString appendAttributedString:timeString];
        [dateString addAttribute:NSForegroundColorAttributeName value:dateLabel.textColor range:NSMakeRange(0, dateString.length)];
        dateLabel.attributedText = dateString;
    }
    else {
        dateLabel.text = @"";
    }
    
    return dateLabel;
}
- (UILabel *)firstToReplyLabelForPost:(Post *)post {
    UILabel *label = [[UILabel alloc] initWithFrame:self.bounds];
    label.text = @"Be the first to reply!";
    label.textColor = postActivityTextColor;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:postActivityFontSize weight:UIFontWeightSemibold];
    
    return label;
}
- (UIButton *)liveCountButtonForPost:(Post *)post {
    // use button so we can easily add the live dot to the left
    NSLog(@"calculate live count for button with post:");
    NSLog(@"%@", post);
    
    NSInteger liveCount = post.attributes.summaries.counts.live; // fake it til we make it
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    if (liveCount == 0) {
        [button setTitle:@"Spark this post to help it go viral!" forState:UIControlStateNormal];
        [button.titleLabel setFont:[UIFont systemFontOfSize:postActivityFontSize weight:UIFontWeightSemibold]];
        [button setTitleColor:postActivityTextColor forState:UIControlStateNormal];
    }
    else {
        [button setImage:[UIImage imageNamed:@"postLiveDot"] forState:UIControlStateNormal];
        
        CABasicAnimation *pulseAnimation;
        pulseAnimation=[CABasicAnimation animationWithKeyPath:@"opacity"];
        pulseAnimation.duration = 1.0;
        pulseAnimation.repeatCount=HUGE_VALF;
        pulseAnimation.autoreverses = YES;
        pulseAnimation.fromValue=[NSNumber numberWithFloat:1.0];
        pulseAnimation.toValue=[NSNumber numberWithFloat:0.6];
        [button.imageView.layer addAnimation:pulseAnimation forKey:@"animateOpacity"];
        
        [button setTitleEdgeInsets:UIEdgeInsetsMake(0, 6, 0, 0)];
        [button setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 6)];
        NSMutableAttributedString *liveString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%ld LIVE", (long)liveCount]];
        [liveString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:postActivityFontSize weight:UIFontWeightSemibold] range:NSMakeRange(0, liveString.length)];
        NSMutableAttributedString *timeString = [[NSMutableAttributedString alloc] initWithString:@" in the last 24hr"];
        [timeString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:postActivityFontSize weight:UIFontWeightRegular] range:NSMakeRange(0, timeString.length)];
        [liveString appendAttributedString:timeString];
        [liveString addAttribute:NSForegroundColorAttributeName value:[UIColor bonfireRed] range:NSMakeRange(0, liveString.length)];
        [button setAttributedTitle:liveString forState:UIControlStateNormal];
    }
    
    return button;
}

- (void)start {
    if (!active) {
        active = true;
        
        step = 0;
        
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
    timer = nil;
    [timer invalidate];
}

- (void)next {
    if (self.views.count <= 1) return;
    
    UIView *currentView = self.views[step];
    
    step = step + 1;
    if (step >= self.views.count) {
        step = 0;
    }
    UIView *nextView = self.views[step];
    
    // animate current one out
    [UIView animateWithDuration:1.f delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        currentView.alpha = 0;
        currentView.transform = CGAffineTransformMakeTranslation(0, -self.frame.size.height);
    } completion:^(BOOL finished) {
        currentView.transform = CGAffineTransformMakeTranslation(0, self.frame.size.height);
    }];
    
    // animate next one in
    [UIView animateWithDuration:1.f delay:0.2f usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        nextView.alpha = 1;
        nextView.transform = CGAffineTransformMakeTranslation(0, 0);
    } completion:^(BOOL finished) {
        
    }];
    
    // start timer
    [timer invalidate];
    timer = [NSTimer scheduledTimerWithTimeInterval:8.f
                                             target: self
                                           selector:@selector(next)
                                           userInfo: nil repeats:NO];
}


@end
