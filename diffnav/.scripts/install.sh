#!/bin/sh

install_diffnav() {
  ensure_brew_tap dlvhdr/formulae
  brew_install_formulas dlvhdr/formulae/diffnav
}

register_installer install_diffnav
