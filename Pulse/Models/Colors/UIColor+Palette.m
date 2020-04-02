//
//  UIColor+Palette.m
//  Pulse
//
//  Created by Austin Valleskey on 11/18/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "UIColor+Palette.h"

@implementation UIColor (Palette)

#pragma mark - Helper Methods
+ (UIColor * _Nonnull)fromHex:(NSString *)hex {
    return [self fromHex:hex adjustForOptimalContrast:false];
}
+ (UIColor * _Nonnull)fromHex:(NSString *)hex adjustForOptimalContrast:(BOOL)adjustForOptimalContrast {
    unsigned rgbValue = 0;
    hex = [hex stringByReplacingOccurrencesOfString:@"#" withString:@""];
    
    if (hex.length == 0 || hex.length > 6) hex = @"616d7c";
    
    if (hex != nil && hex.length == 6) {
        NSScanner *scanner = [NSScanner scannerWithString:hex];
        [scanner setScanLocation:0]; // bypass '#' character
        [scanner scanHexInt:&rgbValue];

        // bonfire brand -> p3
        CGFloat r = ((rgbValue & 0xFF0000) >> 16)/255.0;
        CGFloat g = ((rgbValue & 0xFF00) >> 8)/255.0;
        CGFloat b = (rgbValue & 0xFF)/255.0;
        
        if ([hex isEqualToString:@"FF513C"] || [hex isEqualToString:@"#FF513C"]) {
            // Bonfire p3 color
            return [UIColor colorWithDisplayP3Red:r green:g blue:b alpha:1.0];
        }
        else {
            __block UIColor *ogColor = [UIColor colorWithRed:r green:g blue:b alpha:1.0];
            if (adjustForOptimalContrast) {
                if (@available(iOS 13.0, *)) {
                    // build dynamic UIColor
                    return [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
                        CGFloat colorContrast = [self contrastRatioBetween:ogColor and:[self cardBackgroundColor]];
                        
                        CGFloat minimumViableColorContrastRatio = 4;
                        if (colorContrast < minimumViableColorContrastRatio) {
                            return [ogColor minimumViableContrastColorWithContrastRatio:minimumViableColorContrastRatio];
                        }
                        else {
                            return ogColor;
                        }
                    }];
                }
                else {
                    CGFloat colorContrast = [self contrastRatioBetween:ogColor and:[self cardBackgroundColor]];
                    
                    CGFloat minimumViableColorContrastRatio = 4;
                    if (colorContrast < minimumViableColorContrastRatio) {
                        return [ogColor minimumViableContrastColorWithContrastRatio:minimumViableColorContrastRatio];
                    }
                    else {
                        return ogColor;
                    }
                }
            }
            
            
            return ogColor;
        }
    }
    else {
        return [UIColor bonfireGrayWithLevel:800];
    }
}
+ (CGFloat)contrastRatioBetween:(UIColor *)color1 and:(UIColor *)color2 {
    CGFloat luminance1 = [UIColor luminanceWithColor:color1];
    CGFloat luminance2 = [UIColor luminanceWithColor:color2];
    
    CGFloat luminanceDarker = MIN(luminance1, luminance2);
    CGFloat luminanceLighter = MAX(luminance1, luminance2);

    return (luminanceLighter + 0.05) / (luminanceDarker + 0.05);
}
+ (CGFloat)luminanceWithColor:(UIColor *)color {
    CIColor *ciColor = [[CIColor alloc] initWithColor:color];
    
    return 0.2126 * [UIColor adjust:ciColor.red] + 0.7152 * [UIColor adjust:ciColor.green] + 0.0722 * [UIColor adjust:ciColor.blue];
}
+ (CGFloat)adjust:(CGFloat)colorComponent {
    return (colorComponent < 0.03928) ? (colorComponent / 12.92) : pow((colorComponent + 0.055) / 1.055, 2.4);
}
- (UIColor *)minimumViableContrastColorWithContrastRatio:(CGFloat)targetColorContrast {
    UIColor *foreground = self; // foreground
    UIColor *background = [UIColor cardBackgroundColor]; // background
    
    CGFloat colorContrast = [UIColor contrastRatioBetween:foreground and:background];
    
    CGFloat foregroundLuminance = [UIColor luminanceWithColor:foreground];
    CGFloat backgroundLuminance = [UIColor luminanceWithColor:background];
    
    BOOL makeLighter = [UIColor useWhiteForegroundForColor:background];
    BOOL makeDarker = !makeLighter;
    
    BOOL notDarkEnough = makeDarker && foregroundLuminance >= backgroundLuminance;
    BOOL notLightEnough = (makeLighter && foregroundLuminance <= backgroundLuminance);
    
    if (notDarkEnough || notLightEnough) {
        foreground = makeLighter ? [UIColor lighterColorForColor:foreground amount:0.3] : [UIColor darkerColorForColor:foreground amount:0.3];
        foregroundLuminance = [UIColor luminanceWithColor:foreground];
        colorContrast = [UIColor contrastRatioBetween:foreground and:background];
    }
    
    CGFloat luminance1_after = foregroundLuminance * (targetColorContrast / colorContrast);
    
    // m represents the percentage change between the luminance before and after adjusting for our suggested target color contrast
    CGFloat m = luminance1_after / foregroundLuminance;
    
    CGFloat h;
    CGFloat s;
    CGFloat b;
    [foreground getHue:&h saturation:&s brightness:&b alpha:nil];
    
    CGFloat bAfter = makeLighter ? CLAMP(b * m, 0, 1) : CLAMP(b / m, 0, 1);
    CGFloat maxS = 0.95;
    if (@available(iOS 13.0, *)) {
        if ([UITraitCollection currentTraitCollection].userInterfaceStyle == UIUserInterfaceStyleDark) {
            maxS = 0.6;
        }
    }
    s = CLAMP(s - fabs(b - bAfter), 0, maxS);
    b = bAfter;
    
    UIColor *resultColor = [UIColor colorWithHue:h saturation:s brightness:b alpha:1];
    
    // DLog(@"Resulting contrast ratio: %f", [UIColor contrastRatioBetween:resultColor and:background]);
        
    return resultColor;
}

