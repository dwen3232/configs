TPM_PATH := "$HOME/.config/tmux/plugins/tpm"

# List all recipes
default:
    @just --list

# Installs homebrew
install-brew:
    @echo "------------------------------------------"
    @echo "Checking for Homebrew installation..."
    @if ! command -v brew &>/dev/null; then \
        echo "Homebrew not found, installing..."; \
        /bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
        echo "Homebrew installed successfully."; \
    else \
        echo "Homebrew is already installed!"; \
    fi

# Install brew casks
install-casks: install-brew
    @echo "------------------------------------------"
    @echo "Installing casks..."
    @brew install --cask alt-tab    # For windows-like window navigation
    @brew install --cask kitty      # GPU-rendered GUI
    @brew install --cask raycast    # Better spotlight
    @brew install --cask rectangle  # Window manager, not exactly a tiler, but good enough for my needs
    @brew install --cask stats      # OS stats
    @brew install --cask brave-browser  # Preferred browser, maybe should try out firefox too?
    @brew install --cask spotify    # Music
    @brew install --cask marta      # Finder replacement, finder sucks so much
    @brew install --cask orbstack   # Docker drop-in replacement
    @brew install --cask openlens   # Open-source lens
    @brew install --cask boop       # Dev utils
    @brew install --cask basictex   # Latex
    @brew install --cask obsidian   # Note taking app
    @brew tap homebrew/cask-fonts   
    @brew install --cask font-hack-nerd-font

# Install brew formulae
install-formulae: install-brew
    @echo "------------------------------------------"
    @echo "Installing formulae..."
    @brew install neovim    # maybe I should build from source? 
    @brew install tmux      # Terminal multiplexer
    @brew install neofetch  # TODO: this got archived, remove this? Also has horrible performance on work laptop
    @brew install tree      # Nice util for viewing dir structure
    @brew install tree-sitter   # Language syntax highlighter
    @brew install ripgrep   # Grep I use with Telescope
    @brew install fd        # TODO: do I need this since I have ripgrep?
    @brew install fzf       # TODO: do I need this since I have ripgrep?
    @brew install wget      # This doesn't come preinstalled on MacOS, surprisingly
    @brew install git
    @brew install mercurial

# Install all language dependencies
install-lang-deps: install-brew
    # TODO: should this be split by language?
    @echo "------------------------------------------"
    @echo "Installing language dependencies..."
    @brew install gcc   # C, C++ compiler

    # Python
    @brew install pyenv
    @brew install virtualenv
    @brew install poetry 

    # NodeJS
    @brew install nvm

    # Golang
    @brew install mercurial
    @bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)

    # Java (TODO)
    @brew install jenv
    @brew install java

    # Terraform
    @brew install tfenv
    @tfenv install
    @tfenv use
    @terraform -install-autocomplete

    # K8s
    @brew install kubernetes-cli

# Install all cloud provider SDKs
install-cloud-clis: install-brew
    @echo "------------------------------------------"
    @echo "Installing cloud prover CLIs..."
    @brew install awscli    # AWS CLI
    @brew install google-cloud-sdk  # GCP CLI

# Install all homebrew packages
install-all: install-lang-deps install-formulae install-casks install-cloud-sdks

# Setup terminal (kitty and zsh)
setup-terminal: install-casks
    @echo "------------------------------------------"
    @echo "Setting up kitty and zsh..."
    @kitty +kitten themes --reload-in=all Catppuccin-Mocha
    @echo "Checking for Oh My Zsh installation..."
    @if [ ! -d "${HOME}/.oh-my-zsh" ]; then \
        echo "Oh My Zsh not found, installing..."; \
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"; \
        echo "Oh My Zsh installed!"; \
    else \
        echo "Oh My Zsh is already installed!"; \
    fi
    @brew install zsh-completions
    @brew install zsh-syntax-highlighting
    # Maybe I should just force myself to set this manually every time? Not a good way to check for the other two
    @if [ -z "{{env_var_or_default("ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR", "")}}" ]; then \
        echo "ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR not set, adding to .zshrc..."; \
        echo "export ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR=/opt/homebrew/share/zsh-syntax-highlighting/highlighters" >> ~/.zshrc; \
    fi
    @brew install zsh-autosuggestions

# Setup tmux
setup-tmux: install-formulae
    @echo "------------------------------------------"
    @echo "Setting up tmux..."
    @echo "Checking for TPM installation..."
    @if [ ! -d {{TPM_PATH}} ]; then \
        echo "TPM not found at {{TPM_PATH}}. Cloning TPM..."; \
        git clone https://github.com/tmux-plugins/tpm {{TPM_PATH}}; \
    else \
        echo "TPM is already installed."; \
    fi
    @echo "Installing missing plugins..."
    @TMUX_PLUGIN_MANAGER_PATH={{TPM_PATH}} tmux start-server \; source-file ~/.config/tmux/tmux.conf \; run-shell "{{TPM_PATH}}/bin/install_plugins"
    @echo "All missing plugins have been installed."

# Setup all tools
setup-all: setup-terminal setup-tmux

# Upgrade all tools
upgrade:
    @brew upgrade
