//
//  YWFMDB.h
//  YWFMDBExamples
//
//  Created by yaowei on 2019/3/7.
//  Copyright © 2019 yaowei. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YWFieldFilter.h"
#import "YWFieldOrder.h"
#import "YWPageable.h"
#import "YWFunction.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YWFMDBExportType) {
    CSV   = 0,
    TXT   = 1,
};

@interface YWFMDB : NSObject
/**
 获取全局的唯一对象

 @return 对象
 */
+ (instancetype)standardYWFMDBDefaults;
/**
 连接（创建、连接、重连DB）

 @param dbPath 数据库的路径(如:xxx/xxx/yw.db)
 */
+ (void)connectionDB:(NSString *)dbPath;
/**
 连接加密的数据库（创建、连接、重连DB）
 
 @param dbPath 数据库的路径(如:xxx/xxx/yw.db)
 @param key 秘钥
 */
+ (void)connectionEncryptionDB:(NSString *)dbPath enKey:(NSString *)key;
/**
 关闭数据库
 */
+ (void)close;
/**
 判断数据库中的数据表是否存在
 
 @param tableName 的表名
 @return YES/NO
 */
+ (BOOL)tableExists:(NSString *)tableName;
/**
 获取版本号

 @return 版本号
 */
+ (NSString *)version;
//MARK: -------------------------- 存储 ------------------------------------
/**
 批量存储model（1、判断表是否存在；2、开始存入数据）(默认检测model的版本号)
 
 @param model model的数组
 @return 存储成功与否
 */
+ (BOOL)storageModels:(NSArray<NSObject*>*)model;
/**
 批量存储model
 
 @param model model的数组
 @param isAuto 是否自动根据model的版本号检测表结构是否发生变化(新增字段或者删除字段)(根据需要选择)
 @return 存储成功与否
 */
+ (BOOL)storageModels:(NSArray<NSObject*>*)model checkTableStructure:(BOOL)isAuto;
/**
 存储单个model（1、判断表是否存在；2、开始存入数据）(默认检测model的版本号)
 
 @param model model的数组
 @return 存储成功与否
 */
+ (BOOL)storageModel:(NSObject*)model;
/**
 存储单个model
 
 @param model model的数组
 @param isAuto 是否自动根据model的版本号检测表结构是否发生变化(新增字段或者删除字段)(根据需要选择)
 @return 存储成功与否
 */
+ (BOOL)storageModel:(NSObject*)model checkTableStructure:(BOOL)isAuto;

/**
 see also：当超多50条记录时，优先删除count最小的数据，在存储当前的数据，参数值：ifExceed=>50，orderBy=>count, desc=>YES
 */

/// 批量存储（限制多少条数据，一旦超过，先删除在插入）
/// @param models model的数组
/// @param count 记录的阀值
/// @param by 具体删除的条件（该字段必须是NSInteger的数据基本类型）
/// @param desc 删除条件的排序
/// @param isAuto 存储的时候，是否自动检查字段是否有更新
+ (BOOL)storageModels:(NSArray<NSObject *> *)models
             ifExceed:(NSInteger)count
              orderBy:(NSString *)by
                 desc:(BOOL)desc
  checkTableStructure:(BOOL)isAuto;

//MARK: ------------------------------------- 更新 ------------------------------------
/**
 更新本地存储的model数据
 
 @param model model
 @param automatic 是否需要自动检测表是否有新增的字段（如果确定没有新增的字典，请传入NO,可以节省一定的开支）(根据需要选择)
 @param wheres 筛选条件
 @return 更新成功与否
 */
+ (BOOL)updateWithModel:(NSObject *)model checkTableStructure:(BOOL)automatic where:(NSArray<YWFieldFilter *> *)wheres;
/**
 指定更新本地存储的model的特定数据

 @param modelClass model的类名
 @param specifiedValue 指定的值
 @param automatic 是否需要自动检测表是否有新增的字段（如果确定没有新增的字典，请传入NO,可以节省一定的开支）(根据需要选择)
 @param wheres 筛选条件
 @return 更新成功与否
 */