+ (UIColor *)lighterColorForColor:(UIColor *)c amount:(CGFloat)amount {
    if (amount == 0) amount = 0.2;
        
    CGFloat h, s, b, a;
    
    if ([c getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h saturation:MAX(s-amount, 0) brightness:MIN(s+amount, 1) alpha:1];
    
    return [UIColor whiteColor];
}

+ (UIColor *)darkerColorForColor:(UIColor *)c amount:(CGFloat)amount {
    if (amount == 0) amount = 0.2;
    
    CGFloat h, s, b, a;
    
    if ([c getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h saturation:MAX(s+amount, 0) brightness:MIN(s-amount, 1) alpha:1];
    
    return [UIColor blackColor];
}
+ (NSString *)toHex:(UIColor *)color {
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    
    if (components == NULL) {
        return @"616d7c";
    }
        
    CGFloat r = MAX(MIN(components[0], 1), 0);
    CGFloat g = MAX(MIN(components[1], 1), 0);
    CGFloat b = MAX(MIN(components[2], 1), 0);
    
    return [NSString stringWithFormat:@"%02lX%02lX%02lX",
            lroundf(r * 255),
            lroundf(g * 255),
            lroundf(b * 255)];
}
- (CGFloat)hue {
    CGFloat hFloat,sFloat,bFloat;
    [self getHue:&hFloat saturation:&sFloat brightness:&bFloat alpha:nil];
    return hFloat;
}
- (CGFloat)saturation {
    CGFloat hFloat,sFloat,bFloat;
    [self getHue:&hFloat saturation:&sFloat brightness:&bFloat alpha:nil];
    return sFloat;
}
- (CGFloat)brightness {
    CGFloat hFloat,sFloat,bFloat;
    [self getHue:&hFloat saturation:&sFloat brightness:&bFloat alpha:nil];
    return bFloat;
}

+ (BOOL)useWhiteForegroundForColor:(UIColor*)backgroundColor {
    if (!backgroundColor) return false;
    
    CGFloat contrastRatio = [UIColor contrastRatioBetween:backgroundColor and:[UIColor whiteColor]];

    return contrastRatio >= 2.3;
}

+ (UIColor *)highContrastForegroundForBackground:(UIColor*)backgroundColor {
    if ([self useWhiteForegroundForColor:backgroundColor]) {
        return [UIColor whiteColor];
    }
    else {
        return [UIColor blackColor];
    }
}

+ (UIColor * _Nonnull) contentBackgroundColor {
    return [UIColor colorNamed:@"ContentBackgroundColor"];
}

+ (UIColor * _Nonnull) contentHighlightedColor {
    return [UIColor colorNamed:@"ContentBackgroundColor_Highlighted"];
}

+ (UIColor * _Nonnull) cardBackgroundColor {
    return [UIColor colorNamed:@"CardBackgroundColor"];
}

+ (UIColor * _Nonnull) tableViewBackgroundColor {
    return [UIColor colorNamed:@"TableViewBackgroundColor"];
}
+ (UIColor * _Nonnull) viewBackgroundColor {
    return [UIColor colorNamed:@"BackgroundColor"];
}

+ (UIColor * _Nonnull) tableViewSeparatorColor {
    return [UIColor colorNamed:@"SeparatorColor"];
}

+ (UIColor * _Nonnull) linkColor {
    return [UIColor colorNamed:@"LinkColor"];
}

+ (UIColor * _Nonnull) threadLineColor {
    return [UIColor colorNamed:@"ThreadLineColor"];
}

// Gray
+ (UIColor * _Nonnull) bonfireBrandWithLevel:(int)level {
    switch(level) {
        case 50:
            return [UIColor fromHex:@"#ffedeb"];
        case 100:
            return [UIColor fromHex:@"#ffd9d4"];
        case 200:
            return [UIColor fromHex:@"#ffc2bb"];
        case 300:
            return [UIColor fromHex:@"#ffa79d"];
        case 400:
            return [UIColor fromHex:@"#ff8577"];
        case 500:
            return [UIColor fromHex:@"#FF513C"];
        case 600:
            return [UIColor fromHex:@"#e64836"];
        case 700:
            return [UIColor fromHex:@"#ca3f2f"];
        case 800:
            return [UIColor fromHex:@"#a73427"];
        case 900:
            return [UIColor fromHex:@"#78251c"];
        default:
            return [UIColor bonfireBrandWithLevel:500];
    }
}
+ (UIColor * _Nonnull) bonfireBrand {
    return [UIColor colorWithDisplayP3Red:1.00 green:0.36 blue:0.29 alpha:1.0];
}

+ (UIColor * _Nonnull) bonfirePrimaryColor {
    return [UIColor colorNamed:@"PrimaryColor"];
//    return [UIColor fromHex:@"31373D"];
}

// Gray
+ (UIColor * _Nonnull) bonfireGrayWithLevel:(int)level {
    switch(level) {
        case 50:
            return [UIColor fromHex:@"#f8f9fa"];
        case 100:
            return [UIColor fromHex:@"#ebedef"];
        case 200:
            return [UIColor fromHex:@"#dde1e4"];
        case 300:
            return [UIColor fromHex:@"#ced3d9"];
        case 400:
            return [UIColor fromHex:@"#bec4cc"];
        case 500:
            return [UIColor fromHex:@"#A5A9B2"];
        case 600:
            return [UIColor fromHex:@"#96a0ad"];
        case 700:
            return [UIColor fromHex:@"#7d8a99"];
        case 800:
            return [UIColor fromHex:@"#616d7c"];
        case 900:
            return [UIColor fromHex:@"#383f48"];
        default:
            return [UIColor bonfireGrayWithLevel:500];
    }
}
+ (UIColor * _Nonnull) bonfireSecondaryColor {
    return [UIColor colorNamed:@"SecondaryColor"];
}

+ (UIColor * _Nonnull) bonfireDetailColor {
    return [UIColor colorNamed:@"DetailColor"];
}

+ (UIColor * _Nonnull) bonfireDisabledColor {
    return [UIColor colorNamed:@"DisabledColor"];
}

+ (UIColor * _Nonnull) bonfireDetailHighlightedColor {
    return [UIColor colorNamed:@"DetailColor_Highlighted"];
}

// Blue
+ (UIColor * _Nonnull) bonfireBlueWithLevel:(int)level {
    switch(level) {
        case 50:
            return [UIColor fromHex:@"#e4f0ff"];
        case 100:
            return [UIColor fromHex:@"#c7e1ff"];
        case 200:
            return [UIColor fromHex:@"#a5cfff"];
        case 300:
            return [UIColor fromHex:@"#7ebaff"];
        case 400:
            return [UIColor fromHex:@"#4b9fff"];
        case 500:
            return [UIColor fromHex:@"#00A0FF"];
        case 600:
            return [UIColor fromHex:@"#006be6"];
        case 700:
            return [UIColor fromHex:@"#005ec9"];
        case 800:
            return [UIColor fromHex:@"#004da6"];
        case 900:
            return [UIColor fromHex:@"#003776"];
        default:
            return [UIColor bonfireBlueWithLevel:500];
    }
}
+ (UIColor * _Nonnull) bonfireBlue {
    return [UIColor bonfireBlueWithLevel:500];
}

// Indigo
+ (UIColor * _Nonnull) bonfireIndigoWithLevel:(int)level {
    switch(level) {
        case 50:
            return [UIColor fromHex:@"#ebebff"];
        case 100:
            return [UIColor fromHex:@"#d6d4ff"];
        case 200:
            return [UIColor fromHex:@"#bdbbff"];
        case 300:
            return [UIColor fromHex:@"#9e9bff"];
        case 400:
            return [UIColor fromHex:@"#7570ff"];
        case 500:
            return [UIColor fromHex:@"#0800ff"];
        case 600:
            return [UIColor fromHex:@"#0700e7"];
        case 700:
            return [UIColor fromHex:@"#0600cb"];
        case 800:
            return [UIColor fromHex:@"#0500a9"];
        case 900:
            return [UIColor fromHex:@"#03007a"];
        default:
            return [UIColor bonfireIndigoWithLevel:500];
    }
}
+ (UIColor * _Nonnull) bonfireIndigo {
    return [UIColor bonfireIndigoWithLevel:500];
}

// Violet
+ (UIColor * _Nonnull) bonfireVioletWithLevel:(int)level {
    switch(level) {
        case 50:
            return [UIColor fromHex:@"#f5e9ff"];
        case 100:
            return [UIColor fromHex:@"#ead2ff"];
        case 200:
            return [UIColor fromHex:@"#ddb6ff"];
        case 300:
            return [UIColor fromHex:@"#cd94ff"];
        case 400:
            return [UIColor fromHex:@"#b766ff"];
        case 500:
            return [UIColor fromHex:@"#8800ff"];
        case 600:
            return [UIColor fromHex:@"#7b00e6"];
        case 700:
            return [UIColor fromHex:@"#6b00ca"];
        case 800:
            return [UIColor fromHex:@"#5900a8"];
        case 900:
            return [UIColor fromHex:@"#400079"];
        default:
            return [UIColor bonfireVioletWithLevel:500];;
    }
}
+ (UIColor * _Nonnull) bonfireViolet {
    return [UIColor bonfireVioletWithLevel:500];
}

// Fuschia
+ (UIColor * _Nonnull) bonfireFuschiaWithLevel:(int)level {
    switch(level) {
        case 50:
            return [UIColor fromHex:@"#ffebfe"];
        case 100:
            return [UIColor fromHex:@"#ffd4fd"];
        case 200:
            return [UIColor fromHex:@"#ffbbfc"];
        case 300:
            return [UIColor fromHex:@"#ff9bfb"];
        case 400:
            return [UIColor fromHex:@"#ff70f9"];
        case 500:
            return [UIColor fromHex:@"#ff00f6"];
        case 600:
            return [UIColor fromHex:@"#e700de"];
        case 700:
            return [UIColor fromHex:@"#cb00c4"];
        case 800:
            return [UIColor fromHex:@"#a900a3"];
        case 900:
            return [UIColor fromHex:@"#7b0077"];
        default:
            return [UIColor bonfireFuschiaWithLevel:500];
    }
}
+ (UIColor * _Nonnull) bonfireFuschia {
    return [UIColor bonfireFuschiaWithLevel:500];
}

// Pink
+ (UIColor * _Nonnull) bonfirePinkWithLevel:(int)level {
    switch(level) {
        case 50:
            return [UIColor fromHex:@"#ffeaf4"];
        case 100:
            return [UIColor fromHex:@"#ffd4e8"];
        case 200:
            return [UIColor fromHex:@"#ffb9da"];
        case 300:
            return [UIColor fromHex:@"#ff99c8"];
        case 400:
            return [UIColor fromHex:@"#ff6db1"];
        case 500:
            return [UIColor fromHex:@"#ff0077"];
        case 600:
            return [UIColor fromHex:@"#e7006b"];
        case 700:
            return [UIColor fromHex:@"#cb005e"];
        case 800:
            return [UIColor fromHex:@"#a9004f"];
        case 900:
            return [UIColor fromHex:@"#7b0039"];
        default:
            return [UIColor bonfirePinkWithLevel:500];
    }
}
+ (UIColor * _Nonnull) bonfirePink {
    return [UIColor bonfirePinkWithLevel:500];
}

// Red
+ (UIColor * _Nonnull) bonfireRedWithLevel:(int)level {
    switch(level) {
        case 50:
            return [UIColor fromHex:@"#ffebea"];
        case 100:
            return [UIColor fromHex:@"#ffd5d3"];
        case 200:
            return [UIColor fromHex:@"#ffbbb9"];
        case 300:
            return [UIColor fromHex:@"#ff9c99"];
        case 400:
            return [UIColor fromHex:@"#ff726d"];
        case 500:
            return [UIColor fromHex:@"#E60800"];
        case 600:
            return [UIColor fromHex:@"#e60800"];
        case 700:
            return [UIColor fromHex:@"#cb0700"];
        case 800:
            return [UIColor fromHex:@"#a90500"];
        case 900:
            return [UIColor fromHex:@"#7a0400"];
        default:
            return [UIColor bonfireRedWithLevel:500];
    }
}
+ (UIColor * _Nonnull) bonfireRed {
    return [UIColor bonfireRedWithLevel:500];
}

// Orange
+ (UIColor * _Nonnull) bonfireOrangeWithLevel:(int)level {
    switch(level) {
        case 50:
            return [UIColor fromHex:@"#fff1e1"];
        case 100:
            return [UIColor fromHex:@"#ffe2c1"];
        case 200:
            return [UIColor fromHex:@"#ffd19d"];
        case 300:
            return [UIColor fromHex:@"#ffbd73"];
        case 400:
            return [UIColor fromHex:@"#ffa641"];
        case 500:
            return [UIColor fromHex:@"#ff8800"];
        case 600:
            return [UIColor fromHex:@"#e67b00"];
        case 700:
            return [UIColor fromHex:@"#ca6b00"];
        case 800:
            return [UIColor fromHex:@"#a75900"];
        case 900:
            return [UIColor fromHex:@"#784000"];
        default:
            return [UIColor bonfireOrangeWithLevel:500];
    }
}
+ (UIColor * _Nonnull) bonfireOrange {
    return [UIColor bonfireOrangeWithLevel:500];
}

// Yellow
+ (UIColor * _Nonnull) bonfireYellowWithLevel:(int)level {
    switch(level) {
        case 50:
            return [UIColor fromHex:@"#fdf8e1"];
        case 100:
            return [UIColor fromHex:@"#fcf0c2"];
        case 200:
            return [UIColor fromHex:@"#fae8a0"];
        case 300:
            return [UIColor fromHex:@"#f9df7b"];
        case 400:
            return [UIColor fromHex:@"#f7d651"];
        case 500:
            return [UIColor fromHex:@"#f5cb23"];
        case 600:
            return [UIColor fromHex:@"#ddb71f"];
        case 700:
            return [UIColor fromHex:@"#c2a11b"];
        case 800:
            return [UIColor fromHex:@"#a28617"];
        case 900:
            return [UIColor fromHex:@"#756110"];
        default:
            return [UIColor bonfireYellowWithLevel:500];
    }
}
+ (UIColor * _Nonnull) bonfireYellow {
    return [UIColor bonfireYellowWithLevel:500];
}

// Lime
+ (UIColor * _Nonnull) bonfireLimeWithLevel:(int)level {
    switch(level) {
        case 50:
            return [UIColor fromHex:@"#f1ffe5"];
        case 100:
            return [UIColor fromHex:@"#e1ffc8"];
        case 200:
            return [UIColor fromHex:@"#d0ffa6"];
        case 300:
            return [UIColor fromHex:@"#baff7f"];
        case 400:
            return [UIColor fromHex:@"#a0ff4c"];
        case 500:
            return [UIColor fromHex:@"#77ff00"];
        case 600:
            return [UIColor fromHex:@"#6be700"];
        case 700:
            return [UIColor fromHex:@"#5ecb00"];
        case 800:
            return [UIColor fromHex:@"#4fa900"];
        case 900:
            return [UIColor fromHex:@"#397b00"];
        default:
            return [UIColor bonfireLimeWithLevel:500];
    }
}
+ (UIColor * _Nonnull) bonfireLime {
    return [UIColor bonfireLimeWithLevel:500];
}

// Green
+ (UIColor * _Nonnull) bonfireGreenWithLevel:(int)level {
    switch(level) {
        case 50:
            return [UIColor fromHex:@"#e6f8ea"];
        case 100:
            return [UIColor fromHex:@"#caf0d4"];
        case 200:
            return [UIColor fromHex:@"#ace7bb"];
        case 300:
            return [UIColor fromHex:@"#89dd9e"];
        case 400:
            return [UIColor fromHex:@"#5fd27c"];
        case 500:
            return [UIColor fromHex:@"#29c350"];
        case 600:
            return [UIColor fromHex:@"#25b048"];
        case 700:
            return [UIColor fromHex:@"#209a3f"];
        case 800:
            return [UIColor fromHex:@"#1a8034"];
        case 900:
            return [UIColor fromHex:@"#135c25"];
        default:
            return [UIColor bonfireGreenWithLevel:500];
    }
}
+ (UIColor * _Nonnull) bonfireGreen {
    return [UIColor bonfireGreenWithLevel:500];
}

// Teal
+ (UIColor * _Nonnull) bonfireTealWithLevel:(int)level {
    switch(level) {
        case 50:
            return [UIColor fromHex:@"#e9fff5"];
        case 100:
            return [UIColor fromHex:@"#d1ffe9"];
        case 200:
            return [UIColor fromHex:@"#b5ffdc"];
        case 300:
            return [UIColor fromHex:@"#93ffcc"];
        case 400:
            return [UIColor fromHex:@"#65ffb7"];
        case 500:
            return [UIColor fromHex:@"#00ff88"];
        case 600:
            return [UIColor fromHex:@"#00e77b"];
        case 700:
            return [UIColor fromHex:@"#00cb6c"];
        case 800:
            return [UIColor fromHex:@"#00a95a"];
        case 900:
            return [UIColor fromHex:@"#007b41"];
        default:
            return [UIColor bonfireTealWithLevel:500];
    }
}
+ (UIColor * _Nonnull) bonfireTeal {
    return [UIColor bonfireTealWithLevel:500];
}

// Cyan
+ (UIColor * _Nonnull) bonfireCyanWithLevel:(int)level {
    switch(level) {
        case 50:
            return [UIColor fromHex:@"#e8feff"];
        case 100:
            return [UIColor fromHex:@"#cffdff"];
        case 200:
            return [UIColor fromHex:@"#b2fcff"];
        case 300:
            return [UIColor fromHex:@"#8ffbff"];
        case 400:
            return [UIColor fromHex:@"#5ef9ff"];
        case 500:
            return [UIColor fromHex:@"#00f6ff"];
        case 600:
            return [UIColor fromHex:@"#00dee7"];
        case 700:
            return [UIColor fromHex:@"#00c4cb"];
        case 800:
            return [UIColor fromHex:@"#00a3a9"];
        case 900:
            return [UIColor fromHex:@"#00767b"];
        default:
            return [UIColor bonfireCyanWithLevel:500];
    }
}
+ (UIColor * _Nonnull) bonfireCyan {
    return [UIColor bonfireCyanWithLevel:500];
}

+ (UIColor * _Nonnull) bonfireTextFieldBackgroundOnWhite {
    return [UIColor colorWithRed:0 green:0 blue:0.1f alpha:0.08f];
}

+ (UIColor * _Nonnull) bonfireTextFieldBackgroundOnContent {
    return [UIColor colorNamed:@"TextFieldBackgroundOnContent"];
}

+ (UIColor * _Nonnull) bonfireTextFieldBackgroundOnDark {
    return [UIColor colorWithWhite:1 alpha:0.16f];
}


@end
