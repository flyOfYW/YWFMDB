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


@end
NS_ASSUME_NONNULL_END
