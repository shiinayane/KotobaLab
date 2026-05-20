# Dictionary Builder

Build KotobaLab SQLite dictionary database from Yomitan source files.

## Usage

```bash
python3 Tools/DictionaryBuilder/main.py \
  --source dataset/source/jitendex-yomitan \
  --output KotobaLab/Resources/dictionary.sqlite
```

## Benchmark

Search query uses prefix LIKE on both `words.term` and `words.reading`.
SQLite requires `PRAGMA case_sensitive_like = ON` to use `idx_words_term` / `idx_words_reading`.
Without it, `EXPLAIN QUERY PLAN` shows `SCAN words`.
With it, the plan becomes `MULTI-INDEX OR` over both indexes.

### Search Benchmark Record

Tool:

```bash
python3 Tools/DictionaryBuilder/debug/benchmark_search.py \
  --db Tools/DictionaryBuilder/output/dictionary.sqlite
```

Query shape:

```sql
WHERE w.term LIKE ? OR w.reading LIKE ?
```

Results:

| Setting | Query | Average time | Query plan |
| --- | --- | ---: | --- |
| Before `PRAGMA case_sensitive_like = ON` | `見る` | ~16.8 ms | `SCAN words` |
| Before `PRAGMA case_sensitive_like = ON` | `zzzznotfound` | ~16.2 ms | `SCAN words` |
| After `PRAGMA case_sensitive_like = ON` | `見る` | ~0.034 ms | `MULTI-INDEX OR` (`idx_words_term` + `idx_words_reading`) |
| After `PRAGMA case_sensitive_like = ON` | `zzzznotfound` | ~0.012 ms | `MULTI-INDEX OR` (`idx_words_term` + `idx_words_reading`) |

Conclusion:

`PRAGMA case_sensitive_like = ON` is required for the current prefix search to engage `idx_words_term` and `idx_words_reading`. The app enables this in `DatabaseManager`.
