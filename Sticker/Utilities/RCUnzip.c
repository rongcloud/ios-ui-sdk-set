//
//  RCUnzip.c
//  RongSticker
//
//  Created by Zhaoqianyu on 2018/12/27.
//  Copyright © 2018 RongCloud. All rights reserved.
//

#include "RCUnzip.h"
#include <zlib.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <errno.h>

#ifndef F_SEEK_SET
#define F_SEEK_SET 0
#endif

#ifndef F_SEEK_CUR
#define F_SEEK_CUR 1
#endif

#ifndef F_SEEK_END
#define F_SEEK_END 2
#endif

#ifndef MALLOC
#define MALLOC(size) (malloc(size))
#endif

#ifndef FREE
#define FREE(p) {if (p) free(p);}
#endif

#ifndef BUF_SIZE
#define BUF_SIZE (16384)
#endif

#ifndef BUF_READ_COMMENT
#define BUF_READ_COMMENT (0x400)
#endif

#define SIZE_CENTRAL_DIR_ITEM (0x2e)
#define SIZE_ZIP_LOCAL_HEADER (0x1e)

/* zip 文件中央目录结构尾部信息 */
typedef struct
{
    uLong number_entry;         /* zip 文件中的文件总数 */
    uLong size_central_dir;     /* 整个中心目录大小 */
    uLong offset_central_dir;   /* 中心目录相对于起始位置的磁盘偏移量 */
    uLong size_comment;         /* zip 文件注释长度 */
} central_dir_terminate_s;

/* zip 文件中央目录结构，如果多个文件组成的 zip，则该结构通常是数组 */
typedef struct
{
    uLong version;              /* 主机操作系统               2 bytes */
    uLong version_needed;       /* 解压缩所需要的版本          2 bytes */
    uLong flag;                 /* 通用比特标识位             2 bytes */
    uLong compression_method;   /* 压缩方式                  2 bytes */
    uLong dosDate;              /* 文件最后修改日期           4 bytes */
    uLong crc;                  /* crc-32位校验码            4 bytes */
    uLong compressed_size;      /* 压缩文件大小               4 bytes */
    uLong uncompressed_size;    /* 未压缩文件大小             4 bytes */
    uLong size_filename;        /* 文件名长                  2 bytes */
    uLong size_file_extra;      /* 扩展段长                  2 bytes */
    uLong size_file_comment;    /* 文件注释长                2 bytes */
    
    uLong disk_num_start;       /* 磁盘起始号                2 bytes */
    uLong internal_fa;          /* 内部文件属性               2 bytes */
    uLong external_fa;          /* 外部文件属性               4 bytes */
    
} central_file_info;

/* 保存读取和解压 zip 文件时的一些属性  */
typedef struct
{
    char  *read_buffer;         /* internal buffer for compressed data */
    z_stream stream;            /* zLib stream structure for inflate */
    
    uLong pos_in_zipfile;       /* position in byte on the zipfile, for fseek*/
    uLong stream_initialised;   /* flag set if stream structure is initialised*/
    
    uLong offset_local_extrafield;/* offset of the local extra field */
    uInt  size_local_extrafield;/* size of the local extra field */
    uLong pos_local_extrafield;   /* position in the local extra field in read*/
    
    uLong crc32;                /* crc32 of all data uncompressed */
    uLong crc32_wait;           /* crc32 we must obtain after decompress all */
    uLong rest_read_compressed; /* number of byte to be decompressed */
    uLong rest_read_uncompressed;/*number of byte to be obtained after decomp*/
    voidpf filestream;        /* io structore of the zipfile */
    uLong compression_method;   /* compression method (0==store) */
    uLong byte_before_the_zipfile;/* byte before the zipfile, (>0 for sfx)*/
    int   raw;
} zip_file_read_info;


/*  */
typedef struct
{
    voidpf filestream;        /* io structore of the zipfile */
    central_dir_terminate_s gi;       /* public global information */
    uLong byte_before_the_zipfile;/* byte before the zipfile, (>0 for sfx)*/
    uLong num_file;             /* number of the current file in the zipfile*/
    uLong pos_in_central_dir;   /* pos of the current file in the central dir*/
    uLong current_file_ok;      /* flag about the usability of the current file*/
    uLong central_pos;          /* position of the beginning of the central dir*/
    
    central_file_info cur_file_info; /* public info about the current file in zip*/
    uLong offset_curfile;/* relative offset of local header 4 bytes */
    zip_file_read_info* pfile_in_zip_read; /* structure about the current
                                                 file if we are decompressing it */
    int encrypted;
} unzip_s;

/* ===========================================================================
 File io operation
 */
voidpf fopen_file (const char *filename, const char *mode)
{
    FILE* file = NULL;
    const char* mode_fopen = mode;
    if (filename!=NULL)
        file = fopen(filename, mode_fopen);
    return file;
    return NULL;
}

uLong fread_file (voidpf stream, void *buf, uLong size)
{
    uLong ret;
    ret = (uLong)fread(buf, 1, (size_t)size, (FILE *)stream);
    return ret;
}


