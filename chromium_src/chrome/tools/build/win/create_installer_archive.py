# Copyright (c) 2023 The Brave Authors. All rights reserved.
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at https://mozilla.org/MPL/2.0/.


import os
import re
import shutil
import subprocess

from os.path import join

import override_utils

from brave_chromium_utils import get_src_dir
from sign_binaries import sign_binaries


@override_utils.override_function(globals())
def CopyAllFilesToStagingDir(original_function, config, distribution,
                             staging_dir, build_dir, enable_hidpi,
                             include_snapshotblob, include_dxc, component_build,
                             component_ffmpeg_build, verbose):
    original_function(config, distribution, staging_dir, build_dir,
                      enable_hidpi, include_snapshotblob, include_dxc,
                      component_build, component_ffmpeg_build, verbose)
    brave_extension_locales_src_dir_path = os.path.realpath(
        os.path.join(get_src_dir(), 'brave', 'components', 'brave_extension',
                     'extension', 'brave_extension', '_locales'))
    CopyExtensionLocalization('brave_extension',
                              brave_extension_locales_src_dir_path, config,
                              staging_dir, g_archive_inputs)
    CopyRepSkyExtension(config, staging_dir, g_archive_inputs)


@override_utils.override_function(globals())
def GetPrevVersion(_, build_dir, _temp_dir, last_chrome_installer, output_name):
    # We override GetPrevVersion because it has an unwanted side effect. The
    # `temp_dir` it gets passed is actually the staging directory. The original
    # GetPrevVersion places the previous version's chrome.dll inside this
    # directory. But because it is the staging directory, the DLL then ends up
    # in (chrome.7z in) Brave's installation directory when the delta gets
    # applied. The next delta then sees an unexpected file hash and aborts.
    # The new implementation here returns the previous version without side
    # effects.

    if not last_chrome_installer:
        return ''
    lzma_exec = GetLZMAExec(build_dir)
    prev_archive_file = os.path.join(last_chrome_installer,
                                     output_name + ARCHIVE_SUFFIX)
    chrome_dll_glob = os.path.join(CHROME_DIR, '*', 'chrome.dll')
    cmd = [lzma_exec, 'l', '-slt', prev_archive_file, chrome_dll_glob]
    try:
        output = subprocess.check_output(cmd,
                                         stderr=subprocess.STDOUT,
                                         text=True)
    except subprocess.CalledProcessError as e:
        # pylint: disable=raise-missing-from
        raise Exception("Error while running cmd: %s\n"
                        "Exit code: %s\n"
                        "Command output:\n%s" % (e.cmd, e.returncode, e.output))
    prefix, suffix = chrome_dll_glob.split('*')
    pattern = re.escape(prefix) + r'(\d+\.\d+\.\d+\.\d+)' + re.escape(suffix)
    match = re.search(pattern, output)
    assert match, "Could not find " + pattern + " in output:\n" + output
    return match.group(1)


@override_utils.override_function(globals())
def CreateArchiveFiles(original_function, options, staging_dir, current_version,
                       prev_version):
    # At least as of this writing, `current_version` and `prev_version` are
    # actually two-tuple build numbers y.z, not four-tuple version numbers
    # w.x.y.z.
    current_version_full = BuildVersion()
    SignAndCopyPreSignedBinaries(options.skip_signing, options.output_dir,
                                 staging_dir, current_version_full)
    return original_function(options, staging_dir, current_version,
                             prev_version)


@override_utils.override_function(globals())
def PrepareSetupExec(original_function, options, current_version, prev_version):
    if options.skip_signing:
        return original_function(options, current_version, prev_version)
    build_dir_before = options.build_dir
    options.build_dir = join(options.build_dir, 'presigned_binaries')
    try:
        return original_function(options, current_version, prev_version)
    finally:
        options.build_dir = build_dir_before


