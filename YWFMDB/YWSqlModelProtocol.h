//
//  YWSqlModelProtocol.h
//  YWFMDBExamples
//
//  Created by yaowei on 2019/3/7.
//  Copyright © 2019 yaowei. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol YWSqlModelProtocol <NSObject>
@optional
/**
 自定义主键名，切勿可跟对象的属性名一样
 
 @return 主键名（默认db_id）
 */
- (NSString *)sql_mainKey;
/**
 自定义主键对应的类型（TEXT\INTERGER）
 
 @return 主键名（默认INTERGER）
 */
- (NSString *)sql_mainKeyClass;
/**
 表名（默认是model的类名）

 @return 表名
 */
- (NSString *)sql_tableName;
/**
 表的版本号（默认1.0）

 @return 表的版本号
 */
- (NSNumber *)sql_version;
/**
 忽略的存储字段

 @return 忽略的存储字段
 */
- (NSSet<NSString *>*)sql_ignoreTheField;
/**
 声明一个属性为自定义类的时候，用此z属性
 
 @return 自定义类名
 */
- (NSSet<NSString *>*)sql_CustomClassAsField;

@end
NS_ASSUME_NONNULL_END