uLong fwrite_file (voidpf stream, const void *buf, uLong size)
{
    uLong ret;
    ret = (uLong)fwrite(buf, 1, (size_t)size, (FILE *)stream);
    return ret;
}

long ftell_file (voidpf stream)
{
    long ret;
    ret = ftell((FILE *)stream);
    return ret;
}

long fseek_file (voidpf stream, uLong offset, int origin)
{
    int fseek_origin=0;
    long ret;
    switch (origin)
    {
        case 0 :
            fseek_origin = F_SEEK_SET;
            break;
        case 1 :
            fseek_origin = F_SEEK_CUR;
            break;
        case 2 :
            fseek_origin = F_SEEK_END;
            break;
        default: return -1;
    }
    ret = 0;
    fseek((FILE *)stream, offset, fseek_origin);
    return ret;
}

int fclose_file (voidpf stream)
{
    int ret;
    ret = fclose((FILE *)stream);
    return ret;
}

int ferror_file (voidpf stream)
{
    int ret;
    ret = ferror((FILE *)stream);
    return ret;
}

/* ===========================================================================
 Reads bytes from zip or unzip file
 */
int unz_getByte(voidpf filestream, int *pi)
{
    unsigned char c;
    int err = (int)fread_file(filestream, &c, 1);
    if (err==1)
    {
        *pi = (int)c;
        return UNZ_OK;
    }
    else
    {
        if (ferror_file(filestream))
            return UNZ_ERRNO;
        else
            return UNZ_EOF;
    }
}

int unz_getShort (voidpf filestream, uLong *pX)
{
    uLong x ;
    int i;
    int err;
    
    err = unz_getByte(filestream,&i);
    x = (uLong)i;
    
    if (err==UNZ_OK)
        err = unz_getByte(filestream,&i);
    x += ((uLong)i)<<8;
    
    if (err==UNZ_OK)
        *pX = x;
    else
        *pX = 0;
    return err;
}

int unz_getLong (voidpf filestream,uLong *pX)
{
    uLong x ;
    int i;
    int err;
    
    err = unz_getByte(filestream,&i);
    x = (uLong)i;
    
    if (err==UNZ_OK)
        err = unz_getByte(filestream,&i);
    x += ((uLong)i)<<8;
    
    if (err==UNZ_OK)
        err = unz_getByte(filestream,&i);
    x += ((uLong)i)<<16;
    
    if (err==UNZ_OK)
        err = unz_getByte(filestream,&i);
    x += ((uLong)i)<<24;
    
    if (err==UNZ_OK)
        *pX = x;
    else
        *pX = 0;
    return err;
}

voidp unz_open (const char *path);
int unz_close (voidp file);
uLong unz_centralDir_pos(voidpf filestream);
int unz_goToFirstFile (voidp file);
int unz_goToNextFile (voidp file);
int unz_getCurrentFileInfo (voidp file,
                            central_file_info *pfile_info,
                            char *szFileName, uLong fileNameBufferSize,
                            void *extraField, uLong extraFieldBufferSize,
                            char *szComment, uLong commentBufferSize);
int unz_getCurrentFileInfoInternal (voidp file,
                                         central_file_info *pfile_info,
                                         char *szFileName, uLong fileNameBufferSize,
                                         void *extraField, uLong extraFieldBufferSize,
                                         char *szComment,  uLong commentBufferSize);
int unz_closeCurrentFile (voidp file);

int unz_close (voidp file)
{
    unzip_s* s;
    if (file==NULL)
        return UNZ_PARAMERROR;
    s=(unzip_s*)file;
    
    if (s->pfile_in_zip_read!=NULL)
        unz_closeCurrentFile(file);
    fclose_file(s->filestream);
    FREE(s);
    return UNZ_OK;
}

