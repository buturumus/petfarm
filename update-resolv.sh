#!/bin/bash

split_into_parts()
{
   part1="$1"
   part2="$2"
   part3="$3"
}

case "$script_type" in
  up)
        mv /etc/resolv.conf /etc/resolv.conf.orig

        for optionvarname in ${!foreign_option_*} ; do
            option="${!optionvarname}"
            echo "$option"
            split_into_parts $option
            if [ "$part1" = "dhcp-option" ] ; then
                if [ "$part2" = "DNS" ] ; then
                    echo "nameserver $part3" >> /etc/resolv.conf
                fi
            fi
        done


        ;;
  down)
        cp -a /etc/resolv.conf.orig /etc/resolv.conf
        ;;
esac


