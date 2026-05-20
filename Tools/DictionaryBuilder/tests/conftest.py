#
#  conftest.py
#  KotobaLab
#
#  Created by 椎名アヤネ on 2026/05/17.
#

import pytest


@pytest.fixture
def make_entry():
    def _make(content):
        return ["食べる", "たべる", "★", "v1", 200, content, 1358280, ""]
    return _make