voidp unz_open (const char *path)
{
    unzip_s us;
    unzip_s *s;
    uLong central_pos,uL;
    
    uLong number_disk;          /* number of the current dist, used for
                                 spaning ZIP, unsupported, always 0*/
    uLong number_disk_with_CD;  /* number the the disk with central dir, used
                                 for spaning ZIP, unsupported, always 0*/
    uLong number_entry_CD;      /* total number of entries in
                                 the central dir
                                 (same than number_entry on nospan) */
    
    int err=UNZ_OK;

    us.filestream= fopen_file(path, "rb");
    if (us.filestream==NULL)
        return NULL;
    
    central_pos = unz_centralDir_pos(us.filestream);
    if (central_pos==0)
        err=UNZ_ERRNO;
    
    if (fseek_file(us.filestream,
              central_pos,F_SEEK_SET)!=0)
        err=UNZ_ERRNO;
    
    /* the signature, already checked */
    if (unz_getLong(us.filestream,&uL)!=UNZ_OK)
        err=UNZ_ERRNO;
    
    /* number of this disk */
    if (unz_getShort(us.filestream,&number_disk)!=UNZ_OK)
        err=UNZ_ERRNO;
    
    /* number of the disk with the start of the central directory */
    if (unz_getShort(us.filestream,&number_disk_with_CD)!=UNZ_OK)
        err=UNZ_ERRNO;
    
    /* total number of entries in the central dir on this disk */
    if (unz_getShort(us.filestream,&us.gi.number_entry)!=UNZ_OK)
        err=UNZ_ERRNO;
    
    /* total number of entries in the central dir */
    if (unz_getShort(us.filestream,&number_entry_CD)!=UNZ_OK)
        err=UNZ_ERRNO;
    
    if ((number_entry_CD!=us.gi.number_entry) ||
        (number_disk_with_CD!=0) ||
        (number_disk!=0))
        err=UNZ_BADZIPFILE;
    
    /* size of the central directory */
    if (unz_getLong(us.filestream,&us.gi.size_central_dir)!=UNZ_OK)
        err=UNZ_ERRNO;
    
    /* offset of start of central directory with respect to the
     starting disk number */
    if (unz_getLong(us.filestream,&us.gi.offset_central_dir)!=UNZ_OK)
        err=UNZ_ERRNO;
    
    /* zipfile comment length */
    if (unz_getShort(us.filestream,&us.gi.size_comment)!=UNZ_OK)
        err=UNZ_ERRNO;
    
    if ((central_pos<us.gi.offset_central_dir+us.gi.size_central_dir) &&
        (err==UNZ_OK))
        err=UNZ_BADZIPFILE;
    
    if (err!=UNZ_OK)
    {
        fclose_file(us.filestream);
        return NULL;
    }
    
    us.byte_before_the_zipfile = central_pos -
    (us.gi.offset_central_dir+us.gi.size_central_dir);
    us.central_pos = central_pos;
    us.pfile_in_zip_read = NULL;
    us.encrypted = 0;
    
    
    s=(unzip_s *)MALLOC(sizeof(unzip_s));
    *s=us;
    unz_goToFirstFile((voidp)s);
    return (voidp)s;
}

uLong unz_centralDir_pos(voidpf filestream)
{
    unsigned char* buf;
    uLong uSizeFile;
    uLong uBackRead;
    uLong uMaxBack=0xffff; /* maximum size of global comment */
    uLong uPosFound=0;
    
    
    if (fseek_file(filestream, 0, F_SEEK_END) != 0)
        return 0;
    
    uSizeFile = ftell_file(filestream);
    if (uMaxBack>uSizeFile)
        uMaxBack = uSizeFile;
    buf = (unsigned char*)MALLOC(BUF_READ_COMMENT+4);
    if (buf==NULL)
        return 0;
    
    uBackRead = 4;
    while (uBackRead<uMaxBack)
    {
        uLong uReadSize,uReadPos ;
        int i;
        if (uBackRead+BUF_READ_COMMENT>uMaxBack)
            uBackRead = uMaxBack;
        else
            uBackRead+=BUF_READ_COMMENT;
        uReadPos = uSizeFile-uBackRead ;
        
        uReadSize = ((BUF_READ_COMMENT+4) < (uSizeFile-uReadPos)) ?
        (BUF_READ_COMMENT+4) : (uSizeFile-uReadPos);
        if (fseek_file(filestream,uReadPos,F_SEEK_SET)!=0)
            break;
        
        if (fread_file(filestream,buf,uReadSize)!=uReadSize)
            break;
        
        for (i=(int)uReadSize-3; (i--)>0;)
            if (((*(buf+i))==0x50) && ((*(buf+i+1))==0x4b) &&
                ((*(buf+i+2))==0x05) && ((*(buf+i+3))==0x06))
            {
                uPosFound = uReadPos+i;
                break;
            }
        
        if (uPosFound!=0)
            break;
    }
    FREE(buf);
    return uPosFound;
}

int unz_goToFirstFile (voidp file)
{
    int err=UNZ_OK;
    unzip_s* s;
    if (file==NULL)
        return UNZ_PARAMERROR;
    s=(unzip_s*)file;
    s->pos_in_central_dir=s->gi.offset_central_dir;
    s->num_file=0;
    err=unz_getCurrentFileInfoInternal(file,&s->cur_file_info,
                                            NULL,0,NULL,0,NULL,0);
    s->current_file_ok = (err == UNZ_OK);
    return err;
}

int unz_goToNextFile (voidp file)
{
    unzip_s* s;
    int err;
    if (file==NULL)
    {
        return UNZ_PARAMERROR;
    }
    s=(unzip_s*)file;
    if (!s->current_file_ok)
    {
        return UNZ_END_OF_LIST_OF_FILE;
    }
    if (s->gi.number_entry != 0xffff)/* 2^16 files overflow hack */
    {
        if (s->num_file+1==s->gi.number_entry)
        {
            return UNZ_END_OF_LIST_OF_FILE;
        }
    }
    
    s->pos_in_central_dir += SIZE_CENTRAL_DIR_ITEM + s->cur_file_info.size_filename +
    s->cur_file_info.size_file_extra + s->cur_file_info.size_file_comment ;
    s->num_file++;
    err = unz_getCurrentFileInfoInternal(file,&s->cur_file_info,
                                              NULL,0,NULL,0,NULL,0);
    s->current_file_ok = (err == UNZ_OK);
    return err;
}

