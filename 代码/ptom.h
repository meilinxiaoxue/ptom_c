#ifndef _PTOM_H_
#define _PTOM_H_


typedef unsigned char u8;
typedef unsigned short u16;
typedef unsigned int u32;
typedef unsigned long long u64;

extern float ptom_getVersion();
extern int ptom_parse(char* mpath, char *ppath);
extern int ptom_init();
extern void ptom_deinit();

#endif
