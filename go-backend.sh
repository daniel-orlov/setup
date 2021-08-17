#!/bin/bash

# standard bash error handling
set -o errexit;
set -o pipefail;
set -o nounset;
# debug commands
# set -x;

function determine_shell_profile() {
	if [ -n "$($SHELL -c 'echo $ZSH_VERSION')" ]; then
		export SHELL_PROFILE="zshrc"
	elif [ -n "$($SHELL -c 'echo $BASH_VERSION')" ]; then
		export SHELL_PROFILE="bashrc"
	fi
}

function install_snap() {
	echo 'Installing snap'
	snap --version || sudo apt install snapd
}

# Installing latest golang version
function install_latest_golang() {
  VERSION="$(curl -s https://golang.org/VERSION?m=text)"

  [ -z "$GOROOT" ] && GOROOT="$HOME/.go"
  [ -z "$GOPATH" ] && GOPATH="$HOME/go"

  OS="$(uname -s)"
  ARCH="$(uname -m)"

	if [ "$OS" == "Linux" ]; then
	    case $ARCH in
                "x86_64")
                    ARCH=amd64
                    ;;
                "armv6")
                    ARCH=armv6l
                    ;;
                "armv8")
                    ARCH=arm64
                    ;;
                .*386.*)
                    ARCH=386
                    ;;
                esac
                PLATFORM="linux-$ARCH"
	fi

  if [ -d "$GOROOT" ]; then
		echo "The Go install directory ($GOROOT) already exists. Exiting."
		exit 1
  fi

  PACKAGE_NAME="go$VERSION.$PLATFORM.tar.gz"

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
  touch "$HOME/.${SHELL_PROFILE}"
  {
		echo "# GoLang"
		echo "export GOROOT=${GOROOT}"
		echo "export PATH=$GOROOT/bin:$PATH"
		echo "export GOPATH=$GOPATH"
		echo "export PATH=$GOPATH/bin:$PATH"
  } >> "$HOME/.${SHELL_PROFILE}"

  mkdir -p "$GOPATH"/{src,pkg,bin}
  echo -e "\nGo $VERSION was installed into $GOROOT.\nMake sure to relogin into your shell or run:"
  echo -e "\n\tsource $HOME/.${SHELL_PROFILE}\n\nto update your environment variables."

  rm -f /tmp/go.tar.gz
  unset PACKAGE_NAME
  unset VERSION
  unset PLATFORM
}

function install_docker() {
	curl -fsSL https://get.docker.com -o get-docker.sh
	chmod 700 get-docker.sh
	./get-docker.sh

	# Make docker run w/o sudo
	sudo groupadd docker
	sudo gpasswd -a "$USER" docker
	sudo service docker restart
}

function install_kind() {
	echo 'Installing kind'

	KIND='/usr/local/bin/kind'
	VERSION="v0.11.1"
	KIND_BINARY_URL="https://github.com/kubernetes-sigs/kind/releases/download/${VERSION}/kind-linux-amd64"
	wget -O "${KIND}" "${KIND_BINARY_URL}"
	chmod +x "${KIND}"

	GO111MODULE=on go get sigs.k8s.io/kind

	unset KIND
	unset KIND_BINARY_URL
	unset VERSION
}

function install_kubectl() {
	echo 'Installing kubectl'
	curl -LO https://storage.googleapis.com/kubernetes-release/release/"$(curl -s "https://storage.googleapis.com/kubernetes-release/release/stable.txt")"/bin/linux/amd64/kubectl
	chmod +x ./kubectl

	touch "$HOME/.${SHELL_PROFILE}"
	{
		echo "# Kubectl"
		echo "export KUBE_EDITOR=vim"
		echo "source <(kubectl completion bash)"
		echo "alias k=kubectl"
		echo "complete -F __start_kubectl k"
	} >> "$HOME/.${SHELL_PROFILE}"
}

function install_slack() {
	echo 'Installing Slack'
	sudo snap install slack --classic
}

function install_lens() {
	echo 'Installing Lens'
	sudo snap install kontena-lens --classic
}

function install_goland() {
	echo 'Installing Goland'
	sudo snap install goland --classic
}

function install_k9s() {
	echo 'Installing k9s'
	git clone https://github.com/derailed/k9s.git || make build && ./execs/k9s
}

function install_helm() {
	echo 'Installing Helm'
	curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
	chmod 700 get_helm.sh
	./get_helm.sh
}

function install_psql() {
	echo 'Installing Postgres tools'
	sudo apt update && sudo apt install postgresql postgresql-contrib
}

function install_bloomrpc() {
	echo 'Installing BloomRPC'

	VERSION="1.5.3"
	BLOOM_DEB_URL="https://github.com/uw-labs/bloomrpc/releases/download/${VERSION}/bloomrpc_${VERSION}_amd64.deb"
	BLOOM_DEB="./tmp/bloomrpc_${VERSION}_amd64.deb"

	wget -O "${BLOOM_DEB}" "${BLOOM_DEB_URL}"
	sudo apt-get install -f "${BLOOM_DEB}"
}

function install_postman() {
	echo 'Installing Postman'
	sudo snap install postman
}

function install_krew() {
	set -x; cd "$(mktemp -d)" &&
	OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
	ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
	curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/krew.tar.gz" &&
	tar zxvf krew.tar.gz &&
	KREW=./krew-"${OS}_${ARCH}" &&
	"$KREW" install krew

	{
		echo "# Krew"
		echo "export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH""
	} >> "$HOME/.${SHELL_PROFILE}"
	# installing context switcher
	kubectl krew install ctx
	sudo apt-get install fzf
}

function install_clickhouse_client() {
	echo 'Installing ClickHouse client'
	sudo apt-key adv --keyserver keyserver.ubuntu.com --recv E0C56BD4
	echo "deb http://repo.yandex.ru/clickhouse/deb/stable/ main/" | sudo tee /etc/apt/sources.list.d/clickhouse.list
	sudo apt update
	sudo apt install clickhouse-client
}

function install_pycharm() {
	echo 'Installing Pycharm CE'
	 	sudo snap install pycharm-community --classic
}

function install_redis_cli() {
	echo 'Installing Redis CLI'
	cd /tmp
  wget http://download.redis.io/redis-stable.tar.gz
  tar xvzf redis-stable.tar.gz
  cd redis-stable
  make
  cp src/redis-cli /usr/local/bin/
  chmod 755 /usr/local/bin/redis-cli
}

function main() {
#	Prepare for installation
	sudo apt update
	install_snap
	determine_shell_profile

#	Begin work environment setup
# Install Golang and Ops tools
	install_latest_golang
	install_docker
  install_kubectl
  install_kind
  install_helm
  install_k9s
  install_lens
  install_krew

# Install IDE
  install_goland
  install_pycharm

# Install db clients
  install_clickhouse_client
  install_psql
  install_redis_cli

# Install API tools
  install_postman
  install_bloomrpc

# Install distraction machine
  install_slack
}

onexit() {
     echo "GL HF"
}
trap onexit EXIT

main
