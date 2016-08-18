//
//  Const.h
//  QRCode
//
//  Created by 黄利强 on 16/8/18.
//  Copyright © 2016年 黄利强. All rights reserved.
//

#ifndef Const_h
#define Const_h

#pragma mark - Tool

#ifdef DEBUG
#   define MDLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#   define MDLog(...)
#endif

#define FONT_WITH_SIZE(fontSize) [UIFont systemFontOfSize:(fontSize)]
#define BOLD_FONT_WITH_SIZE(fontSize) [UIFont boldSystemFontOfSize:(fontSize)]

#define UICOLOR_RGB(hex) [UIColor colorWithRed:((hex)>>16)*1.0/255.0 green:(((hex)&0x00FF00)>>8)*1.0/255.0 blue:((hex)&0x0000FF)*1.0/255.0 alpha:1]

#define DEVICE_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define DEVICE_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define DEVICE_VERSION ([[UIDevice currentDevice].systemVersion doubleValue])
#define DEVICE_SCALE ([UIScreen mainScreen].scale)


#endif /* Const_h */
