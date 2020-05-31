/*
*FME test app
*
*
*/
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <termios.h>
#include <fcntl.h>
#include <errno.h>

char devname[] = "/dev/xilinx_hwicap0";
char filepath[]= "./bit_file/kcu105_partial_clear.bit";
int g_devFile = -1;

enum XCLMGMT_IOC_TYPES {
    FME_MGMT_IOC_INFO,
    FME_MGMT_IOC_ICAP_DOWNLOAD,
    FME_MGMT_IOC_FREQ_SCALE,
    FME_MGMT_IOC_OCL_RESET,
    FME_MGMT_IOC_HOT_RESET,
    FME_MGMT_IOC_REBOOT,
    FME_MGMT_IOC_ICAP_DOWNLOAD_AXLF,
    FME_MGMT_IOC_ERR_INFO,
    FME_MGMT_IOC_MAX
};

struct hwicap_status{
    int hw_status;
};
enum HWICAP_STATUS{
    ICAP_DOWNLOADING = 0,
    ICAP_DOWNLOAD_FINISH,
    ICAP_DOWNLOAD_ERROR
};


struct fme_ioc_bitstream {
    int   len;
    char *buff;
};


#define XCLMGMT_IOC_MAGIC   'X'
#define FME_IOC_ICAP_DOWNLOAD     _IOW (XCLMGMT_IOC_MAGIC,FME_MGMT_IOC_ICAP_DOWNLOAD,    struct fme_ioc_bitstream)


unsigned long get_file_size(const char *path)  
{      
    unsigned long filesize = -1;     
    FILE *fp;     
    fp = fopen(path, "r");    
    if(fp == NULL)       
        return filesize;    
    fseek(fp, 0L, SEEK_END);   
    filesize = ftell(fp);   
    fclose(fp);   
    return filesize;  
}  


int main()
{
  int i, j;
  int iter_count = 1;
  struct fme_ioc_bitstream bit;
  char* devfilename = devname;
  long file_size;
  long ret;
  g_devFile = open(devfilename, O_RDWR);

  if ( g_devFile < 0 )  {
    printf("Error opening device file\n");
    return 0;
  }

  file_size = get_file_size(filepath);
  printf("file_size:%0lx\n",file_size);
 
  fme_ioc_bitstream obj;
  obj.len = file_size;
  obj.buff = (char*)malloc(file_size);
  
  //open bit file
  int fd = open(filepath, O_RDONLY);
  if (fd < 0) 
  {
    printf( "Unable to open device node\n");
    return -1;
  }
  // read buffer
  if((ret = read(fd, obj.buff, file_size))==-1)
  {
    printf("pread error\n");
    exit(1);
  }

  hwicap_status st;
  st.hw_status = ICAP_DOWNLOADING;

  ioctl(g_devFile,FME_IOC_ICAP_DOWNLOAD,&obj);
  
  while(st.hw_status == ICAP_DOWNLOADING)
  {
    read(g_devFile,&st,sizeof(hwicap_status));
    printf("hwicap_status value:%d\n",st.hw_status);
    sleep(1);
  }

  
  close(fd);
  free(obj.buff);
  
}
