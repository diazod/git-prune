# Git prune plugin
This plugin allows you to delete and clean the branches that are already merged in your git repositories, including local and remote branches.

## Instalation

1. You first must install oh-my-zsh

	https://github.com/robbyrussell/oh-my-zsh

2. Download or clone git-prune and copy/move to the directory.oh-my-zsh/plugins

3. Edit the the following lines in the file .zshrc

	```bash
	# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
	# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
	# Example format: plugins=(rails git textmate ruby lighthouse)
	# Add wisely, as too many plugins slow down shell startup.

	plugins=(git git-prune)

	```


## Usage

You can performe the removal just by writing the command
```bash
gprune <branch name>
```
<branch name> being the  branch you are going to compare to know what branches are already merged

You can also select to clean and remove local or remote branches separately by using these commands respectively:

#### Remote branches

```bash
gprune -l <branch name>
```

#### Remote branches

```bash
gprune -r <branch name>
```