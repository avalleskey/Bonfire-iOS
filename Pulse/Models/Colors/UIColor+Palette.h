//
//  UIColor+Palette.h
//  Pulse
//
//  Created by Austin Valleskey on 11/18/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (Palette)

/**
 *  Attempt to convert hex string to UIColor
 *
 *  @return The color value of the hex string
 */
+ (UIColor * _Nonnull)fromHex:(NSString *)hex;

/**
 *  Return lighter variant of provided color, given a (optional) specified amount
 *
 *  @return A lighter color variant of the provided color
 */
+ (UIColor *)lighterColorForColor:(UIColor *)c amount:(CGFloat)amount;

/**
 *  Return darker variant of provided color, given a (optional) specified amount
 *
 *  @return A darker color variant of the provided color
 */
+ (UIColor *)darkerColorForColor:(UIColor *)c amount:(CGFloat)amount;

/**
 * Convert UIColor to hex string
 *
 * @return The hex string value of the UIColor
 */
+ (NSString *)toHex:(UIColor *)color;

+ (BOOL)useWhiteForegroundForColor:(UIColor*)backgroundColor;

/**
 *  Header background color
 *
 *  @return UIColor representing the current header background color. May return user-defined Tweak value.
 */
+ (UIColor * _Nonnull) headerBackgroundColor;

/**
 *  Separator background color
 *
 *  @return UIColor representing the current line separator color.
 */
+ (UIColor * _Nonnull) separatorColor;

/**
 *  Bonfire brand color of the specified level
 *
 *  @param level The level of color from 50,100-900 (increment of 100)
 *
 *  @return UIColor representing the bonfire brand color
 */
+ (UIColor * _Nonnull) bonfireBrandWithLevel:(int)level;

/**
 *  Bonfire gray color of the specified level
 *
 *  @param level The level of color from 50,100-900 (increment of 100)
 *
 *  @return UIColor representing the bonfire color gray
 */
+ (UIColor * _Nonnull) bonfireGrayWithLevel:(int)level;

/**
 *  Bonfire blue color of the specified level
 *
 *  @param level The level of color from 50,100-900 (increment of 100)
 *
 *  @return UIColor representing the bonfire color blue
 */
+ (UIColor * _Nonnull) bonfireBlueWithLevel:(int)level;

/**
 *  Bonfire indigo color of the specified level
 *
 *  @param level The level of color from 50,100-900 (increment of 100)
 *
 *  @return UIColor representing the bonfire color indigo
 */
+ (UIColor * _Nonnull) bonfireIndigoWithLevel:(int)level;

/**
 *  Bonfire violet color of the specified level
 *
 *  @param level The level of color from 50,100-900 (increment of 100)
 *
 *  @return UIColor representing the bonfire color violet
 */
+ (UIColor * _Nonnull) bonfireVioletWithLevel:(int)level;

/**
 *  Bonfire fuschia color of the specified level
 *
 *  @param level The level of color from 50,100-900 (increment of 100)
 *
 *  @return UIColor representing the bonfire color fuschia
 */
+ (UIColor * _Nonnull) bonfireFuschiaWithLevel:(int)level;

/**
 *  Bonfire pink color of the specified level
 *
 *  @param level The level of color from 50,100-900 (increment of 100)
 *
 *  @return UIColor representing the bonfire color pink
 */
+ (UIColor * _Nonnull) bonfirePinkWithLevel:(int)level;

/**
 *  Bonfire red color of the specified level
 *
 *  @param level The level of color from 50,100-900 (increment of 100)
 *
 *  @return UIColor representing the bonfire color red
 */
+ (UIColor * _Nonnull) bonfireRedWithLevel:(int)level;

/**
 *  Bonfire orange color of the specified level
 *
 *  @param level The level of color from 50,100-900 (increment of 100)
 *
 *  @return UIColor representing the bonfire color orange
 */
+ (UIColor * _Nonnull) bonfireOrangeWithLevel:(int)level;

/**
 *  Bonfire yellow color of the specified level
 *
 *  @param level The level of color from 50,100-900 (increment of 100)
 *
 *  @return UIColor representing the bonfire color yellow
 */
+ (UIColor * _Nonnull) bonfireYellowWithLevel:(int)level;

