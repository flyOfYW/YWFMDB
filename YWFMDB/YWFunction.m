//
//  YWFunction.m
//  YWFMDBExamples
//
//  Created by yaowei on 2019/3/14.
//  Copyright © 2019 yaowei. All rights reserved.
//

#import "YWFunction.h"

@implementation YWFunction
+ (YWFunction *)funcionWithField:(NSString*)field function:(YWFunctionType)func{
    YWFunction *fun = [YWFunction new];
    fun.func = func;
    fun.field = field;
    return fun;
}
- (NSString *)toSqlFunction{
    NSString* ret = @"";
    switch (self.func) {
        case YWFunctionCount:
            ret = @"count(*)";
            break;
        case YWFunctionMax:
            ret = [NSString stringWithFormat:@"max(%@)",self.field];
            break;
        case YWFunctionMin:
            ret = [NSString stringWithFormat:@"min(%@)",self.field];
            break;
        case YWFunctionAvg:
            ret = [NSString stringWithFormat:@"avg(%@)",self.field];
            break;
        case YWFunctionSum:
            ret = [NSString stringWithFormat:@"sum(%@)",self.field];
            break;
        case YWFunctionAbs:
            ret = [NSString stringWithFormat:@"abs(%@)",self.field];
            break;
        case YWFunctionUpper:
            ret = [NSString stringWithFormat:@"upper(%@)",self.field];
            break;
        case YWFunctionLower:
            ret = [NSString stringWithFormat:@"lower(%@)",self.field];
            break;
        case YWFunctionLength:
            ret = [NSString stringWithFormat:@"length(%@)",self.field];
            break;
    }
    return ret;

}
@end
