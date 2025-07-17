#!/bin/bash

# Copyright   2014  Johns Hopkins University (author: Daniel Povey)
# Apache 2.0

remove_archive=false

if [ "$1" == --remove-archive ]; then
  remove_archive=true
  shift
fi

if [ $# -ne 3 ]; then
  echo "Usage: $0 [--remove-archive] <data-base> <url-base> <corpus-part>"
  echo "e.g.: $0 /export/a15/vpanayotov/data www.openslr.org/resources/11 dev-clean"
  echo "With --remove-archive it will remove the archive after successfully un-tarring it."
  echo "<corpus-part> can be one of: dev-clean, test-clean, dev-other, test-other,"
  echo "          train-clean-100, train-clean-360, train-other-500."
  exit 1
fi

data=$1
url="https://data.keithito.com/data/speech/LJSpeech-1.1.tar.bz2"
part="LJSpeech-1.1"

if [ ! -d "$data" ]; then
  echo "$0: no such directory $data"
  exit 1
fi

#part_ok=false
#list="dev-clean test-clean dev-other test-other train-clean-100 train-clean-360 train-other-500"
#for x in $list; do
#  if [ "$part" == $x ]; then part_ok=true; fi
#done
#if ! $part_ok; then
#  echo "$0: expected <corpus-part> to be one of $list, but got '$part'"
#  exit 1
#fi
#
#if [ -z "$url" ]; then
#  echo "$0: empty URL base."
#  exit 1
#fi
#
#if [ -f $data/LibriTTS/$part/.complete ]; then
#  echo "$0: data part $part was already successfully extracted, nothing to do."
#  exit 0
#fi

if [ ! -d "$data" ]; then
  echo "$0: no such directory $data"
  exit 1
fi

if [ -f $data/$part/.complete ]; then
  echo "$0: data part $part was already successfully extracted, nothing to do."
  exit 0
fi


# sizes of the archive files in bytes.  This is some older versions.
#sizes_old="371012589 347390293 379743611 361838298 6420417880 23082659865 30626749128"
# sizes_new is the archive file sizes of the final release.  Some of these sizes are of
# things we probably won't download.
#sizes_new="337926286 314305928 695964615 297279345 87960560420 33373768 346663984 328757843 6387309499 23049477885 30593501606"

size_ljspeech="2744553444" 


if [ -f $data/$part.tar.bz2 ]; then
  size=$(/bin/ls -l $data/$part.tar.bz2 | awk '{print $5}')
  if [ "$size" != "$size_ljspeech" ]; then
    echo "$0: removing existing file $data/$part.tar.bz2 because its size in bytes $size"
    echo "does not equal the expected size of $size_ljspeech."
    rm $data/$part.tar.bz2
  else
    echo "$data/$part.tar.bz2 exists and appears to be complete."
  fi
fi


if [ ! -f $data/$part.tar.bz2 ]; then
  if ! which wget >/dev/null; then
    echo "$0: wget is not installed."
    exit 1
  fi
  echo "$0: downloading data from $url. This may take some time, please be patient."

  if ! wget -P $data --no-check-certificate $url; then
    echo "$0: error executing wget $url"
    exit 1
  fi
fi

if ! tar -C $data -xvf $data/$part.tar.bz2; then
  echo "$0: error un-tarring archive $data/$part.tar.bz2"
  exit 1
fi

touch $data/$part/.complete


#echo "$0: Successfully downloaded and un-tarred $data/$part.tar.gz"
echo "$0: Successfully downloaded and un-tarred $data/$part.tar.bz2"

if $remove_archive; then
  echo "$0: removing $data/$part.tar.bz2 file since --remove-archive option was supplied."
  rm $data/$part.tar.bz2
fi
