#ifndef _ZMALLOC_H
#define _ZMALLOC_H

#include <stdlib.h>

#define zmalloc(sz) malloc(sz)
#define zfree(ptr) free(ptr)

 
#endif /* _ZMALLOC_H */