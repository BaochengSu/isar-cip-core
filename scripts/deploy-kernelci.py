#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import subprocess
import requests
import os
import sys
import time
from urllib.parse import urljoin

cdate=time.strftime("%Y%m%d")
api="https://api.staging.kernelci.org/upload"
token=os.getenv("KERNELCI_TOKEN")

release=sys.argv[1]
target=sys.argv[2]
extension=sys.argv[3]

rootfs_filename="cip-core-image-"+extension+"-cip-core-"+release+"-"+target+".tar.gz"
initrd_filename="cip-core-image-"+extension+"-cip-core-"+release+"-"+target+"-initrd.img"
input_dir="build/tmp/deploy/images/"+target
upload_path="/images/rootfs/cip/"+cdate+"/"+target+"/"
rootfs=input_dir+"/"+rootfs_filename
initrd=input_dir+"/"+initrd_filename

print("build directory contents:")
print(os.listdir(input_dir))

def upload_file(api, token, path, input_file, input_filename):
    headers = {
        'Authorization': token,
    }
    data = {
        'path': path,
    }
    files = {
        'file': (input_filename, open(input_file, 'rb').read()),
    }
    url = urljoin(api, 'upload')
    resp = requests.post(url, headers=headers, data=data, files=files)
    resp.raise_for_status()

if os.path.exists(rootfs) and os.path.exists(initrd):
    print("uploading rootfs to KernelCI")
    upload_file(api, token, upload_path, rootfs, rootfs_filename)
    print("uploading initrd to KernelCI")
    upload_file(api, token, upload_path, initrd, initrd_filename)
    print("uploaded to: https://storage.staging.kernelci.org"+upload_path)