int unz_getCurrentFileInfo (voidp file,
                              central_file_info *pfile_info,
                              char *szFileName, uLong fileNameBufferSize,
                              void *extraField, uLong extraFieldBufferSize,
                              char *szComment, uLong commentBufferSize)
{
    return unz_getCurrentFileInfoInternal(file,pfile_info,
                                          szFileName,fileNameBufferSize,
                                          extraField,extraFieldBufferSize,
                                          szComment,commentBufferSize);
}

int unz_getCurrentFileInfoInternal (voidp file,
                                    central_file_info *pfile_info,
                                    char *szFileName, uLong fileNameBufferSize,
                                    void *extraField, uLong extraFieldBufferSize,
                                    char *szComment,  uLong commentBufferSize)
{
    unzip_s* s;
    central_file_info file_info;
    int err=UNZ_OK;
    uLong uMagic;
    long lSeek=0;
    
    if (file==NULL)
        return UNZ_PARAMERROR;
    s=(unzip_s*)file;
    if (fseek_file(s->filestream,
              s->pos_in_central_dir+s->byte_before_the_zipfile,
              F_SEEK_SET)!=0)
        err=UNZ_ERRNO;
    
    /* we check the magic */
    if (err==UNZ_OK)
    {
        if (unz_getLong(s->filestream,&uMagic) != UNZ_OK)
            err=UNZ_ERRNO;
        else if (uMagic!=0x02014b50)
            err=UNZ_BADZIPFILE;
    }
            
    if (unz_getShort(s->filestream,&file_info.version) != UNZ_OK)
        err=UNZ_ERRNO;
    
    if (unz_getShort(s->filestream,&file_info.version_needed) != UNZ_OK)
        err=UNZ_ERRNO;
            
    if (unz_getShort(s->filestream,&file_info.flag) != UNZ_OK)
        err=UNZ_ERRNO;
        
    if (unz_getShort(s->filestream,&file_info.compression_method) != UNZ_OK)
        err=UNZ_ERRNO;
            
    if (unz_getLong(s->filestream,&file_info.dosDate) != UNZ_OK)
        err=UNZ_ERRNO;
        
    if (unz_getLong(s->filestream,&file_info.crc) != UNZ_OK)
        err=UNZ_ERRNO;
            
    if (unz_getLong(s->filestream,&file_info.compressed_size) != UNZ_OK)
        err=UNZ_ERRNO;
                
    if (unz_getLong(s->filestream,&file_info.uncompressed_size) != UNZ_OK)
        err=UNZ_ERRNO;
                    
    if (unz_getShort(s->filestream,&file_info.size_filename) != UNZ_OK)
        err=UNZ_ERRNO;
                        
    if (unz_getShort(s->filestream,&file_info.size_file_extra) != UNZ_OK)
        err=UNZ_ERRNO;
                            
    if (unz_getShort(s->filestream,&file_info.size_file_comment) != UNZ_OK)
        err=UNZ_ERRNO;
                                
    if (unz_getShort(s->filestream,&file_info.disk_num_start) != UNZ_OK)
        err=UNZ_ERRNO;
                                    
    if (unz_getShort(s->filestream,&file_info.internal_fa) != UNZ_OK)
        err=UNZ_ERRNO;
                                        
    if (unz_getLong(s->filestream,&file_info.external_fa) != UNZ_OK)
        err=UNZ_ERRNO;
                                            
    if (unz_getLong(s->filestream,&s->offset_curfile) != UNZ_OK)
        err=UNZ_ERRNO;
        
    lSeek+=file_info.size_filename;
    
    if ((err==UNZ_OK) && (szFileName!=NULL))
    {
        uLong uSizeRead ;
        if (file_info.size_filename<fileNameBufferSize)
        {
            *(szFileName+file_info.size_filename)='\0';
            uSizeRead = file_info.size_filename;
        }
        else
        {
            uSizeRead = fileNameBufferSize;
        }
        
        if ((file_info.size_filename>0) && (fileNameBufferSize>0))
        {
            if (fread_file(s->filestream,szFileName,uSizeRead)!=uSizeRead)
            {
                err=UNZ_ERRNO;
            }
        }
        
        lSeek -= uSizeRead;
    }
    
    
    if ((err==UNZ_OK) && (extraField!=NULL))
    {
        uLong uSizeRead ;
        if (file_info.size_file_extra<extraFieldBufferSize)
            uSizeRead = file_info.size_file_extra;
        else
            uSizeRead = extraFieldBufferSize;
        
        if (lSeek!=0)
        {
            if (fseek_file(s->filestream,lSeek,F_SEEK_CUR)==0)
                lSeek=0;
            else
                err=UNZ_ERRNO;
        }
        if ((file_info.size_file_extra>0) && (extraFieldBufferSize>0))
        {
            if (fread_file(s->filestream,extraField,uSizeRead)!=uSizeRead)
            {
                err=UNZ_ERRNO;
            }
        }
        
        lSeek += file_info.size_file_extra - uSizeRead;
    }
    else
    {
        lSeek+=file_info.size_file_extra;
    }
    
    if ((err==UNZ_OK) && (szComment!=NULL))
    {
        uLong uSizeRead ;
        if (file_info.size_file_comment<commentBufferSize)
        {
            *(szComment+file_info.size_file_comment)='\0';
            uSizeRead = file_info.size_file_comment;
        }
        else
        {
            uSizeRead = commentBufferSize;
        }
        
        if (lSeek!=0)
        {
            if (fseek_file(s->filestream,lSeek,F_SEEK_CUR)==0)
            {
                lSeek=0;
            }
            else
            {
                err=UNZ_ERRNO;
            }
        }
        
        if ((file_info.size_file_comment>0) && (commentBufferSize>0))
        {
            if (fread_file(s->filestream,szComment,uSizeRead)!=uSizeRead)
            {
                err=UNZ_ERRNO;
            }
        }
        lSeek+=file_info.size_file_comment - uSizeRead;
    }
    else
    {
        lSeek+=file_info.size_file_comment;
    }
    
    if ((err==UNZ_OK) && (pfile_info!=NULL))
    {
        *pfile_info=file_info;
    }
                
    return err;
}

