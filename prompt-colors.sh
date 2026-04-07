#!/usr/bin/env bash
# prompt-colors.sh
#
# source this file to get color definitions
# are also printed to STDERR.

# bash/zsh cross compatibility notes:
# - using colors modules to set colors in zsh, please autoload it
# - Dim colors, Intense Black not supported in zsh

define_color_names() {

  ColorNames=( Black Red Green Yellow Blue Magenta Cyan White )
  FgColors=(    30   31   32    33     34   35      36   37  )
  BgColors=(    40   41   42    43     44   45      46   47  )

  local AttrNorm=0
  local AttrBright=1
  local AttrDim=2

  # define "BoldCOLOR", "BrightCOLOR", and "DimCOLOR" names

  # _map_colors ATTRNAME ATTRVALUE
  #
  # Defines three names for every color, attribute combintaion:
  #    {ATTRNAME}{COLORNAME}
  #    {ATTRNAME}{COLORNAME}Fg
  #    {ATTRNAME}{COLORNAME}Bg
  #
  # Example: BoldRed, BoldRedFg, BoldRedBg

  _map_colors() {
    local x=0
    local attrname="${1}"
    local attrcode="${2}"
    while (( x < 8 )) ; do
      local colorname="${ColorNames[$x]}"
      local fgcolorcode="${FgColors[$x]}"
      local bgcolorcode="${BgColors[$x]}"
      longcolorname="${attrname}${colorname}"

      if [ -n "$ZSH_VERSION" ]; then
        # zsh
        lowercolorname=$(printf "%s" "${colorname}" | tr '[:upper:]' '[:lower:]')
        _def_color_zsh "${longcolorname}"   "${attrcode}" "${lowercolorname}" "fg"
        _def_color_zsh "${longcolorname}Fg" "${attrcode}" "${lowercolorname}" "fg"
        _def_color_zsh "${longcolorname}Bg" "${attrcode}" "${lowercolorname}" "bg"
      else
        # bash
        _def_color "${longcolorname}"   "${attrcode}" "${fgcolorcode}"
        _def_color "${longcolorname}Fg" "${attrcode}" "${fgcolorcode}"
        _def_color "${longcolorname}Bg" "${attrcode}" "${bgcolorcode}"
      fi
      (( x++ ))
    done
  }

  # _term_color [ N | N M ]
  _term_color() {
    local cv
    if [[ "${#}" -gt 1 ]]; then
      cv="${1};${2}"
    else
      cv="${1}"
    fi
    printf "\\[\\033[%sm\\]" "${cv}"
  }

  # def_color NAME ATTRCODE COLORCODE
  _def_color() {
    local def="${1}=\"\`_term_color ${2} ${3}\`\""
    eval "${def}"
  }

  # def_color_zsh NAME ATTRCODE COLORNAME FG|BG
  _def_color_zsh() {
    if [ "${3}" = "0" ]; then
      local def="${1}=\"%{\$reset_color%}\""
    else
      case ${2} in
        1) # bold color
          local def="${1}=\"%{\$${4}_bold[${3}]%}\""
          ;;
        *)
          local def="${1}=\"%{\$${4}[${3}]%}\""
          ;;
      esac
    fi
    eval "${def}"
  }


  _map_colors Bold   ${AttrBright}
  _map_colors Bright ${AttrBright}
  _map_colors Dim    ${AttrDim}
  _map_colors ''     ${AttrNorm}

  if [ -n "$ZSH_VERSION" ]; then
    _def_color_zsh IntenseBlack 0 90
    _def_color_zsh ResetColor   0 0
  else
    _def_color IntenseBlack 0 90
    _def_color ResetColor   0 0
  fi
}

# do the color definitions only once
if [[ -z "${ColorNames+x}" || "${#ColorNames[*]}" = 0 || -z "${IntenseBlack:+x}" || -z "${ResetColor:+x}" ]]; then
  define_color_names
fi
