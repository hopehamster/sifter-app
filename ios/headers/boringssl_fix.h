/* BoringSSL Fix Header - This will be injected into BoringSSL header files */
#ifndef BORINGSSL_FIX_H
#define BORINGSSL_FIX_H

/* Save original attribute if needed */
#ifdef __attribute__
#define __saved_attribute__ __attribute__
#endif

/* Completely disable format attributes */
#undef __attribute__
#define __attribute__(x)

/* Disable printf format macros */
#undef OPENSSL_PRINTF_FORMAT
#define OPENSSL_PRINTF_FORMAT(a, b)
#undef OPENSSL_PRINTF_FORMAT_FUNC
#define OPENSSL_PRINTF_FORMAT_FUNC(a, b)

/* Disable ASM */
#define OPENSSL_NO_ASM 1

#endif /* BORINGSSL_FIX_H */
