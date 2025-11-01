default: format check

pull:
  git pull

update:
  nix flake update

format:
  shopt -s globstar && nix fmt *.nix **/*.nix

check:
  nix flake check
