#!/usr/bin/env python3
"""Compatibility entry point: edit the canonical word catalog and export it.

Legacy append packs and positional overrides have been retired. This command
cannot restore deleted entries or overwrite approved wording from an old pack.
"""
from curate_word_database import main

if __name__ == "__main__":
    main()
