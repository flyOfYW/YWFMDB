//
//  YWFMDatabase.h
//  YWUserCenterSDkDemo
//
//  Created by yaowei on 2019/3/18.
//  Copyright © 2019 yaowei. All rights reserved.
//

#import <FMDB/FMDatabase.h>

NS_ASSUME_NONNULL_BEGIN

@interface YWFMDatabase : FMDatabase
+ (void)setEncryptKey:(NSString *)encryptKey;
@end

NS_ASSUME_NONNULL_END
