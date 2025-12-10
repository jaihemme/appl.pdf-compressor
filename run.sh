# lancer le run avec un npm de fichier à compresser se trouvant dans le dossier 'test'
docker ps -a

# Lancer un conteneur temporaire
IMAGE=jaihemme/pdf-compressor:latest
IMAGE=pdf-compressor:latest

docker run --rm -t -v "${1%/*}":/data -e API_ILOVEPDF_TOKEN=$(cat api_ilovepdf_token.txt) ${IMAGE} "${1##*/}"

# ... avec nouvel entrypoint et user root et un commande bash
# docker run --rm -t -v ./test:/data -e API_ILOVEPDF_TOKEN=$(cat api_ilovepdf_token.txt) --entrypoint bash -u0 -i pdf-compressor:latest -c "ls -l /data"
