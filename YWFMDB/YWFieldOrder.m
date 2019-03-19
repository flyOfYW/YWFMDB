//
//  YWFieldOrder.m
//  YWFMDBExamples
//
//  Created by yaowei on 2019/3/11.
//  Copyright © 2019 yaowei. All rights reserved.
//

#import "YWFieldOrder.h"

@implementation YWFieldOrder
+ (YWFieldOrder*) fieldOrderWithField:(NSString*)field direction:(FieldOrderDirection)direction{
    YWFieldOrder *fieldOrder = [YWFieldOrder new];
    fieldOrder.field = field;
    fieldOrder.direction = direction;
    return fieldOrder;
}
-(NSString *)toSqlDirection{
    NSString* ret = @"desc";
    switch (self.direction) {
        case desc:
            ret = @"desc";
            break;
        case asc:
            ret = @"asc";
            break;
    }
    return ret;
}
@end
