//
//  YWFMDB.m
//  YWFMDBExamples
//
//  Created by yaowei on 2019/3/7.
//  Copyright © 2019 yaowei. All rights reserved.
//

#import "YWFMDB.h"
#import <FMDB/FMDatabaseAdditions.h>
#import "NSObject+YWSqlModel.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "YWFMDatabaseQueue.h"
#import "YWFMDatabase.h"

#define YW_String               @"TEXT"
#define YW_Number               @"DOUBLE"
#define YW_Data                 @"BLOB"//暂时不支持
#define YW_Array                @"BLOB"//暂时不支持
#define YW_Dictionary           @"BLOB"//暂时不支持
#define YW_MutableArray         @"BLOB"//暂时不支持
#define YW_MutableDictionary    @"BLOB"//暂时不支持
#define YW_Date                 @"DOUBLE"//暂时不支持
#define YW_Int                  @"INTERGER"
#define YW_Boolean              @"INTERGER"
#define YW_Double               @"DOUBLE"
#define YW_Float                @"DOUBLE"
#define YW_Char                 @"NVARCHAR"//暂时不支持


static const NSString *sqlKey = @"sql";
static const NSString *valueKey = @"values";

@interface YWFMDB ()
//当表字段（列）发生变化失败时，是否重新创建表（即model里的属性有增加或者减少时）
@property (nonatomic, assign,readwrite) BOOL needCreate;
//db的路径
@property (nonatomic, copy,  readwrite) NSString *dbPath;

@property (nonatomic, strong) FMDatabaseQueue *queue;

@end


static YWFMDB *singletonInstance = nil;

@implementation YWFMDB

+ (instancetype)standardYWFMDBDefaults{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singletonInstance = [[self alloc] init];
    });
    return singletonInstance;
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singletonInstance = [super allocWithZone:zone];
    });
    return singletonInstance;
}
- (id)copyWithZone:(struct _NSZone *)zone{
    return singletonInstance;
}
/**
 连接（创建、连接、重连DB）
 
 @param dbPath 数据库的路径(如:xxx/xxx/yw.db)
 */
+ (void)connectionDB:(NSString *)dbPath{
    if (!dbPath) {
        dbPath = [self dbPath];
    }
    NSLog(@"不加密db:%@",dbPath);
    if ([YWFMDB standardYWFMDBDefaults].queue) {//存在
        if ([dbPath isEqualToString:singletonInstance.dbPath]) {
            return;
        }
        [self close];
        singletonInstance.queue = nil;
        singletonInstance.dbPath = nil;
    }
    singletonInstance.dbPath = dbPath;
    singletonInstance.queue = [[FMDatabaseQueue alloc] initWithPath:dbPath];
    [self createVersionTable];
}
/**
 连接加密的数据库（创建、连接、重连DB）
 
 @param dbPath 数据库的路径(如:xxx/xxx/yw.db)
 @param key 秘钥
 */
+ (void)connectionEncryptionDB:(NSString *)dbPath enKey:(NSString *)key{
    if (!dbPath) {
        dbPath = [self dbPath];
    }
    NSLog(@"加密db:%@",dbPath);
    if ([YWFMDB standardYWFMDBDefaults].queue) {//存在
        if ([dbPath isEqualToString:singletonInstance.dbPath]) {
            [YWFMDatabase setEncryptKey:key];
            return;
        }
        [self close];
        singletonInstance.queue = nil;
        singletonInstance.dbPath = nil;
    }
    [YWFMDatabase setEncryptKey:key];
    singletonInstance.dbPath = dbPath;
    singletonInstance.queue = [[YWFMDatabaseQueue alloc] initWithPath:dbPath];
    [self createVersionTable];
}
/**
 关闭数据库
 */
+ (void)close{
    [singletonInstance.queue close];
}
/**
 判断数据库中的数据表是否存在
 
 @param tableName 的表名
 @return YES/NO
 */
+ (BOOL)tableExists:(NSString *)tableName{
    if (!singletonInstance.queue) {
        [self log:@"请先连接数据库"];
        return NO;
    }
    __block BOOL result = NO;
    [singletonInstance.queue inDatabase:^(FMDatabase * _Nonnull db) {
        result =  [db tableExists:tableName];
    }];
    return result;
}
/**
 删除该表
 
 @param table 表名
 @return 删除表成功与否
 */
+ (BOOL)dropTable:(NSString *)table{
    if (!singletonInstance.queue) {
        [self log:@"请先连接数据库"];
        return NO;
    }
    __block BOOL drop = NO;
    [singletonInstance.queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        drop = [db executeUpdate:[NSString stringWithFormat:@"drop table %@",table]];
        if (!drop) {
            *rollback = YES;
            return ;
        }
    }];
    return drop;
}
//MARK: -------------------------- 存储 ------------------------------------
/**
 批量存储model（1、判断表是否存在；2、开始存入数据）(默认检测model的版本号)
 
 @param model model的数组
 @return 存储成功与否
 */
+ (BOOL)storageModels:(NSArray<NSObject*>*)model{
    return [self storageModels:model checkTableStructure:YES];
}
/**
 批量存储model（1、判断表是否存在；2、开始存入数据）
 
 @param model model的数组
 @param isAuto 是否自动根据model的版本号检测表结构是否发生变化(新增字段或者删除字段)
 @return 存储成功与否
 */
+ (BOOL)storageModels:(NSArray<NSObject*>*)model checkTableStructure:(BOOL)isAuto{
    if (!singletonInstance.queue) {
        [self log:@"请先连接数据库"];
        return NO;
    }
    NSError *error = nil;
    //先判断是否存在表，不存在则创建
    BOOL isHave = [self createTable:model.firstObject error:&error];
    if (isHave) {
        //开始写入数据到数据库表中
        return [self startStorageModel:model tableExists:NO checkTableStructure:isAuto];
    }else{
        //已经存在的表
        if (error && error.code == -2) {
            return [self startStorageModel:model tableExists:YES checkTableStructure:isAuto];
        }
    }
    return NO;
}
/**
 存储单个model（1、判断表是否存在；2、开始存入数据）(默认检测model的版本号)
 
 @param model model的数组
 @return 存储成功与否
 */
+ (BOOL)storageModel:(NSObject*)model{
    return [self storageModel:model checkTableStructure:YES];
}
/**
 存储单个model（1、判断表是否存在；2、开始存入数据）
 
 @param model model的数组
 @param isAuto 是否自动根据model的版本号检测表结构是否发生变化(新增字段或者删除字段)
 @return 存储成功与否
 */
+ (BOOL)storageModel:(NSObject*)model checkTableStructure:(BOOL)isAuto{
    if (!singletonInstance.queue) {
        [self log:@"请先连接数据库"];
        return NO;
    }
    NSError *error = nil;
    //先判断是否存在表，不存在则创建
    BOOL isHave = [self createTable:model error:&error];
    if (isHave) {
        //开始写入数据到数据库表中
        return [self startStorageModel:@[model] tableExists:NO checkTableStructure:isAuto];
    }else{
        //已经存在的表
        if (error && error.code == -2) {
            return [self startStorageModel:@[model] tableExists:YES checkTableStructure:isAuto];
        }
    }
    return NO;
}
/**
 批量存储dict（1、判断表是否存在；2、开始存入数据）
 
 @param list list的数组
 @return 存储成功与否
 */
+ (BOOL)storageModels:(NSArray<NSDictionary*>*)list table:(NSString *)tableName{
    if (!singletonInstance.queue) {
        [self log:@"请先连接数据库"];
        return NO;
    }
    //先判断是否存在表，不存在则创建
     [self createTableDict:list.firstObject table:tableName];

    //批量插入操作，最好使用事务
     [singletonInstance.queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
         for (NSDictionary *obj in list) {
             NSDictionary *dict = [self insertTableSqlDict:obj table:tableName];
             if ([db executeUpdate:dict[sqlKey] withArgumentsInArray:dict[valueKey]]) {
                 dict = nil;
             }else{
                 [self log:@"插入数据失败"];
                 *rollback = YES;
                 dict = nil;
                 return ;
             }
         }
     }];
     return NO;
    
}
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
  checkTableStructure:(BOOL)isAuto{
    if (!singletonInstance.queue) {
        [self log:@"请先连接数据库"];
        return NO;
    }
    if (!models || models.count == 0) {
        [self log:@"传入的数组不存在或者个数为0"];
        return NO;
    }
    NSError *error = nil;
    //先判断是否存在表，不存在则创建
    BOOL isHave = [self createTable:models.firstObject error:&error];
    if (isHave) {
        //开始写入数据到数据库表中
        return [self startStorageModel:models tableExists:NO checkTableStructure:isAuto];
    }else{
        //已经存在的表
        if (error && error.code == -2) {
            NSString *table = models.firstObject.sql_tableName;
            NSString *mianKey = models.firstObject.sql_mainKey;
            NSString *descStr = desc ? @"desc":@"asc";
            NSString *byStr = by ? by : mianKey;
            NSString *deletSql = [NSString stringWithFormat:@"delete from %@ where (select count(%@) from %@ ) > %zi and %@ in (select %@ from %@ order by %@ %@ limit (select count(%@) from %@) offset %zi)",table,mianKey,table,count,mianKey,mianKey,table,byStr,descStr,mianKey,table,count];
            BOOL isRelust =  [self executeSql:deletSql value:@[]];
            if (!isRelust) {
                return NO;
            }
            return [self startStorageModel:models tableExists:YES checkTableStructure:isAuto];
        }
    }
    return YES;
}
/**
 开始写入数据
 
 @param models 模型集合
 @param exists 表是否已经存在了
 @return 是否成功
 */
