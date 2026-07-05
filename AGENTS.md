# Repository Guidelines

## Project Structure & Module Organization

NixVirt is a Nix flake for declaring libvirt objects. Top-level Nix entry points are `flake.nix`, `default.nix`, `lib.nix`, and `modules.nix`. XML generation logic lives in `generate-xml/`, with separate files for domains, networks, pools, volumes, and shared XML helpers. Reusable VM templates are under `templates/`. Runtime helper scripts are in `tool/`, including `virtdeclare`, `nixvirt-module-helper`, and the shared Python module `nixvirt.py`. Golden-file tests are under `checks/<object>/<case>/`, where each case contains `input.nix` and `expected.xml`.

## Build, Test, and Development Commands

- `nix develop`: enter the development shell with `just` available.
- `just`: run the default workflow, currently `format` followed by `check`.
- `just format` or `nix fmt`: format Nix files with `nixpkgs-fmt`.
- `just check` or `nix flake check`: run all flake checks, including XML golden tests.
- `nix build`: build the default package containing `virtdeclare`.
- `nix run .#virtdeclare -- --help`: inspect the CLI wrapper built by the flake.

## Coding Style & Naming Conventions

Use `nixpkgs-fmt` for all Nix code. Keep the existing two-space indentation and attrset style. In XML generator files, prefer names that mirror libvirt XML element and attribute names, such as `currentMemory`, `startupPolicy`, or `mac`. Test case directories use lower-kebab names, for example `template-windows-1`. Python helpers should follow the local style in `tool/nixvirt.py`; avoid broad style-only rewrites when changing behavior.

## Testing Guidelines

Add or update golden tests for changes to XML generation. Create a new directory such as `checks/domain/my-case/` with `input.nix` and `expected.xml`, then register it in `checks/checks.nix`. Run `nix flake check` before submitting. If the change affects the `virtdeclare` behavior, document manual validation steps because these paths depend on a live libvirt connection.

## Commit & Pull Request Guidelines

Recent history uses concise imperative commits, sometimes with Conventional Commit scopes such as `feat(domain): add missing attributes to <graphics> element`. Prefer that style for feature work; short plain commits are acceptable for maintenance. Pull requests should describe the changed libvirt surface, list tests run, and call out any generated XML differences or compatibility concerns. Link issues when applicable.

## Agent-Specific Notes

Do not edit `.direnv/` or other local environment artifacts. Keep changes focused on repository sources, tests, and documentation.
