#
# bootstrap: Ensure Zephyr is properly boostrapped.
#

# Set ZEPHYR_HOME.
0=${(%):-%N}
: ${ZEPHYR_HOME:=${0:a:h:h}}

# Set critical Zsh options.
setopt extended_glob interactive_comments

# Set Zsh locations.
typeset -gx __zsh_{config,cache,user_data}_dir
: ${__zsh_config_dir:=${ZDOTDIR:-${XDG_CONFIG_HOME:-$HOME/.config}/zsh}}
: ${__zsh_cache_dir:=${XDG_CACHE_HOME:-$HOME/.cache}/zsh}
: ${__zsh_user_data_dir:=${XDG_DATA_HOME:-$HOME/.local/share}/zsh}
() {
  local _zdir; for _zdir in $@; [ -d ${(P)_zdir} ] || mkdir -p ${(P)_zdir}
} __zsh_{config,cache,user_data}_dir

# Ensure path arrays do not contain duplicates.
typeset -gU cdpath fpath mailpath path

# Set the list of directories that Zsh searches for programs.
if [[ ! -v prepath ]]; then
  # If path ever gets out of order, you can use `path=($prepath $path)` to reset it.
  typeset -ga prepath=(
    $HOME/{,s}bin(N)
    $HOME/.local/{,s}bin(N)
  )
fi
path=(
  $prepath
  /opt/{homebrew,local}/{,s}bin(N)
  /usr/local/{,s}bin(N)
  $path
)

# Support for hooks.
autoload -Uz add-zsh-hook

##? Cache the results of an eval command
function cached-eval {
  emulate -L zsh; setopt local_options extended_glob
  (( $# >= 2 )) || return 1

  : ${__zsh_cache_dir:=${XDG_CACHE_HOME:-$HOME/.cache}/zsh}
  local cmdname=$1; shift
  local cachefile=$__zsh_cache_dir/cached/${cmdname}.zsh
  local -a cached=($cachefile(Nmh-20))
  # If the file has no size (is empty), or is older than 20 hours re-gen the cache.
  if [[ ! -s $cachefile ]] || (( ! ${#cached} )); then
    mkdir -p ${cachefile:h}
    "$@" >| $cachefile
  fi
  source $cachefile
}

# Mark this lib as loaded.
zstyle ":zephyr:lib:bootstrap" loaded 'yes'
