//
//  YWPageable.m
//  YWFMDBExamples
//
//  Created by yaowei on 2019/3/11.
//  Copyright © 2019 yaowei. All rights reserved.
//

#import "YWPageable.h"


@implementation YWPageable

+ (YWPageable *)pageablePage:(NSUInteger)page{
    YWPageable *pageObj = [YWPageable new];
    pageObj.page = page;
    pageObj.rows = 30;
    return pageObj;
}
+ (YWPageable *)pageablePage:(NSUInteger)page row:(NSUInteger)row{
    YWPageable *pageObj = [YWPageable new];
    pageObj.page = page;
    pageObj.rows = row;
    return pageObj;
}
@end
