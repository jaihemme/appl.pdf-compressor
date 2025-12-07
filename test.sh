date
rm -vrf test
mkdir test
FILE="file-$(date +%Y%m%d-%H%M%S).pdf"
cp -v file1.pdf test/$FILE
./compress.sh test/$FILE 2>&1 | tee -a compress.log
touch compress.log
exec less +F compress.log