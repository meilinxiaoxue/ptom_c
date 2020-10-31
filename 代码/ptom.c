#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <windows.h>
#include "ptom.h"

#define H8(x) ((u8)(x>>24))

struct mfile_t
{
	u32 token[7];
	u32 size;
	u8 *mdata;
};

struct pfile_t
{
	char major[6];
	char minor[6];
	u32  scramble;
	u32  crc;
	u32  uk2;
	u32  size_after_compass;
	u32  size_befor_compass;
	u8*  pdata;
};

struct slot_t
{
	char** name;
	u32 size;
};

typedef int (*uncompress)(u8*,u32*,u8*,u64);

static const u32 s_scramble_tbl[256] = {
	0x050F0687,0xC3F63AB0,0x2E022A9C,0x036DAA8C,0x32ED8AE2,0xF5571876,0xC66FE7F3,0x6CF0D7C0,
	0xBE08BA59,0x0CBB32BE,0x2E1E76F9,0x5B095029,0xD7B83753,0xB949C2EA,0x002B7101,0x10BF6F59,
	0x5A565564,0xCF31F672,0x49B64869,0x30B5AE91,0x33D84C72,0xE4B5B87D,0x97EF0BD8,0x58A53999,
	0xA2D54211,0x040D16F3,0x8ED0F2AB,0xA1123692,0x7CAD41FD,0x47FD2EE5,0xD5B56675,0x01BC4884,
	0x8BF36995,0x83B79111,0x8529F311,0x3EE0F477,0x790EA987,0x4B99DB04,0x2BD1CC37,0x371763E1,
	0x58550DC3,0xD9F04330,0x1220B40A,0xB00D4516,0x133A061B,0x924C250C,0x40CCB470,0x6D905B7F,
	0x617E1B7E,0x0A82FCD9,0x1E460A11,0x155667F0,0x6F38B557,0x363515E9,0x6DFBA189,0x920DF768,
	0x3A422CDD,0x7CCC9435,0xB3202DFB,0x36EF6EDA,0x44C9C31A,0x08D59470,0xB8ABB75E,0x50BD2CAF,
	0x8C8D2582,0x3DD5AA6F,0x0F9E2126,0x059BCF09,0x096F8574,0x3B6FED5D,0x3CB332EA,0x61C49337,
	0x9560308D,0x4ED3E6F5,0x91D1D84D,0xA89A36A8,0xE1200C01,0xD29E8CBD,0x162A9228,0x429E277F,
	0x5D218997,0x34709C39,0x57F48F70,0x4C5A3EEE,0x6AA5B222,0xC5F030F9,0xDE683656,0xA4E7DEFF,
	0xC2BCC52E,0x11886451,0xDBD74DD9,0x87868848,0x1A5DF8C2,0x14830538,0xD843B4F7,0x26EB1E44,
	0x5258AFA7,0xE7E1D61D,0x2C86ED4D,0x5BC8351B,0x2351C37A,0x693A2038,0x3D8CC852,0xB8B1F408,
	0x380E072D,0x4F5EA0A0,0xE14C2AB0,0x192E132E,0xA1FD2D5D,0xF776BCD8,0x5BCC3AAD,0xFF1EB6F4,
	0xABE75911,0x33C0CA1D,0xCB78F5E2,0x168D0B34,0xF9B0FB17,0xA9E12C39,0xBB74EA33,0x3C6DC045,
	0xBB69908A,0x174C380D,0x43F4488E,0x55C7894C,0xABCF3D45,0x9C37FD85,0x7CB2A790,0xFE27ECEC,
	0x8419D3A3,0x293994DE,0x59F02208,0xA76B971D,0x1273B516,0x177CEA5A,0x601D8B25,0x4A81BC43,
	0x66DB8AFA,0xC169B5D6,0x63AFCF71,0x08D8B858,0x38E072AE,0x3F7C0A1E,0x87F76F4C,0x64C7CBC0,
	0xF33CD43C,0xD370652F,0x7B54D6F4,0x6CEDCF53,0x7D519168,0xB6C9C127,0xA95B8F98,0xB8BB21F2,
	0xCE15F934,0xED4FD826,0x8E82AB3F,0x79E53679,0x0987D5AC,0x8B3552CF,0x780D2366,0x8DA1A94F,
	0xB46EE7AD,0x51FD456E,0x350D406C,0xC6E29CC3,0x697A2FC8,0x952ACB92,0x11645906,0xD055BAC3,
	0x56948168,0x75142877,0xD92E731B,0x8F74F416,0xB4903296,0x6125E267,0xF43CBFD6,0x27CD06D2,
	0xB4964796,0xEF9196CA,0x14BAD625,0xB1E7D8FE,0x265B57F2,0xBE1665BD,0xEAA2FAF1,0xF4715126,
	0x2B663DE4,0x7925A630,0x6E5687A0,0xB4EE1390,0x045AF8FF,0x6663AB06,0x428FBCDF,0xB8C9E0AD,
	0x3860F074,0xF79CFD4B,0xFFAC7D70,0x21DB203C,0x0CC7C8DD,0x9110D677,0xF230DAFF,0x635C4A45,
	0x8624FEEE,0x4B5F4E1A,0xF2D13E5C,0x3AB53184,0xAC853082,0x670DFE32,0x62823856,0x611B7818,
	0xD69F94FD,0xF73D0E7B,0x13035117,0xFCFAECEF,0x35537439,0xFDA64C08,0xF16C3E15,0xE0B9B21D,
	0xF6CBF238,0xDFC2C5B5,0x15A7C5AD,0xFB26EB37,0xC62670BB,0x5837828C,0xB3F0CBE4,0xFE87612F,
	0xCFD47FD7,0x339D4955,0xA062816C,0xDC9C48B5,0xC4AE1FCC,0x92935C6B,0x3FF892FA,0x4AD31EBA,
	0xDDF2AA86,0xB2C9D156,0x8588503F,0x0A77DB08,0x19D7CF89,0xE80A8895,0xEB935320,0xF0776486,
	0x5F479711,0xFE96A437,0xED725175,0x949B0B4A,0x7C3CF03F,0x5EDE8F8A,0x7554BD67,0xF308E277,
	0xBEA15540,0x0AFC8314,0xEE2FCDAF,0x04C7C5FB,0x633405A0,0x22209993,0x834F272B,0x33088577,
};
static const char s_token[134][25]= {
	 "",
	 "function ",
	 "function ",
	 "if",
	 "switch",
	 "try",
	 "while",
	 "for",
	 "end",
	 "else",
	 "elseif",
	 "break",
	 "return ",
	 "parfor",
	 "",
	 "global ",
	 "persistent ",
	 "",
	 "",
	 "",
	 "catch ",
	 "continue ",
	 "case ",
	 "otherwise",
	 "",
	 "classdef ",
	 "",
	 "",
	 "properties ",
	 "",
	 "methods ",
	 "events ",
	 "enumeration ",
	 "spmd ",
	 "parsection ",
	 "section ",
	 "",
	 "",
	 "",
	 "",
	 "id ",
	 "end",
	 "int ",
	 "float ",
	 "string ",
	 "dual ",
	 "bang ",
	 "?",
	 "",
	 "",
	 "; ",
	 ",",
	 "(",
	 ")",
	 "[",
	 "]",
	 "{",
	 "}",
	 "feend ",
	 "",
	 "' ",
	 "dottrans ",
	 "~",
	 "@",
	 "$",
	 "`",
	 "\"",
	 "",
	 "",
	 "",
	 "+",
	 "-",
	 "*",
	 "/",
	 "\\",
	 "^",
	 ":",
	 "",
	 "",
	 "",
	 ".",
	 ".*",
	 "./",
	 ".\\",
	 ".^",
	 "&",
	 "|",
	 "&&",
	 "||",
	 "<",
	 ">",
	 "<=",
	 ">=",
	 "==",
	 "~=",
	 "=",
	 "cne ",
	 "arrow ",
	 "",
	 "",
	 "\n",
	 "\n ",
	 "\n ",
	 "...\n    ",
	 "",
	 "comment ",
	 "blkstart ",
	 "blkcom ",
	 "blkend ",
	 "cpad ",
	 "pragma ",
	 "...",
	 "..",
	 "deep_nest ",
	 "deep_stmt ",
	 "",
	 "white ",
	 "",
	 "negerr ",
	 "semerr ",
	 "eolerr ",
	 "unterm ",
	 "badchar ",
	 "deep_paren ",
	 "fp_err ",
	 "res_err ",
	 "deep_com ",
	 "begin_type ",
	 "end_type ",
	 "string_literal ",
	 "unterm_string_literal ",
	 "arguments_block ",
	 "last_token ",
	 ""
};

