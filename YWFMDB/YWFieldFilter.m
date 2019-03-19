//
//  YWFieldFilter.m
//  YWFMDBExamples
//
//  Created by yaowei on 2019/3/11.
//  Copyright © 2019 yaowei. All rights reserved.
//

#import "YWFieldFilter.h"

@implementation YWFieldFilter

+ (YWFieldFilter *)fieldFilterWithField:(NSString*)field operator:(FieldFilterOperator)fOperator value:(id)value{
    YWFieldFilter *fl = [YWFieldFilter new];
    fl.field = field;
    fl.fOperator = fOperator;
    fl.value = value;
    return fl;
}
+ (YWFieldFilter *)fieldFilterWithField:(NSString*)field operator:(FieldFilterOperator)fOperator value:(id)value connector:(YWFieldConnector)connector{
    YWFieldFilter *fl = [self fieldFilterWithField:field operator:fOperator value:value];
    fl.connector = connector;
    return fl;
}
//处理like和非like
+ (NSArray *)preProcessFieldFilters:(NSArray <YWFieldFilter*> *)fieldFilters{
    NSMutableArray <YWFieldFilter*>* nonLikeFilters = [NSMutableArray arrayWithCapacity:1];
    NSMutableArray <YWFieldFilter*>* likeFilters = [NSMutableArray arrayWithCapacity:1];
    for (YWFieldFilter *fl in fieldFilters) {
        
        if (fl.fOperator == like) {
            [likeFilters addObject:fl];
        }else{
            [nonLikeFilters addObject:fl];
        }
    }
    return @[nonLikeFilters.copy,likeFilters.copy];
}
- (NSString *)toSqlConnector{
    NSString* ret = nil;
    switch (self.connector) {
        case AND:
            ret = @" and ";
            break;
        case OR:
            ret = @" or ";
            break;
        default:
            break;
        
    }
    return ret;
}
- (NSString *)toSqlOperator{
    NSString* ret = nil;
    switch (self.fOperator) {
        case eq:
            ret = @"=";
            break;
        case ne:
            ret = @"<>";
            break;
        case gt:
            ret = @">";
            break;
        case lt:
            ret = @"<";
            break;
        case ge:
            ret = @">=";
            break;
        case le:
            ret = @"<=";
            break;
        case like:
            ret = @"like";
            break;
        case ins:
            ret = @"in";
            break;
        case isNull:
            ret = @"is null";
            break;
        case isNotNull:
            ret = @"is not null";
            break;
    }
    return ret;
}

@end
