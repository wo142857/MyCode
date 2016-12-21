#!/bin/bash
# ffmpeg filter setpts atempo script

########## 参数处理 ##########

while getopts :p:i:o:v:a: param ; do
  case $param in
    p)
      path=$OPTARG
      ;;
    i)
      infile=$OPTARG
      ;;
    o)
      outfile=$OPTARG
      ;;
    v)
      setpts=$OPTARG
      ;;
    a)
      atempo=$OPTARG
      ;;
  esac
done
##############################

if test -d $path
then
  cd $path
else
  echo '目录地址不存在！'
fi

ffmpeg='/data/ffmpeg/bin/ffmpeg'

filter='[0:v]'
if test ${#setpts} -gt 0
then
  filter=$filter'setpts='$setpts'[v]'
else
  filter=$filter'[0:v]setpts=1*PTS[v]'
fi

if test ${#atempo} -gt 0
then
  filter=$filter';[0:a]atempo='$atempo'[a]'
else
  filter=$filter';[0:a]atempo=1.0[a]'
fi

cmd_line=$ffmpeg
if test -r $infile
then
  cmd_line=($cmd_line -i $infile -filter_complex $filter)
else
  echo '输入视频有误！'
fi

cmd_line=(${cmd_line[@]} -map '[v]' -map '[a]' $outfile)

echo ${cmd_line[@]}
${cmd_line[@]}
exit
