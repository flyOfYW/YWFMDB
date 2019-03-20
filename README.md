# YWFMDB
基于FMDB对model和字典的直接操作

简介
==============
- **架构**: 采用runtime和FMDB完美结合打造的强大数据库操作
- **安全**: 支持数据库级别加密
- **易用**: 真正实现一行代码操作数据库
- **目标**: 替代手写sql语句方式
- **支持**: (NSString,NSNumber,Int,double,float,Bool)类型
- **灵活**: 依据模型类实现的YWSqlModelProtocol协议,支持忽略模型类属性存储数据表中
- **智能**: 根据模型类实现的YWSqlModelProtocol协议返回的版本号即时更新数据库字段(动态删除/添加)
- **强大**: 支持导出表（格式CSV和TXT）

要求
==============
* iOS 8.0 or later
* Xcode 8.0 or later

效果
==============
 ![image](https://github.com/flyOfYW/YWFMDB/blob/master/image/red.gif)

集成
==============
**Cocoapods**
```
1. 不需加密: pod 'YWFMDB'
2. 需加密数据库: pod 'YWFMDB/SQLCipher'
```
**手动安装**
```
1. 下载 YWFMDB 文件夹内的所有内容。
2. 将 YWFMDB文件添加(拖放)到你的工程。
3. 导入 "YWFMDB.h"。
4、加密：需单独导入SQLCipher以及配置相关配置
```


注意
==============
- 在需要对数据表自定义相关信息请先查看YWSqlModelProtocol协议
- 当模型类有新增/删除属性的时候需要在模型类实现sql_version并返回相应的版本号来表明有字段更新操作，YWFMDB会根据这个VERSION变更智能检查并自动更新数据库字段，无需手动更新数据库字段
- 当模型类需要忽略属性存储字段时，请实现sql_ignoreTheField协议方法即可return要忽略属性名称集合
- 如果自定义主键时，请实现sql_mainKey协议方法即可return主键字段（默认db_id）
- 如果自定义表名时，请实现sql_tableName协议方法即可return表名（默认是存储类的类名）

```objective-c
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

```
使用方法
==============
#### 1.创建数据库
```objective-c
  NSString *path = [NSString stringWithFormat:@"%@/Library/Caches/YWSqlite.db",NSHomeDirectory()];
    //创建数据库,并连接
    [YWFMDB connectionDB:path];
```
#### 2.批量存储模型对象到数据库

```objective-c
 NSMutableArray *marr = @[].mutableCopy;
        for (int i = 0; i < 5; i ++) {
            int index = [self arcrandom];
            YWPerson *p = [YWPerson new];
            p.name = _names[index];
            p.age = [_ages[index] integerValue];
            p.phone = _phones[index];
            p.weight = [_weights[index] floatValue];
            p.height = [_heights[index] floatValue];
            p.menu = _menus[index];
            p.email = _emails[index];
            p.qq = _qqs[index];
            p.weChat = _qqs[index];
            [marr addObject:p];
        }
        [YWFMDB storageModels:marr checkTableStructure:NO];
```
#### 3.更新模型指定属性的值到数据库
```objective-c
 [YWFMDB updateWithModel:[YWPerson class] specifiedValue:@{@"age":@"21"} checkTableStructure:NO where:@[[YWFieldFilter fieldFilterWithField:@"name" operator:eq value:@"yw"]]];
```
#### 4.更新模型对象到数据库
```objective-c
        int index = [self arcrandom];
        YWPerson *p = [YWPerson new];
        p.name = @"lpl";
        p.age = [_ages[index] integerValue];
        p.phone = _phones[index];
        p.weight = [_weights[index] floatValue];
        p.height = [_heights[index] floatValue];
        p.menu = _menus[index];
        p.email = _emails[index];
        p.qq = _qqs[index];
        p.weChat = _qqs[index];
        [YWFMDB updateWithModel:p checkTableStructure:NO where:@[[YWFieldFilter fieldFilterWithField:@"name" operator:eq value:@"lpl"]]];
```
#### 5.删除指定条件在表中的记录
```objective-c
 [YWFMDB deleteTableWithModel:[YWPerson class] where:@[[YWFieldFilter fieldFilterWithField:@"name" operator:eq value:@"yw"]]];
```
#### 6.删除某个模型在数据库的记录
```objective-c
  [YWFMDB deleteTableWithModel:[YWPerson class]];
```
#### 7.查询某个模型在数据库中所有的记录
```objective-c
  [YWFMDB queryWithModel:[YWPerson class]]
```
#### 8.条件查询某个模型在数据库中所有的记录结果并排序
```objective-c
 //eq查询
 list = [YWFMDB queryWithModel:[YWPerson class] where:@[[YWFieldFilter fieldFilterWithField:@"name" operator:eq value:@"yw"]]];
        //模糊查询
 list = [YWFMDB queryWithModel:[YWPerson class] where:@[[YWFieldFilter fieldFilterWithField:@"name" operator:like value:likeString]] order:@[[YWFieldOrder fieldOrderWithField:@"age" direction:desc]]];
        
```
#### 9.条件分页查询某个模型在数据库中所有的记录
```objective-c
 list = [YWFMDB queryWithModel:[YWPerson class] limit:[YWPageable pageablePage:0 row:3]];
```

Api文档
==============
```objective-c

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
 批量存储model
 
 @param model model的数组
 @param isAuto 是否自动根据model的版本号检测表结构是否发生变化(新增字段或者删除字段)
 @return 存储成功与否
 */
+ (BOOL)storageModels:(NSArray<NSObject*>*)model checkTableStructure:(BOOL)isAuto;
/**
 存储单个model
 
 @param model model的数组
 @param isAuto 是否自动根据model的版本号检测表结构是否发生变化(新增字段或者删除字段)
 @return 存储成功与否
 */
+ (BOOL)storageModel:(NSObject*)model checkTableStructure:(BOOL)isAuto;
//MARK: ------------------------------------- 更新 ------------------------------------
/**
 更新本地存储的model数据
 
 @param model model
 @param automatic 是否需要自动检测表是否有新增的字段（如果确定没有新增的字典，请传入NO,可以节省一定的开支）
 @param wheres 筛选条件
 @return 更新成功与否
 */
+ (BOOL)updateWithModel:(NSObject *)model checkTableStructure:(BOOL)automatic where:(NSArray<YWFieldFilter *> *)wheres;
/**
 指定更新本地存储的model的特定数据

 @param modelClass model的类名
 @param specifiedValue 指定的值
 @param automatic 是否需要自动检测表是否有新增的字段（如果确定没有新增的字典，请传入NO,可以节省一定的开支）
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


```

