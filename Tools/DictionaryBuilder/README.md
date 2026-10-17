# Dictionary Builder

Python 3.14 toolchain that builds KotobaLab's SQLite dictionary from Yomitan
source files, verifies it, and publishes it as a GitHub Release asset.

The pipeline, commands, verification steps, and measurements are documented in
[`docs/dictionary.md`](../../docs/dictionary.md).

Run the self-contained test suite with:

```bash
python3 -m pytest
```
