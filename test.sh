date
rm -vf test
mkdir test
cp -v file1.pdf test/file-$(date +%Y%m%d-%H%M%S).pdf
sleep 3
exec less +F compress.log
