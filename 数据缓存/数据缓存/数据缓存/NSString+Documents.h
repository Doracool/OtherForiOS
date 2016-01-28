//
//  NSString+Documents.h
//  SoftLink
//
//  Created by qingyun on 16/1/18.
//  Copyright © 2016年 河南青云信息技术有限公司. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Documents)


//返回文件在documents文件夹下的路径
+(NSString *)DocumentsFilePath:(NSString *)fileName;
@end
