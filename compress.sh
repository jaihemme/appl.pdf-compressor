#!/usr/bin/env bash
# Comprime un fichier pdf via l'API du site ilovepdf
# https://developer.ilovepdf.com/docs/api-reference
set -Eeuo pipefail

printf
date
printf "Run folder actions, $0, args: $*"

[[ "$#" -ne 0 ]] && test "$1" = '-x' && { set -xv; shift; printf "=== trace ==="; }
[[ "$#" -ne 1 ]] && { printf "Usage: $0 <nom_fichier.pdf>"; exit 1; }
PdfFile="/data/${1##*/}"  # le nom du fichier
test -r "$PdfFile" || { printf "Erreur: le fichier $PdfFile n'a pas été trouvé. Exit 1."; exit 1; }
test -f "$PdfFile" || { printf "Erreur: $PdfFile n'est pas un fichier. Exit 1."; exit 1; }
[[ "${PdfFile##*/}" =~ .pdf$ ]] || { printf "Erreur: le nom du fichier $PdfFile n'a pas l'extension '.pdf'.Exit 1."; exit 1; }
[[ "${PdfFile##*/}" =~ .min.pdf$ ]] || { printf "L'extension '.min.pdf' est utilisée pour les fichiers compressés qui ne seront pas traités une deuxième fois. Exit 1."; exit 1; }
[[ $(file -b "$PdfFile") == PDF* ]] || { printf "Erreur: le fichier $PdfFile n'a pas le format PDF. Exit 1."; exit 1; }
ls -l  ${PdfFile/.pdf/.min.pdf} 2>/dev/null && { printf "Ce fichier a déjà été compressé. Exit 0."; exit 0; }

CURL="/usr/bin/curl"
JQ="/usr/bin/jq"
Accept="Accept: application/json"
Server="api.ilovepdf.com"
out1="compress.out_compress.json"
out2="compress.out_upload.json"
out3="compress.out_process.json"
msg="-w%{http_code} %{method} %{url_effective} %{content_type} %{size_download} %{time_connect}\n"

rm -f compress.out_*.json

printf -n "Create JWT token ... "
Token="$(source ./create_jwt_token.sh; create_jwt_token)"
Authorization="Authorization: Bearer $Token"
printf OK
printf $Authorization

# $CURL -s -A "$UserAgent" -d "$Data" -H "$Authorization" -H "$Accept" -o "$out1" $Url/v1/start/compress -X GET
printf -n "Starting compress task ... "
$CURL -s -H "$Authorization" -H "$Accept" -o "$out1" "$msg" https://$Server/v1/start/compress -X GET
test -r "$out1" || { printf "Erreur: le fichier $out1 n'a pas été créé. Exit 1."; exit 1; }

Server="$($JQ -er '.server' $out1)" || { printf "Erreur: le champ 'server' n'a pas été trouvé. Exit 1."; tail "$out1"; exit 1; }
printf "Server: $Server"

Task="$($JQ -er '.task' $out1)" || { printf "Erreur: le champ 'task' n'a pas été trouvé. Exit 1."; tail "$out1"; exit 1; }
printf "Task: $Task"

printf -n "Uploading file $PdfFile ... "
$CURL -s -F "file=@\"$PdfFile\"" -F "task=$Task" -H "$Authorization" -H "$Accept" -o "$out2" "$msg" https://$Server/v1/upload 
test -r "$out2" || { printf "Erreur: le fichier $out2 n'a pas été créé. Exit 1."; exit 1; }

ServerFileName="$($JQ -er '.server_filename' $out2)" || { printf "Erreur: le champ 'server_filename' n'a pas été trouvé. Exit 1."; tail "$out2"; exit 1; }
printf "Server file name: $ServerFileName"

FileName=${PdfFile##*/}
DirName=${PdfFile%/*}

printf -n "Compressing $FileName ... "
# compression_level peut être modifié (extreme ou low)
$CURL -s -d "task=$Task" -d "tool=compress" -d "files[0][server_filename]=$ServerFileName" -d "files[0][filename]=$FileName" -H "$Authorization" -H "$Accept" -o "$out3" "$msg" https://$Server/v1/process
test -r "$out3" || { printf "Erreur: le fichier $out3 n'a pas été créé. Exit 1."; exit 1; }

Status="$($JQ -er '.status' $out3)" || { printf "Erreur: le champ 'status' n'a pas été trouvé. Exit 1."; tail "$out3"; exit 1; }
printf "Status: $Status"
test "$Status" = "TaskSuccess" || { printf "Erreur: status inattendu (≠'TaskSuccess'). Exit 1."; tail "$out3"; exit 1; }

FileName=${PdfFile/.pdf/.min.pdf}
printf -n "Downloading $FileName ... "
$CURL -s -H "$Authorization" -H "$Accept" -o "${FileName}" "$msg" https://$Server/v1/download/$Task -X GET
test -r "$FileName" || { printf "Erreur: le fichier $FileName n'a pas été créé. Exit 1."; exit 1; }
ls -l "$PdfFile" "$FileName"
taux="$(( $(stat -c%s "$FileName") * 100 / $(stat -c%s "$PdfFile"))) %"

MESSAGE="${FileName##*/} compressé avec un taux de $taux" # nbsp with option+space to keep all words of message together
printf $MESSAGE
# -appIcon ne fonctionne pas, -sender incompatible avec -execute ou -open
# $NOTIFY -message "${MESSAGE// / }" -title "RunFolderAction" -group "RunFolderAction" -subtitle "$(realpath $PWD/$0)" -execute "open -a Preview ${FileName// /\ }" && echo "Notify done" || printf "terminal-notifyer exit $?"

###