+ (BOOL)startStorageModel:(NSArray<NSObject*>*)models tableExists:(BOOL)exists checkTableStructure:(BOOL)isAuto{
    
    NSObject * firstModel = models.firstObject;
    BOOL needAlert = NO;
    double sql_version = 1.0;
    if (isAuto) {
        //检测是否需要更新字段，以及更新字段成功的结果
        NSDictionary *relustls = [self upgradeTable:firstModel tableExists:exists];
        if (![relustls[@"updateTable"] boolValue]) {
            return NO;
        }
        needAlert = [relustls[@"needAlert"] boolValue];
        sql_version = [relustls[@"version"] doubleValue];
    }
    //批量插入操作，最好使用事务
    [singletonInstance.queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        for (NSObject *obj in models) {
            NSDictionary *dict = [self insertTableSqlModel:obj];
            if ([db executeUpdate:dict[sqlKey] withArgumentsInArray:dict[valueKey]]) {
                dict = nil;
            }else{
                [self log:@"插入数据失败"];
                *rollback = YES;
                dict = nil;
                return ;
            }
        }
    }];
    
    if (!exists) {//表不存在
        [self insertOrUpdate:YES table:firstModel.sql_tableName version:firstModel.sql_version];
    }else{
        if (needAlert) {
            if (sql_version == 0) {
                [self insertOrUpdate:YES table:firstModel.sql_tableName version:firstModel.sql_version];
            }else{
                [self insertOrUpdate:NO table:firstModel.sql_tableName version:firstModel.sql_version];
            }
        }
    }
    return YES;
}
//MARK: ------------------------------------- 更新 ------------------------------------
/**
 更新本地存储的model数据
 
 @param model model
 @param automatic 是否需要自动检测表是否有新增的字段（如果确定没有新增的字典，请传入NO,可以节省一定的开支）
 @param wheres 筛选条件
 @return 更新成功与否
 */
+ (BOOL)updateWithModel:(NSObject *)model checkTableStructure:(BOOL)automatic where:(NSArray<YWFieldFilter *> *)wheres{
    
    if (!singletonInstance.queue) {
        [self log:@"请先连接数据库"];
        return NO;
    }
    if (!wheres || wheres.count == 0) {
        [self log:@"更新数据，需要指定条件"];
        return NO;
    }
    BOOL needAlert = NO;
    double sql_version = 0;
    if (automatic) {
        //检测是否需要更新字段，以及更新字段成功的结果
        NSDictionary *relustls = [self upgradeTable:model tableExists:YES];
        if (![relustls[@"updateTable"] boolValue]) {
            return NO;
        }
        needAlert = [relustls[@"needAlert"] boolValue];
        sql_version = [relustls[@"version"] doubleValue];
    }
    
    NSDictionary *updateDict = [self updateTableSqlModel:model];
    
    NSDictionary *whereDict = [self whereFlieds:wheres];
    
    NSMutableArray *values = [[NSMutableArray alloc] initWithCapacity:2];
    
    [values addObjectsFromArray:updateDict[valueKey]];
    
    [values addObjectsFromArray:whereDict[valueKey]];
    
    NSString *sql = [NSString stringWithFormat:@"%@ where %@",updateDict[sqlKey],whereDict[sqlKey]];
    
    __block BOOL update = YES;
    
    [singletonInstance.queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        if (![db executeUpdate:sql withArgumentsInArray:values]) {
            update = NO;
            *rollback = YES;
            [self log:@"更新数据失败"];
            return ;
        }
    }];
    
    sql = nil;
    [values removeAllObjects];
    values = nil;
    updateDict = nil;
    whereDict = nil;
    
    if (needAlert) {
        if (sql_version == 0) {
            [self insertOrUpdate:YES table:model.sql_tableName version:model.sql_version];
        }else{
            [self insertOrUpdate:NO table:model.sql_tableName version:model.sql_version];
        }
    }
    return update;
}
/**
 指定更新本地存储的model的特定数据
 
 @param modelClass model的类名
 @param specifiedValue 指定的值
 @param automatic 是否需要自动检测表是否有新增的字段（如果确定没有新增的字典，请传入NO,可以节省一定的开支）
 @param wheres 筛选条件
 @return 更新成功与否
 */
+ (BOOL)updateWithModel:(Class)modelClass specifiedValue:(NSDictionary *)specifiedValue checkTableStructure:(BOOL)automatic where:(NSArray<YWFieldFilter *> *)wheres{
    if (!singletonInstance.queue) {
        [self log:@"请先连接数据库"];
        return NO;
    }
    if (!wheres || wheres.count == 0) {
        [self log:@"更新数据，需要指定条件"];
        return NO;
    }
    NSObject *model = [modelClass new];
    BOOL needAlert = NO;
    double sql_version = 0;
    if (automatic) {
        //检测是否需要更新字段，以及更新字段成功的结果
        NSDictionary *relustls = [self upgradeTable:model tableExists:YES];
        if (![relustls[@"updateTable"] boolValue]) {
            return NO;
        }
        needAlert = [relustls[@"needAlert"] boolValue];
        sql_version = [relustls[@"version"] doubleValue];
    }
    
    NSDictionary *updateDict = [self updateTableSqlSpecifiedValue:specifiedValue table:model.sql_tableName];
    
    NSDictionary *whereDict = [self whereFlieds:wheres];
    
    NSMutableArray *values = [[NSMutableArray alloc] initWithCapacity:2];
    
    [values addObjectsFromArray:updateDict[valueKey]];
    
    [values addObjectsFromArray:whereDict[valueKey]];
    
    NSString *sql = [NSString stringWithFormat:@"%@ where %@",updateDict[sqlKey],whereDict[sqlKey]];
    
    __block BOOL update = YES;
    
    [singletonInstance.queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        if (![db executeUpdate:sql withArgumentsInArray:values]) {
            update = NO;
            *rollback = YES;
            [self log:@"更新数据失败"];
            return ;
        }
    }];
    
    sql = nil;
    [values removeAllObjects];
    values = nil;
    updateDict = nil;
    whereDict = nil;
    
    if (needAlert) {
        if (sql_version == 0) {
            [self insertOrUpdate:YES table:model.sql_tableName version:model.sql_version];
        }else{
            [self insertOrUpdate:NO table:model.sql_tableName version:model.sql_version];
        }
    }
    return update;
    
}
//MARK: ----------------------------------------  创建表 --------------------------------------------
+ (BOOL)createTable:(NSObject *)model error:(NSError **)error{
    
    NSError *newError = nil;
    __block BOOL isSuccess = NO;
    if (![self tableExists:model.sql_tableName]) {//判断表是否已经存在
        //获取创建表的sql
        NSString *sql = [self createTableModel:model];
        [singletonInstance.queue inDatabase:^(FMDatabase * _Nonnull db) {
            isSuccess = [db executeUpdate:sql];
        }];
        if (!isSuccess) {
            newError = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:@"创建表失败"}];
        }
    }else{
        newError = [NSError errorWithDomain:NSCocoaErrorDomain code:-2 userInfo:@{NSLocalizedDescriptionKey:@"创建表失败,因表已经存在"}];
    }
    if (newError != nil) {
        if (error != NULL) {
            *error = newError;
        }
    }
    return isSuccess;
}
+ (BOOL)createTable:(NSString *)tableName fileds:(NSObject *)filed error:(NSError **)error{
    
    NSError *newError = nil;
    __block BOOL isSuccess = NO;
    if (![self tableExists:tableName]) {//判断表是否已经存在
        //获取创建表的sql
        NSString *sql = [self createTableModel:filed];
        [singletonInstance.queue inDatabase:^(FMDatabase * _Nonnull db) {
            isSuccess = [db executeUpdate:sql];
        }];
        if (!isSuccess) {
            newError = [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey:@"创建表失败"}];
        }
    }else{
        newError = [NSError errorWithDomain:NSCocoaErrorDomain code:-2 userInfo:@{NSLocalizedDescriptionKey:@"创建表失败,因表已经存在"}];
    }
    if (newError != nil) {
        if (error != NULL) {
            *error = newError;
        }
    }
    return isSuccess;
}
//MARK: ------------------------------------- 查询 ------------------------------------
/**
 查询本地存储的模型对象
 
 @param cls model的类型
 @return 模型对象集合
 */
