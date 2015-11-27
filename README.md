# Git prune plugin
This plugin allows you to delete and clean the branches that are already merged in your git repositories, included local and remote repositories.

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