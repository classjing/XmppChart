//
//  Common.h
//  企信通
//
//  Created by apple on 14-3-5.
//  Copyright (c) 2014年 itcast. All rights reserved.
//

#import "DDLog.h"
#import "DDTTYLogger.h"
#import "NSString+Helper.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_OFF;
#endif



// 1.判断是否为iPhone5的宏
#define iPhone5 ([UIScreen mainScreen].bounds.size.height == 568)

// 2.日志输出宏定义
#ifdef DEBUG
// 调试状态
#define MyLog(...) NSLog(__VA_ARGS__)
#else
// 发布状态
#define MyLog(...)
#endif
//判断是否为ios7
#define ISIOS7 ([[UIDevice currentDevice].systemVersion floatValue] >= 7.0f)



#define kFileServerURL @"http://182.18.23.244" //文件服务器路径
