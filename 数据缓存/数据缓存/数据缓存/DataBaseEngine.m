//
//  DataBaseEngine.m
//  数据缓存
//
//  Created by qingyun on 16/1/28.
//  Copyright © 2016年 河南青云信息技术有限公司. All rights reserved.
//

#import "DataBaseEngine.h"
#import "FMDB.h"
#import "NSString+Documents.h"
#import "Model.h"
#define KDBName @""
#define KTableName @""

static NSArray *statusColumns;
@implementation DataBaseEngine

//
+(void)initialize
{
    if (self == [DataBaseEngine class]) {
        //将db文件copy到document
        [self copyFile2Document];
        statusColumns = [self tableColumn:KTableName];
    }
}

+(void)copyFile2Document{
    NSString *scure = [[NSBundle mainBundle] pathForResource:@"" ofType:@""];
    //获取路径
    NSString *toPath = [NSString DocumentsFilePath:KDBName];
    NSError *error;
    
    //在document文件下存储 只有在文件不存在的情况在才能copy
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:toPath]) {
        [fileManager copyItemAtPath:scure toPath:toPath error:&error];
    }
}

//保存从网络上获取的数据
+(void)savaStatuses:(NSArray *)statuses
{
    //创建一个队列
    FMDatabaseQueue *queue = [FMDatabaseQueue databaseQueueWithPath:[NSString DocumentsFilePath:KDBName]];
    //执行插入操作
    [queue inDatabase:^(FMDatabase *db) {
        [statuses enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSDictionary *status = obj;
            //创建sql语句执行插入操作
            //查询出table的column 字典中的所有字段 并查询出子集
            NSArray *allKey = status.allKeys;
            
            //对比数组之间的相同
            NSArray *contentKey = [self contentFromArray:allKey And:statusColumns];
            
            //根据主键 拼接字符串
            NSString *sqlString = [self sqlStringWithColumn:contentKey];
            //筛选出要插入的字典 字典中值的类型 转换为二进制对象
            NSMutableDictionary *muStatus = [NSMutableDictionary dictionary];
            [status enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                //只保存插入的key
                if ([contentKey containsObject:key]) {
                    //处理对象
                    if ([obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSDictionary class]]) {
                        obj = [NSKeyedArchiver archivedDataWithRootObject:obj];
                    }
                    //排除空对象
                    if (![contentKey isKindOfClass:[NSNull class]]) {
                        [muStatus setObject:obj forKey:key];
                    }
                }
            }];
            //执行插入语句
            [db executeUpdate:sqlString withParameterDictionary:muStatus];
        }];
    }];
}


//从本地读取已经存储的数据
+(NSArray *)selectedStatuses
{
    //创建数据库对象
    FMDatabase *db = [FMDatabase databaseWithPath:[NSString DocumentsFilePath:KDBName]];
    [db open];
    
    NSString *sqlString = @"select * from order by limit 20";
    
    FMResultSet *resultSet = [db executeQuery:sqlString];
    
    NSMutableArray *statuses = [NSMutableArray array];
    
    while ([resultSet next]) {
        //将查询出来的每一条数据转换为字典
        NSDictionary *status = [resultSet resultDictionary];
        NSMutableDictionary *muStatus = [NSMutableDictionary dictionary];
        [status enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[NSData class]]) {
                obj = [NSKeyedUnarchiver unarchiveObjectWithData:obj];
            }
            if (![obj isKindOfClass:[NSNull class]]) {
                [muStatus setObject:obj forKey:key];
            }
        }];
        Model *statusModel = [[Model alloc] init];
        
        [statuses addObject:statusModel];
    }
    return statuses;
}
+(NSArray *)contentFromArray:(NSArray *)array1 And:(NSArray *)array2
{
    NSMutableArray *result = [NSMutableArray array];
    
    [array1 enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([array2 containsObject:obj]) {
            [result addObject:obj];
        }
    }];
    return result;
}

+(NSString *)sqlStringWithColumn:(NSArray *)columns
{
    //insert into tableName (a, b, c) values (:a, :b, :c)
    NSString *column = [columns componentsJoinedByString:@", "];
    NSString *value = [columns componentsJoinedByString:@", :"];
    value = [@":" stringByAppendingString:value];
    
    return [NSString stringWithFormat:@"insert into %@(%@) values %@",KTableName,column,value];
}

+(NSArray *)tableColumn:(NSString *)tableName{
    //创建db
    FMDatabase *db = [FMDatabase databaseWithPath:[NSString DocumentsFilePath:KDBName]];
    [db open];
    
    //查询结果
    FMResultSet *reSultset = [db getTableSchema:tableName];
    //创建一个可变的数组接受结果
    NSMutableArray *columns = [NSMutableArray array];
    while ([reSultset next]) {
        //从结果中去出字段的名字
        NSString *column = [reSultset objectForColumnName:@"name"];
        [columns addObject:column];
    }
    return columns;
}
@end