+ (BOOL)updateWithModel:(Class)modelClass specifiedValue:(NSDictionary *)specifiedValue checkTableStructure:(BOOL)automatic where:(NSArray<YWFieldFilter *> *)wheres;
//MARK: ------------------------------ 查询操作 ----------------------------------------------
/**
 查询本地存储的模型对象
 
 @param cls model的类型
 @return 模型对象集合
 */
+ (NSArray *)queryWithModel:(Class)cls;
/**
 查询指定条件的本地存储的模型对象

 @param cls model的类型
 @param wheres 筛选条件
 @return 模型对象集合
 */
+ (NSArray *)queryWithModel:(Class)cls where:(NSArray<YWFieldFilter *> *)wheres;
/**
 查询指定条件的本地存储的模型对象(结果排序)
 
 @param cls model的类型
 @param orders 排序条件
 @return 模型对象集合
 */
+ (NSArray *)queryWithModel:(Class)cls order:(NSArray<YWFieldOrder *> *)orders;
/**
 分页查询指定条件的本地存储的模型对象
 
 @param cls model的类型
 @param page 分页
 @return 模型对象集合
 */
+ (NSArray *)queryWithModel:(Class)cls limit:(YWPageable *)page;
/**
 查询指定条件的本地存储的模型对象,结果并按指定的条件进行排序
 
 @param cls model的类型
 @param wheres 筛选条件
 @param orders 排序条件
 @return 模型对象集合
 */
+ (NSArray *)queryWithModel:(Class)cls where:(NSArray<YWFieldFilter *> *)wheres order:(NSArray<YWFieldOrder *> *)orders;
/**
 分页查询指定条件的本地存储的模型对象,结果并按指定的条件进行排序
 
 @param cls model的类型
 @param wheres 筛选条件
 @param page 分页
 @return 模型对象集合
 */
+ (NSArray *)queryWithModel:(Class)cls where:(NSArray<YWFieldFilter *> *)wheres limit:(YWPageable *)page;
/**
 分页查询本地存储的模型对象,结果并按指定的条件进行排序
 
 @param cls model的类型
 @param orders 排序条件
 @param page 分页
 @return 模型对象集合
 */
+ (NSArray *)queryWithModel:(Class)cls order:(NSArray<YWFieldOrder *> *)orders limit:(YWPageable *)page;
/**
 分页查询指定条件的本地存储的模型对象,结果并按指定的条件进行排序
 
 @param cls model的类型
 @param wheres 筛选条件
 @param orders 排序条件
 @param page 分页
 @return 模型对象集合
 */
+ (NSArray *)queryWithModel:(Class)cls where:(NSArray<YWFieldFilter *> *)wheres order:(NSArray<YWFieldOrder *> *)orders limit:(YWPageable *)page;
/**
 函数查询

 @param cls model的类型
 @param function 函数条件
 @return 具体结果
 */
+ (NSArray *)queryWithModel:(Class)cls function:(NSArray<YWFunction *> *)function;

//MARK: ------------------------------------- 删除相关 ------------------------------------
/**
 删除该表（表和数据一起删除）
 
 @param table 表名
 @return 删除表成功与否
 */
+ (BOOL)dropTable:(NSString *)table;
/**
 删除该model对应的表所有数据
 
 @param cls model的类名
 @return 删除成功与否
 */
+ (BOOL)deleteTableWithModel:(Class)cls;
/**
 删除该表的所有数据

 @param table 表名
 @return 删除成功与否
 */
+ (BOOL)deleteTable:(NSString *)table;
/**
 删除该model指定条件的数据
 
 @param cls model的类名
 @param wheres 筛选条件
 @return 删除成功与否
 */
+ (BOOL)deleteTableWithModel:(Class)cls where:(NSArray<YWFieldFilter *> *)wheres;
/**
 删除该表指定条件的数据
 
 @param table 表名
 @param wheres 筛选条件
 @return 删除成功与否
 */
+ (BOOL)deleteTable:(NSString *)table where:(NSArray<YWFieldFilter *> *)wheres;

//MARK: ------------------------------------- 导出（CSV/TXT） ------------------------------------
/**
 导出数据表
 
 @param table 表名
 @param type csv/txt
 @return 导出的路径
 */
+ (NSString *)exportTable:(NSString *)table type:(YWFMDBExportType)type;

@end

NS_ASSUME_NONNULL_END