+(NSArray *)queryWithModel:(Class)cls{
    if (!singletonInstance.queue) {
        [self log:@"请先连接数据库"];
        return @[];
    }
    NSObject *model = [cls new];
    NSString *sql = [self selectSql:nil table:model.sql_tableName];
    return [self queryCommon:sql withArgumentsInArray:@[] model:[cls new]];
}
/**
 查询指定条件的本地存储的模型对象
 
 @param cls model的类型
 @param wheres 筛选条件
 @return 模型对象集合
 */
+ (NSArray *)queryWithModel:(Class)cls where:(NSArray<YWFieldFilter *> *)wheres{
    if (!singletonInstance.queue) {
        [self log:@"请先连接数据库"];
        return @[];
    }
    if (!wheres || wheres.count == 0) {
        [self log:@"wheres为nil，已经默认查询全部，如查询有误，请录入正确的筛选条件"];
        return [self queryWithModel:cls];
    }
    NSObject *model = [cls new];
    NSString *sql = [self selectSql:nil table:model.sql_tableName];
    NSDictionary *dict = [self whereFlieds:wheres];
    return [self queryCommon:[NSString stringWithFormat:@"%@ where %@",sql,dict[sqlKey]] withArgumentsInArray:dict[valueKey] model:[cls new]];
}
/**
 查询指定条件的本地存储的模型对象(结果排序)
 
 @param cls model的类型
 @param orders 排序条件
 @return 模型对象集合
 */
+ (NSArray *)queryWithModel:(Class)cls order:(NSArray<YWFieldOrder *> *)orders{
    if (!singletonInstance.queue) {
        [self log:@"请先连接数据库"];
        return @[];
    }
    if (!orders || orders.count == 0) {
        [self log:@"wheres为nil，已经默认查询全部，如查询有误，请录入正确的筛选条件"];
        return [self queryWithModel:cls];
    }
    NSObject *model = [cls new];
    NSString *sql = [self selectSql:nil table:model.sql_tableName];
    return [self queryCommon:[NSString stringWithFormat:@"%@ %@",sql,[self orderFlieds:orders]] withArgumentsInArray:@[] model:[cls new]];
}
/**
 分页查询指定条件的本地存储的模型对象
 
 @param cls model的类型
 @param page 分页
 @return 模型对象集合
 */
+ (NSArray *)queryWithModel:(Class)cls limit:(YWPageable *)page{
    if (!singletonInstance.queue) {
        [self log:@"请先连接数据库"];
        return @[];
    }
    if (!page) {
        [self log:@"wheres为nil，已经默认查询全部，如查询有误，请录入正确的筛选条件"];
        return [self queryWithModel:cls];
    }
    NSObject *model = [cls new];
    NSString *sql = [self selectSql:nil table:model.sql_tableName];
    return [self queryCommon:[NSString stringWithFormat:@"%@ %@",sql,[self limitFlieds:page]] withArgumentsInArray:@[] model:[cls new]];
}
/**
 查询指定条件的本地存储的模型对象,结果并按指定的条件进行排序
 
 @param cls model的类型
 @param wheres 筛选条件
 @param orders 排序条件
 @return 模型对象集合
 */
+ (NSArray *)queryWithModel:(Class)cls where:(NSArray<YWFieldFilter *> *)wheres order:(NSArray<YWFieldOrder *> *)orders{
    
    if (!singletonInstance.queue) {
        [self log:@"请先连接数据库"];
        return @[];
    }
    NSObject *model = [cls new];
    NSString *sql = [self selectSql:nil table:model.sql_tableName];
    NSDictionary *dict = nil;
    if (!wheres || wheres.count == 0) {
        dict = [self whereFlieds:@[]];
    }else{
        dict = [self whereFlieds:wheres];
    }
    NSString *orderSql = @"";
    if (orders) {
        orderSql = [self orderFlieds:orders];
    }
    NSString *readySql = @"";
    if (!dict[sqlKey] || [dict[sqlKey] length] <= 0) {
        readySql = @"";
    }else{
        readySql = [NSString stringWithFormat:@"%@ where %@ %@",sql,dict[sqlKey],orderSql];
    }
    return [self queryCommon:readySql withArgumentsInArray:dict[valueKey] model:[cls new]];
    
}
/**
 查询指定条件的本地存储的模型对象,结果并按指定的条件进行排序
 
 @param cls model的类型
 @param wheres 筛选条件
 @param page 排序条件
 @return 模型对象集合
 */
+ (NSArray *)queryWithModel:(Class)cls where:(NSArray<YWFieldFilter *> *)wheres limit:(YWPageable *)page{
    
    if (!singletonInstance.queue) {
        [self log:@"请先连接数据库"];
        return @[];
    }
    NSObject *model = [cls new];
    NSString *sql = [self selectSql:nil table:model.sql_tableName];
    NSDictionary *dict = nil;
    if (!wheres || wheres.count == 0) {
        dict = [self whereFlieds:@[]];
    }else{
        dict = [self whereFlieds:wheres];
    }
    NSString *pageSql = @"";
    if (page) {
        pageSql = [self limitFlieds:page];
    }
    NSString *readySql = @"";
    if (!dict[sqlKey] || [dict[sqlKey] length] <= 0) {
        readySql = [NSString stringWithFormat:@"%@ %@",sql,pageSql];
    }else{
        readySql = [NSString stringWithFormat:@"%@ where %@ %@",sql,dict[sqlKey],pageSql];
    }
    return [self queryCommon:readySql withArgumentsInArray:dict[valueKey] model:[cls new]];
}
/**
 查询指定条件的本地存储的模型对象,结果并按指定的条件进行排序
 
 @param cls model的类型
 @param orders 排序条件
 @param page 分页
 @return 模型对象集合
 */
+ (NSArray *)queryWithModel:(Class)cls order:(NSArray<YWFieldOrder *> *)orders limit:(YWPageable *)page{
    if (!singletonInstance.queue) {
        [self log:@"请先连接数据库"];
        return @[];
    }
    NSString *orderSql = @"";
    if (orders) {
        orderSql = [self orderFlieds:orders];
    }
    NSString *pageSql = @"";
    if (page) {
        pageSql = [self limitFlieds:page];
    }
    NSObject *model = [cls new];
    NSString *sql = [self selectSql:nil table:model.sql_tableName];
    return [self queryCommon:[NSString stringWithFormat:@"%@ %@ %@",sql,orderSql,pageSql] withArgumentsInArray:@[] model:[cls new]];
}
/**
 分页查询指定条件的本地存储的模型对象,结果并按指定的条件进行排序
 
 @param cls model的类型
 @param wheres 筛选条件
 @param orders 排序条件
 @param page 分页
 @return 模型对象集合
 */
+ (NSArray *)queryWithModel:(Class)cls where:(NSArray<YWFieldFilter *> *)wheres order:(NSArray<YWFieldOrder *> *)orders limit:(YWPageable *)page{
    if (!singletonInstance.queue) {
        [self log:@"请先连接数据库"];
        return @[];
    }
    NSObject *model = [cls new];
    NSString *sql = [self selectSql:nil table:model.sql_tableName];
    NSDictionary *dict = nil;
    if (!wheres || wheres.count == 0) {
        dict = [self whereFlieds:@[]];
    }else{
        dict = [self whereFlieds:wheres];
    }
    NSString *orderSql = @"";
    if (orders) {
        orderSql = [self orderFlieds:orders];
    }
    NSString *pageSql = @"";
    if (page) {
        pageSql = [self limitFlieds:page];
    }
    NSString *readySql = @"";
    if (!dict[sqlKey] || [dict[sqlKey] length] <= 0) {
        readySql = [NSString stringWithFormat:@"%@ %@ %@",sql,orderSql,pageSql];
    }else{
        readySql = [NSString stringWithFormat:@"%@ where %@ %@ %@",sql,dict[sqlKey],orderSql,pageSql];
    }
    return [self queryCommon:readySql withArgumentsInArray:dict[valueKey] model:[cls new]];
}
/**
 分页查询指定条件的本地存储的数据,结果并按指定的条件进行排序【返回结果无需转成对象】
 
 @param tableName 表名
 @param fields 查询的字段集合
 @param wheres 筛选条件
 @param orders 排序条件
 @param page 分页
 @return 模型对象集合
 */