int unz_checkCurrentFileCoherencyHeader (unzip_s *s, uInt *piSizeVar,
                                         uLong *poffset_local_extrafield,
                                         uInt *psize_local_extrafield)
{
    uLong uMagic,uData,uFlags;
    uLong size_filename;
    uLong size_extra_field;
    int err=UNZ_OK;
    
    *piSizeVar = 0;
    *poffset_local_extrafield = 0;
    *psize_local_extrafield = 0;
    
    if (fseek_file(s->filestream,s->offset_curfile +
              s->byte_before_the_zipfile,F_SEEK_SET)!=0)
        return UNZ_ERRNO;
    
    if (err==UNZ_OK)
    {
        if (unz_getLong(s->filestream,&uMagic) != UNZ_OK)
            err=UNZ_ERRNO;
        else if (uMagic!=0x04034b50)
            err=UNZ_BADZIPFILE;
    }
                
    if (unz_getShort(s->filestream,&uData) != UNZ_OK)
        err=UNZ_ERRNO;
    /*
     else if ((err==UNZ_OK) && (uData!=s->cur_file_info.wVersion))
        err=UNZ_BADZIPFILE;
     */
    if (unz_getShort(s->filestream,&uFlags) != UNZ_OK)
        err=UNZ_ERRNO;
                        
    if (unz_getShort(s->filestream,&uData) != UNZ_OK)
    {
        err=UNZ_ERRNO;
    }
    else if ((err==UNZ_OK) && (uData!=s->cur_file_info.compression_method))
    {
        err=UNZ_BADZIPFILE;
    }
                                
    if ((err==UNZ_OK) && (s->cur_file_info.compression_method!=0) &&
        (s->cur_file_info.compression_method!=Z_DEFLATED))
        err=UNZ_BADZIPFILE;
                                    
    if (unz_getLong(s->filestream,&uData) != UNZ_OK) /* date/time */
        err=UNZ_ERRNO;
                                        
    if (unz_getLong(s->filestream,&uData) != UNZ_OK) /* crc */
    {
        err=UNZ_ERRNO;
    }
    else if ((err==UNZ_OK) && (uData!=s->cur_file_info.crc) &&
             ((uFlags & 8)==0))
    {
        err=UNZ_BADZIPFILE;
    }
                                                
    if (unz_getLong(s->filestream,&uData) != UNZ_OK) /* size compr */
    {
        err=UNZ_ERRNO;
    }
    else if ((err==UNZ_OK) && (uData!=s->cur_file_info.compressed_size) &&
             ((uFlags & 8)==0))
    {
        err=UNZ_BADZIPFILE;
    }
                                                        
    if (unz_getLong(s->filestream,&uData) != UNZ_OK) /* size uncompr */
    {
        err=UNZ_ERRNO;
    }
    else if ((err==UNZ_OK) && (uData!=s->cur_file_info.uncompressed_size) &&
             ((uFlags & 8)==0))
    {
        err=UNZ_BADZIPFILE;
    }
                                                                
    if (unz_getShort(s->filestream,&size_filename) != UNZ_OK)
    {
        err=UNZ_ERRNO;
    }
    else if ((err==UNZ_OK) && (size_filename!=s->cur_file_info.size_filename))
    {
        err=UNZ_BADZIPFILE;
    }
                                                                        
    *piSizeVar += (uInt)size_filename;
                                                                        
    if (unz_getShort(s->filestream,&size_extra_field) != UNZ_OK)
        err=UNZ_ERRNO;
    
    *poffset_local_extrafield = s->offset_curfile + SIZE_ZIP_LOCAL_HEADER + size_filename;
    *psize_local_extrafield = (uInt)size_extra_field;
    *piSizeVar += (uInt)size_extra_field;
                                                                            
    return err;
}