/**
 *  Bonfire lime color of the specified level
 *
 *  @param level The level of color from 50,100-900 (increment of 100)
 *
 *  @return UIColor representing the bonfire color lime
 */
+ (UIColor * _Nonnull) bonfireLimeWithLevel:(int)level;

/**
 *  Bonfire green color of the specified level
 *
 *  @param level The level of color from 50,100-900 (increment of 100)
 *
 *  @return UIColor representing the bonfire color green
 */
+ (UIColor * _Nonnull) bonfireGreenWithLevel:(int)level;

/**
 *  Bonfire teal color of the specified level
 *
 *  @param level The level of color from 50,100-900 (increment of 100)
 *
 *  @return UIColor representing the bonfire color teal
 */
+ (UIColor * _Nonnull) bonfireTealWithLevel:(int)level;

/**
 *  Bonfire cyan color of the specified level
 *
 *  @param level The level of color from 50,100-900 (increment of 100)
 *
 *  @return UIColor representing the bonfire color cyan
 */
+ (UIColor * _Nonnull) bonfireCyanWithLevel:(int)level;

/**
 *  Bonfire brand color of level 500
 *
 *  @return UIColor representing the bonfire brand color at level 500
 */
+ (UIColor * _Nonnull)bonfireBrand;

/**
 *  Bonfire gray color of level 500
 *
 *  @return UIColor representing the bonfire color gray at level 500
 */
+ (UIColor * _Nonnull)bonfireGray;

/**
 *  Bonfire blue color of level 500
 *
 *  @return UIColor representing the bonfire color blue at level 500
 */
+ (UIColor * _Nonnull)bonfireBlue;

/**
 *  Bonfire indigo color of level 500
 *
 *  @return UIColor representing the bonfire color indigo at level 500
 */
+ (UIColor * _Nonnull)bonfireIndigo;

/**
 *  Bonfire violet color of level 500
 *
 *  @return UIColor representing the bonfire color violet at level 500
 */
+ (UIColor * _Nonnull)bonfireViolet;

/**
 *  Bonfire fuschia color of level 500
 *
 *  @return UIColor representing the bonfire color fuschia at level 500
 */
+ (UIColor * _Nonnull)bonfireFuschia;

/**
 *  Bonfire pink color of level 500
 *
 *  @return UIColor representing the bonfire color pink at level 500
 */
+ (UIColor * _Nonnull)bonfirePink;

/**
 *  Bonfire red color of level 500
 *
 *  @return UIColor representing the bonfire color red at level 500
 */
+ (UIColor * _Nonnull)bonfireRed;

/**
 *  Bonfire orange color of level 500
 *
 *  @return UIColor representing the bonfire color orange at level 500
 */
+ (UIColor * _Nonnull)bonfireOrange;

/**
 *  Bonfire yellow color of level 500
 *
 *  @return UIColor representing the bonfire color yellow at level 500
 */
+ (UIColor * _Nonnull)bonfireYellow;

/**
 *  Bonfire lime color of level 500
 *
 *  @return UIColor representing the bonfire color lime at level 500
 */
+ (UIColor * _Nonnull)bonfireLime;

/**
 *  Bonfire green color of level 500
 *
 *  @return UIColor representing the bonfire color green at level 500
 */
+ (UIColor * _Nonnull)bonfireGreen;

/**
 *  Bonfire teal color of level 500
 *
 *  @return UIColor representing the bonfire color teal at level 500
 */
+ (UIColor * _Nonnull)bonfireTeal;

/**
 *  Bonfire cyan color of level 500
 *
 *  @return UIColor representing the bonfire color cyan at level 500
 */
+ (UIColor * _Nonnull)bonfireCyan;

/**
 *  Bonfire text field background color on white
 *
 *  @return UIColor representing the bonfire text field background color on white
 */
+ (UIColor * _Nonnull) bonfireTextFieldBackgroundOnWhite;

/**
 *  Bonfire text field background color on light
 *
 *  @return UIColor representing the bonfire text field background color on light
 */
+ (UIColor * _Nonnull) bonfireTextFieldBackgroundOnLight;

/**
 *  Bonfire text field background color on dark
 *
 *  @return UIColor representing the bonfire text field background color on dark
 */
+ (UIColor * _Nonnull) bonfireTextFieldBackgroundOnDark;

@end

NS_ASSUME_NONNULL_END