+ (NSArray *)queryWithTableName:(NSString *)tableName fields:(NSDictionary*)fields where:(NSArray<YWFieldFilter *> *)wheres order:(NSArray<YWFieldOrder *> *)orders limit:(YWPageable *)page{
    if (!singletonInstance.queue) {
          [self log:@"请先连接数据库"];
          return @[];
      }
      NSString *sql = [self selectSql:nil table:tableName];
      NSDictionary *dict = nil;
      if (!wheres || wheres.count == 0) {
          dict = [self whereFlieds:@[]];
      }else{
          dict = [self whereFlieds:wheres];
      }
      NSString *orderSql = @"";
      if (orders) {
          orderSql = [self orderFlieds:orders];
      }
      NSString *pageSql = @"";
      if (page) {
          pageSql = [self limitFlieds:page];
      }
      NSString *readySql = @"";
      if (!dict[sqlKey] || [dict[sqlKey] length] <= 0) {
          readySql = [NSString stringWithFormat:@"%@ %@ %@",sql,orderSql,pageSql];
      }else{
          readySql = [NSString stringWithFormat:@"%@ where %@ %@ %@",sql,dict[sqlKey],orderSql,pageSql];
      }
    return [self queryCommon:readySql withArgumentsInArray:dict[valueKey] tableName:tableName dict:fields];

    return nil;
}
/**
 函数查询
 
 @param cls model的类型
 @param function 函数条件
 @return 具体结果
 */
+ (NSArray *)queryWithModel:(Class)cls function:(NSArray<YWFunction *> *)function{
    
    if (!singletonInstance.queue) {
        [self log:@"请先连接数据库"];
        return nil;
    }
    if (!function) {
        return @[];
    }
    NSObject *model = [cls new];
    NSString *sql = [NSString stringWithFormat:@"select %@ from %@",[self functionFlieds:function],model.sql_tableName];
    __block NSMutableArray *marr = [NSMutableArray new];
    [singletonInstance.queue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet *resultSet = [db executeQuery:sql];
        int col = [resultSet columnCount];
        while ([resultSet next]) {
            for (int i = 0; i < col; i ++) {
                [marr addObject:[resultSet objectForColumnIndex:i]];
            }
        }
        [resultSet close];
    }];
    model = nil;
    return marr.copy;
}
//MARK: ------------------------------------- 删除相关 ------------------------------------
/**
 删除该model对应的表所有数据
 
 @param cls model的类名
 @return 删除成功与否
 */
+ (BOOL)deleteTableWithModel:(Class)cls{
    return [self deleteTable:[[cls new] sql_tableName]];
}
/**
 删除该表的所有数据
 
 @param table 表名
 @return 删除成功与否
 */
+ (BOOL)deleteTable:(NSString *)table{
    return [self deleteTableCommon:table where:@"" value:@[]];
}
/**
 删除该model指定条件的数据
 
 @param cls model的类名
 @param wheres 筛选条件
 @return 删除成功与否
 */
+ (BOOL)deleteTableWithModel:(Class)cls where:(NSArray<YWFieldFilter *> *)wheres{
    NSDictionary *wh;
    if (!wheres || wheres.count == 0) {
        [self log:@"wheres为空，默认删除表所有的数据"];
        wh = [self whereFlieds:@[]];
    }else{
        wh = [self whereFlieds:wheres];
    }
    return [self deleteTableCommon:[[cls new] sql_tableName] where:wh[sqlKey] value:wh[valueKey]];
}
/**
 删除该表指定条件的数据
 
 @param table 表名
 @param wheres 筛选条件
 @return 删除成功与否
 */
+ (BOOL)deleteTable:(NSString *)table where:(NSArray<YWFieldFilter *> *)wheres{
    NSDictionary *wh;
    if (!wheres || wheres.count == 0) {
        [self log:@"wheres为空，默认删除表所有的数据"];
        wh = [self whereFlieds:@[]];
    }else{
        wh = [self whereFlieds:wheres];
    }
    return [self deleteTableCommon:table where:wh[sqlKey] value:wh[valueKey]];
}
+ (BOOL)deleteTableCommon:(NSString *)table where:(NSString *)where value:(NSArray *)args{
    if (!singletonInstance.queue) {
        [self log:@"请先连接数据库"];
        return NO;
    }
    NSString *sql = @"";
    if (!where || [where length] <= 0) {
        sql = [NSString stringWithFormat:@"delete from %@",table];
    }else{
        sql = [NSString stringWithFormat:@"delete from %@ where %@",table,where];
    }
    __block BOOL re = NO;
    [singletonInstance.queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        re = [db executeUpdate:sql withArgumentsInArray:args];
        if (!re) {
            *rollback = YES;
            return ;
        }
    }];
    return re;
}

+ (BOOL)executeSql:(NSString *)sql value:(NSArray *)args{
    __block BOOL re = NO;
    [singletonInstance.queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        re = [db executeUpdate:sql withArgumentsInArray:args];
        if (!re) {
            *rollback = YES;
            return ;
        }
    }];
    return re;
}

//MARK: ------------------------------------- 导出（CSV/TXT） ------------------------------------
/**
 导出数据表
 
 @param table 表名
 @param type csv/txt
 @return 导出的路径
 */
+ (NSString *)exportTable:(NSString *)table type:(YWFMDBExportType )type{
    if (!singletonInstance.queue) {
        [self log:@"请先连接数据库"];
        return nil;
    }
    if (type == CSV) {
        return [self exportCsvTable:table];
    }
    if (type == TXT) {
        return [self exportTxtTable:table];
    }
    return nil;
}
+ (NSString *)exportTxtTable:(NSString *)table{
    NSString *tagertPath = [NSString stringWithFormat:@"%@/Library/Caches/%@.txt",NSHomeDirectory(),table];
    __block NSMutableArray *txts = [[NSMutableArray alloc] initWithCapacity:1];
    
    [singletonInstance.queue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet *result = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM %@",table]];
        int columnCount = [result columnCount];
        while ([result next]) {
            NSMutableDictionary *dict = [NSMutableDictionary new];
            for (int i = 0 ; i < columnCount;i ++) {
                [dict setValue:[NSString stringWithFormat:@"%@",[result objectForColumnIndex:i]] forKey:[result columnNameForIndex:i]];
            }
            [txts addObject:dict.copy];
            [dict removeAllObjects];
            dict = nil;
        }
        [result close];
    }];
    NSError *error = nil;
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:txts.copy options:NSJSONWritingPrettyPrinted error:&error];
    [txts removeAllObjects];
    txts = nil;
    if (error) {
        [self log:[NSString stringWithFormat:@"导出失败:%@",error.userInfo]];
        return nil;
    }
    
    [data writeToFile:tagertPath options:NSDataWritingAtomic error:&error];
    
    if (error) {
        [self log:[NSString stringWithFormat:@"导出失败:%@",error.userInfo]];
        return nil;
    }
    return tagertPath;
}
+ (NSString *)exportCsvTable:(NSString *)table{
    NSString *tagertPath = [NSString stringWithFormat:@"%@/Library/Caches/%@.csv",NSHomeDirectory(),table];
    __block NSMutableString *csv = [[NSMutableString alloc] initWithString:@""];
    [singletonInstance.queue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet *result = [db executeQuery:[NSString stringWithFormat:@"SELECT * FROM %@",table]];
        int columnCount = [result columnCount];
        for (int i = 0 ; i < columnCount;i ++) {
            [csv appendFormat:@"%@", [result objectForColumnIndex:i]];
            if (i != columnCount -1) {
                [csv appendString:@","];
            }else{
                [csv appendString:@"\n"];
            }
        }
        while ([result next]) {
            for (int i = 0 ; i < columnCount;i ++) {
                [csv appendFormat:@"%@", [result stringForColumnIndex:i]];
                if (i != columnCount -1) {
                    [csv appendString:@","];
                }else{
                    [csv appendString:@"\n"];
                }
            }
        }
        [result close];
    }];
    NSError *error = nil;
    [csv writeToFile:tagertPath
          atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        [self log:[NSString stringWithFormat:@"导出失败:%@",error.userInfo]];
    }
    return tagertPath;
}

//MARK: ------------------------------------- 修改表字段（升级表字段结构） ------------------------------------
/**
 升级表字段
 
 @param model 模型
 @return 结果
 */
