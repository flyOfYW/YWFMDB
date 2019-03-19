//
//  YWFMDatabaseQueue.m
//  YWUserCenterSDkDemo
//
//  Created by yaowei on 2019/3/18.
//  Copyright © 2019 yaowei. All rights reserved.
//

#import "YWFMDatabaseQueue.h"
#import "YWFMDatabase.h"

@implementation YWFMDatabaseQueue
+ (Class)databaseClass{
    return [YWFMDatabase class];
}

@end
