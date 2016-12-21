#!/bin/bash

# param
path_param=$1

# const
FLAG="/"
_M3U8="*.m3u8"
INDEX_M3U8="index.m3u8"
STREAM_M3U8="stream.m3u8"
FFMPEG="/data/ffmpeg/bin/ffmpeg"

# var
path_in=""
joint=""

# 转换成MP4文件
function fun_ffmpeg()
{
    local concat=$1
    local out=$2".mp4"
    local t=$3

    $FFMPEG -i $concat -acodec copy -vcodec copy -bsf:a aac_adtstoasc -movflags faststart -t $t $out -y

    joint=""
}

# 拼接TS文件
function joint_sub()
{
    local file=$1
    local t=$2
    echo "access ts file $file"
    local dir=${file%/*}"/"
    local txt=`cat $file | grep ".ts"`

    for line in $txt
    do
        tmp=`echo $line | tr -d "\r" | tr -d "\n"`
        joint="$joint|$dir$tmp"
    done
    concat="concat:"${joint#*|}

    fun_ffmpeg $concat ${file%.*} $t
}

# 读取M3U8文本，获取TS文件路径
function get_sub_file()
{
    local file=$1
    local dir=${file%/*}"/"
    echo "access m3u8 file $file ... "
    local txt=`cat $file | grep ".m3u8"`

    for line in $txt
    do
        line=`echo $line | tr -d "\r" | tr -d "\n"`
        if [ -z $line ]
        then
            continue
        fi

        local cur_arr=${line##*\?}
        local cur_len=${cur_arr##*\&}
        local cur_len_value=${cur_len##*\=}

        local len
        if [[ -z $len || $len -gt $cur_len_value ]]
        then
            len=`echo $cur_len_value`
        fi

        echo "len: "$len

        local dir_file=$dir${line%%\?*}

        joint_sub $dir_file $len
    done
}

function path_format()
{
    local path=$1
    if [ ! -d "$path" ]
    then
        echo "Please input valid path!"
        exit 1
    fi

    if [ ${path:0-1:1} = $FLAG ]
    then
        path_in=$path
    else
        path_in=$path"/"
    fi
}

# 遍历路径函数
function search_file()
{
    path_format $1
    local path=$?
    echo "access $path_in ... "
    for file in `find $path_in -name $_M3U8`
    do
        if [ "${file##*/}" = $INDEX_M3U8 ]
        then
            get_sub_file $file
        #elif [ "${file##*/}" = $STREAM_M3U8 ]
        #then
        #    joint_sub $file
        fi
    done
}

search_file $path_param
