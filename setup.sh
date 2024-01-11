#!/usr/bin/env bash

# global variables
home_skel=home/skel
etc_skel=etc/skel
usr_bin=/usr/local/bin

cp $home_skel/.bashrc $HOME/.bashrc

#########################
# enable rpmfusion repo #
#########################
check_repo_exists=$(dnf repolist | grep rpmfusion | wc -l)
expect=4
if [ ! $check_repo_exists == $expect ]; then
	sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
fi

######################
# enable docker repo #
######################
check_repo_exists=$(dnf repolist | grep docker-ce-stable | wc -l)
expect=1
if [ ! $check_repo_exists == $expect ]; then
	sudo dnf install -y dnf-plugins-core
	sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
fi

##########################
# enable fish-shell repo #
##########################
check_repo_exists=$(dnf repolist | grep shells_fish | wc -l)
expect=1
if [ ! $check_repo_exists == $expect ]; then
	sudo dnf config-manager --add-repo https://download.opensuse.org/repositories/shells:fish/Fedora_39/shells:fish.repo
fi

#############################
# enable google-chrome repo #
#############################
check_repo_exists=$(dnf repolist | grep google-chrome | wc -l)
expect=1
if [ ! $check_repo_exists == $expect ]; then
	sudo dnf install fedora-workstation-repositories -y
	sudo dnf config-manager --set-enabled google-chrome
fi

######################################
# enable alacritty and lazygit repos #
######################################
check_repo_exists=$(dnf repolist | grep atim | wc -l)
expect=2
if [ ! $check_repo_exists == $expect ]; then
	sudo dnf copr enable atim/alacritty -y
fi

###########################
# install distro packages #
###########################
sudo dnf groupinstall -y 'C Development Tools and Libraries'
sudo dnf install -y $(cat packages.txt)
pip3 install --user -r python-packages.txt

################
# install rust #
################
if ! command -v cargo &>/dev/null; then
	curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh
	source ~/.bashrc
	cargo install bat eza ripgrep zoxide fnm
	cargo install joshuto --version 0.9.4
fi

###############
# install fzf #
###############
if [ ! -d $HOME/.fzf ]; then
	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
	bash ~/.fzf/install
	source ~/.bashrc
fi

#######################
# install nerd fronts #
#######################
nerd_fonts_home=$HOME/.nerd-fonts
if [ ! -d $nerd_fonts_home ]; then
	git clone --depth 1 https://github.com/ryanoasis/nerd-fonts.git ~/.nerd-fonts
	bash ~/.nerd-fonts/install.sh
fi

#####################
# config fish-shell #
#####################
omf_home=$HOME/.local/share/omf
if [ ! -d $omf_home ]; then
	# install oh-my-fish
	curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish
	# install plugins
	omf install bang-bang
	omf install clearance
fi
# copy config
cp $home_skel/.config/fish/functions/* $HOME/.config/fish/functions/
cp $home_skel/.config/fish/config.fish $HOME/.config/fish/
cp $home_skel/.config/fish/fish_variables $HOME/.config/fish/

####################
# config alacritty #
####################
alacritty_home=$HOME/.config/alacritty
alacritty_theme=$alacritty_home/themes
if [ ! -d $alacritty_home ]; then
	mkdir -p $alacritty_home/themes
    git clone --depth 1 --branch yaml https://github.com/alacritty/alacritty-theme $alacritty_theme
fi
cp $home_skel/.config/alacritty/alacritty.yml $alacritty_home/alacritty.yml

#######################
# post-install docker #
#######################
sudo systemctl enable --now docker
sudo systemctl enable --now containerd
sudo usermod -aG docker $USER
echo "Install Docker successfully, Please Log out and Log back!!"

#########################
# paste utility scripts #
#########################
sudo cp -a $etc_skel/$usr_bin/* $usr_bin/

#############
# setup vpn #
#############
# setup Opsta vpn
vpn_home=$HOME/vpn
cp -r $home_skel/vpn $vpn_home
# setup PTT vpn
vpn_ptt_venv=$HOME/.vpn-ptt-venv
if [ ! -d $vpn_ptt_venv ]; then
	python3 -m venv $vpn_ptt_venv
	source "$vpn_ptt_venv/bin/activate"
	pip3 install -r $vpn_home/vpn-ptt-requirements.txt
	deactivate
fi

###################
# install postman #
###################
postman_home=$HOME/.Postman
if [ ! -d $postman_home ]; then
	wget https://dl.pstmn.io/download/latest/linux_64
	tar xf linux_64
	rm -rf linux_64
	mv Postman $postman_home
	sudo ln -sf $postman_home/Postman /usr/local/bin/postman
fi

######################
# install kube stack #
######################
if [ ! -f $usr_bin/kubectl ]; then
	# install kubectl
	curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
	chmod +x kubectl
	sudo mv kubectl $usr_bin/
fi

if [ ! -f $usr_bin/kubectx ]; then
	# install kubectx
	sudo git clone https://github.com/ahmetb/kubectx $HOME/.kubectx
	sudo ln -s $HOME/.kubectx/kubectx $usr_bin/kubectx
	sudo ln -s $HOME/.kubectx/kubens $usr_bin/kubens
fi

if [ ! -f $usr_bin/helm ]; then
	# install helm
	curl -LO https://get.helm.sh/helm-v3.13.2-linux-amd64.tar.gz
	tar xf helm-*
	chmod +x linux-amd64/helm
	sudo mv linux-amd64/helm $usr_bin/
	rm -rf linux-amd64 helm-*
fi

if [ ! -f $usr_bin/minikube ]; then
	# install minikube
	curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
	sudo install minikube-linux-amd64 $usr_bin/minikube
	rm -rvf minikube-linux-amd64
fi

################
# disable beep #
################
if [ ! -f /etc/systemd/system/disable-pcspkr.service ]; then
	sudo cp $etc_skel/systemd/system/disable-pcspkr.service /etc/systemd/system/disable-pcspkr.service
	sudo systemctl enable --now disable-pcspkr.service
fi

###############
# tmux config #
###############
cp $home_skel/.tmux.conf $HOME/.tmux.conf

##################
# discord config #
##################
cp $home_skel/.config/discord/settings.json $HOME/.config/discord/settings.json

##############################
# install Node (lasted step) #
##############################
node_version_file=$HOME/.node-version
if [ ! -f $node_version_file ]; then
	cp $home_skel/.node-version $node_version_file
	# bug on this step, run commands manually after this script is finished.
    cd ~
	fnm install
fi