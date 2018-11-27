//
//  ErrorView.m
//  Pulse
//
//  Created by Austin Valleskey on 10/3/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ErrorView.h"

@implementation ErrorView

const NSInteger ErrorViewTypeGeneral         = 0;
const NSInteger ErrorViewTypeBlocked         = 1;
const NSInteger ErrorViewTypeNotFound        = 2;
const NSInteger ErrorViewTypeNoInternet      = 3;
const NSInteger ErrorViewTypeLocked          = 4;
const NSInteger ErrorViewTypeHeart           = 5;
const NSInteger ErrorViewTypeNoPosts         = 6;
const NSInteger ErrorViewTypeNoNotifications = 7;
const NSInteger ErrorViewTypeContactsDenied  = 8;

- (id)initWithFrame:(CGRect)rect title:(NSString *)title description:(NSString *)description type:(NSInteger)type {
    self = [super initWithFrame:rect];
    if (self) {
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width / 2 - 32, 0, 64, 64)];
        self.imageView.contentMode = UIViewContentModeCenter;
        self.imageView.layer.cornerRadius = self.imageView.frame.size.width / 2;
        self.imageView.layer.masksToBounds = true;
        self.imageView.backgroundColor = [UIColor whiteColor];
        [self updateType:type];
        [self addSubview:self.imageView];
        
        self.errorTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, self.imageView.frame.origin.y + self.imageView.frame.size.height + 16, self.frame.size.width, 30)];
        self.errorTitle.font = [UIFont systemFontOfSize:24.f weight:UIFontWeightHeavy];
        self.errorTitle.textColor = [UIColor colorWithWhite:0.2f alpha:1];
        self.errorTitle.text = title;
        self.errorTitle.textAlignment = NSTextAlignmentCenter;
        self.errorTitle.numberOfLines = 0;
        self.errorTitle.lineBreakMode = NSLineBreakByWordWrapping;
        [self addSubview:self.errorTitle];
        
        self.errorDescription = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width * .1, self.errorTitle.frame.origin.y + self.errorTitle.frame.size.height + 8, self.frame.size.width * .8, 30)];
        self.errorDescription.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightRegular];
        self.errorDescription.textColor = [UIColor colorWithWhite:0.6f alpha:1];
        self.errorDescription.text = description;
        self.errorDescription.textAlignment = NSTextAlignmentCenter;
        self.errorDescription.numberOfLines = 0;
        self.errorDescription.lineBreakMode = NSLineBreakByWordWrapping;
        [self addSubview:self.errorDescription];
        
        [self resize];
    }
    
    return self;
}

- (void)resize {
    CGPoint oldCenter = self.center;
    
    CGRect titleRect = [self.errorTitle.text boundingRectWithSize:CGSizeMake(self.frame.size.width, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.errorTitle.font} context:nil];
    self.errorTitle.frame = CGRectMake(self.errorTitle.frame.origin.x, self.errorTitle.frame.origin.y, self.frame.size.width, ceilf(titleRect.size.height));
    
    CGRect descriptionRect = [self.errorDescription.text boundingRectWithSize:CGSizeMake(self.frame.size.width * .8, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.errorDescription.font} context:nil];
    self.errorDescription.frame = CGRectMake(self.frame.size.width * .1, self.errorTitle.frame.origin.y + self.errorTitle.frame.size.height + 8, self.frame.size.width * .8, ceilf(descriptionRect.size.height));
    
    if (self.errorDescription.text.length == 0) {
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.errorTitle.frame.origin.y + self.errorTitle.frame.size.height);
    }
    else {
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.errorDescription.frame.origin.y + self.errorDescription.frame.size.height);
    }
    
    self.center = oldCenter;
}

- (void)updateType:(NSInteger)newType {
    switch (newType) {
        case ErrorViewTypeGeneral:
            self.imageView.image = [UIImage imageNamed:@"errorGeneral"];
            self.imageView.backgroundColor = [UIColor colorWithDisplayP3Red:0.96 green:0.54 blue:0.14 alpha:1.0];
            break;
        case ErrorViewTypeBlocked:
            self.imageView.image = [UIImage imageNamed:@"errorBlocked"];
            self.imageView.backgroundColor = [UIColor colorWithDisplayP3Red:0.44 green:0.45 blue:0.47 alpha:1.0];
            break;
        case ErrorViewTypeNotFound:
            self.imageView.image = [UIImage imageNamed:@"errorNotFound"];
            self.imageView.backgroundColor = [UIColor colorWithDisplayP3Red:0.44 green:0.45 blue:0.47 alpha:1.0];
            break;
        case ErrorViewTypeLocked:
            self.imageView.image = [UIImage imageNamed:@"errorPrivate"];
            self.imageView.backgroundColor = [UIColor colorWithDisplayP3Red:0.44 green:0.45 blue:0.47 alpha:1.0];
            break;
        case ErrorViewTypeNoInternet:
            self.imageView.image = [UIImage imageNamed:@"errorNoInternet"];
            self.imageView.backgroundColor = [UIColor colorWithDisplayP3Red:0.44 green:0.45 blue:0.47 alpha:1.0];
            break;
        case ErrorViewTypeHeart:
            self.imageView.image = [UIImage imageNamed:@"errorHeart"];
            self.imageView.backgroundColor = [UIColor colorWithDisplayP3Red:0.89 green:0.10 blue:0.13 alpha:1.0];
            break;
        case ErrorViewTypeNoPosts:
            self.imageView.image = [UIImage imageNamed:@"errorFlower"];
            self.imageView.backgroundColor = [UIColor colorWithDisplayP3Red:0.6f green:0.6f blue:0.6f alpha:1.0];
            break;
        case ErrorViewTypeNoNotifications:
            self.imageView.image = [UIImage imageNamed:@"errorNotifications"];
            self.imageView.backgroundColor = [UIColor colorWithDisplayP3Red:0.6f green:0.6f blue:0.6f alpha:1.0];
            break;
        case ErrorViewTypeContactsDenied:
            self.imageView.image = [UIImage imageNamed:@"errorContacts"];
            self.imageView.backgroundColor = [UIColor colorWithDisplayP3Red:0.44 green:0.45 blue:0.47 alpha:1.0];
            break;
            
        default:
            self.imageView.image = [UIImage imageNamed:@"errorGeneral"];
            self.imageView.backgroundColor = [UIColor colorWithDisplayP3Red:0.96 green:0.54 blue:0.14 alpha:1.0];
            break;
    }
}
- (void)updateTitle:(NSString *)newTitle {
    self.errorTitle.text = newTitle;
    [self resize];
}
- (void)updateDescription:(NSString *)newDescription {
    self.errorDescription.text = newDescription;
    [self resize];
    
    if (newDescription.length == 0) {
        self.errorTitle.textColor = [UIColor colorWithWhite:0.6f alpha:1];
    }
    else {
        self.errorTitle.textColor = [UIColor colorWithWhite:0.2f alpha:1];
    }
}

@end
