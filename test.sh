# ce test.sh ne fonctionne pas sur macOs (compatibilité de la commande stat)
# il doit tourner dans le conteneur: 
# docker run --rm -t -e API_ILOVEPDF_TOKEN=$(cat api_ilovepdf_token.txt) --entrypoint /bin/bash  -i jaihemme/appl.pdf-compressor:latest -c "./test.sh"
date
export DATA=./test
rm -vrf $DATA
mkdir -v $DATA
FILE="file-$(date +%Y%m%d-%H%M%S).pdf"
LOG=$DATA/compress.log
cp -v test_file.pdf $DATA/$FILE
test $API_ILOVEPDF_TOKEN || export API_ILOVEPDF_TOKEN=$(cat api_ilovepdf_token.txt) 
./compress.sh $FILE 2>&1 | tee -a ${LOG}
ls -l $DATA/
