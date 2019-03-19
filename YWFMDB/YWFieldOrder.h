//
//  YWFieldOrder.h
//  YWFMDBExamples
//
//  Created by yaowei on 2019/3/11.
//  Copyright © 2019 yaowei. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


typedef NS_ENUM(NSInteger, FieldOrderDirection) {
    asc   = 0,
    desc   = 1,
};


@interface YWFieldOrder : NSObject

@property (nonatomic, assign) FieldOrderDirection direction;
// 字段
@property (nonatomic,  copy) NSString * field;
//便利构造
+ (YWFieldOrder*) fieldOrderWithField:(NSString*)field direction:(FieldOrderDirection)direction;

-(NSString *)toSqlDirection;

@end

NS_ASSUME_NONNULL_END