int unz_openCurrentFile2 (voidp file, int *method, int *level, int raw)
{
    int err=UNZ_OK;
    uInt iSizeVar;
    unzip_s* s;
    zip_file_read_info* pfile_in_zip_read_info;
    uLong offset_local_extrafield;  /* offset of the local extra field */
    uInt  size_local_extrafield;    /* size of the local extra field */
    
    if (file==NULL)
        return UNZ_PARAMERROR;
    s=(unzip_s*)file;
    if (!s->current_file_ok)
        return UNZ_PARAMERROR;
    
    if (s->pfile_in_zip_read != NULL)
        unz_closeCurrentFile(file);
        
    if (unz_checkCurrentFileCoherencyHeader(s,&iSizeVar,
                                                     &offset_local_extrafield,&size_local_extrafield)!=UNZ_OK)
        return UNZ_BADZIPFILE;
    
    pfile_in_zip_read_info = (zip_file_read_info *)MALLOC(sizeof(zip_file_read_info));
    if (pfile_in_zip_read_info==NULL)
        return UNZ_INTERNALERROR;
    
    pfile_in_zip_read_info->read_buffer=(char*)MALLOC(BUF_SIZE);
    pfile_in_zip_read_info->offset_local_extrafield = offset_local_extrafield;
    pfile_in_zip_read_info->size_local_extrafield = size_local_extrafield;
    pfile_in_zip_read_info->pos_local_extrafield=0;
    pfile_in_zip_read_info->raw=raw;
    
    if (pfile_in_zip_read_info->read_buffer==NULL)
    {
        FREE(pfile_in_zip_read_info);
        return UNZ_INTERNALERROR;
    }
    
    pfile_in_zip_read_info->stream_initialised=0;
    
    if (method!=NULL)
        *method = (int)s->cur_file_info.compression_method;
        
    if (level!=NULL)
    {
        *level = 6;
        switch (s->cur_file_info.flag & 0x06)
        {
            case 6 : *level = 1; break;
            case 4 : *level = 2; break;
            case 2 : *level = 9; break;
        }
    }
    
    if ((s->cur_file_info.compression_method!=0) &&
        (s->cur_file_info.compression_method!=Z_DEFLATED))
        err=UNZ_BADZIPFILE;
        
    pfile_in_zip_read_info->crc32_wait=s->cur_file_info.crc;
    pfile_in_zip_read_info->crc32=0;
    pfile_in_zip_read_info->compression_method =
    s->cur_file_info.compression_method;
    pfile_in_zip_read_info->filestream=s->filestream;
    pfile_in_zip_read_info->byte_before_the_zipfile=s->byte_before_the_zipfile;
    
    pfile_in_zip_read_info->stream.total_out = 0;
        
    if ((s->cur_file_info.compression_method==Z_DEFLATED) &&
        (!raw))
    {
        pfile_in_zip_read_info->stream.zalloc = (alloc_func)0;
        pfile_in_zip_read_info->stream.zfree = (free_func)0;
        pfile_in_zip_read_info->stream.opaque = (voidpf)0;
        pfile_in_zip_read_info->stream.next_in = (voidpf)0;
        pfile_in_zip_read_info->stream.avail_in = 0;
        
        err=inflateInit2(&pfile_in_zip_read_info->stream, -MAX_WBITS);
        if (err == Z_OK)
            pfile_in_zip_read_info->stream_initialised=1;
        else
        {
            FREE(pfile_in_zip_read_info);
            return err;
        }
        /* windowBits is passed < 0 to tell that there is no zlib header.
         * Note that in this case inflate *requires* an extra "dummy" byte
         * after the compressed stream in order to complete decompression and
         * return Z_STREAM_END.
         * In unzip, i don't wait absolutely Z_STREAM_END because I known the
         * size of both compressed and uncompressed data
         */
    }
    pfile_in_zip_read_info->rest_read_compressed = s->cur_file_info.compressed_size ;
    pfile_in_zip_read_info->rest_read_uncompressed = s->cur_file_info.uncompressed_size ;
    
    pfile_in_zip_read_info->pos_in_zipfile = s->offset_curfile + SIZE_ZIP_LOCAL_HEADER +
    iSizeVar;
    
    pfile_in_zip_read_info->stream.avail_in = (uInt)0;
    
    s->pfile_in_zip_read = pfile_in_zip_read_info;
    
    return UNZ_OK;
}

int unz_openCurrentFile (voidp file)
{
    return unz_openCurrentFile2(file, NULL, NULL, 0);
}

int unz_closeCurrentFile (voidp file)
{
    int err=UNZ_OK;
    
    unzip_s* s;
    zip_file_read_info* pfile_in_zip_read_info;
    if (file==NULL)
        return UNZ_PARAMERROR;
    s=(unzip_s*)file;
    pfile_in_zip_read_info=s->pfile_in_zip_read;
    
    if (pfile_in_zip_read_info==NULL)
        return UNZ_PARAMERROR;
    
    
    if ((pfile_in_zip_read_info->rest_read_uncompressed == 0) &&
        (!pfile_in_zip_read_info->raw))
    {
        if (pfile_in_zip_read_info->crc32 != pfile_in_zip_read_info->crc32_wait)
            err=UNZ_CRCERROR;
    }
    
    
    FREE(pfile_in_zip_read_info->read_buffer);
    pfile_in_zip_read_info->read_buffer = NULL;
    if (pfile_in_zip_read_info->stream_initialised)
        inflateEnd(&pfile_in_zip_read_info->stream);
    
    pfile_in_zip_read_info->stream_initialised = 0;
    FREE(pfile_in_zip_read_info);
    
    s->pfile_in_zip_read=NULL;
    
    return err;
}