+ (BOOL)upgradeTable:(NSObject *)model{
    
    __block BOOL upgradeSuecces = YES;
    
    NSMutableString *addString = [NSMutableString new];
    NSMutableString *deleteString = [NSMutableString new];
    NSMutableSet *set = [NSMutableSet set];
    NSMutableArray *oldList = [NSMutableArray new];//查询当前表的列元素
    [singletonInstance.queue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet *resultSet = [db getTableSchema:model.sql_tableName];
        while ([resultSet next]) {
            [oldList addObject:[resultSet stringForColumn:@"name"]];
        }
        [resultSet close];
    }];
    
    //先进行增减字段后，在进行更新数据表的数据
    NSDictionary *dict = [self propertyAndTypeOnModel:model];
    NSDictionary *propertys = [dict objectForKey:@"py"];//新model的字段
    int i = 0;
    for (NSString *column in oldList) {
        if (![propertys.allKeys containsObject:column]) {//在当前新model的字段列，找不到当前数据表的列字段，则是删除字段
            if (i == propertys.count - 1) {
                [deleteString appendString:column];
            }else{
                [deleteString appendString:column];
                [deleteString appendString:@","];
            }
        }
        i++;
    }
    
    i = 0;
    for (NSString *column in propertys.allKeys) {
        if (![oldList containsObject:column]) {//在当前的数据表的列字段里没有的字段，则是新增字段
            if (i == propertys.count - 1) {
                [addString appendString:column];
                [addString appendFormat:@" %@",propertys[column]];
            }else{
                [addString appendString:column];
                [addString appendFormat:@" %@,",propertys[column]];
            }
        }
        i++;
    }
    if (addString && addString.length > 0) {
        upgradeSuecces = [self addColumn:addString table:model.sql_tableName];//新增字段执行完毕
    }
    
    if (upgradeSuecces) {
        if (deleteString && deleteString.length > 0) {
            NSString *defalut = [NSString stringWithFormat:@"%@,",model.sql_mainKey];
            if (![deleteString isEqualToString:defalut]) {
                [set addObjectsFromArray:propertys.allKeys];
                [set addObjectsFromArray:oldList];
                NSMutableArray *commomList = set.allObjects.mutableCopy;//去掉重复的字段
                for (NSString *column in [deleteString componentsSeparatedByString:@","]) {
                    if (column.length > 0) {
                        [commomList removeObject:column];
                    }
                }
                NSMutableString *comStr = @"".mutableCopy;
                int q = 0;
                for (NSString *column in commomList) {
                    [comStr appendString:column];
                    if (q != commomList.count - 1) {
                        [comStr appendString:@","];
                    }
                    q++;
                }
                //删除字段
                upgradeSuecces = [self dropColumn:comStr table:model.sql_tableName mainKey:model.sql_mainKey];
                commomList = nil;
            }
            defalut = nil;
        }
        
    }
    return upgradeSuecces;
    
}
/**
 删除表的一列操作
 
 @param comStr 新表的字段
 @param table 原表名
 @return 删除成功与h否
 */
+ (BOOL)dropColumn:(NSString *)comStr table:(NSString *)table mainKey:(NSString *)mainKey{
    
    //进行删除字段操作，参考 https://www.sqlite.org/faq.html#q11
    NSString *newTable = [NSString stringWithFormat:@"%@_temp",table];
    NSString *newComStr = [NSString stringWithFormat:@"%@,%@",mainKey,comStr];
    NSMutableArray *dropList = [NSMutableArray new];
    [dropList addObject:[NSString stringWithFormat:@"CREATE TEMPORARY TABLE %@(%@ INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,%@)",newTable,mainKey,comStr]];
    [dropList addObject:[NSString stringWithFormat:@"INSERT INTO %@ SELECT %@ FROM %@;",newTable,newComStr,table]];
    [dropList addObject:[NSString stringWithFormat:@"DROP TABLE %@;",table]];
    [dropList addObject:[NSString stringWithFormat:@"CREATE  TABLE %@(%@ INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,%@)",table,mainKey,comStr]];
    [dropList addObject:[NSString stringWithFormat:@"INSERT INTO %@ SELECT %@ FROM %@;",table,newComStr,newTable]];
    [dropList addObject:[NSString stringWithFormat:@"DROP TABLE %@;",newTable]];
    
    //        BEGIN TRANSACTION;
    //        CREATE TEMPORARY TABLE t1_backup(a,b);
    //        INSERT INTO t1_backup SELECT a,b FROM t1;
    //        DROP TABLE t1;
    //        CREATE TABLE t1(a,b);
    //        INSERT INTO t1 SELECT a,b FROM t1_backup;
    //        DROP TABLE t1_backup;
    //        COMMIT;
    
    __block BOOL drop = NO;
    [singletonInstance.queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        for (NSString *sql in dropList) {
            if ([db executeUpdate:sql]) {
                drop = YES;
            }else{
                drop = NO;
                *rollback = YES;
                return ;
            }
        }
        
    }];
    newTable = nil;
    return drop;
}
/**
 增加列字段
 
 @param sql 语句
 @return 返回结果
 */
+ (BOOL)addColumn:(NSString *)sql table:(NSString *)table{
    //sqlite3 不支持增加多列
    __block BOOL add = NO;
    NSArray *list = [sql componentsSeparatedByString:@","];
    [singletonInstance.queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        for (NSString *obj in list) {
            if (obj.length <= 0) {
                continue;
            }
            NSString *addSql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD COLUMN %@",table, obj];
            [self log:[NSString stringWithFormat:@"新增字段sql:%@",addSql]];
            if ([db executeUpdate:addSql]) {
                add = YES;
                addSql = nil;
            }else{
                add = NO;
                *rollback = YES;
                addSql = nil;
                return ;
            }
        }
    }];
    return add;
}
//MARK: ----------------------------------------  组装sql语句 --------------------------------------------
+ (NSString *)createTableModel:(NSObject *)model{
    
    NSString *modelSql = [[self propertyAndTypeOnModel:model] objectForKey:@"createSql"];
    
    NSString *sql = [NSString stringWithFormat:@"%@%@)",[self createTableSqlWith:model modelSql:modelSql],modelSql];
    
    return sql;
}
+ (NSString *)createTableDict:(NSDictionary *)dict table:(NSString *)tableName{
    
     NSMutableArray *sqls = [NSMutableArray new];
    for (NSString *key in dict.allKeys) {
        id value = dict[key];
        if ([value isKindOfClass:NSString.class]) {
            [sqls addObject:[NSString stringWithFormat:@"%@ TEXT",key]];
        }else if ([value isKindOfClass:NSNumber.class]){
            [sqls addObject:[NSString stringWithFormat:@"%@ DOUBLE",key]];
        }else if ([value isKindOfClass:NSData.class]){
            [sqls addObject:[NSString stringWithFormat:@"%@ BLOB",key]];
        }else if ([value isKindOfClass:NSArray.class]){
            [sqls addObject:[NSString stringWithFormat:@"%@ BLOB",key]];
        }else if ([value isKindOfClass:NSMutableArray.class]){
            [sqls addObject:[NSString stringWithFormat:@"%@ BLOB",key]];
        }else if ([value isKindOfClass:NSDictionary.class]){
            [sqls addObject:[NSString stringWithFormat:@"%@ BLOB",key]];
        }else if ([value isKindOfClass:NSMutableDictionary.class]){
            [sqls addObject:[NSString stringWithFormat:@"%@ BLOB",key]];
        }
    }
    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"CREATE TABLE %@ (main_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,",tableName];
    [sql appendString:[sqls componentsJoinedByString:@","]];
    [sql appendString:@")"];
    
    return sql.copy;
}

+ (NSString *)createTableSqlWith:(NSObject *)model modelSql:(NSString *)modelSql{
    NSString *mainKeyClass = model.sql_mainKeyClass;
    if ([mainKeyClass isEqualToString:@"TEXT"]) {
        NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"CREATE TABLE %@ (%@ TEXT NOT NULL PRIMARY KEY%@",model.sql_tableName,model.sql_mainKey,modelSql.length == 0 ? @"": modelSql];
        return sql.copy;
    } else {
        return [self createTable:model.sql_tableName mainKey:model.sql_mainKey];
    }
}
/**
 依据model生成创建表的sql
 
 @param tableName 表名
 @param mainKey 主键（的值必须是基本数据类型）
 @return 创建表sql（CREATE TABLE %@ (%@ INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT）
 */
+ (NSString *)createTable:(NSString *)tableName mainKey:(NSString *)mainKey{
    
    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"CREATE TABLE %@ (%@ INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,",tableName,mainKey];
    
    return sql.copy;
}

/**
 创建中间表（主要用来维护表字段结构）
 
 @return 创建成功与否
 */
