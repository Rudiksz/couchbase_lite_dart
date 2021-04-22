//Includes
/* #undef CBL_HAVE_UNISTD_H */
#define CBL_HAVE_DIRECT_H

// Functions
/* #undef CBL_HAVE_VASPRINTF */

// Includes
#ifdef CBL_HAVE_UNISTD_H
#include <unistd.h>
#endif

#ifdef CBL_HAVE_DIRECT_H
#include <direct.h>
#endif

// Functions
#ifndef CBL_HAVE_VASPRINTF
#include "asprintf.h"
#endif
