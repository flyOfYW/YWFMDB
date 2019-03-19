//
//  YWFunction.h
//  YWFMDBExamples
//
//  Created by yaowei on 2019/3/14.
//  Copyright © 2019 yaowei. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YWFunctionType) {
    YWFunctionCount   = 0,//COUNT 函数 (计算一个数据库表中的行数)
    YWFunctionMax     = 1,// MAX 函数 (允许我们选择某列的最大值)
    YWFunctionMin     = 2,// Min 函数 (允许我们选择某列的最小值)
    YWFunctionAvg     = 3,// AVG 函数 (计算某列的平均值)
    YWFunctionSum     = 4,// SUM 函数 (计算一个数值列计算总和)
    YWFunctionAbs     = 5,// ABS 函数 (返回数值参数的绝对值)
    YWFunctionUpper   = 6,// UPPER 函数 (字符串转换为大写字母)
    YWFunctionLower   = 7,// LOWER 函数 (字符串转换为小写字母)
    YWFunctionLength  = 8,// LENGTH 函数 (返回字符串的长度)
};


@interface YWFunction : NSObject

@property (nonatomic, assign) YWFunctionType func;
// 字段
@property (nonatomic,  copy) NSString * field;
//便利构造
+ (YWFunction *)funcionWithField:(NSString*)field function:(YWFunctionType)func;

- (NSString *)toSqlFunction;

@end

NS_ASSUME_NONNULL_END
