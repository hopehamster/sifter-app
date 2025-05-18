/* This is a wrapper for tgmath.h that avoids the __attribute__((__format__)) issue */
#ifndef _TGMATH_H_WRAPPER_
#define _TGMATH_H_WRAPPER_

/* Save __attribute__ and redefine it to avoid issues */
#ifdef __attribute__
#define __saved_attribute__ __attribute__
#endif

/* Completely disable attributes */
#define __attribute__(x)

/* Include the system tgmath.h via full path to prevent recursion */
#include_next <tgmath.h>

/* Restore original __attribute__ if needed */
#ifdef __saved_attribute__
#undef __attribute__
#define __attribute__ __saved_attribute__
#undef __saved_attribute__
#endif

#endif /* _TGMATH_H_WRAPPER_ */
