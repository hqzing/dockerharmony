FROM scratch
COPY ./ramdisk /
CMD ["/bin/sh"]