+ (BOOL)createVersionTable{
    __block BOOL result = [self tableExists:@"yw_sql_version"];
    if (!result) {//不存在该表
        [singletonInstance.queue inDatabase:^(FMDatabase * _Nonnull db) {
            result = [db executeUpdate:@"create table yw_sql_version (table_name TEXT PRIMARY KEY,version DOUBLE)"];
        }];
    }
    return result;
}
+ (NSDictionary *)insertTableSqlModel:(NSObject *)obj{
    NSDictionary *dict = [self propertysValueOnModel:obj];//@{@"name":@"yw"}
    NSMutableString *sqlQuestion = [[NSMutableString alloc] initWithString:@" values ("];
    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"insert into %@ (",obj.sql_tableName];
    NSMutableArray *valus = [[NSMutableArray alloc] initWithCapacity:3];
    int i = 0,count = (int)dict.allKeys.count;
    for (NSString *key in dict.allKeys) {
        [sql appendString:key];
        [sqlQuestion appendString:@"?"];
        [valus addObject:dict[key]];
        if (i != count - 1) {
            [sql appendString:@","];
            [sqlQuestion appendString:@","];
        }
        i++;
    }
    [sql appendString:@")"];
    [sqlQuestion appendString:@")"];
    NSString *readSql = [NSString stringWithFormat:@"%@%@",sql,sqlQuestion];
    sql = nil;
    sqlQuestion = nil;
    return @{sqlKey:readSql,valueKey:valus.copy};
}
+ (NSDictionary *)insertTableSqlDict:(NSDictionary *)obj table:(NSString *)tableName{
    NSDictionary *dict = obj;//@{@"name":@"yw"}
    NSMutableString *sqlQuestion = [[NSMutableString alloc] initWithString:@" values ("];
    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"insert into %@ (",tableName];
    NSMutableArray *valus = [[NSMutableArray alloc] initWithCapacity:3];
    int i = 0,count = (int)dict.allKeys.count;
    for (NSString *key in dict.allKeys) {
        [sql appendString:key];
        [sqlQuestion appendString:@"?"];
        [valus addObject:dict[key]];
        if (i != count - 1) {
            [sql appendString:@","];
            [sqlQuestion appendString:@","];
        }
        i++;
    }
    [sql appendString:@")"];
    [sqlQuestion appendString:@")"];
    NSString *readSql = [NSString stringWithFormat:@"%@%@",sql,sqlQuestion];
    sql = nil;
    sqlQuestion = nil;
    return @{sqlKey:readSql,valueKey:valus.copy};
}
+ (NSDictionary *)updateTableSqlSpecifiedValue:(NSDictionary *)dict table:(NSString *)table{
    return [self updateTableSqlCommon:table value:dict];
}
+ (NSDictionary *)updateTableSqlModel:(NSObject *)obj{
    NSDictionary *dict = [self propertysValueOnModel:obj];
    return [self updateTableSqlCommon:obj.sql_tableName value:dict];
}
+ (NSDictionary *)updateTableSqlCommon:(NSString *)tableName value:(NSDictionary *)dict{
    NSMutableString *sql = [[NSMutableString alloc] initWithFormat:@"update %@ set ",tableName];
    int i = 0;
    int co = (int)dict.allKeys.count;
    NSMutableArray *values = [[NSMutableArray alloc] initWithCapacity:3];
    for (NSString *field in dict.allKeys) {
        [sql appendFormat:@"%@ = ?",field];
        if (i != co - 1) {
            [sql appendString:@","];
        }
        [values addObject:dict[field]];
        i ++;
    }
    return @{sqlKey:sql.copy,valueKey:values.copy};
}
+ (NSString *)selectSql:(NSString *)conditions table:(NSString *)table{
    NSString *sql = nil;
    if (!conditions) {
        sql = [NSString stringWithFormat:@"select * from %@ ",table];
    }else{
        sql = [NSString stringWithFormat:@"select %@ from %@ ",conditions,table];
    }
    return sql;
}
+ (NSDictionary *)whereFlieds:(NSArray <YWFieldFilter *> *)wheres{
    
    NSArray *newWheres = [YWFieldFilter preProcessFieldFilters:wheres];
    
    NSArray <YWFieldFilter *>* nonLikes = newWheres.firstObject;
    
    NSArray <YWFieldFilter *>* likes = newWheres.lastObject;
    
    NSDictionary *nonLikeDict = @{};
    if (nonLikes.count > 0) {
        nonLikeDict = [self preFields:nonLikes connector:@" and "];
    }
    NSDictionary *likeDict = @{};
    if (likes.count > 0) {
        likeDict = [self preFields:likes connector:@" or "];
    }
    
    NSArray *likeValues = likeDict[valueKey];
    
    NSArray *nonLikeValues = nonLikeDict[valueKey];
    NSMutableString *sql = [[NSMutableString alloc] initWithString:@""];
    NSMutableArray *values = [[NSMutableArray alloc] initWithCapacity:1];
    
    if (likeValues.count > 0 && nonLikeValues.count > 0) {
        [sql appendFormat:@" %@ and ( %@ ) ", nonLikeDict[sqlKey], likeDict[sqlKey]];
        [values addObjectsFromArray:nonLikeValues];
        [values addObjectsFromArray:likeValues];
    }else{
        if (likeValues.count > 0) {
            [sql appendFormat:@" ( %@ ) ",likeDict[sqlKey]];
            [values addObjectsFromArray:likeValues];
        }else if (nonLikeValues.count > 0){
            [sql appendFormat:@" ( %@ ) ",nonLikeDict[sqlKey]];
            [values addObjectsFromArray:nonLikeValues];
        }
    }
    return @{sqlKey:sql.copy,valueKey:values.copy};
    
}
+ (NSDictionary *)preFields:(NSArray<YWFieldFilter *>*)fields connector:(NSString *)connector{
    
    NSMutableString *sql = [[NSMutableString alloc] initWithString:@""];
    NSMutableArray *values = [[NSMutableArray alloc] initWithCapacity:1];
    int i = 0;
    for (YWFieldFilter *fl in fields) {
        [sql appendFormat:@"%@",fl.field];
        [sql appendString:@" "];
        [sql appendFormat:@"%@",[fl toSqlOperator]];
        [sql appendString:@" ? "];
        if (!fl.value) {//防止添加空的数据
            [values addObject:@"null"];
        }else{
            [values addObject:fl.value];
        }
        if (i != fields.count - 1) {
            if (!fl.toSqlConnector) {
                [sql appendString:connector];
            }else{
                [sql appendString:fl.toSqlConnector];
            }
        }
        i ++;
    }
    return @{sqlKey:sql.copy,valueKey:values.copy};
}
+ (NSString *)orderFlieds:(NSArray <YWFieldOrder *> *)orders{
    
    NSMutableString *sql = [[NSMutableString alloc] initWithString:@""];
    int i = 0;
    for (YWFieldOrder *fo in orders) {
        [sql appendString:fo.field];
        [sql appendString:@" "];
        [sql appendFormat:@"%@",fo.toSqlDirection];
        if (i != orders.count - 1) {
            [sql appendString:@","];
        }
        [sql appendString:@" "];
    }
    if (!sql || sql.length <= 0) {
        return @"";
    }
    return [NSString stringWithFormat:@" order by %@",sql];
}
+ (NSString *)limitFlieds:(YWPageable *)page{
    if (page.rows == 0 && page.page == 0) {
        return @"";
    }
    return [NSString stringWithFormat:@" limit %zi offset %zi", page.rows, (page.rows * page.page)];
}

+ (NSString *)functionFlieds:(NSArray <YWFunction *> *)function{
    
    NSMutableString *sql = [[NSMutableString alloc] initWithString:@""];
    int i = 0;
    for (YWFunction *func in function) {
        [sql appendString:func.toSqlFunction];
        if (i != function.count - 1) {
            [sql appendString:@","];
        }
        i ++;
    }
    return sql.copy;
}
//MARK: ----------------------------- private method -------------------------------------
/**
 查询语句的执行
 
 @param sql 语句
 @param arg 值
 @param obj 对象
 @return 结果数组
 */
+ (NSArray *)queryCommon:(NSString *)sql
    withArgumentsInArray:(NSArray *)arg
                   model:(NSObject *)obj{
    
    if (![self tableExists:obj.sql_tableName]) {
        return @[];
    }
    //key-属性，value-属性的类型
    NSDictionary *propertyDict = [self propertysSetterOnModel:obj];
    NSDictionary *propertyType = [propertyDict objectForKey:@"sql"];
    NSDictionary *selDict = [propertyDict objectForKey:@"sel"];
    
    NSMutableArray *models = [NSMutableArray new];
    Class cls = obj.class;
    [singletonInstance.queue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet *resultSet = [db executeQuery:sql withArgumentsInArray:arg];
        while ([resultSet next]) {
            NSObject *obj = [cls new];
            for (NSString *key in propertyType.allKeys) {
                [self setObj:obj key:key
                   valueType:[propertyType objectForKey:key]
                   resultSet:resultSet dict:selDict];
            }
            [models addObject:obj];
        }
        [resultSet close];
    }];
    return models.copy;
}
/**
 查询语句的执行
 
 @param sql 语句
 @param arg 值
 @param tableName 表名
 @param dict 对象
 @return 结果数组
 */
