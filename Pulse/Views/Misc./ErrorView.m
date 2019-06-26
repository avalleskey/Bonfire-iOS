//
//  ErrorView.m
//  Pulse
//
//  Created by Austin Valleskey on 10/3/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ErrorView.h"
#import "UIColor+Palette.h"

@implementation ErrorView

- (id)initWithFrame:(CGRect)rect title:(NSString *)title description:(NSString *)description type:(NSInteger)type {
    self = [super initWithFrame:rect];
    if (self) {
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.frame.size.width / 2 - 28, 0, 56, 56)];
        self.imageView.contentMode = UIViewContentModeCenter;
        self.imageView.layer.cornerRadius = self.imageView.frame.size.width / 2;
        self.imageView.layer.masksToBounds = true;
        self.imageView.backgroundColor = [UIColor whiteColor];
        [self updateType:type];
        [self addSubview:self.imageView];
        
        self.errorTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, self.imageView.frame.origin.y + self.imageView.frame.size.height + 12, self.frame.size.width, 30)];
        self.errorTitle.font = [UIFont systemFontOfSize:20.f weight:UIFontWeightHeavy];
        self.errorTitle.textColor = [UIColor bonfireGray];
        self.errorTitle.text = title;
        self.errorTitle.textAlignment = NSTextAlignmentCenter;
        self.errorTitle.numberOfLines = 0;
        self.errorTitle.lineBreakMode = NSLineBreakByWordWrapping;
        [self addSubview:self.errorTitle];
        
        self.errorDescription = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width * .1, self.errorTitle.frame.origin.y + self.errorTitle.frame.size.height + 6, self.frame.size.width * .8, 30)];
        self.errorDescription.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightRegular];
        self.errorDescription.textColor = [UIColor bonfireGray];
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
    titleRect.origin.y = (self.imageView.isHidden ? 0 : self.imageView.frame.origin.y + self.imageView.frame.size.height + 12);
    self.errorTitle.frame = CGRectMake(self.errorTitle.frame.origin.x, titleRect.origin.y, self.frame.size.width, ceilf(titleRect.size.height));
    
    CGRect descriptionRect = [self.errorDescription.text boundingRectWithSize:CGSizeMake(self.frame.size.width * .8, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName:self.errorDescription.font} context:nil];
    self.errorDescription.frame = CGRectMake(self.frame.size.width * .1, self.errorTitle.frame.origin.y + self.errorTitle.frame.size.height + 6, self.frame.size.width * .8, ceilf(descriptionRect.size.height));
    
    if (self.errorDescription.text.length == 0) {
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.errorTitle.frame.origin.y + self.errorTitle.frame.size.height);
    }
    else {
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.errorDescription.frame.origin.y + self.errorDescription.frame.size.height);
    }
    
    self.center = oldCenter;
}

- (void)updateType:(ErrorViewType)newType {
    BOOL hideImageView = false;
    BOOL allowRefresh = false;
    
    switch (newType) {
        case ErrorViewTypeGeneral:
            hideImageView = true;
            allowRefresh = true;
            break;
        case ErrorViewTypeBlocked:
            self.imageView.image = [UIImage imageNamed:@"errorBlocked"];
            self.imageView.backgroundColor = [UIColor bonfireGray];
            allowRefresh = false;
            break;
        case ErrorViewTypeNotFound:
            self.imageView.image = [UIImage imageNamed:@"errorNotFound"];
            self.imageView.backgroundColor = [UIColor bonfireGray];
            allowRefresh = false;
            break;
        case ErrorViewTypeLocked:
            self.imageView.image = [UIImage imageNamed:@"errorPrivate"];
            self.imageView.backgroundColor = [UIColor bonfireGray];
            allowRefresh = false;
            break;
        case ErrorViewTypeNoInternet:
            self.imageView.image = [UIImage imageNamed:@"errorNoInternet"];
            self.imageView.backgroundColor = [UIColor bonfireGray];
            allowRefresh = true;
            break;
        case ErrorViewTypeHeart:
            self.imageView.image = [UIImage imageNamed:@"errorHeart"];
            self.imageView.backgroundColor = [UIColor bonfireGray];
            allowRefresh = false;
            break;
        case ErrorViewTypeNoPosts:
            self.imageView.image = [UIImage imageNamed:@"errorFlower"];
            self.imageView.backgroundColor = [UIColor bonfireGray];
            allowRefresh = true;
            break;
        case ErrorViewTypeNoNotifications:
            self.imageView.image = [UIImage imageNamed:@"errorNotifications"];
            self.imageView.backgroundColor = [UIColor bonfireGray];
            allowRefresh = false;
            break;
        case ErrorViewTypeContactsDenied:
            self.imageView.image = [UIImage imageNamed:@"errorContacts"];
            self.imageView.backgroundColor = [UIColor bonfireGray];
            allowRefresh = true;
            break;
        case ErrorViewTypeClock:
            self.imageView.image = [UIImage imageNamed:@"errorClock"];
            self.imageView.backgroundColor = [UIColor bonfireGray];
            allowRefresh = true;
            break;
            
        default:
            self.imageView.image = [UIImage imageNamed:@"errorGeneral"];
            self.imageView.backgroundColor = [UIColor bonfireGray];
            allowRefresh = true;
            break;
    }

    self.userInteractionEnabled = allowRefresh;
    self.imageView.hidden = hideImageView;
    
    [self updateErrorTitleColor];
}
- (void)updateTitle:(nullable NSString *)newTitle {
    self.errorTitle.text = newTitle;
    [self resize];
    
    [self updateErrorTitleColor];
}
- (void)updateDescription:(nullable NSString *)newDescription {
    self.errorDescription.text = newDescription;
    [self resize];
    
    [self updateErrorTitleColor];
}

- (void)updateErrorTitleColor {
    if (self.errorDescription.text.length == 0) {
        self.errorTitle.textColor = [UIColor bonfireGray];
    }
    else if (self.imageView.image == nil) {
        self.errorTitle.textColor = [UIColor bonfireGray];
    }
    else {
        self.errorTitle.textColor = [UIColor bonfireGray];
    }
}

@end
