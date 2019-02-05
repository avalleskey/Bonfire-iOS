//
//  MiniBubblePostView.m
//  Pulse
//
//  Created by Austin Valleskey on 1/3/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "MiniBubblePostView.h"
#import "UIColor+Palette.h"

@implementation MiniBubblePostView

- (id)init {
    self = [super init];
    if (self) {
        _profilePicture = [[BFAvatarView alloc] initWithFrame:CGRectMake(0, 0, MINI_BUBBLE_HEIGHT, MINI_BUBBLE_HEIGHT)];
        [self addSubview:_profilePicture];
        
        _messageBubble = [[UIView alloc] initWithFrame:CGRectMake(_profilePicture.frame.size.width + 8, 0, 0, _profilePicture.frame.size.height)];
        _messageBubble.layer.masksToBounds = true;
        _messageBubble.layer.cornerRadius = _messageBubble.frame.size.height / 2;
        
        _messageBubble.backgroundColor = [UIColor colorWithRed:0.92 green:0.93 blue:0.94 alpha:1.0];
        //_messageBubble.layer.borderWidth = 1;
        //_messageBubble.layer.borderColor = [UIColor colorWithWhite:0.92 alpha:1].CGColor;
        
        _gradientLayer = [CAGradientLayer layer];
        _gradientLayer.frame = _messageBubble.bounds;
        _gradientLayer.colors = @[(id)[UIColor colorWithRed:0 green:0 blue:0 alpha:0].CGColor, (id)[UIColor colorWithRed:0 green:0 blue:0 alpha:0.04].CGColor];
        //[_messageBubble.layer insertSublayer:_gradientLayer atIndex:0];
        
        [self addSubview:_messageBubble];
        
        _messageBubbleText = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, _messageBubble.frame.size.height)];
        _messageBubbleText.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightRegular];
        _messageBubbleText.textColor = [UIColor colorWithWhite:0.07 alpha:1];
        _messageBubbleText.textAlignment = NSTextAlignmentLeft;
        [_messageBubble addSubview:_messageBubbleText];
    }
    return self;
}

- (void)setPost:(Post *)post {
    if (post != _post) {
        _post = post;
        
        _profilePicture.user = post.attributes.details.creator;
        
        /*NSArray *colors = [self colorsWithIdentifier:post.attributes.details.creator.attributes.details.identifier];
        _gradientLayer.colors = colors;*/
        
        _messageBubbleText.text = post.attributes.details.message;
        
        CGFloat bubblePadding = 12;
        CGFloat maxBubbleWidth = self.superview.frame.size.width - _messageBubble.frame.origin.x - (bubblePadding * 2);
        CGSize messageBubbleSize = [_messageBubbleText.text boundingRectWithSize:CGSizeMake(maxBubbleWidth, _messageBubble.frame.size.height) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: _messageBubbleText.font} context:nil].size;
        _messageBubble.frame = CGRectMake(_messageBubble.frame.origin.x, _messageBubble.frame.origin.y, ceilf(messageBubbleSize.width) + (bubblePadding * 2), _messageBubble.frame.size.height);
        _gradientLayer.frame = _messageBubble.bounds;
        _messageBubbleText.frame = CGRectMake(bubblePadding, 0, ceilf(messageBubbleSize.width), _messageBubble.frame.size.height);
    }
}

- (NSArray *)colorsWithIdentifier:(NSString *)identifier {
    identifier = [identifier lowercaseString];
    identifier = [identifier stringByReplacingOccurrencesOfString:@"-" withString:@""];
    identifier = [identifier stringByReplacingOccurrencesOfString:@"_" withString:@""];
    NSLog(@"identifier:: %@", identifier);
    
    // baseline color
    // choose between 193 and 263
    CGFloat hue = 330; // 0 - 360
    CGFloat hue_afforded_variance = (360 - hue) + 20;
    
    CGFloat saturation = 78; // 0 - 100
    CGFloat saturation_afforded_variance = 0;
    
    CGFloat brightness = 98; // 0 - 100
    CGFloat brightness_afforded_variance = 0;
    
    // number between -1 and 1 that determines how much darker or lighter than the baseline we'll return
    CGFloat score = 0;
    // use the average character number
    NSArray *alphabet = [@"_ - b 1 a 2 d 3 c 4 f 5 e 6 h g j i l k 7 n 8 m 9 o p q r s t u v w x y z" componentsSeparatedByString:@" "];
    for (int i = 0; i < identifier.length; i++) {
        NSInteger indexOfObject = [alphabet indexOfObject:[identifier substringWithRange:NSMakeRange(i, 1)]];
        
        score = score + indexOfObject;
    }
    score = score / ((alphabet.count-1) * identifier.length); // get average and let that serve as our "score"
    NSLog(@"score: %f", score);
    
    hue = hue + (hue_afforded_variance * score);
    if (hue > 360) hue = hue - 360;
    hue = hue / 360;
    
    saturation = (saturation - (saturation_afforded_variance / 2) + (saturation_afforded_variance * score)) / 100;
    brightness = (brightness - (brightness_afforded_variance * score)) / 100;
    
    NSLog(@"%f: %f, %f, %f", score, hue, saturation, brightness);
    
    return @[
             (id)[UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1].CGColor,
             (id)[UIColor colorWithHue:hue saturation:(saturation+.06) brightness:(brightness-.06) alpha:1].CGColor
             ];
}

@end