int unz_readCurrentFile (voidp file, voidp buf, unsigned len)
{
    int err=UNZ_OK;
    uInt iRead = 0;
    unzip_s* s;
    zip_file_read_info* pfile_in_zip_read_info;
    if (file==NULL)
        return UNZ_PARAMERROR;
    s=(unzip_s*)file;
    pfile_in_zip_read_info=s->pfile_in_zip_read;
    
    if (pfile_in_zip_read_info==NULL)
        return UNZ_PARAMERROR;
    
    if (pfile_in_zip_read_info->read_buffer==NULL)
        return UNZ_END_OF_LIST_OF_FILE;
    if (len==0)
        return 0;
    
    pfile_in_zip_read_info->stream.next_out = (Bytef*)buf;
    pfile_in_zip_read_info->stream.avail_out = (uInt)len;
    if ((len>pfile_in_zip_read_info->rest_read_uncompressed) &&
        (!(pfile_in_zip_read_info->raw)))
        pfile_in_zip_read_info->stream.avail_out =
        (uInt)pfile_in_zip_read_info->rest_read_uncompressed;

    if ((len>pfile_in_zip_read_info->rest_read_compressed+
         pfile_in_zip_read_info->stream.avail_in) &&
        (pfile_in_zip_read_info->raw))
        pfile_in_zip_read_info->stream.avail_out =
        (uInt)pfile_in_zip_read_info->rest_read_compressed+
        pfile_in_zip_read_info->stream.avail_in;
    while (pfile_in_zip_read_info->stream.avail_out>0)
    {
        if ((pfile_in_zip_read_info->stream.avail_in==0) &&
            (pfile_in_zip_read_info->rest_read_compressed>0))
        {
            uInt uReadThis = BUF_SIZE;
            if (pfile_in_zip_read_info->rest_read_compressed<uReadThis)
                uReadThis = (uInt)pfile_in_zip_read_info->rest_read_compressed;
            if (uReadThis == 0)
                return UNZ_EOF;
            if (fseek_file(pfile_in_zip_read_info->filestream,
                           pfile_in_zip_read_info->pos_in_zipfile +
                           pfile_in_zip_read_info->byte_before_the_zipfile,
                           F_SEEK_SET) != 0)
                return UNZ_ERRNO;
            if (fread_file(pfile_in_zip_read_info->filestream,
                           pfile_in_zip_read_info->read_buffer,
                           uReadThis) != uReadThis)
                return UNZ_ERRNO;
            
            pfile_in_zip_read_info->pos_in_zipfile += uReadThis;
            
            pfile_in_zip_read_info->rest_read_compressed-=uReadThis;
            
            pfile_in_zip_read_info->stream.next_in =
            (Bytef*)pfile_in_zip_read_info->read_buffer;
            pfile_in_zip_read_info->stream.avail_in = (uInt)uReadThis;
        }
        if ((pfile_in_zip_read_info->compression_method==0) || (pfile_in_zip_read_info->raw))
        {
            uInt uDoCopy,i ;
            
            if ((pfile_in_zip_read_info->stream.avail_in == 0) &&
                (pfile_in_zip_read_info->rest_read_compressed == 0))
                return (iRead==0) ? UNZ_EOF : iRead;
            
            if (pfile_in_zip_read_info->stream.avail_out <
                pfile_in_zip_read_info->stream.avail_in)
                uDoCopy = pfile_in_zip_read_info->stream.avail_out ;
            else
                uDoCopy = pfile_in_zip_read_info->stream.avail_in ;
            
            for (i=0;i<uDoCopy;i++)
                *(pfile_in_zip_read_info->stream.next_out+i) =
                *(pfile_in_zip_read_info->stream.next_in+i);
            
            pfile_in_zip_read_info->crc32 = crc32(pfile_in_zip_read_info->crc32,
                                                  pfile_in_zip_read_info->stream.next_out,
                                                  uDoCopy);
            pfile_in_zip_read_info->rest_read_uncompressed-=uDoCopy;
            pfile_in_zip_read_info->stream.avail_in -= uDoCopy;
            pfile_in_zip_read_info->stream.avail_out -= uDoCopy;
            pfile_in_zip_read_info->stream.next_out += uDoCopy;
            pfile_in_zip_read_info->stream.next_in += uDoCopy;
            pfile_in_zip_read_info->stream.total_out += uDoCopy;
            iRead += uDoCopy;
        }
        else
        {
            uLong uTotalOutBefore,uTotalOutAfter;
            const Bytef *bufBefore;
            uLong uOutThis;
            int flush=Z_SYNC_FLUSH;
            
            uTotalOutBefore = pfile_in_zip_read_info->stream.total_out;
            bufBefore = pfile_in_zip_read_info->stream.next_out;
            
            /*
             if ((pfile_in_zip_read_info->rest_read_uncompressed ==
             pfile_in_zip_read_info->stream.avail_out) &&
             (pfile_in_zip_read_info->rest_read_compressed == 0))
             flush = Z_FINISH;
             */
            err=inflate(&pfile_in_zip_read_info->stream,flush);
            
            if ((err>=0) && (pfile_in_zip_read_info->stream.msg!=NULL))
                err = Z_DATA_ERROR;
            
            uTotalOutAfter = pfile_in_zip_read_info->stream.total_out;
            uOutThis = uTotalOutAfter-uTotalOutBefore;
            
            pfile_in_zip_read_info->crc32 =
            crc32(pfile_in_zip_read_info->crc32,bufBefore,
                  (uInt)(uOutThis));
            
            pfile_in_zip_read_info->rest_read_uncompressed -=
            uOutThis;
            
            iRead += (uInt)(uTotalOutAfter - uTotalOutBefore);
            
            if (err==Z_STREAM_END)
                return (iRead==0) ? UNZ_EOF : iRead;
            if (err!=Z_OK)
                break;
        }
    }
    if (err==Z_OK)
        return iRead;
    return err;
}