+ (NSArray *)queryCommon:(NSString *)sql
    withArgumentsInArray:(NSArray *)arg
               tableName:(NSString *)tableName
                    dict:(NSDictionary *)dict{
    
    if (![self tableExists:tableName]) {
        return @[];
    }
    NSMutableArray *models = [NSMutableArray new];
    [singletonInstance.queue inDatabase:^(FMDatabase * _Nonnull db) {
        FMResultSet *resultSet = [db executeQuery:sql withArgumentsInArray:arg];
        while ([resultSet next]) {
            NSMutableDictionary *obj = [NSMutableDictionary new];
            for (NSString *key in dict.allKeys) {
            [self setObj:obj key:key
               valueType:[dict objectForKey:key]
               resultSet:resultSet dict:nil];
            }
            [models addObject:obj];
        }
        [resultSet close];
    }];
    return models.copy;
}
/**
 判断是否需要更新表的字段
 
 @param model model
 @param exists 表是否已经存在
 @return 结果
 */
+ (NSDictionary *)upgradeTable:(NSObject *)model tableExists:(BOOL)exists{
    BOOL needAlert = NO;
    __block double sql_version = 0;//查询不到
    BOOL updateTable = YES;
    if (exists && model.sql_version && [model.sql_version floatValue] > 1) {
        //如果表已经存在，同时model的sql_version存在且大于1的时候，就从中间表查询，该表对应的版本号
        NSString *sqlVersion = [NSString stringWithFormat:@"select version from yw_sql_version where table_name = '%@'",model.sql_tableName];
        [singletonInstance.queue inDatabase:^(FMDatabase * _Nonnull db) {
            FMResultSet *resultSet = [db executeQuery:sqlVersion];
            while ([resultSet next]) {
                sql_version = 1.0;//查询到的时候，就默认1
                //实际值
                sql_version = [resultSet doubleForColumnIndex:0];
            }
            [resultSet close];
        }];
        if ([model.sql_version doubleValue] > sql_version) {
            needAlert = YES;
            //开始更新表字段，成功就进行更新数据内容操作
            updateTable = [self upgradeTable:model];
            if (!updateTable) {
                if (singletonInstance.needCreate) {
                    if ([self dropTable:model.sql_tableName]) {
                        updateTable = [self createTable:model error:nil];
                    }
                }
            }
        }
    }
    return @{@"needAlert":@(needAlert),
             @"updateTable":@(updateTable),
             @"version":[NSString stringWithFormat:@"%f",sql_version]};
}

/**
 插入或者更新中间表的信息
 
 @param isInsert 插入还是更新
 @param table 值
 @param version 当前的版本号
 */
+ (void)insertOrUpdate:(BOOL)isInsert table:(NSString *)table version:(NSNumber *)version{
    NSString *sqlInsertVersion = nil;
    if (isInsert) {
        sqlInsertVersion = @"insert into yw_sql_version (version,table_name) values (?, ?)";
    }else{
        sqlInsertVersion = @"update yw_sql_version set version = ? where table_name = ?";
    }
    [singletonInstance.queue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        if (![db executeUpdate:sqlInsertVersion withArgumentsInArray:@[version,table]]) {
            *rollback = YES;
            return ;
        }else{
            [self log:@"中间表更新数据成功"];
        }
    }];
}
//以下三个方法独立起来，比较好，可以节省一定对象开支
//获取model的属性名和类型（create,升级字段）
+ (NSDictionary *)propertyAndTypeOnModel:(NSObject *)obj{
    NSMutableDictionary *dict = [NSMutableDictionary new];
    NSMutableDictionary *py = [NSMutableDictionary new];//@{@"name":@"text"}
    NSMutableString *proType = [[NSMutableString alloc] initWithString:@""];
    unsigned int count = 0;
    Ivar *ivarList = class_copyIvarList(obj.class, &count);
    NSSet *customSet = nil;
    for (int i = 0; i < count; i++) {
        Ivar ivar = ivarList[i];
        /// 成员变量名称
        NSString *ivarName = [NSString stringWithUTF8String:ivar_getName(ivar)];
        if ([ivarName hasPrefix:@"_"]) {
            ivarName = [ivarName substringFromIndex:1];
        }
        if ([obj.sql_ignoreTheField.allObjects containsObject:ivarName]) {
            continue;
        }
        if ([obj.sql_mainKey isEqualToString:ivarName]) {
            continue;
        }
        /// 成员变量类型
        NSString *ivarType = [NSString stringWithUTF8String:ivar_getTypeEncoding(ivar)];
        ivarType = [ivarType stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"@\""]];
        //获取属性的类型
        NSString *propertyType = nil;
        if (!customSet) {
            customSet = obj.sql_CustomClassAsField;
        }
        if (customSet
            && [customSet.allObjects containsObject:ivarType]) {
            propertyType = [NSString stringWithFormat:@"%@",YW_Data];
        }else{
            propertyType = [NSString stringWithFormat:@"%@",[self databaseFieldTypeWithType:ivarType]];
        }
        [proType appendString:ivarName];
        [proType appendString:@" "];
        [proType appendString:propertyType];
        if (i != count - 1) {
            [proType appendString:@","];
        }
        [py setValue:propertyType forKey:ivarName];
        ivarType = nil;
    }
    [dict setValue:proType.copy forKey:@"createSql"];
    [dict setValue:py.copy forKey:@"py"];
    proType = nil;
    free(ivarList);
    return dict.copy;
}
//获取model的属性名和相应的value(inster,update)
+ (NSDictionary *)propertysValueOnModel:(NSObject*)obj{
    NSMutableDictionary *dict = [NSMutableDictionary new];//@{@"name":@"yw"}
    unsigned int count = 0;
    Ivar *ivarList = class_copyIvarList(obj.class, &count);
    for (int i = 0; i < count; i++) {
        Ivar ivar = ivarList[i];
        /// 成员变量名称
        NSString *ivarName = [NSString stringWithUTF8String:ivar_getName(ivar)];
        if ([ivarName hasPrefix:@"_"]) {
            ivarName = [ivarName substringFromIndex:1];
        }
        if ([obj.sql_ignoreTheField.allObjects containsObject:ivarName]) {
            continue;
        }
        // 成员变量类型
        NSString *ivarType = [NSString stringWithUTF8String:ivar_getTypeEncoding(ivar)];
        ivarType = [ivarType stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"@\""]];
        id vale = [obj valueForKey:ivarName];
        if (!vale) {
            vale = [self valueOnObj:vale ivarType:ivarType];
        }else{
            if ([ivarType isEqualToString:@"NSArray"]){
                @try {
                    vale = [NSKeyedArchiver archivedDataWithRootObject:vale];
                } @catch (NSException *exception) {
                    [self log:[NSString stringWithFormat:@"(%@) Array/Dictionary 元素没实现NSCoding协议解归档失败",ivarName]];
                } @finally {
                    
                }
            }else if ([ivarType isEqualToString:@"NSMutableArray"]){
                @try {
                    vale = [NSKeyedArchiver archivedDataWithRootObject:vale];
                } @catch (NSException *exception) {
                    [self log:[NSString stringWithFormat:@"(%@) Array/Dictionary 元素没实现NSCoding协议解归档失败",ivarName]];
                } @finally {
                    
                }
            }else if ([ivarType isEqualToString:@"NSDictionary"]){
                @try {
                    vale = [NSKeyedArchiver archivedDataWithRootObject:vale];
                } @catch (NSException *exception) {
                    [self log:[NSString stringWithFormat:@"(%@) Array/Dictionary 元素没实现NSCoding协议解归档失败",ivarName]];
                } @finally {
                    
                }
            }else if ([ivarType isEqualToString:@"NSMutableDictionary"]){
                @try {
                    vale = [NSKeyedArchiver archivedDataWithRootObject:vale];
                } @catch (NSException *exception) {
                    [self log:[NSString stringWithFormat:@"(%@) Array/Dictionary 元素没实现NSCoding协议解归档失败",ivarName]];
                } @finally {
                    
                }
            }else{
                if (obj.sql_CustomClassAsField && [obj.sql_CustomClassAsField.allObjects containsObject:ivarType]) {
                    @try {
                        vale = [NSKeyedArchiver archivedDataWithRootObject:vale];
                    } @catch (NSException *exception) {
                        [self log:[NSString stringWithFormat:@"(%@) 元素没实现NSCoding协议解归档失败",ivarName]];
                    } @finally {
                        
                    }
                }
            }
        }
        [dict setValue:vale forKey:ivarName];
        ivarType = nil;
    }
    free(ivarList);
    return dict.copy;
}
//获取model的属性名和相应的setter方法(query)
+ (NSDictionary *)propertysSetterOnModel:(NSObject *)obj{
    
    NSMutableDictionary *SelDict = [NSMutableDictionary new];//@{@"name":@"setName:"}
    NSMutableDictionary *dict = [NSMutableDictionary new];//@{@"name":@"text"}
    
    unsigned int count = 0;
    Ivar *ivarList = class_copyIvarList(obj.class, &count);
    for (int i = 0; i < count; i++) {
        Ivar ivar = ivarList[i];
        /// 成员变量名称
        NSString *ivarName = [NSString stringWithUTF8String:ivar_getName(ivar)];
        if ([ivarName hasPrefix:@"_"]) {
            ivarName = [ivarName substringFromIndex:1];
        }
        if ([obj.sql_ignoreTheField.allObjects containsObject:ivarName]) {
            continue;
        }
        // 成员变量类型
        NSString *ivarType = [NSString stringWithUTF8String:ivar_getTypeEncoding(ivar)];
        ivarType = [ivarType stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"@\""]];
        [dict setValue:ivarType forKey:ivarName];
        [SelDict setValue:[NSString stringWithFormat:@"set%@%@:",[ivarName substringToIndex:1].uppercaseString,[ivarName substringFromIndex:1]] forKey:ivarName];
        ivarType = nil;
    }
    free(ivarList);
    
    return @{@"sql":dict.copy,@"sel":SelDict.copy};
}
/**
 依据FMResultSet对象给模型赋值
 
 @param obj 模型
 @param key 主键
 @param type 主键的类型
 @param resultSet 查询结果对象
 @param selDict set方法集合
 */
