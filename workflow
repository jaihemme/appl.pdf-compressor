# shell /bin/sh avec donées d'entrée en argument

export PATH=.:/Users/yogi/.docker/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

cd /Users/yogi/Docker/appl.pdf-compressor
[[ "${#}" -eq 0 ]] && { printf "Le script ne fonctionne qu'en action de dossier. Exit."; exit 0; }
[[ "${1}" =~ .min.pdf$ ]] && { printf "Fichier compressé ne doit pas être traité. Exit." |& tee -a compress.log; exit; }

docker run --rm -t -v "${1%/*}":/data -e API_ILOVEPDF_TOKEN=$(cat api_ilovepdf_token.txt) jaihemme/pdf-compressor:latest "${1##*/}" |& tee -a compress.log

test $? -ne 0 && printf "le process docker termine avec erreur: rc=$?" |& tee -a compress.log

###
