# Zanki Zero Datamining Tools
My collection of tools for picking apart the en-US PC version of Zanki Zero. I make no promises that this will work with any other localization, the original Japanese version, or any of the PS4 versions. I know for certain this won't work on the Vita version.

Licensed under the MIT license. See `LICENSE` for more information.

# Components
`SeparateDat.rb`: A tool that, slowly, separates and decompresses the game's `.dat` files into individual binary files. At present time, I don't know how to recover the original filenames, so the files are just organized by a linear counter, similarly to Fire Emblem: Three Houses.

# Dependencies
You'll need to download [the Aqualead LZSS decompression tool](https://github.com/Brolijah/Aqualead_LZSS) and place Aqualead_LZSS.exe in a directory named `Tools` to use `SeparateDat.rb`.

# Notes
## SeparateDat.rb
If your Zanki Zero install is somewhere besides `C:/Program Files (x86)/Steam/steamapps/common/ZankiZero`, you'll need to change the `ZANKI_ZERO_DAT_PATH` variable in `SeparateDat.rb`. Don't forget to add `app` to the end of the path, that's where all of the .dat files actually are!