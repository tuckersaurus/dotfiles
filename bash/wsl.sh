if grep -qi microsoft /proc/version 2>/dev/null; then
    export BROWSER="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"

    if ! service docker status > /dev/null 2>&1; then
        sudo service docker start
    fi
fi
