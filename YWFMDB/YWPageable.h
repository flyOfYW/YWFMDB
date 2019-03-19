//
//  YWPageable.h
//  YWFMDBExamples
//
//  Created by yaowei on 2019/3/11.
//  Copyright © 2019 yaowei. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YWPageable : NSObject
// 页码
@property (nonatomic,assign) NSUInteger page;
// 每页记录数
@property (nonatomic,assign) NSUInteger rows;
+ (YWPageable *)pageablePage:(NSUInteger)page;
+ (YWPageable *)pageablePage:(NSUInteger)page row:(NSUInteger)row;
@end

NS_ASSUME_NONNULL_END
