setopt prompt_cr prompt_subst prompt_sp no_global_rcs

## Use the following command to get a list of color codes:
## $ zsh  <<< 'for code in {000..255}; do print -nP -- "%F{$code}$code %f"; [ $((${code} % 16)) -eq 15 ] && echo; done'

# Background colors per time
MORNING_BG="#1C2D30"
AFTERNOON_BG="#000030"
EVENING_BG="#1D1F21"

# Prompt colors
ARROW_COLOR=210
PATH_FONT=235
PATH_FG_COLOR="%F{$PATH_FONT}"
PATH_BG_COLOR="%K{$ARROW_COLOR}"
SEPARATOR_FG_COLOR="%F{$ARROW_COLOR}"
SEGMENT_SEPARATOR="\ue0b0"

COLOR=093
SYS_INFO_COLOR="%F{$COLOR}"

# Caches and constants
_cached_sys_info=""
_cached_local_ip=""
_cached_global_ip=""
_last_update_time=0
_last_time_period=""
PROMPT_EOL_MARK=""

# Gather system information
get_sys_info() {
    local current_time
    current_time=$(date +%s)

    if (( current_time - _last_update_time < 1 )); then
        return
    fi

    _last_update_time=$current_time

    local cpu_usage mem_usage battery local_ip_command
    if [[ "$(uname)" == "Darwin" ]]; then
        cpu_usage=$(ps -A -o %cpu | awk '{s+=$1} END {print s}' | cut -d. -f1)
        local_ip_command="ifconfig | grep 'inet ' | grep -v 127.0.0.1 | awk '{print \$2}' | tr '\n' ' / ' | sed 's/ \/ $//'"
        total_mem=$(sysctl -n hw.memsize | awk '{print $1/1024/1024/1024}')  # Total memory in GB
        used_mem=$(vm_stat | awk '
            /Pages active/ {active=$3}
            /Pages speculative/ {speculative=$3}
            /Pages wired down/ {wired=$4}
            /Pages purgeable/ {purgeable=$3}
            /File-backed pages/ {file_backed=$3}
            /Pages free/ {free=$3}
            END {
                page_size=4096/1024/1024  # Convert to MB
                used=(active+speculative+wired+purgeable+file_backed)*page_size
                print used/1024  # Convert to GB
            }')
        mem_usage=$(awk -v used=$used_mem -v total=$total_mem 'BEGIN {printf "%.1f/%.1fGB", used, total}')
        battery=$(pmset -g batt | grep -o '[0-9]*%' | tr -d '%')
    else
        cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{usage=100-$8} END {print usage}')
        local_ip_command="hostname -I | awk '{print \$1}'"
        mem_usage=$(free -m | awk '/Mem/ {printf "%.1f/%.1fGB", $3/1024, $2/1024}')
        battery=$(upower -i $(upower -e | grep BAT) | grep percentage | awk '{print $2}' | tr -d '%')
    fi

    _cached_local_ip=${_cached_local_ip:-$(eval $local_ip_command)}
    _cached_global_ip=${_cached_global_ip:-$(curl -s ifconfig.me)}

    _cached_sys_info="[CPU: ${SYS_INFO_COLOR}${cpu_usage}%%%f ⚙️  ] [MEM: ${SYS_INFO_COLOR}${mem_usage}%f 💾 ] [BAT: ${SYS_INFO_COLOR}${battery}%%%f ⚡ ] [LocalIP: ${SYS_INFO_COLOR}${_cached_local_ip}%f 🌐 ] [GlobalIP: ${SYS_INFO_COLOR}${_cached_global_ip}%f 🌍 ]"
}

TMOUT=1

TRAPALRM() {
    # Wait until PROMPT is fully initialized
    if [[ -z $PROMPT ]]; then
        return
    fi

    get_sys_info

    local hour=$(date +"%H")
    local current_period

    if (( hour < 12 )); then
        current_period="morning"
    elif (( hour < 18 )); then
        current_period="afternoon"
    else
        current_period="evening"
    fi

    if [[ "$current_period" != "$_last_time_period" ]]; then
        set_background
        _last_time_period="$current_period"
    fi

    case "$WIDGET" in
        expand-or-complete|up-line-or-beginning-search|down-line-or-beginning-search|.history-incremental-search-backward|.history-incremental-search-forward)
            :
            ;;
        *)
            if [[ -o zle ]]; then
                zle reset-prompt
            fi
            ;;
    esac
}

TRAPWINCH() {
    export COLUMNS=$(tput cols)
    export LINES=$(tput lines)
}

# Git prompt configuration
ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}git:(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%}) %{$fg[yellow]%}%1{✗%}"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})"

# Set the background based on time
set_background() {
    local hour=$(date +"%H")
    if (( hour < 12 )); then
        printf "\033]11;${MORNING_BG}\007"
    elif (( hour < 18 )); then
        printf "\033]11;${AFTERNOON_BG}\007"
    else
        printf "\033]11;${EVENING_BG}\007"
    fi
}

[[ -n `command -v figlet` ]] && figlet "0xBADDCAFE" && echo $'\n'

# Initialization
set_background
get_sys_info

PROMPT=$'\n'
PROMPT+="[CLK: %{$SYS_INFO_COLOR%}%D{%L:%M:%S %p}%{$reset_color%} 🕰️  ] "'${_cached_sys_info} '$'\n\n'"%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ )""%{$PATH_FG_COLOR%}%{$PATH_BG_COLOR%} %d %f%k"$(print -n "$SEPARATOR_FG_COLOR$SEGMENT_SEPARATOR%f")' $(git_prompt_info)'
