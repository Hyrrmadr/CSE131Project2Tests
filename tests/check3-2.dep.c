
extern int* my_global;

int my_static = 2;

int world(int i);

int ext_var = 42;

int hello(int i, int b) {
  int ret;

  printf("hello %d, %s\n", i, b == 0 ? "false" : "true");

  printf("my_static %d\n", my_static);

  ret = world(123456);
  printf("ret = %s\n", ret == 0 ? "false" : "true");

  printf("my_global1 %s\n", my_global == (int*)0 ? "false" : "true");

  my_global = &ext_var;

  printf("my_global2 %d\n", *my_global);

  return ext_var;
}
