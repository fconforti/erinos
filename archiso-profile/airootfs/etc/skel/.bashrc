# ~/.bashrc — ErinOS default shell config

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias ll='ls -lah'
alias erinos='erinos'

PS1='[\u@erinos \W]\$ '

export EDITOR=nvim
export OLLAMA_HOST=127.0.0.1:11434
