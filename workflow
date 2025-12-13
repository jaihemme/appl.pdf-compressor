# ce script est le contenu de "Exécuter un shell script" avec /bin/sh et les données en entrée comme argument dans un workflow "action de dossier"
# le workflow complet est enregistrée dans /Users/yogi/Library/Workflows/Applications/Folder\ Actions/Compress\ PDF.workflow
# le script peut être testé avec test_wf.sh

printf "\nStart folder action with arg '%s'" "${1}" | tee -a compress.log

export PATH=.:/Users/yogi/.docker/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

IMAGE="jaihemme/appl.pdf-compressor:latest"
cd /Users/yogi/Docker/appl.pdf-compressor
[[ "${#}" -eq 0 ]] && { printf "Le script ne fonctionne qu'en action de dossier. Exit.\n"; exit 0; }a | tee -a compress.log; exit; }
[[ "${1}" =~ .min.pdf$ ]] && { printf "Fichier compressé '%s' ne doit pas être traité. Exit.\n" "${1##*/}" | tee -a compress.log; exit; }

docker run --rm -t -v "${1%/*}":/data -e API_ILOVEPDF_TOKEN=$(cat api_ilovepdf_token.txt) $IMAGE "${1##*/}" | tee -a compress.log
# avec scripts mappés: docker run --rm -t -v .:/app -v "${1%/*}":/data -e API_ILOVEPDF_TOKEN=$(cat api_ilovepdf_token.txt) $IMAGE -x "${1##*/}" | tee -a compress.log
# tests: docker run --rm -t -v .:/app -v "${1%/*}":/data -e API_ILOVEPDF_TOKEN=$(cat api_ilovepdf_token.txt) --entrypoint bash -it $IMAGE

test $? -ne 0 && printf "le process docker termine avec erreur: rc=$?\n" | tee -a compress.log

###
