#!/bin/bash


exists()
{
  command -v "$1" >/dev/null 2>&1
}
if exists curl; then
	echo ''
else
  sudo apt install curl -y < "/dev/null"
fi
bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi

function setup_Vars {
	if [ ! $COSMIC_NODENAME ]; then
		read -p "Enter node name: " COSMIC_NODENAME
		echo 'export COSMIC_NODENAME='\"${COSMIC_NODENAME}\" >> $HOME/.bash_profile
	fi
	. $HOME/.bash_profile
	sleep 1
}

function install_Go {
	cd $HOME
	wget -O go1.17.1.linux-amd64.tar.gz https://golang.org/dl/go1.17.1.linux-amd64.tar.gz
	rm -rf /usr/local/go && tar -C /usr/local -xzf go1.17.1.linux-amd64.tar.gz && rm go1.17.1.linux-amd64.tar.gz
	echo 'export GOROOT=/usr/local/go' >> $HOME/.bash_profile
	echo 'export GOPATH=$HOME/go' >> $HOME/.bash_profile
	echo 'export GO111MODULE=on' >> $HOME/.bash_profile
	echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile && . $HOME/.bash_profile
	go version
}

function install_Deps {
	cd $HOME
	sudo apt update
	sudo apt install make clang pkg-config libssl-dev liblz4-tool build-essential git jq ncdu bsdmainutils htop net-tools lsof -y < "/dev/null"
}

function install_Software {
	curl https://get.starport.network/starport! | bash
	git clone https://github.com/cosmic-horizon/coho.git
	cd coho
	git checkout v0.1
	starport chain build
	cohod init $COSMIC_NODENAME --chain-id darkenergy-1
	cd ~/.coho/config
	rm genesis.json
	wget https://raw.githubusercontent.com/cosmic-horizon/testnets/main/darkenergy-1/genesis.json
}

function state_sync {
	systemctl stop cohod
	cohod unsafe-reset-all
	external_address=$(wget -qO- eth0.me)
	peers="a78d0be772be97d05037ba1a1a065b56077475b2@89.163.164.207:26656"
	sed -i.bak -e "s/^external_address *=.*/external_address = \"$external_address:26656\"/; s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.coho/config/config.toml
	

	SNAP="http://89.163.164.207:26657"
	LATEST_HEIGHT=$(curl -s $SNAP/block | jq -r .result.block.header.height)
	TRUST_HEIGHT=$((LATEST_HEIGHT - 200))
	TRUST_HASH=$(curl -s "$SNAP/block?height=$TRUST_HEIGHT" | jq -r .result.block_id.hash)

	sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
	s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP,$SNAP\"| ; \
	s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$TRUST_HEIGHT| ; \
	s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.coho/config/config.toml

	sudo systemctl start cohod
	journalctl -u cohod -f
}

function install_Service {

echo "[Unit]
Description=cosmic-horizon Node
After=network.target
[Service]
User=$USER
Type=simple
ExecStart=$(which cohod) start
Restart=on-failure
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target" > $HOME/cohod.service
sudo mv $HOME/cohod.service /etc/systemd/system
sudo tee <<EOF >/dev/null /etc/systemd/journald.conf
Storage=persistent
EOF
sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
sudo systemctl enable cohod
}

PS3='Please enter your choice (input your option number and press enter): '
options=("full installation on a new server" "state_sync" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "full installation on a new server")
            		sleep 1
			setup_Vars
			install_Go
			install_Deps
			install_Software
			install_Service
			state_sync
			break
            ;;
        "state_sync")
            		sleep 1
			state_sync
			break
            ;;
        "Quit")
            break
            ;;
        *) echo -e "\e[91minvalid option $REPLY\e[0m";;
    esac
done
