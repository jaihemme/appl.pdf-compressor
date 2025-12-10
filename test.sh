# ce test.sh ne fonctionne pas sur macOs (compatibilité de la commande stat)
# il doit tourner dans le conteneur: docker run --rm -t -v ./test:/data -e API_ILOVEPDF_TOKEN=$(cat api_ilovepdf_token.txt) --entrypoint /bin/bash  -i pdf-compressor:latest -c "./test.sh"
date
rm -vrf test
mkdir -v test
FILE="file-$(date +%Y%m%d-%H%M%S).pdf"
LOG=test/compress.log
cp -v test_file.pdf test/$FILE
test $API_ILOVEPDF_TOKEN || export API_ILOVEPDF_TOKEN=$(cat api_ilovepdf_token.txt) 
unset OUTPUT_DIR
./compress.sh test/$FILE 2>&1 | tee -a ${LOG}
ls -l test/
