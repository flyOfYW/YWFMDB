//
//  YWFieldFilter.h
//  YWFMDBExamples
//
//  Created by yaowei on 2019/3/11.
//  Copyright © 2019 yaowei. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 运算符（按覆盖索引的优先级顺序排序）

typedef NS_ENUM(NSInteger, FieldFilterOperator) {
    // 等于
    eq = 0,
    // 大于
    gt = 1,
    // 小于
    lt = 2,
    // 大于等于
    ge = 3,
    // 小于等于
    le = 4,
    // 为Null
    isNull = 5,
    // 包含
    ins = 6,
    // 不等于
    ne = 7,
    // 不为NULL
    isNotNull = 8,
    //相似
    like = 9,
};
//连接符（多个YWFieldFilter之间的连接符）
typedef NS_ENUM(NSInteger, YWFieldConnector) {
    DEFALUT = 0,//默认
    //
    AND = 1,
    // 大于
    OR = 2,
};
@interface YWFieldFilter : NSObject
// 字段
@property (nonatomic,  copy) NSString * field;
//值
@property (nonatomic,  strong) id value;
//运算符
@property (nonatomic, assign) FieldFilterOperator fOperator;
//连接符
@property (nonatomic, assign) YWFieldConnector connector;
//便利构造
+ (YWFieldFilter *)fieldFilterWithField:(NSString*)field operator:(FieldFilterOperator)fOperator value:(id)value;
//便利构造,如果存在多个YWFieldFilter时，开发者可以根据sql语法来选择是and还是or
+ (YWFieldFilter *)fieldFilterWithField:(NSString*)field operator:(FieldFilterOperator)fOperator value:(id)value connector:(YWFieldConnector)connector;
//处理like和非like(第一个是nonlike,第二个是like)
+ (NSArray *)preProcessFieldFilters:(NSArray <YWFieldFilter*> *)fieldFilters;
//获取操作符的字符串
- (NSString *)toSqlOperator;
//获取连接符的字符串
- (NSString *)toSqlConnector;

@end

NS_ASSUME_NONNULL_END
