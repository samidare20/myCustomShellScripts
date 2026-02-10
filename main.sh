
# Detect script directory
if [ -n "${BASH_SOURCE-}" ]; then
    __main_file="${BASH_SOURCE[0]}"
elif [ -n "${ZSH_VERSION-}" ]; then
    __main_file="${(%):-%N}"
else
    __main_file="$0"
fi
__main_dir="$(cd "$(dirname "${__main_file}")" 2>/dev/null && pwd)"
unset __main_file

# Project line counter functions
count-lines() {
    "${__main_dir}/CountProjectLine.sh" "$@"
}

# Alias for backward compatibility
cpl() {
    count-lines "$@"
}

# Load sub-scripts if they exist
for _script in "KeyBind.sh" "aliass.sh"; do
    if [ -f "${__main_dir}/${_script}" ]; then
        source "${__main_dir}/${_script}"
    fi
done
unset _script

# Display available commands with colors
show-commands() {
    local cyan='\033[36m'
    local yellow='\033[33m'
    local reset='\033[0m'
    local bold='\033[1m'

    printf "${bold}${cyan}Available commands:${reset}\n"
    printf "  ${yellow}count-lines${reset} [options] - Calculate project line count\n"
    printf "    -s, --show          - Show current directory history\n"
    printf "  ${yellow}cpl${reset} [options]         - Alias for count-lines\n"
    printf "  ${yellow}show-commands${reset}       - Show this help\n"
    printf "\n"
    printf "${bold}Current directory:${reset} ${PWD}\n"
}