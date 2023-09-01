#!/usr/bin/env sh
rebrand() {
    find ./* -type f -exec sed -i "s/$1/$2/g" {} +
}

#rebrand "\/io\/gitlab\/" "\/org\/garudalinux\/"
#rebrand "io.gitlab." "org.garudalinux."
rebrand LibreWolf JoJo-Browser
rebrand Librewolf JoJo-Browser
rebrand librewolf JoJo-Browser
#rebrand "fredragon\.net" "librewolf.net"
#rebrand "#why-is-firedragon-forcing-light-theme" "#why-is-librewolf-forcing-light-theme"
#rebrand kmozillahelper kfiredragonhelper
