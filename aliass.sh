# Unalias existing git aliases to prevent conflicts with function definitions
unalias gs ga gp gf gc gac gr gm 2>/dev/null || true

# Basic aliases
alias c="clear"

# Git aliases with clear
gs() {
    clear
    git status
}
ga() { 
    clear
    git add .
}
gp() { 
    clear 
    git push
}
gf() { 
    clear
    git fetch
}

# Git functions with arguments
gc() {
    clear
    git commit -m "$*"
}

gac() {
    clear
    git commit -a -m "$*"
}

gr() {
    clear
    git rebase -i HEAD~"${1:-1}"
}

gm() {
    local branch="${1:-main}"
    clear
    git checkout "$branch" && \
    git pull && \
    git checkout dev && \
    git merge "$branch"
}