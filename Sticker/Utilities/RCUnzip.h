//
//  RCUnzip.h
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/12/27.
//  Copyright © 2018 RongCloud. All rights reserved.
//

#ifndef RCUnzip_h
#define RCUnzip_h

#include <stdio.h>
#include <stdbool.h>
#include <zconf.h>

#define UNZ_OK (0)
#define UNZ_END_OF_LIST_OF_FILE (-100)
#define UNZ_ERRNO (Z_ERRNO)
#define UNZ_EOF (0)
#define UNZ_PARAMERROR (-102)
#define UNZ_BADZIPFILE (-103)
#define UNZ_INTERNALERROR (-104)
#define UNZ_CRCERROR (-105)

#ifdef __cplusplus
extern "C" {
#endif
bool ZEXPORT unzipFile OF((char *orgPath, char *targetPath));
#ifdef __cplusplus
}
#endif

#endif /* RCUnzip_h */
