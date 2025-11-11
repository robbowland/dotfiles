#!/bin/sh

install_serie() {
	ensure_brew_tap robbowland/kegs
	brew_install_formulas robbowland/kegs/serie
}

register_installer install_serie
