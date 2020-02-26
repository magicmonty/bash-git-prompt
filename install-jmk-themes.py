#!/usr/bin/env python

from __future__ import print_function

import argparse
import glob
import os
import os.path
import sys

CUSTOM_THEMES_LIST = "jmk-themes.lst"

TARGET_PACKAGE_NAME = "bash-git-prompt"

OLD_SUFFIX = ".old"
ORIG_SUFFIX = ".orig"

DRY_RUN_PREFIX = "[DRY_RUN]"


def get_source_dir():
    return os.getcwd()


def get_source_theme_dir():
    return os.path.join(get_source_dir(), "themes")


def get_custom_themes():
    with open(os.path.join(get_source_dir(), CUSTOM_THEMES_LIST), "r") as f:
        themes = [x.strip() for x in f.readlines()]
    return themes


def get_homebrew_prefix():
    homebrew_prefix = os.environ.get("HOMEBREW_PREFIX", "/usr/local")
    return os.path.realpath(os.path.abspath(homebrew_prefix))


def get_package_root():
    return os.path.join(get_homebrew_prefix(), "Cellar", TARGET_PACKAGE_NAME)


def get_package_dirs():
    return [
        x for x in glob.glob(os.path.join(get_package_root(), "*")) if os.path.isdir(x)
    ]


def get_target_theme_dirs():
    theme_dirs = []
    for x in get_package_dirs():
        theme_dir = os.path.join(x, "share", "themes")
        if os.path.isdir(theme_dir):
            theme_dirs.append(theme_dir)
    return theme_dirs


def message(
    dry_run_message, wet_run_message, prefix=None, suffix=None, sep=":", dry_run=False
):
    message_parts = []
    if dry_run:
        message_body = dry_run_message
        message_parts.append(DRY_RUN_PREFIX)
    else:
        message_body = wet_run_message
    if prefix is not None:
        message_parts.append(prefix + sep)
    message_parts.append(message_body)
    if suffix is not None:
        message_parts.append(sep + suffix)
    print(" ".join(message_parts))


def remove_file(target, dry_run):
    message("Would remove", "Removing", suffix=target, dry_run=dry_run)
    if not dry_run:
        os.remove(target)


def rename_file(source, target, dry_run):
    suffix = "{source} -> {target}".format(source=source, target=target)
    message("Would rename", "Renaming", suffix=suffix, dry_run=dry_run)
    if not dry_run:
        os.rename(source, target)


def create_symlink(source, target, dry_run):
    suffix = "{source} -> {target}".format(source=source, target=target)
    message("Would link", "Linking", suffix=suffix, dry_run=dry_run)
    if not dry_run:
        os.symlink(source, target)


def backup(target, dry_run):
    old_target = "".join([target, OLD_SUFFIX])
    orig_target = "".join([target, ORIG_SUFFIX])
    if os.path.lexists(target):
        if not os.path.islink(target):
            rename_file(target, orig_target, dry_run=dry_run)
        else:
            if os.path.lexists(old_target):
                remove_file(old_target, dry_run=dry_run)
            rename_file(target, old_target, dry_run=dry_run)


def setup_arguments(description):
    argparser = argparse.ArgumentParser(description=description)
    argparser.add_argument(
        "-n",
        "--dry-run",
        "--dryrun",
        dest="dry_run",
        action="store_true",
        default=False,
        help="Show what would be done, but don't actually do it",
    )
    return argparser


def main():
    argparser = setup_arguments(description="Install custom bash-git-prompt themes")
    args = argparser.parse_args()
    custom_themes = get_custom_themes()
    abs_source_dir = get_source_theme_dir()
    target_dirs = get_target_theme_dirs()
    for target_dir in target_dirs:
        message(
            "Would install",
            "Installing",
            suffix="custom themes in {target_dir} ...".format(target_dir=target_dir),
            sep="",
            dry_run=args.dry_run,
        )
        rel_source_dir = os.path.relpath(abs_source_dir, start=target_dir)
        for theme_name in custom_themes:
            source_theme = os.path.join(rel_source_dir, theme_name)
            target_theme = os.path.join(target_dir, theme_name)
            backup(target_theme, dry_run=args.dry_run)
            create_symlink(source_theme, target_theme, dry_run=args.dry_run)


if __name__ == "__main__":
    main()
