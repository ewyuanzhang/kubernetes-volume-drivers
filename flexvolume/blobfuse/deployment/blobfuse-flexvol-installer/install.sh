#!/bin/sh

LOG="/var/log/blobfuse-flexvol-installer.log"
VER="1.0.9"
target_dir="${TARGET_DIR}"

if [[ -z "${target_dir}" ]]; then
  target_dir="/etc/kubernetes/volumeplugins"
fi

echo "begin to install blobfuse FlexVolume driver ${VER}, target dir:${target_dir} ..." >> $LOG

#install jq
apt-get install jq cifs-utils -y

#setup blobfuse volume directory
blobfuse_vol_dir="${target_dir}/azure~blobfuse"
mkdir -p ${blobfuse_vol_dir} >>$LOG 2>&1

#download blobfuse binary and lib
wget -O ${blobfuse_vol_dir}/release.json https://api.github.com/repos/ewyuanzhang/azure-storage-fuse/releases/latest >>$LOG 2>&1
blobfuse_url=`cat ${blobfuse_vol_dir}/release.json | grep "browser_download_url" | cut -d '"' -f 4` >>$LOG 2>&1
wget -O ${blobfuse_vol_dir}/blobfuse.zip ${blobfuse_url} >>$LOG 2>&1
unzip -d ${blobfuse_vol_dir} ${blobfuse_vol_dir}/blobfuse.zip >>$LOG 2>&1
blobfuse_lib_dir="${blobfuse_vol_dir}/lib"
blobfuse_bin_dir="${blobfuse_vol_dir}/bin"
chmod a+x ${blobfuse_bin_dir}/blobfuse >>$LOG 2>&1
rm ${blobfuse_vol_dir}/release.json ${blobfuse_vol_dir}/blobfuse.zip >>$LOG 2>&1

#copy blobfuse script
sed -i "s,BLOBFUSE_BIN=\"\",BLOBFUSE_BIN=\"$blobfuse_bin_dir/blobfuse\",g" /blobfuse/blobfuse
sed -i "s,BLOBFUSE_LIB=\"\",BLOBFUSE_LIB=\"$blobfuse_lib_dir\",g" /blobfuse/blobfuse
cp /blobfuse/blobfuse ${blobfuse_vol_dir}/blobfuse >>$LOG 2>&1
chmod a+x ${blobfuse_vol_dir}/blobfuse >>$LOG 2>&1

echo "install blobfuse FlexVolume driver completed." >> $LOG

#https://github.com/kubernetes/kubernetes/issues/17182
# if we are running on kubernetes cluster as a daemon set we should
# not exit otherwise, container will restart and goes into crashloop (even if exit code is 0)
while true; do echo "install done, daemonset sleeping" && sleep 3600; done
