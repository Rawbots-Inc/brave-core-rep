# Copyright (c) 2025 The Brave Authors. All rights reserved.
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at https://mozilla.org/MPL/2.0/.

# Upstream's signing and PKG/DMG/ZIP generation logic lets embedders hook into
# the process by providing a module named `signing.internal_invoker` with a
# class named `Invoker`. This file provides such code to apply customizations
# that are necessary for Brave. It collaborates with the similar hook
# `internal_config.py` in this directory.

import glob
import os
import plistlib
import tempfile
from os import makedirs
from os.path import basename

from signing import standard_invoker, commands, pipeline


class Invoker(standard_invoker.Invoker):

    @staticmethod
    def register_arguments(parser):
        standard_invoker.Invoker.register_arguments(parser)
        parser.add_argument("--skip_signing", action="store_true")
        parser.add_argument("--universal", action="store_true")
        parser.add_argument("--provisioning_profile_basename")

    def __init__(self, args, config):
        super().__init__(args, config)
        scrub_restricted_entitlements_for_custom_builds(config)
        add_preinstall_to_dmg()
        if args.skip_signing:
            stub_out_signing_in_upstream()
        # The config can use this to access the args:
        self.args = args


_RESTRICTED_ENTITLEMENTS_TO_STRIP = (
    # These are restricted entitlements. If they are present but not authorized
    # for the signing identity, macOS will SIGKILL the process at exec time.
    'com.apple.developer.associated-domains.applinks.read-write',
    'com.apple.developer.web-browser.public-key-credential',
    'com.apple.developer.networking.vpn.api',
)


def _strip_restricted_entitlements_in_place(entitlements_path: str) -> bool:
    with open(entitlements_path, 'rb') as f:
        entitlements = plistlib.load(f)

    if not isinstance(entitlements, dict):
        return False

    changed = False
    for key in _RESTRICTED_ENTITLEMENTS_TO_STRIP:
        if key in entitlements:
            del entitlements[key]
            changed = True

    if not changed:
        return False

    with open(entitlements_path, 'wb') as f:
        plistlib.dump(entitlements, f, fmt=plistlib.FMT_XML, sort_keys=True)
    return True


def scrub_restricted_entitlements_for_custom_builds(config):
    # Brave's official builds may be authorized for restricted entitlements.
    # For custom-branded builds, default to stripping them so the app can run.
    if getattr(config, 'base_bundle_id', '').startswith('com.brave.Browser'):
        return
    if os.environ.get('BRAVE_STRIP_RESTRICTED_ENTITLEMENTS', '1') == '0':
        return

    run_command_orig = commands.run_command
    run_command_all_output_async_orig = commands.run_command_all_output_async

    scrubbed_paths = set()

    def _maybe_scrub_entitlements(args):
        if not args or basename(args[0]) != 'codesign':
            return

        entitlements_path = None
        for i, arg in enumerate(args):
            if arg == '--entitlements' and i + 1 < len(args):
                entitlements_path = args[i + 1]
                break
            if arg.startswith('--entitlements='):
                entitlements_path = arg.split('=', 1)[1]
                break

        if not entitlements_path:
            return
        if entitlements_path in scrubbed_paths:
            return
        if not os.path.exists(entitlements_path):
            return

        try:
            if _strip_restricted_entitlements_in_place(entitlements_path):
                scrubbed_paths.add(entitlements_path)
        except Exception:
            # If parsing fails, don't block signing; leave entitlements intact.
            return

    def run_command(args, **kwargs):
        _maybe_scrub_entitlements(args)
        return run_command_orig(args, **kwargs)

    async def run_command_all_output_async(args, **kwargs):
        _maybe_scrub_entitlements(args)
        return await run_command_all_output_async_orig(args, **kwargs)

    commands.run_command = run_command
    commands.run_command_all_output_async = run_command_all_output_async


