#include <nccl.h>

#include <cstdio>

int main() {
  ncclUniqueId id;
  ncclResult_t result = ncclGetUniqueId(&id);
  if (result == ncclSuccess) {
    printf("NCCL library successfully linked and initialized\n");
    return 0;
  } else {
    printf("NCCL initialization failed\n");
    return 1;
  }
}
