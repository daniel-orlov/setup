#!/bin/bash

# standard bash error handling
set -o errexit;
set -o pipefail;
set -o nounset;
# debug commands
# set -x;

function main() {
#	Prepare for installation
	sudo apt update
	install_basics

#	Begin work environment setup
#	Install Golang and Ops tools
	install_latest_golang
	install_go_tools
	install_docker
	install_kubectl
	install_kind
	install_helm
	install_k9s
	install_lens
	install_krew

#	Install IDE
	install_goland
	install_pycharm

#	Install db clients
	install_clickhouse_client
	install_psql
	install_redis_cli

#	Install API tools
	install_postman
	install_bloomrpc

# Install VPN tools
	install_wireguard

#	Install distraction machine
	install_slack
}

function install_curl() {
	echo '----------Installing curl----------'
	sudo apt install curl
}

function install_snap() {
	echo '----------Installing snap----------'
	sudo apt install snapd
}

function install_git() {
	echo '----------Installing git----------'
	sudo apt install git

	{
    	echo ""
    	echo "# Git"
    	echo "export GIT_SSH_COMMAND="ssh -i ~/.ssh/""
  } >> "$HOME/.bashrc"
	source "$HOME"/.bashrc
}


function install_make() {
	echo '----------Installing make----------'
	sudo apt install make
}

function install_pip() {
	echo '----------Installing pip----------'
	sudo apt install python3-pip
}

function install_cc() {
	echo '----------Installing cc----------'
	sudo apt install clang
	sudo apt install gcc
}

function install_vim() {
	echo '----------Installing vim----------'
	sudo apt install vim
}

function install_basics() {
	install_curl
	install_snap
	install_git
	install_make
	install_cc
	install_vim
	install_pip
}

function install_wireguard() {
	echo '----------Installing wireguard----------'
	sudo apt install wireguard-tools
  sudo apt install resolvconf

  {
  		echo ""
  		echo "# Wireguard"
  		echo "alias vpnon='wg-quick up do'"
  		echo "alias vpnoff='wg-quick down do'"
  		echo "alias vpnawson='wg-quick up aws'"
      echo "alias vpnawsoff='wg-quick down aws'"
  } >> "$HOME/.bashrc"
}


# Installing latest golang version
function install_latest_golang() {
	echo '----------Installing latest Golang----------'
	GOROOT="$HOME/.go" 
	GOPATH="$HOME/go"
	
	if [ -d "$GOROOT" ]; then
		echo "The Go install directory ($GOROOT) already exists. Exiting."
		exit 1
	fi
	
 	VERSION="$(curl -s https://golang.org/VERSION?m=text)" &&
	OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
	ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
	PLATFORM="$OS-$ARCH" &&
	PACKAGE_NAME="$VERSION.$PLATFORM.tar.gz" &&
	echo "Downloading $PACKAGE_NAME ..."
	
	if hash wget 2>/dev/null; then
		wget --quiet https://storage.googleapis.com/golang/"$PACKAGE_NAME" -O /tmp/go.tar.gz
		else
		curl -o /tmp/go.tar.gz https://storage.googleapis.com/golang/"$PACKAGE_NAME"
		fi
	if [ $? -ne 0 ]; then
		echo "Download failed! Exiting."
		exit 1
	fi

	echo "Extracting File..."
	mkdir -p "$GOROOT"
	tar -C "$GOROOT" --strip-components=1 -xzf /tmp/go.tar.gz
	touch "$HOME/.bashrc"
 	{
		echo ""	
		echo "# GoLang"
		echo "export GOROOT=${GOROOT}"
		echo "export GOPATH=${GOPATH}"
		echo "export PATH=$GOPATH/bin:$GOROOT/bin:$PATH"
	} >> "$HOME/.bashrc"
	source "$HOME"/.bashrc

	echo -e "\nGo $VERSION was installed into $GOROOT."

	rm -f /tmp/go.tar.gz
	unset PACKAGE_NAME
	unset VERSION
	unset PLATFORM
}

function install_go_tools() {
	echo '----------Installing Go tools----------'
	# Integration with Goland :
  # File > Settings > Tools > File watchers > Add > choose 'golangci-lint'
	curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b "$(go env GOPATH)"/bin v1.42.0
	#	Adding linters
	golangci-lint linters --enable prealloc,predeclared,revive,wastedassign,wsl
	# Installing tools
	go get golang.org/x/tools/cmd/goimports
	go get -u github.com/sqs/goreturns
	go install github.com/golang/mock/mockgen@v1.6.0
}

