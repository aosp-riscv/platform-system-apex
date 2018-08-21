#!/bin/bash

# Copyright (C) 2018 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

if [ -z $ANDROID_BUILD_TOP ]; then
  echo "You need to source and lunch before you can use this script"
  exit 1
fi

echo "Running test"
set -e # fail early

source $ANDROID_BUILD_TOP/build/envsetup.sh
m -j apexer

input_dir=$(mktemp -d)
output_dir=$(mktemp -d)

function finish {
  sudo umount /dev/loop10
  sudo losetup --detach /dev/loop10

  rm -rf ${input_dir}
  rm -rf ${output_dir}
}

trap finish EXIT
#############################################
# prepare the inputs
#############################################
# Create the input directory having 3 files with random bits
head -c 1M </dev/urandom > ${input_dir}/file1
head -c 1M </dev/urandom > ${input_dir}/file2
mkdir ${input_dir}/sub
head -c 1M </dev/urandom > ${input_dir}/sub/file3

# Create the APEX manifest file
manifest_file=$(mktemp)
echo '{"name": "com.android.example.apex", "version": 1}' > ${manifest_file}

# Create the file_contexts file
file_contexts_file=$(mktemp)
echo '
(/.*)?           u:object_r:root_file:s0
/sub(/.*)?       u:object_r:sub_file:s0
/sub/file3       u:object_r:file3_file:s0
' > ${file_contexts_file}

output_file=${output_dir}/test.apex

#############################################
# run the tool
#############################################
${ANDROID_HOST_OUT}/bin/apexer --verbose --manifest ${manifest_file} \
  --file_contexts ${file_contexts_file} \
  ${input_dir} ${output_file}

#############################################
# check the result
#############################################
offset=$(zipalign -v -c 4096 ${output_file} | grep image.img | tr -s ' ' | cut -d ' ' -f 2)

# test if it is mountable
mkdir ${output_dir}/mnt
sudo losetup -o ${offset} /dev/loop10 ${output_file}
sudo mount -o ro /dev/loop10 ${output_dir}/mnt
unzip ${output_file} manifest.json -d ${output_dir}

# check the contents
sudo diff ${manifest_file} ${output_dir}/mnt/manifest.json
diff ${manifest_file} ${output_dir}/manifest.json
sudo diff ${input_dir}/file1 ${output_dir}/mnt/file1
sudo diff ${input_dir}/file2 ${output_dir}/mnt/file2
sudo diff ${input_dir}/sub/file3 ${output_dir}/mnt/sub/file3

# check the selinux labels
[ `ls -Z ${output_dir}/mnt/file1 | cut -d ' ' -f 1` = "u:object_r:root_file:s0" ]
[ `ls -Z ${output_dir}/mnt/file2 | cut -d ' ' -f 1` = "u:object_r:root_file:s0" ]
[ `ls -d -Z ${output_dir}/mnt/sub/ | cut -d ' ' -f 1` = "u:object_r:sub_file:s0" ]
[ `ls -Z ${output_dir}/mnt/sub/file3 | cut -d ' ' -f 1` = "u:object_r:file3_file:s0" ]
[ `ls -Z ${output_dir}/mnt/manifest.json | cut -d ' ' -f 1` = "u:object_r:root_file:s0" ]

# check the android manifest
aapt dump xmltree ${output_file} AndroidManifest.xml | grep com.android.example.apex

echo Passed
