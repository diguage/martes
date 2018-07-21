#!/bin/bash
#
# 构建脚本

base_dir=`pwd`
style_dir=styles
index_file=index.adoc

# 确保 asciidoctor 命令被安装
asciidoctor=`which asciidoctor`
if [ ! -n `which asciidoctor` ]; then
  gem install asciidoctor
  asciidoctor=`which asciidoctor`
fi

# 解决 Mac 与 Linux 中 sed 处理不统一的问题
gsed=`which sed`
if [[ `uname` == Darwin* ]]
then
  gsed=`which gsed`
fi

# 确保 cssnano 命令被安装
cssnano=`which cssnano`
if [ ! -n `which cssnano` ]; then
  npm install cssnano-cli --g --registry=https://registry.npm.taobao.org
  cssnano=`which cssnano`
fi

# 确保 html-minifier 命令被安装
htmlminifier=`which html-minifier`
if [ ! -n `which html-minifier` ]; then
  npm install html-minifier -g --registry=https://registry.npm.taobao.org
  htmlminifier=`which html-minifier`
fi

rm -rf *.html $style_dir $index_file 1>/dev/null 2>&1 &

function a2h() {
  afile="$1"
  if [ ! -z "$afile" -a "$afile" != " " ]; then
    extension="${afile##*.}"
    if [ $extension = 'adoc' ]; then
      echo "Start to build $afile ..."
      # https://stackoverflow.com/a/46250107/951836
      filename="${afile%.*}"
      hfile="${filename}_temp.html"
      wfile="$filename.html"
      # echo $hfile, $wfile

      $asciidoctor  -r asciidoctor-diagram \
                    -d article \
                    -a stylesdir=$style_dir \
                    -a linkcss \
                    -a  source-highlighter=coderay \
                    -a nofooter \
                    -a toc  \
                    -a author=D瓜哥 \
                    -a email=https://www.diguage.com/ \
                    -a revdate=`date "+%Y-%m-%d"` \
                    -a stem=latexmath \
                    -a allow-uri-read \
                    -a source_base_path=https://raw.githubusercontent.com/diguage/leetcode/master/src/main/java/com/diguage/algorithm/leetcode \
                    -a source_attrs=linenums \
                    $afile -o $hfile

      # 调整样式
      $gsed -i "s/<\/head>/<style>a{text-decoration:none;}.img_bk{text-align:center;}<\/style><\/head>/" $hfile
      # 替换 Font Awesome，(内置功能不能保证版本一致)
      $gsed -i "s/https:\/\/cdnjs.cloudflare.com\/ajax\/libs/\/\/cdn.bootcss.com/" $hfile
      # 替换 Google Fonts
      $gsed -i "s/https:\/\/fonts.googleapis.com/\/\/fonts.proxy.ustclug.org/" $hfile
      
      #压缩
      $htmlminifier -c html-minifier.config.json $hfile -o $wfile
      rm -rf $hfile
    fi
  fi
}
export -f a2h

# 生成List
# touch $index_file
# echo "= MARTES" >> $index_file
# echo "D瓜哥 <https://www.diguage.com/>" >> $index_file
# echo "{docdate}" >> $index_file
# echo "" >> $index_file

touch $index_file

# cat >> $index_file <<EOF
# = MARTES
# 
# EOF

cat >> $index_file <<EOF
= MARTES

EOF


for a in `ls *.adoc`
do
  filename="${a%.*}"
  echo ". link:./${filename}.html[$filename]" >> $index_file
done

for a in `ls *.adoc`
do
  a2h $a
done

# 压缩 CSS
cd ./$style_dir
for f in `ls .`
do
  $cssnano $f $f
done
cd $base_dir


echo "`date '+%Y-%m-%d %H:%M:%S'` build"

if [ -n "$1" ]; then
    rsync -avz --exclude=".*" ./*.html $style_dir deployer@notes.diguage.com:/home/deployer/diguage.com/notes/martes
    echo ""
    echo "`date '+%Y-%m-%d %H:%M:%S'` deploy"
    echo ""
    echo "  https://notes.diguage.com/martes/  "
    echo ""
    echo ""
    rm -rf *.html $style_dir 1>/dev/null 2>&1 &
fi