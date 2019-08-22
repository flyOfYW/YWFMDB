//
//  NSObject+YWSqlModel.m
//  YWUserCenterSDkDemo
//
//  Created by yaowei on 2019/3/4.
//  Copyright © 2019 yaowei. All rights reserved.
//

#import "NSObject+YWSqlModel.h"

@implementation NSObject (YWSqlModel)
- (NSString *)sql_mainKey{
    return @"db_id";
}
- (NSString *)sql_mainKeyClass{
    return @"INTERGER";
}
- (NSString *)sql_tableName{
    return NSStringFromClass(self.class);
}
- (NSNumber *)sql_version{
    return @1.0;
}
- (NSSet<NSString *>*)sql_ignoreTheField{
    return nil;
}
- (NSSet<NSString *>*)sql_CustomClassAsField{
    return nil;
}
@end
