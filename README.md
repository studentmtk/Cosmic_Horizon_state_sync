# Cosmic_Horizon_state_sync

#### Automatic installation

```
wget https://raw.githubusercontent.com/studentmtk/Cosmic_Horizon_state_sync/main/Cosmic_Horizon_state_sync.sh
bash Cosmic_Horizon_state_sync.sh
```
select  
1 - complete installation of the environment on a new server and fast synchronization  
2 - the server already has the cohod binary file, the network is initialized and you want to quickly catch up with the height of the network  
3 - exit the menu

#### Manual installation


##### Installing the necessary environment

```
cd $HOME
sudo apt update
sudo apt install make clang curl pkg-config libssl-dev build-essential git jq ncdu bsdmainutils htop net-tools lsof -y < "/dev/null"

```

#### installing Go
```
cd $HOME
wget -O go1.17.1.linux-amd64.tar.gz https://golang.org/dl/go1.17.1.linux-amd64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.17.1.linux-amd64.tar.gz && rm go1.17.1.linux-amd64.tar.gz
echo 'export GOROOT=/usr/local/go' >> $HOME/.bash_profile
echo 'export GOPATH=$HOME/go' >> $HOME/.bash_profile
echo 'export GO111MODULE=on' >> $HOME/.bash_profile
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile && . $HOME/.bash_profile
go version

```

#### Creating a binary umeed file
```
curl https://get.starport.network/starport! | bash
git clone https://github.com/cosmic-horizon/coho.git
cd coho
git checkout v0.1
starport chain build

```

#### Initializing the necessary files

```
cohod init $MONIKER_NAME --chain-id darkenergy-1
cd ~/.coho/config
rm genesis.json
wget https://raw.githubusercontent.com/cosmic-horizon/testnets/main/darkenergy-1/genesis.json

```

#### Creating a service file
```  
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

```

#### Preparing for fast synchronization

```
systemctl stop cohod
cohod unsafe-reset-all
external_address=$(wget -qO- eth0.me)
peers="a78d0be772be97d05037ba1a1a065b56077475b2@89.163.164.207:26656"
sed -i.bak -e "s/^external_address *=.*/external_address = \"$external_address:26656\"/; s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.coho/config/config.toml

```
```
SNAP="http://89.163.164.207:26657"
LATEST_HEIGHT=$(curl -s $SNAP/block | jq -r .result.block.header.height)
TRUST_HEIGHT=$((LATEST_HEIGHT - 200))
TRUST_HASH=$(curl -s "$SNAP/block?height=$TRUST_HEIGHT" | jq -r .result.block_id.hash)

```
```
sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP,$SNAP\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$TRUST_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/.coho/config/config.toml

```
```
sudo systemctl start cohod
journalctl -u cohod -f

```  

If necessary:
After you catch up with the height of the network, " stop systemctl stop cohod ", replace the file " $HOME/.coho/config/priv_validator_key.json " to your validator file and run " systemctl start cohod " again.
  
