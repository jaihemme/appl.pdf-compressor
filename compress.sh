#!/usr/bin/env bash
# Comprime un fichier pdf via l'API du site ilovepdf
# https://developer.ilovepdf.com/docs/api-reference
set -Eeuo pipefail

echo ""
date +"%A %d %B %Y %Z %z"
echo "Run folder actions, $0, args($#): $*"
echo "env \$DATA: ${DATA}"

# vérifie l'option -x pour le debug
[[ "$#" -ne 0 ]] && test "$1" = '-x' && { set -xv; shift; echo "=== trace ==="; }
# vérifie la présence d'un argument
[[ "$#" -ne 1 ]] && { echo "Usage: $0 <nom_fichier.pdf>"; exit 1; }
# le chemin complet de fichier dans docker 
PdfFile="${DATA}/${1}"
FileName="${1}"
DirName="${DATA}"
# vérifie l'existence du fichier/dossier
test -r "${PdfFile}" || { printf "Erreur: le fichier %s n'a pas été trouvé. Exit 1.\n" "${PdfFile}"; exit 1; }
# vérifie l'existence du fichier
test -f "${PdfFile}" || { printf "Erreur: %s n'est pas un fichier. Exit 1\n." "${PdfFile}"; exit 1; }
# le nom du fichier doit se terminer par .pdf
[[ "${FileName}" =~ .pdf$ ]] || { printf "Erreur: le nom du fichier %s n'a pas l'extension '.pdf'.Exit 1.\n" "${PdfFile}"; exit 1; }
# le nom du fichier ne doit pas se terminer par .min.pdf qui est déjà compressé
[[ "${FileName}" =~ .min.pdf$ ]] && { printf "L'extension '.min.pdf' est utilisée pour les fichiers compressés qui ne seront pas traités une deuxième fois. Exit 1.\n"; exit 1; }
# vérifie le format pdf 
[[ $(file -b "${PdfFile}") == PDF* ]] || { printf "Erreur: le fichier %s n'a pas le format PDF. Exit 1.\n" "${PdfFile}"; exit 1; }

CURL="curl"
JQ="jq"
Accept="Accept: application/json"
Server="api.ilovepdf.com"
out1="compress.out_compress.json"
out2="compress.out_upload.json"
out3="compress.out_process.json"
msg="-w%{http_code} %{method} %{url_effective} %{content_type} %{size_download} %{time_connect}\n"

rm -f compress.out_*.json

printf "Create JWT token ... "
Token="$(source ./create_jwt_token.sh; create_jwt_token)"
Authorization="Authorization: Bearer $Token"
echo "OK"
echo "$Authorization"

# $CURL -s -A "$UserAgent" -d "$Data" -H "$Authorization" -H "$Accept" -o "$out1" $Url/v1/start/compress -X GET
printf "Starting compress task ...\n"
$CURL -s -H "$Authorization" -H "$Accept" -o "$out1" "$msg" https://$Server/v1/start/compress -X GET
test -r "$out1" || { printf "Erreur: le fichier %s n'a pas été créé. Exit 1.\n" "$out1"; exit 1; }

Server="$($JQ -er '.server' $out1)" || { printf "Erreur: le champ 'server' n'a pas été trouvé. Exit 1.\n"; tail "$out1"; exit 1; }
echo "Server: $Server"

Task="$($JQ -er '.task' $out1)" || { printf "Erreur: le champ 'task' n'a pas été trouvé. Exit 1.\n"; tail "$out1"; exit 1; }
echo "Task: $Task"

printf "Uploading file %s ... " "${PdfFile}"
$CURL -s -F "file=@\"${PdfFile}\"" -F "task=$Task" -H "$Authorization" -H "$Accept" -o "$out2" "$msg" https://$Server/v1/upload 
test -r "$out2" || { printf "Erreur: le fichier %s n'a pas été créé. Exit 1.\n" "$out2"; exit 1; }

ServerFileName="$($JQ -er '.server_filename' $out2)" || { printf "Erreur: le champ 'server_filename' n'a pas été trouvé. Exit 1.\n"; tail "$out2"; exit 1; }
echo "Server file name: $ServerFileName"

printf "Compressing %s ...\n" "$FileName"
# compression_level peut être modifié (extreme ou low)
$CURL -s -d "task=$Task" -d "tool=compress" -d "files[0][server_filename]=$ServerFileName" -d "files[0][filename]=$FileName" -H "$Authorization" -H "$Accept" -o "$out3" "$msg" https://$Server/v1/process
test -r "$out3" || { printf "Erreur: le fichier %s n'a pas été créé. Exit 1.\n" "$out3"; exit 1; }

Status="$($JQ -er '.status' $out3)" || { printf "Erreur: le champ 'status' n'a pas été trouvé. Exit 1.\n"; tail "$out3"; exit 1; }
echo "Status: $Status"
test "$Status" = "TaskSuccess" || { printf "Erreur: status inattendu (≠'TaskSuccess'). Exit 1.\n"; tail "$out3"; exit 1; }

OutputFile="${PdfFile/.pdf/.min.pdf}"
printf "Downloading %s ...\n" "${OutputFile}"
$CURL -s -H "$Authorization" -H "$Accept" -o "${OutputFile}" "$msg" https://$Server/v1/download/$Task -X GET
test -r "${OutputFile}" || { printf "Erreur: le fichier %s n'a pas été créé. Exit 1.\n" "${OutputFile}"; exit 1; }
ls -l "${PdfFile}" "${OutputFile}"
taux="$(( $(stat -c%s "${OutputFile}") * 100 / $(stat -c%s "${PdfFile}"))) %"

MESSAGE="${OutputFile##*/} compressé avec un taux de $taux"
printf '%s\n' "$MESSAGE"

###