static const char s_major_version[6] = "v01.00";
static const char s_minor_version[6] = "v00.00";
static HANDLE s_dll_handle;
static uncompress s_uncompress_func;
static float s_version = 1.0;

/************************************
 *			static code
 ************************************/
 
static struct slot_t* s_slotInit(u32 num)
{
	struct slot_t* slot_ptr = NULL;
	char** name_ptr = NULL;

	slot_ptr = (struct slot_t*)malloc(sizeof(struct slot_t));
	if(!slot_ptr)
		return NULL;
		
	memset(slot_ptr,0,sizeof(struct slot_t));
	slot_ptr->size = num;
	if(num)
	{
		 name_ptr = (char**)malloc(num*sizeof(char*));
		 if(!name_ptr)
		 {
		 	free(slot_ptr);
		 	return NULL;
		 }
		 slot_ptr->name = name_ptr;
	}
	return slot_ptr;
}

static int s_slotSet(struct slot_t* slot, u32 id, char* name)
{
	if(id < slot->size && slot->name != NULL)
	{
		slot->name[id] = name;
		return 1;
	}
	return 0;
}

static char* s_slotGet(struct slot_t* slot, u32 id)
{
	if(id < slot->size && slot->name != NULL && slot->name[id] != NULL)
	{
		return slot->name[id];
	}
	return NULL;
}