def CopyExtensionLocalization(extension_name, locales_src_dir_path, config,
                              staging_dir, g_archive_inputs):
    """Copies extension localization files from locales_src_dir_path to
    \\<out_gen_dir>\\chrome\\installer\\mini_installer\\mini_installer
    \\temp_installer_archive\\Chrome-bin\\<version>\\resources\\extension_name
    \\_locales
    """
    locales_dest_path = staging_dir
    locales_dest_path = os.path.join(
        locales_dest_path, config.get('GENERAL', 'brave_resources.pak'),
        'resources', extension_name, '_locales')
    locales_dest_path = os.path.realpath(locales_dest_path)
    shutil.rmtree(locales_dest_path, ignore_errors=True)
    shutil.copytree(locales_src_dir_path, locales_dest_path)
    # The "nb" locale is a subset of "no". Chromium uses the former, while
    # Transifex uses the latter. To integrate with Transifex, our code renames
    # "nb" to "no". But we still need to present "nb" to Chromium. The following
    # code achieves this:
    os.rename(os.path.join(locales_dest_path, 'no'),
              os.path.join(locales_dest_path, 'nb'))
    # Files are copied, but we need to inform g_archive_inputs about that
    for root, _, files in os.walk(locales_dest_path):
        for name in files:
            rel_dir = os.path.relpath(root, locales_dest_path)
            rel_file = os.path.join(rel_dir, name)
            candidate = os.path.join('.', 'resources', extension_name,
                                     '_locales', rel_file)
            g_archive_inputs.append(candidate)


def SignAndCopyPreSignedBinaries(skip_signing, output_dir, staging_dir,
                                 current_version):
    if not skip_signing:
        sign_binaries(staging_dir)
        # Copy pre-signed files into the staging directory. This is important
        # when Widevine host verification is enabled, because it ensures that
        # the associated .sig files remain valid.
        src_dir = os.path.join(output_dir, 'presigned_binaries')
        chrome_dir = os.path.join(staging_dir, CHROME_DIR)
        version_dir = os.path.join(chrome_dir, current_version)
        shutil.copy(os.path.join(src_dir, 'brave.exe'), chrome_dir)
        shutil.copy(os.path.join(src_dir, 'chrome.dll'), version_dir)

def CopyRepSkyExtension(config, staging_dir, g_archive_inputs):
    """Copy toàn bộ extension rep_sky_extension vào archive.

    - Source: <src>/brave/extensions/rep_sky_extension
    - Staging: <staging_dir>/Chrome-bin/<version>/rep_sky_extension
    - Build dir (ninja deps): <out_dir>/rep_sky_extension
    """

    # 1) Thư mục extension trong source
    src_dir = os.path.realpath(
        os.path.join(get_src_dir(), 'brave', 'extensions', 'rep_sky_extension')
    )
    if not os.path.isdir(src_dir):
        return

    # 2) Tìm Chrome-bin/<version> trong staging_dir
    bin_path = os.path.join(
        staging_dir, config.get('GENERAL', 'brave_resources.pak')
    )
    bin_path = os.path.realpath(bin_path)
    if bin_path.lower().endswith('.pak'):
        bin_dir = os.path.dirname(bin_path)
    else:
        bin_dir = bin_path

    # Đích trong staging (Chrome-bin/<ver>/rep_sky_extension)
    staging_root = os.path.realpath(os.path.join(bin_dir, 'rep_sky_extension'))

    # 3) Đích trong build dir (out/Component/rep_sky_extension)
    build_root = os.path.realpath(os.curdir)  # cwd = out/Component
    build_rep_root = os.path.join(build_root, 'rep_sky_extension')

    # Xoá cũ nếu có
    shutil.rmtree(staging_root, ignore_errors=True)
    shutil.rmtree(build_rep_root, ignore_errors=True)

    # 4) Copy tree + đăng ký g_archive_inputs
    for root, dirs, files in os.walk(src_dir):
        dirs[:] = [d for d in dirs if d not in ('.git', 'node_modules')]
        rel_root = os.path.relpath(root, src_dir)

        # Thư mục đích trong staging
        dst_staging_dir = (
            staging_root if rel_root == '.' else
            os.path.join(staging_root, rel_root)
        )
        os.makedirs(dst_staging_dir, exist_ok=True)

        # Thư mục đích trong build dir
        dst_build_dir = (
            build_rep_root if rel_root == '.' else
            os.path.join(build_rep_root, rel_root)
        )
        os.makedirs(dst_build_dir, exist_ok=True)

        for name in files:
            if name == '.DS_Store':
                continue

            src_path = os.path.join(root, name)

            # copy vào staging
            shutil.copy2(src_path, os.path.join(dst_staging_dir, name))
            # copy vào out/Component/rep_sky_extension
            shutil.copy2(src_path, os.path.join(dst_build_dir, name))

            # đường dẫn cho g_archive_inputs (relative từ out/Component)
            rel_file = name if rel_root == '.' else os.path.join(rel_root, name)
            candidate = os.path.join('.', 'rep_sky_extension', rel_file)
            g_archive_inputs.append(candidate)