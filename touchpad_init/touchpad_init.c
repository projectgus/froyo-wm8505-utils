/*
 * WMT-kernel WM9715 touchscreen calibrator.
 * 
 * Originally by Jacob Stoner, rewritten by Angus Gratton
 *
 */
#include <stdio.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <string.h>

#define TS_IOCTL_CAL_START    0x7401
#define TS_IOCTL_CAL_DONE     0x40047402
#define TS_IOCTL_GET_RAWDATA  0x80047403

#define DATA_SZ 7

// touchcal contents on my m001: 
// original (as shipped?) set shown
// g_CalcParam = -129, -26283, 105670863, 15925, -268, -1091734, 128609
int defaults_m001[DATA_SZ] = { -6, -22676, 91400865, 15084, 257, -5927375, 112424 };


#define handle_error(msg)													\
  do { perror(msg); _exit(1); } while (0)

int main() {
  int data[DATA_SZ];
  
  printf("Loading touchscreen calibration...\n");

  FILE *fr = fopen ("/etc/touchcal", "rt");
  if(fr) {
	 printf("Reading calibration values from /etc/touchcal\n");
	 int n = fscanf(fr, "%d %d %d %d %d %d %d", &data[0], &data[1], &data[2], &data[3],
					&data[4], &data[5], &data[6]);
	 if(n < DATA_SZ)
		handle_error("/etc/touchcal appears to contain invalid data");	 
  }
  else {
	 printf("No calibration file at /etc/touchcal... going with defaults from Angus' M001(!!)\n");
	 memcpy(data, defaults_m001, sizeof(int)*DATA_SZ);
  }

  int fd = open("/dev/touchscreen", O_NONBLOCK);
  if(fd < 0)
	 handle_error("/dev/touchscreen not found, is the module loaded?\n");
  ioctl(fd, TS_IOCTL_CAL_START);
  ioctl(fd, TS_IOCTL_CAL_DONE, data);
  close(fd);
}