static void s_slotDeinit(struct slot_t* slot)
{
	if(slot)
	{
		if(slot->size)
		{
			free(slot->name);
		}
		free(slot);
	}
}
 
static long s_fsize(FILE* fp)
{
	long len = 0, cur = 0;
	
	if(fp)
	{
		cur = fseek(fp, 0, SEEK_CUR);
		fseek(fp, 0, SEEK_END);
		len = ftell(fp);
		fseek(fp, 0, cur);
	}
	return len;
}

static void s_scramble(struct pfile_t *pfile)
{
	u32 i;
	u8 scramble_number;
	u32* pdata = (u32*)pfile->pdata;
	
	scramble_number = (u8)(pfile->scramble>>12);
	for(i = 0;i<pfile->size_after_compass/4;i++)
	{
		*pdata ^= s_scramble_tbl[(u8)(i+scramble_number)];
		pdata++;
	}
	
}

static u32 s_ntohl(u32 in)
{
	u32 out;
	u8 *pin = (u8*)&in;
	u8 *pout = (u8*)&out;
	pout[0] = pin[3];
	pout[1] = pin[2];
	pout[2] = pin[1];
	pout[3] = pin[0];
	return (out);
}

static int s_check_pfile(struct pfile_t *pfile)
{
	if(memcmp(pfile->major,s_major_version,6)==0)
	{
		if(memcmp(pfile->minor,s_minor_version,6)==0)
		{
			pfile->scramble = s_ntohl(pfile->scramble);
			pfile->size_after_compass = s_ntohl(pfile->size_after_compass);
			pfile->size_befor_compass = s_ntohl(pfile->size_befor_compass);
			if(pfile->size_after_compass > 0 && pfile->size_befor_compass > 0)
			{
				return 1;
			}
		}		
	}
	return 0;
}

static int s_check_mfile(struct mfile_t *mfile)
{
	int i;
	
	for(i=0;i<7;i++)
	{
		mfile->token[i] = s_ntohl(mfile->token[i]);
	}
	return 1;
}

static int s_uncompress(struct mfile_t *mfile,struct pfile_t *pfile)
{
	u32 size;
	u8* tmp_ptr;

	if(!s_dll_handle || !s_uncompress_func)
		return 0;

	s_scramble(pfile);

	size = pfile->size_befor_compass;
	tmp_ptr = (u8*)malloc(size);
	if(!tmp_ptr)
		return 0;

	/*
	FILE *fp = fopen("test.tmp","wb"); 
	fwrite(pfile->pdata,1,pfile->size_after_compass,fp);
	fclose(fp);
	*/
	
	s_uncompress_func(tmp_ptr,&size,pfile->pdata,(u64)pfile->size_after_compass);
	
	if(size != pfile->size_befor_compass)
	{
		free(tmp_ptr);
		return 0;
	}
	/*
	FILE *fp = fopen("test.tmp","wb"); 
	fwrite(tmp_ptr,1,size,fp);
	fclose(fp);
	*/
	
	size -= 7*sizeof(u32);
	mfile->mdata = malloc(size);
	if(mfile->mdata)
	{
		memcpy(mfile->token,tmp_ptr,7*sizeof(u32));
		memcpy(mfile->mdata,tmp_ptr+7*sizeof(u32),size);
		mfile->size = pfile->size_befor_compass - 7*sizeof(u32);
		free(tmp_ptr);
		return 1;
	}else
	{
		free(tmp_ptr);
		memset(mfile,0,sizeof(struct mfile_t));
		return 0;
	}
}

static int s_parsePFile(struct pfile_t *pfile, char *path)
{
	FILE* pfp = NULL;
	long psize = 0;
	
	pfp = fopen(path,"rb");
	if(pfp)
	{
		psize = s_fsize(pfp);
		if(psize >= 32)
		{
			fread(pfile,1,32,pfp);
			if(s_check_pfile(pfile))
			{
				pfile->pdata = malloc(pfile->size_after_compass);
				if(pfile->pdata)
				{
					if(pfile->size_after_compass == fread(pfile->pdata,1,pfile->size_after_compass,pfp))
					{
						fclose(pfp);
						return 1;
					}else
					{
						free(pfile->pdata);
					}						
				}
			}
			memset(pfile,0,sizeof(struct pfile_t));
		}	
		fclose(pfp);
	}				
	return 0;
}