# Add dmg_preinstall.sh to the DMG as .preinstall
def add_preinstall_to_dmg():
    _package_dmg_orig = pipeline._package_dmg

    def _should_strip_dmg_xattrs(config) -> bool:
        override = os.environ.get('BRAVE_DMG_STRIP_XATTRS')
        if override is not None:
            return override != '0'
        # Only default-enable for custom-branded builds to avoid adding extra
        # work to Brave's official builds.
        return not getattr(config, 'base_bundle_id', '').startswith(
            'com.brave.Browser')

    def _strip_xattrs_in_dmg_app(dmg_path: str, run_cmd) -> None:
        if not dmg_path or not os.path.exists(dmg_path):
            return

        # The DMG produced by pkg-dmg is typically read-only. Convert to a
        # temporary read-write image, clean xattrs in the contained .app, then
        # convert back to a compressed read-only DMG.
        with tempfile.TemporaryDirectory(prefix='brave_dmg_xattr_') as tmpdir:
            rw_base = os.path.join(tmpdir, 'rw')
            run_cmd(['hdiutil', 'convert', dmg_path, '-format', 'UDRW', '-ov',
                     '-o', rw_base])
            rw_path = rw_base + '.dmg' if os.path.exists(rw_base + '.dmg') else rw_base

            mount_path = os.path.join(tmpdir, 'mnt')
            makedirs(mount_path, exist_ok=True)
            run_cmd([
                'hdiutil', 'attach', rw_path, '-mountpoint', mount_path,
                '-nobrowse', '-noautoopen', '-quiet'
            ])
            try:
                apps = glob.glob(os.path.join(mount_path, '*.app'))
                if not apps:
                    return
                # Strip FinderInfo/resource forks/quarantine/etc. This keeps
                # signatures strictly valid after drag-install.
                run_cmd(['xattr', '-cr', apps[0]])
            finally:
                # Detach the mount regardless of whether xattr succeeded.
                run_cmd(['hdiutil', 'detach', mount_path, '-quiet'])

            # Write the final image next to the original so os.replace works.
            out_base = dmg_path + '.xattrclean'
            run_cmd([
                'hdiutil', 'convert', rw_path, '-format', 'UDZO', '-ov',
                '-imagekey', 'zlib-level=9', '-o', out_base
            ])
            out_path = out_base + '.dmg' if os.path.exists(out_base + '.dmg') else out_base

            # Atomically swap in the cleaned DMG.
            os.replace(out_path, dmg_path)

    def _package_dmg(paths, dist, config):
        run_command_orig = commands.run_command

        def run_command(args, **kwargs):
            if basename(args[0]) == 'pkg-dmg':
                args = args.copy()
                packaging_dir = paths.packaging_dir(config)
                args += [
                    '--copy', f'{packaging_dir}/dmg_preinstall.sh:/.preinstall'
                ]

                # Capture the output dmg path for post-processing.
                try:
                    if '--target' in args:
                        run_command.dmg_target = args[args.index('--target') + 1]
                    else:
                        for a in args:
                            if a.startswith('--target='):
                                run_command.dmg_target = a.split('=', 1)[1]
                                break
                except Exception:
                    pass

                # For custom-branded builds, create a normal Applications link
                # instead of Brave's space-named link which can be confusing.
                if (not getattr(config, 'base_bundle_id', '').startswith(
                        'com.brave.Browser')
                        and os.environ.get('BRAVE_DMG_APPLICATIONS_LINK_NAME',
                                           'Applications') != ' '):
                    desired = os.environ.get('BRAVE_DMG_APPLICATIONS_LINK_NAME',
                                             'Applications')
                    # Remove any existing symlink specs and add our own.
                    rebuilt = []
                    skip_next = False
                    for i in range(len(args)):
                        if skip_next:
                            skip_next = False
                            continue
                        a = args[i]
                        if a == '--symlink' and i + 1 < len(args):
                            skip_next = True
                            continue
                        if a.startswith('--symlink='):
                            continue
                        rebuilt.append(a)
                    # pkg-dmg syntax is: <target>:<path-inside-dmg>
                    # (where the path inside the dmg must start with '/').
                    rebuilt += ['--symlink', f'/Applications:/{desired}']
                    args = rebuilt
                run_command.caught_pkg_dmg = True
            return run_command_orig(args, **kwargs)

        run_command.caught_pkg_dmg = False
        run_command.dmg_target = None
        commands.run_command = run_command
        try:
            result = _package_dmg_orig(paths, dist, config)
            assert run_command.caught_pkg_dmg
            if _should_strip_dmg_xattrs(config):
                _strip_xattrs_in_dmg_app(run_command.dmg_target, run_command_orig)
            return result
        finally:
            commands.run_command = run_command_orig

    pipeline._package_dmg = _package_dmg


def stub_out_signing_in_upstream():
    run_command_orig = commands.run_command
    run_command_all_output_async_orig = commands.run_command_all_output_async

    def scrub_signing_args(args):
        if args[0] == 'codesign':
            # Even non-signing commands such as `codesign --verify` or
            # `codesign --display` fail when signing is skipped. So don't invoke
            # codesign at all:
            return None  # Indicates the command should not be run
        if args[0] == 'productbuild':
            try:
                sign_index = args.index('--sign')
                # Remove '--sign' and the following argument
                del args[sign_index:sign_index + 2]
            except ValueError:
                pass
        return args

    def run_command(args, **kwargs):
        scrubbed = scrub_signing_args(args.copy())
        if scrubbed is not None:
            return run_command_orig(scrubbed, **kwargs)
        return None

    async def run_command_all_output_async(args, **kwargs):
        scrubbed = scrub_signing_args(args.copy())
        if scrubbed is not None:
            return await run_command_all_output_async_orig(scrubbed, **kwargs)
        return ('%s' % args, 0, '', '')

    commands.run_command = run_command
    commands.run_command_all_output_async = run_command_all_output_async
