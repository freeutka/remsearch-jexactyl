#!/bin/bash

if (( $EUID != 0 )); then
    printf "\033[0;33m<remsearch-jexactyl> \033[0;31m[✕]\033[0m Please run this program as root \n"
    exit
fi

watermark="\033[0;33m<remsearch-jexactyl> \033[0;32m[✓]\033[0m"
target_dir=""

chooseDirectory() {
    echo -e "<remsearch-jexactyl> [1] /var/www/jexactyl   (choose this if you installed the panel using the official Jexactyl documentation)"
    echo -e "<remsearch-jexactyl> [2] /var/www/pterodactyl (choose this if you migrated from Pterodactyl to Jexactyl)"

    while true; do
        read -p "<remsearch-jexactyl> [?] Choose jexactyl directory [1/2]: " choice
        case "$choice" in
            1)
                target_dir="/var/www/jexactyl"
                break
                ;;
            2)
                target_dir="/var/www/pterodactyl"
                break
                ;;
            *)
                echo -e "\033[0;33m<remsearch-jexactyl> \033[0;31m[✕]\033[0m Invalid choice. Please enter 1 or 2."
                ;;
        esac
    done
}

startPterodactyl(){
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | sudo -E bash -
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    nvm install node || {
        printf "${watermark} nvm command not found, trying to source nvm script directly... \n"
        . ~/.nvm/nvm.sh
        nvm install node
    }
    apt update

    npm i -g yarn
    yarn
    export NODE_OPTIONS=--openssl-legacy-provider
    yarn build:production || {
        printf "${watermark} node: --openssl-legacy-provider is not allowed in NODE_OPTIONS \n"
        export NODE_OPTIONS=
        yarn build:production
    }
    sudo php artisan optimize:clear
}

deleteModule(){
    chooseDirectory
    printf "${watermark} Deleting module... \n"
    cd "$target_dir"
    rm -rvf remsearch-jexactyl
    printf "${watermark} Previous module successfully removed \n"
    git clone https://github.com/freeutka/remsearch-jexactyl.git
    printf "${watermark} Cloning git repository \n"
    rm -f resources/scripts/components/elements/SidePanel.tsx
    rm -f resources/scripts/components/dashboard/search
    printf "${watermark} Module files successfully removed \n"
    cd remsearch-jexactyl
    mv original-resources/SidePanel.tsx "$target_dir/resources/scripts/components/elements/"
    mv original-resources/search "$target_dir/resources/scripts/components/dashboard/search/"
    printf "${watermark} Original files successfully restored \n"
    rm -rvf "$target_dir/remsearch-jexactyl"
    cd "$target_dir"
    printf "${watermark} Git repository deleted \n"

    printf "${watermark} Module successfully deleted from your jexactyl repository. Thanks for using this module in your projects. Have a nice day \n"

    while true; do
        read -p '<remsearch-jexactyl> [?] Do you want rebuild panel assets [y/N]? ' yn
        case $yn in
            [Yy]* ) startPterodactyl; break;;
            [Nn]* ) exit;;
            * ) exit;;
        esac
    done
}

while true; do
    read -p '<remsearch-jexactyl> [?] Are you sure that you want to delete "remsearch-jexactyls" module [y/N]? ' yn
    case $yn in
        [Yy]* ) deleteModule; break;;
        [Nn]* ) printf "${watermark} Canceled \n"; exit;;
        * ) exit;;
    esac
done
