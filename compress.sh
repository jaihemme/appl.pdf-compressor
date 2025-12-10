#!/usr/bin/env bash
# Comprime un fichier pdf via l'API du site ilovepdf
# https://developer.ilovepdf.com/docs/api-reference
set -Eeuo pipefail

# Output directory: use OUTPUT_DIR env var if set, otherwise use input file's directory
# For Docker: set OUTPUT_DIR=/data (mounted volume)
# For Replit: leave unset (uses same directory as input file)
OUTPUT_DIR="${OUTPUT_DIR:-}"

echo ""
date +"%A %d %B %YY %Z %z"
echo "Run folder actions, $0, args: $*"

[[ "$#" -ne 0 ]] && test "$1" = '-x' && { set -xv; shift; echo "=== trace ==="; }
[[ "$#" -ne 1 ]] && { echo "Usage: $0 <nom_fichier.pdf>"; exit 1; }
PdfFile="${1}"  # le nom du fichier
test -r "$PdfFile" || { printf "Erreur: le fichier %s n'a pas été trouvé. Exit 1.\n" "$PdfFile"; exit 1; }
test -f "$PdfFile" || { printf "Erreur: %s n'est pas un fichier. Exit 1\n." "$PdfFile"; exit 1; }
[[ "${PdfFile##*/}" =~ .pdf$ ]] || { printf "Erreur: le nom du fichier %s n'a pas l'extension '.pdf'.Exit 1.\n" "$PdfFile"; exit 1; }
[[ "${PdfFile##*/}" =~ .min.pdf$ ]] && { printf "L'extension '.min.pdf' est utilisée pour les fichiers compressés qui ne seront pas traités une deuxième fois. Exit 1.\n"; exit 1; }
[[ $(file -b "$PdfFile") == PDF* ]] || { printf "Erreur: le fichier %s n'a pas le format PDF. Exit 1.\n" "$PdfFile"; exit 1; }

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

printf "Uploading file %s ... " "$PdfFile"
$CURL -s -F "file=@\"$PdfFile\"" -F "task=$Task" -H "$Authorization" -H "$Accept" -o "$out2" "$msg" https://$Server/v1/upload 
test -r "$out2" || { printf "Erreur: le fichier %s n'a pas été créé. Exit 1.\n" "$out2"; exit 1; }

ServerFileName="$($JQ -er '.server_filename' $out2)" || { printf "Erreur: le champ 'server_filename' n'a pas été trouvé. Exit 1.\n"; tail "$out2"; exit 1; }
echo "Server file name: $ServerFileName"

FileName=${PdfFile##*/}
DirName=${PdfFile%/*}
# If DirName equals FileName, file is in current directory
[[ "$DirName" == "$PdfFile" ]] && DirName="."

printf "Compressing %s ...\n" "$FileName"
# compression_level peut être modifié (extreme ou low)
$CURL -s -d "task=$Task" -d "tool=compress" -d "files[0][server_filename]=$ServerFileName" -d "files[0][filename]=$FileName" -H "$Authorization" -H "$Accept" -o "$out3" "$msg" https://$Server/v1/process
test -r "$out3" || { printf "Erreur: le fichier %s n'a pas été créé. Exit 1.\n" "$out3"; exit 1; }

Status="$($JQ -er '.status' $out3)" || { printf "Erreur: le champ 'status' n'a pas été trouvé. Exit 1.\n"; tail "$out3"; exit 1; }
echo "Status: $Status"
test "$Status" = "TaskSuccess" || { printf "Erreur: status inattendu (≠'TaskSuccess'). Exit 1.\n"; tail "$out3"; exit 1; }

# Determine output path: use OUTPUT_DIR if set, otherwise use input file's directory
BaseFileName="${PdfFile##*/}"
OutputFileName="${BaseFileName/.pdf/.min.pdf}"
if [[ -n "$OUTPUT_DIR" ]]; then
    OutputPath="${OUTPUT_DIR}/${OutputFileName}"
else
    OutputPath="${DirName}/${OutputFileName}"
fi
printf "Downloading %s ...\n" "$OutputPath"
$CURL -s -H "$Authorization" -H "$Accept" -o "${OutputPath}" "$msg" https://$Server/v1/download/$Task -X GET
test -r "$OutputPath" || { printf "Erreur: le fichier %s n'a pas été créé. Exit 1.\n" "$OutputPath"; exit 1; }
ls -l "$PdfFile" "$OutputPath"
taux="$(( $(stat -c%s "$OutputPath") * 100 / $(stat -c%s "$PdfFile"))) %"

MESSAGE="${OutputFileName} compressé avec un taux de $taux"
printf '%s\n' "$MESSAGE"
# -appIcon ne fonctionne pas, -sender incompatible avec -execute ou -open
# $NOTIFY -message "${MESSAGE// / }" -title "RunFolderAction" -group "RunFolderAction" -subtitle "$(realpath $PWD/$0)" -execute "open -a Preview ${FileName// /\ }" && echo "Notify done" || printf "terminal-notifyer exit $?"

###