+ (void)setObj:(NSObject *)obj
           key:(NSString *)key
     valueType:(NSString *)type
     resultSet:(FMResultSet *)resultSet
          dict:(NSDictionary *)selDict{
    
    if ([type isEqualToString:@"NSString"]) {
        [obj setValue:[resultSet stringForColumn:key] forKey:key];
    }else if ([type isEqualToString:@"NSNumber"]){
        [obj setValue:@([resultSet doubleForColumn:key]) forKey:key];
    }else if ([type isEqualToString:@"NSData"]){
        [obj setValue:[resultSet dataForColumn:key] forKey:key];
    }else if ([type isEqualToString:@"NSArray"]){
        NSData *data = [resultSet dataForColumn:key];
        @try {
            NSArray *arr = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            [obj setValue:arr forKey:key];
        } @catch (NSException *exception) {
            [self log:[NSString stringWithFormat:@"(%@) Array/Dictionary 元素没实现NSCoding协议解归档失败",key]];
        } @finally {
        }
    }else if ([type isEqualToString:@"NSMutableArray"]){
        NSData *data = [resultSet dataForColumn:key];
        @try {
            NSMutableArray *arr = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            [obj setValue:arr forKey:key];
        } @catch (NSException *exception) {
            [self log:[NSString stringWithFormat:@"(%@) Array/Dictionary 元素没实现NSCoding协议解归档失败",key]];
        } @finally {
        }
    }else if ([type isEqualToString:@"NSDictionary"]){
        NSData *data = [resultSet dataForColumn:key];
        @try {
            NSDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            [obj setValue:dict forKey:key];
        } @catch (NSException *exception) {
            [self log:[NSString stringWithFormat:@"(%@) Array/Dictionary 元素没实现NSCoding协议解归档失败",key]];
        } @finally {
        }
    }else if ([type isEqualToString:@"NSMutableDictionary"]){
        NSData *data = [resultSet dataForColumn:key];
        @try {
            NSMutableDictionary *dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            [obj setValue:dict forKey:key];
        } @catch (NSException *exception) {
            [self log:[NSString stringWithFormat:@"(%@) Array/Dictionary 元素没实现NSCoding协议解归档失败",key]];
        } @finally {
        }
    }else if ([type isEqualToString:@"q"]){
        ((void (*)(id, SEL, int64_t))(void *) objc_msgSend)(obj, NSSelectorFromString(selDict[key]), [resultSet intForColumn:key]);
    }else if ([type isEqualToString:@"i"]){
        ((void (*)(id, SEL, int64_t))(void *) objc_msgSend)(obj, NSSelectorFromString(selDict[key]), [resultSet intForColumn:key]);
    }else if ([type isEqualToString:@"Q"]){
        ((void (*)(id, SEL, int64_t))(void *) objc_msgSend)(obj, NSSelectorFromString(selDict[key]), [resultSet intForColumn:key]);
    }else if ([type isEqualToString:@"f"]){
        ((void (*)(id, SEL, float))(void *) objc_msgSend)(obj, NSSelectorFromString(selDict[key]), [resultSet doubleForColumn:key]);
    }else if ([type isEqualToString:@"d"]){
        ((void (*)(id, SEL, float))(void *) objc_msgSend)(obj, NSSelectorFromString(selDict[key]), [resultSet doubleForColumn:key]);
    }else if ([type isEqualToString:@"B"]){
        ((void (*)(id, SEL, int64_t))(void *) objc_msgSend)(obj, NSSelectorFromString(selDict[key]), [resultSet intForColumn:key]);
    }else{
        if (obj.sql_CustomClassAsField && [obj.sql_CustomClassAsField.allObjects containsObject:type]) {
            NSData *data = [resultSet dataForColumn:key];
            @try {
                id dict = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                [obj setValue:dict forKey:key];
            } @catch (NSException *exception) {
                [self log:[NSString stringWithFormat:@"(%@) Array/Dictionary 元素没实现NSCoding协议解归档失败",key]];
            } @finally {
            }
        }
    }
}
+ (NSString *)databaseFieldTypeWithType:(NSString *)type{
    if ([type isEqualToString:@"q"]) {
        return YW_Int;
    }else if([type isEqualToString:@"i"]){
        return YW_Int;
    }else if([type isEqualToString:@"Q"]){
        return YW_Int;
    }else if([type isEqualToString:@"f"]){
        return YW_Float;
    }else if([type isEqualToString:@"d"]){
        return YW_Float;
    }else if([type isEqualToString:@"B"]){//布尔类型
        return YW_Boolean;
    }else if([type isEqualToString:@"NSString"]){
        return YW_String;
    }else if([type isEqualToString:@"NSNumber"]){
        return YW_Number;
    }else if([type isEqualToString:@"NSData"]){
        return YW_Data;
    }else if([type isEqualToString:@"NSArray"]){
        return YW_Array;
    }else if([type isEqualToString:@"NSMutableArray"]){
        return YW_MutableArray;
    }else if([type isEqualToString:@"NSDictionary"]){
        return YW_Dictionary;
    }else if([type isEqualToString:@"NSMutableDictionary"]){
        return YW_MutableDictionary;
    }
    return YW_String;
}
+ (id)valueOnObj:(id)vale ivarType:(NSString *)ivarType{
    id value = vale;
    if([ivarType isEqualToString:@"NSString"]){
        value = @"";
    }else if([ivarType isEqualToString:@"NSNumber"]){
        value = @0;
    }else if ([ivarType isEqualToString:@"NSData"]){
        value = [NSData data];
    }else if ([ivarType isEqualToString:@"NSArray"]){
        value = [NSKeyedArchiver archivedDataWithRootObject:@[]];
    }else if ([ivarType isEqualToString:@"NSMutableArray"]){
        value = [NSKeyedArchiver archivedDataWithRootObject:[NSMutableArray new]];
    }else if ([ivarType isEqualToString:@"NSDictionary"]){
        value = [NSKeyedArchiver archivedDataWithRootObject:@{}];
    }else if ([ivarType isEqualToString:@"NSMutableDictionary"]){
        value = [NSKeyedArchiver archivedDataWithRootObject:[NSMutableDictionary new]];
    }
    //    else{
    //        vale = [NSNull null];
    //    }
    return value;
}
+ (NSString *)dbPath{//默路径
    return [NSString stringWithFormat:@"%@/Library/Caches/YWSqlite.db",NSHomeDirectory()];
}
+ (void)log:(NSString *)error{
    NSLog(@"%@", [NSString stringWithFormat:@"\n/**********YWDBTool*************/\n YWDBTool【%@】\n /**********YWDBTool*************/",error]);
}
+ (NSString *)version{
    return @"0.4.4";
}
@end
