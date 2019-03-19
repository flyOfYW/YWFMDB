//
//  YWFMDatabase.m
//  YWUserCenterSDkDemo
//
//  Created by yaowei on 2019/3/18.
//  Copyright © 2019 yaowei. All rights reserved.
//

#import "YWFMDatabase.h"

static NSString *encryptKey = @"FDLSAFJEIOQJR34JRI4JIGR93209T489FR";

@implementation YWFMDatabase

- (BOOL)open {
    if ([super open]) {
        BOOL en = [self setKey:[NSString stringWithFormat:@"%@",encryptKey]];
        if (!en) {
            NSLog(@"⚠️数据库加密失败");
        }
        return YES;
    }
    return NO;
}

- (BOOL)openWithFlags:(int)flags {
    return [self openWithFlags:flags vfs:nil];
}

- (BOOL)openWithFlags:(int)flags vfs:(NSString *)vfsName {
    if ([super openWithFlags:flags vfs:vfsName]) {
        BOOL en = [self setKey:[NSString stringWithFormat:@"%@",encryptKey]];
        if (!en) {
            NSLog(@"⚠️数据库加密失败");
        }
        return YES;
    }
    return NO;
}

- (const char*)sqlitePath {
    if (!self.databasePath) {
        return ":memory:";
    }
    
    if ([self.databasePath length] == 0) {
        return ""; // this creates a temporary database (it's an sqlite thing).
    }
    
    return [self.databasePath fileSystemRepresentation];
    
}
+ (void)setEncryptKey:(NSString *)encryptKey{
    if (!encryptKey || encryptKey.length <= 0) {
        NSLog(@"⚠️秘钥不能为空");
        return;
    }
    encryptKey = [NSString stringWithFormat:@"%@",encryptKey];
}
@end
