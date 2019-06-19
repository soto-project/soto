#!/bin/sh

set -e

result=0

color() {
  color="$1"
  shift
  case "$color" in
    red)     color=91 ;;
    green)   color=92 ;;
    yellow)  color=93 ;;
    blue)    color=94 ;;
    magenta) color=95 ;;
    cyan)    color=96 ;;
  esac
  printf '[%dm%s[0m\n' $color "$@"
}

check_file() {
  filename=$1
  color yellow "## Checking \"$filename\"..."
  if shellcheck "$filename" 2>&1; then
    color green "Status: ✅"
  else
    color red "Status: ❌"
    result=$(( result + 1 ))
  fi
  echo
}

# Only run shellcheck on files if their shebang line starts with /bin/sh or /bin/bash
#for filename in $(git diff origin/master --name-status | awk '{print $2}' | sort | uniq); do
for filename in $( find ./scripts ); do
    if head -n1 "$filename" | grep -Eqx "#!/bin/(ba)?sh"; then
        check_file "$filename"
    fi
done

color cyan "------"
if [ $result -eq 0 ]; then
  color green "Overall status: ✅"
else
  color red "Overall status: ❌"
fi

exit $result