int t_mkdir(char* dirname)
{
    int ret=0;
    ret = mkdir (dirname,0775);
    return ret;
}

int t_deleteLastPathComponent_index(char *path)
{
    long length = (long)strlen(path);
    if (length <= 0) {
        return 0;
    }
    long endIndex = 0;
    for (long i=length-1; i-- >= 0;)
    {
        char c = path[i];
        if (c == '/') {
            endIndex = i;
            break;
        }
    }
    return (int)endIndex;
}

int makedir (char *newdir)
{
    if(!access(newdir, F_OK)) {
        return 0;
    }
    char *buffer;
    char *p;
    int  len = (int)strlen(newdir);
    
    if (len <= 0)
        return 0;
    
    buffer = (char*)malloc(len+1);
    strcpy(buffer,newdir);
    
    if (buffer[len-1] == '/') {
        buffer[len-1] = '\0';
    }
    if (t_mkdir(buffer) == 0)
    {
        free(buffer);
        return 1;
    }
    
    p = buffer+1;
    while (1)
    {
        char hold;
        
        while(*p && *p != '\\' && *p != '/')
            p++;
        hold = *p;
        *p = 0;
        if ((t_mkdir(buffer) == -1) && (errno == ENOENT))
        { 
            free(buffer);
            return 0;
        }
        if (hold == 0)
            break;
        *p++ = hold;
    }
    free(buffer);
    return 1;
}

bool unzipFile(char *orgPath, char *targetPath) {
    if (strlen(orgPath) == 0 || strlen(targetPath) == 0)
    {
        return false;
    }
    
    voidp zipFile = unz_open(orgPath);
    if (!zipFile)
    {
        return false;
    }
    bool success = true;
    int ret;
    unsigned char buffer[4096] = {0};
    do
    {
        ret = unz_openCurrentFile(zipFile);
        if (ret != UNZ_OK)
        {
            success = false;
            break;
        }
        // reading data and write to file
        int read;
        central_file_info fileInfo ={0};
        ret = unz_getCurrentFileInfo(zipFile, &fileInfo, NULL, 0, NULL, 0, NULL, 0);
        if(ret != UNZ_OK)
        {
            success = false;
            unz_closeCurrentFile(zipFile);
            break;
        }
        char *filename = (char*)malloc(fileInfo.size_filename + 1);
        unz_getCurrentFileInfo(zipFile, &fileInfo, filename, fileInfo.size_filename + 1, NULL, 0, NULL, 0);
        filename[fileInfo.size_filename] = '\0';
        
        bool isDirectory = false;
        if(filename[fileInfo.size_filename-1]=='/')
        {
            isDirectory = true;
        }
        
        if (strstr(filename, "__MACOSX/"))
        {
            unz_closeCurrentFile(zipFile);
            ret = unz_goToNextFile(zipFile);
            FREE(filename);
            filename = NULL;
            continue;
        }
        size_t len = strlen(targetPath) + 1 + strlen(filename);
        char *fullPath = (char *) malloc(len + 1);
        sprintf(fullPath, "%s/%s", targetPath, filename);
        fullPath[len] = '\0';
        char *newPath = "";
        if (isDirectory)
        {
            makedir(fullPath);
        }
        else
        {
            int endIndex = t_deleteLastPathComponent_index(fullPath);
            if (endIndex > 0)
            {
                newPath = (char *)malloc(endIndex+1);
                strncpy(newPath, fullPath, endIndex);
                newPath[endIndex] = '\0';
                makedir(newPath);
                FREE(newPath);
                newPath = NULL;
            }
        }
        if(access((const char*)fullPath, F_OK)) {
            FILE *fp = fopen((const char*)fullPath, "wb");
            while (fp)
            {
                read = unz_readCurrentFile(zipFile, buffer, 4096);
                if (read > 0)
                {
                    fwrite(buffer, read, 1, fp);
                }
                else if(read < 0)
                {
                    break;
                }
                else
                {
                    break;
                }
            }
            if (fp)
            {
                fclose(fp);
            }
        }
        unz_closeCurrentFile(zipFile);
        ret = unz_goToNextFile(zipFile);
        
        FREE(fullPath);
        FREE(filename);
        filename = NULL;
        fullPath = NULL;
    } while (ret==UNZ_OK && UNZ_OK!=UNZ_END_OF_LIST_OF_FILE);
    
    unz_close(zipFile);
    return success;
}
