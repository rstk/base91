# Base91

BasE91 implementation in Luau.

## Why use Base91?

Using Base91 is a great way to store binary data to Roblox Datastores, as it will use most printable characters to encode your data, enabling the best possible compression, while still being very fast.

## Installation

### Wally

TODO

## Differences with the [original BasE91](http://base91.sourceforge.net)

The 90th character of the translation table is `' (0x27)` instead of `" (0x22)`, because the latter gets escaped in JSON.