function install_docker() {
	echo "-----------Installing Docker w/o sudo----------"
	curl -fsSL https://get.docker.com -o get-docker.sh &&
	chmod 700 get-docker.sh &&
	./get-docker.sh

	# Make docker run w/o sudo
	sudo gpasswd -a "$USER" docker &&
	sudo service docker restart
}

function install_kind() {
	echo '----------Installing kind-----------'

	KIND='/usr/local/bin/kind' &&
	VERSION="v0.11.1" &&
	KIND_BINARY_URL="https://github.com/kubernetes-sigs/kind/releases/download/${VERSION}/kind-linux-amd64" &&
	sudo wget -O "${KIND}" "${KIND_BINARY_URL}" &&
	sudo chmod +x "${KIND}" &&
	GO111MODULE=on go get sigs.k8s.io/kind

	unset KIND
	unset KIND_BINARY_URL
	unset VERSION
}

function install_kubectl() {
	echo '----------Installing kubectl----------'
	curl -LO https://storage.googleapis.com/kubernetes-release/release/"$(curl -s "https://storage.googleapis.com/kubernetes-release/release/stable.txt")"/bin/linux/amd64/kubectl
	chmod +x ./kubectl
	sudo mv kubectl /usr/local/bin/kubectl

	touch "$HOME/.bashrc"
	{
		echo ""
		echo "# Kubectl"
		echo "export KUBE_EDITOR=vim"
		echo "source <(kubectl completion bash)"
		echo "alias k=kubectl"
		echo "complete -F __start_kubectl k"
	} >> "$HOME/.bashrc"
	source "$HOME"/.bashrc
}

function install_slack() {
	echo '----------Installing Slack----------'
	sudo snap install slack --classic
}

function install_lens() {
	echo '----------Installing Lens----------'
	sudo snap install kontena-lens --classic
}

function install_goland() {
	echo '----------Installing Goland----------'
	sudo snap install goland --classic
}

function install_k9s() {
	echo '----------Installing k9s----------'
	git clone https://github.com/derailed/k9s.git &&
	cd k9s/ &&
	make build && sudo mv ./execs/k9s /usr/local/bin/k9s
}

function install_helm() {
	echo '----------Installing Helm-----------'
	curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 &&
	chmod 700 get_helm.sh &&
	./get_helm.sh
}

function install_psql() {
	echo '----------Installing Postgres tools----------'
	sudo apt update && sudo apt install postgresql postgresql-contrib
}

function install_bloomrpc() {
	echo '----------Installing BloomRPC----------'

	VERSION="1.5.3" &&
	BLOOM_DEB_URL="https://github.com/uw-labs/bloomrpc/releases/download/${VERSION}/bloomrpc_${VERSION}_amd64.deb" &&
	BLOOM_DEB="/tmp/bloomrpc_${VERSION}_amd64.deb" &&
	sudo wget -O "${BLOOM_DEB}" "${BLOOM_DEB_URL}" &&
	sudo apt-get install -f "${BLOOM_DEB}" 
}

function install_postman() {
	echo '----------Installing Postman----------'
	sudo snap install postman
}

function install_krew() {
	echo '----------Installing Krew----------'
	set -x; cd "$(mktemp -d)" &&
	OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
	ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
	curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.tar.gz" &&
	tar zxvf krew.tar.gz &&
	KREW=./krew-"${OS}_${ARCH}" &&
	"$KREW" install krew

	{
		echo ""
		echo "# Krew"
		echo "export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH""
	} >> "$HOME/.bashrc"
	source "$HOME"/.bashrc

	# installing context switcher
	kubectl krew install ctx
	sudo apt-get update
	sudo apt-get install fzf
}

function install_clickhouse_client() {
	echo '----------Installing ClickHouse client----------'
	sudo apt-key adv --keyserver keyserver.ubuntu.com --recv E0C56BD4
	echo "deb http://repo.yandex.ru/clickhouse/deb/stable/ main/" | sudo tee /etc/apt/sources.list.d/clickhouse.list
	sudo apt update
	sudo apt install clickhouse-client
}

function install_pycharm() {
	echo '----------Installing Pycharm CE----------'
	sudo snap install pycharm-community --classic
}

function install_redis_cli() {
	echo '-----------Installing Redis CLI----------'
	sudo apt install redis-tools
}

onexit() {
     echo "GL HF"
}
trap onexit EXIT

main