static int s_parseMFile(char* mpath, struct mfile_t *mfile)
{
	int i, j, k, success, res_id;
	struct slot_t* slot[1] = {NULL};
	char* name_ptr = NULL;
	char* mfile_ptr = NULL, *mfile_tmp = NULL;
	u8* cur_ptr = NULL;
	u8* end_ptr = NULL;

	s_check_mfile(mfile);

//	if(mfile->size > 0)
//	{
//		FILE* fp_out = fopen("test.bin","wb");
//		fwrite(mfile->token,1,7*sizeof(u32),fp_out);
//		fwrite(mfile->mdata,1,mfile->size,fp_out);
//		fclose(fp_out);
//	}

	/* parse name symbol*/
	for(i=0,j=0;i<7;i++)
		j += mfile->token[i];
	slot[0] = s_slotInit(j);

	name_ptr = (char*)(mfile->mdata);
	k = 0;
	for(i=0;i<7;i++)
	{
		for(j=0;j<mfile->token[i];j++)
		{
			s_slotSet(slot[0],k++,name_ptr);
			name_ptr += strlen(name_ptr)+1; //+1 is because of \0
			//printf("%04X	->	%s\n",k,name_ptr);
		}
	}
	
	/* parse code */
	cur_ptr = (u8*)name_ptr;
	end_ptr = mfile->mdata + mfile->size;
	mfile_tmp = mfile_ptr = (char*)malloc(102400);
	if(!mfile_ptr)
	{
		s_slotDeinit(slot[0]);
		return 0;
	}
		
	
	success = 1;
	int debug = 0; 
	while(1)
	{
		if(debug++ == 5130 && 0)
			break;
		if(cur_ptr >= end_ptr)
			break;
			
		/* parse 2 byte code*/
		if((cur_ptr[0]&0x80) == 0x80)
		{
			res_id = 128 + 256*((cur_ptr[0]&0x7F)-1) + cur_ptr[1];
			name_ptr = s_slotGet(slot[0],res_id);
			
			strcpy(mfile_tmp,name_ptr);
			mfile_tmp += strlen(name_ptr);
			mfile_tmp[0] = ' ';
			mfile_tmp++;
			//printf("%02X %02x -> %d:	%s\n",cur_ptr[0],cur_ptr[1],res_id,name_ptr);
			cur_ptr += 2;
			continue;
		}
				
		/* parse 1 byte code*/
		if(cur_ptr[0] < 134)
		{
			name_ptr = (char*)s_token[cur_ptr[0]];
			
			if(strlen(name_ptr) != 0)
			{
				strcpy(mfile_tmp,name_ptr);
				mfile_tmp += strlen(name_ptr);				
			}
			//printf("NULL string in %02X\n",cur_ptr[0]);
			//printf("%02X:%s\n",cur_ptr[0],name_ptr);
			cur_ptr += 1;
			continue;
		}


		/* parse 3 byte code*/
		
		printf("parse code failed\n");
		while(cur_ptr < end_ptr)
		{
			printf("%02X ",cur_ptr[0]);
			cur_ptr++;
		}
		printf("\n"); 
		success = 0;
		break;
	}
	printf("%d\n",debug);
	 
	if(success || 1)
	{
		FILE* fp = fopen(mpath,"w");
		if(fp)
		{
			fwrite(mfile_ptr,1,strlen(mfile_ptr),fp);
			fclose(fp);
		}	
	}
	
	free(mfile_ptr);
	s_slotDeinit(slot[0]);
	return success;
}


/************************************
 *			extern code
 ************************************/
float ptom_getVersion()
{
	return s_version;
}

int ptom_init()
{
	s_dll_handle = LoadLibraryA("zlib1.dll");
	
	if(!s_dll_handle)
		return 0;
	
	s_uncompress_func = (uncompress)GetProcAddress(s_dll_handle,"uncompress");
	if(!s_uncompress_func)
	{
		FreeLibrary(s_dll_handle);
		return 0;	
	}
	return 1;
}

void ptom_deinit()
{
	if(s_dll_handle)
		FreeLibrary(s_dll_handle);
}

int ptom_parse(char* mpath, char *ppath)
{
	struct pfile_t pfile;
	struct mfile_t mfile;
	
	if(!ppath || !mpath || strlen(ppath) == 0 || strlen(mpath) == 0)
		return 0;
	
	if(s_parsePFile(&pfile,ppath) == 0)
	{
		printf("parsePFile failed\n");
		return 0;
	}
	
	if(s_uncompress(&mfile,&pfile) == 0)
	{
		printf("uncompress failed\n");
		return 0;
	}
	if(s_parseMFile(mpath,&mfile) == 0)
	{
		printf("parseMFile failed\n");
		return 0;
	}
 	return 1;
}

