# Dictionary Builder

Build KotobaLab SQLite dictionary database from Yomitan source files.

## Usage

```bash
python3 Tools/DictionaryBuilder/main.py \
  --source dataset/source/jitendex-yomitan \
  --output KotobaLab/Resources/dictionary.sqlite
```

## Benchmark

Prefix LIKE search requires PRAGMA case_sensitive_like = ON to use idx_words_term / idx_words_reading.
