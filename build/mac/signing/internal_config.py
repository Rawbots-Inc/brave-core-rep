# Copyright (c) 2025 The Brave Authors. All rights reserved.
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at https://mozilla.org/MPL/2.0/.

# Upstream's signing and PKG/DMG/ZIP generation logic lets embedders hook into
# the process by providing a module named `signing.internal_config` with a class
# named `InternalCodeSignConfig`. This file provides such code to apply
# customizations that are necessary for Brave. It collaborates with the similar
# hook `internal_invoker.py` in this directory.

import os

from signing.chromium_config import ChromiumCodeSignConfig
from signing.model import Distribution, NotarizeAndStapleLevel

BRAVE_CHANNEL = os.environ.get('BRAVE_CHANNEL')


class InternalCodeSignConfig(ChromiumCodeSignConfig):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.is_in_sign_chrome = False

    @staticmethod
    def is_chrome_branded():
        # We want to inherit most of upstream's behavior.
        return True

    @property
    def distributions(self):
        # PKG signing requires a separate "Developer ID Installer" identity.
        # For custom/local builds, users often only have a "Developer ID
        # Application" identity. When installer_identity is not provided,
        # skip packaging as PKG instead of failing the whole packaging step.
        package_as_pkg = bool(getattr(self, 'installer_identity', None))
        return [
            Distribution(channel=BRAVE_CHANNEL,
                         package_as_dmg=True,
                         package_as_pkg=package_as_pkg,
                         package_as_zip=True)
        ]

    @property
    def provisioning_profile_basename(self):
        return self.invoker.args.provisioning_profile_basename

    @property
    def run_spctl_assess(self):
        # The signing pipeline calls `validate_app()` before notarization and
        # stapling are performed. Running `spctl --assess` at that stage
        # deterministically fails with "source=Unnotarized Developer ID".
        #
        # Notarization/stapling is validated later by the notarization step
        # itself (and, optionally, by consumers via `spctl` on the final
        # artifact). So do not run spctl assess here.
        return False

    @property
    def app_dir(self):
        app_dir_basename = super().app_dir
        if self.invoker.args.universal and self.is_in_sign_chrome:
            return 'universal/' + app_dir_basename
        return app_dir_basename
