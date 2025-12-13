INPUT='/Users/yogi/Library/Mobile Documents/iCloud~com~ttdeveloped~moneystatistics/Documents/pj/ticket-682f165fed7fbc046f07d8bb.pdf'
test ${#} -gt 0 && INPUT="${1}"
echo Arg: "${INPUT}"
bash ./workflow "${INPUT}"
