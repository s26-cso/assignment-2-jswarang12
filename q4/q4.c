#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <dlfcn.h> // dynamic loading (dlopen, dlsym, dlclose)

int main() {
    // operation name is guaranteed max 5 characters.
    // We allocate 6 bytes for the null terminator
    char op[6];
    int arg1, arg2;

    // read lines continuously from standard input
    // scanf returns 3 when it successfully reads all three arguments
    while (scanf("%5s %d %d", op, &arg1, &arg2) == 3) {
        
        char lib_name[32];
        // construct  shared library name string: ./lib<op>.so
        // prepend "./" to check the current pwd
        snprintf(lib_name, sizeof(lib_name), "./lib%s.so", op);

        // loadshared library
        // RTLD_LAZY performs lazy binding...  efficient here.
        void *handle = dlopen(lib_name, RTLD_LAZY);
        if (!handle) {
            fprintf(stderr, "Error loading library: %s\n", dlerror());
            continue;
        }

        // clear existing errors before looking up the symbol
        dlerror();

        // declare  function pointer type matching the req signature
        typedef int (*op_func_t)(int, int);
        
        // find address of the function <op> in the loaded lib
        op_func_t func = (op_func_t)dlsym(handle, op);
        
        char *err = dlerror();
        if (err != NULL) {
            fprintf(stderr, "Error finding function %s: %s\n", op, err);
            dlclose(handle); // clean up before skipping
            continue;
        }

        // call dynamically loaded fn and print the result
        int result = func(arg1, arg2);
        printf("%d\n", result);

        // MEMORY CONSTRAINT HANDLING:
        // The total mem lim is 2GB, and a single lib can be 1.5GB
        // if we load two different libraries without unloading, we will hit 3GB ... we explicitly unload the library 
        //  using dlclose() to free the 1.5GB before the next loop iteration.
        dlclose(handle);
    }

    return 0;
}