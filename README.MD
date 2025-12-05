#  Compression de fichier PDF

## Description

Cette image comprime un fichier pdf sur la base de l'[api ilovepdf](https://www.iloveapi.com/docs/api-reference). Le dossier contenant la fichier à compresser est donné comme volume. Le nom du fichier à compresser est donné en argument. Il doit avoir l'extension .pdf. Le fichier compressé est enregistrée dans le même dossier avec le suffixe .min.pdf. Si un fichier avec un tel nom existe déjà, la compression ne se fait pas.

La version gratuite de l'API permet 250 appels par mois.

## Usage

```
docker run --rm -t -v <dossier contenant le fichier à compresser>:/data -e API_ILOVEPDF_TOKEN=$(cat <chemin du token>) pdf-compressor <nom_de_fichier.pdf>
```


## Usage pratique dans un Automator workflow défini comme action de dossier

```
cd /Users/yogi/Docker/appl.pdf-compressor
export PATH=.:/Users/yogi/.docker/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
docker run --rm -t -v "${1%/*}":/data -e API_ILOVEPDF_TOKEN=$(cat api_ilovepdf_token.txt) pdf-compressor "${1##*/}"  >> compress.log 2>&1
```

... suivi d'une action "Affiche une notification" qui indique la fin du processus.

## Log
Le processus est journalisé dans le fichier 'compress.log'
