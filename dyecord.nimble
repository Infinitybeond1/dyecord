# Package

version = "0.1.0"
author = "Luke"
description = "Dye as a discord bot"
license = "GPL-3.0-or-later"
srcDir = "src"
bin = @["dyecord"]
binDir = "dist/"


# Dependencies

requires "nim >= 1.4.8"
requires "pixie"
requires "dimscord#head"
requires "https://github.com/Infinitybeond1/dimscmd#head"
requires "dotenv#head"
requires "parsetoml"
requires "sysinfo"
requires "asciitext"

task lint, "Lint all *.nim files":
  exec "nimpretty --indent:2 */**.nim && rm -rvf *.png *.jpg *.jpeg"

task b, "Build the bot":
  exec "nimble build -d:release -d:dimscordDebug --verbose -d:ssl"

task i, "Install and build bot":
  exec "nimble install -d -y && nimble build -d:release -d:dimscordDebug --verbose -d:ssl"

task r, "Run the bot":
  exec "nimble build -d:release -d:dimscordDebug --verbose -d:ssl && ./dist/dyecord"

task z, "Build and run the bot with zig":
  exec "nimble lint && nimble build -d:release -d:dimscordDebug --verbose -d:ssl --cc:clang --clang.exe:zigcc && ./dist/dyecord"
