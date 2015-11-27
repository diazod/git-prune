
gprune() {
    if [[ "$1" == "-l" ]]; then
        git branch --merged | grep -v "$1" | grep -v "master" | xargs git branch -d &&
        git branch;
    elif [[  "$1" == "-r" ]]; then
        git fetch --prune &&
        git branch -r --merged | grep -v "$1" | grep -v "master" | grep -v "HEAD" | sed -e 's/origin\//:/' | xargs git push origin &&
        git branch -a;
    else
        git fetch --prune &&
        git branch -r --merged | grep -v "$1" | grep -v "master" | grep -v "HEAD" | sed -e 's/origin\//:/' | xargs git push origin &&
        git branch --merged | grep -v "$1" | grep -v "master" | xargs git branch -d &&
        git branch -a;
    fi
}