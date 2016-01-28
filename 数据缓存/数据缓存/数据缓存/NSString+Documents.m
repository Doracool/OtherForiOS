//
//  NSString+Documents.m
//  SoftLink
//
//  Created by qingyun on 16/1/18.
//  Copyright © 2016年 河南青云信息技术有限公司. All rights reserved.
//

#import "NSString+Documents.h"

@implementation NSString (Documents)


+(NSString *)DocumentsFilePath:(NSString *)fileName
{
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [path stringByAppendingPathComponent:fileName];
    return filePath;
}
@end
