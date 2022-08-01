include prelude
import dotenv,
       dimscord,
       dimscmd,
       asyncdispatch,
       options,
       osproc,
       parsetoml

import ../lib/[funcs, palettes]

# Read the secrets file
var token: string
var imgurID: string

try:
  load()
  token = getenv("TOKEN")
  imgurID = getenv("IMGUR_ID")
except:
  token = getenv("TOKEN")
  imgurID = getenv("IMGUR_ID")

# Parse the config file
var parsed = parsetoml.parseFile(getCurrentDir() / "config.toml")
var prefix = $(parsed["Config"]["prefix"])
var inviteLink = $(parsed["Config"]["invite_url"])
var ownerID = $(parsed["Config"]["owner_id"])

# Dimscord setup
let discord = newDiscordClient(token)
var cmd = discord.newHandler() # Must be var

proc onReady(s: Shard, r: Ready) {.event(discord).} =
    echo "Ready as " & $r.user

proc messageCreate (s: Shard, msg: Message) {.event(discord).} =
    discard await cmd.handleMessage(prefix, s, msg) # Returns true if a command was handled
    # You can also pass in a list of prefixes
    # discard await cmd.handleMessage(@["$$", "&"], s, msg)

proc interactionCreate (s: Shard, i: Interaction) {.event(discord).} =
    discard await cmd.handleInteraction(s, i)

# Message commands
cmd.addChat("ping") do ():
    discard await discord.api.sendMessage(
            msg.channelID,
            embeds = @[Embed(
                title: some "🏓 Pong!",
                description: some fmt"My ping is: {$s.latency}ms",
                color: some 0x36393f
        )]
    )

cmd.addChat("convert") do (url: string, colors: seq[string]):
    try:
        var filename = url.split("/")[url.split("/").len - 1]
        var imageDir = getCurrentDir() / "images"
        discard execShellCmd(fmt"curl -O {url}")
        echo "Downloaded {filename}"
        var file = filename
        var convName = "conv-" & filename.splitFile().name & ".png"
        var col = colors
        if colors.len == 1:
          for k, v in pal.fieldPairs:
            if k == colors[0]:
              col = v
        col(file, false, col)
        removeFile(imageDir / filename)
        echo "File removed"
        let convUrl = execCmdEx(fmt"curl -s --location --request POST 'https://api.imgur.com/3/image' --header 'Authorization: Client-ID {imgurID}' --form 'image=@{convName}' | jq .data.link")[0].replace("\"", "")
        discard await discord.api.sendMessage(
            msg.channelID,
            embeds = @[Embed(
                title: some "📷 Image converted!",
                description: some fmt"{convUrl}",
                color: some 0x36393f,
                image: some EmbedImage(url: convUrl)
            )]
            #files = @[DiscordFile(
            #    name: convName,
            #    body: convName
            #)]
        )
        removeFile getCurrentDir() / convName
        echo "File removed"
    except:
        discard await discord.api.sendMessage(
            msg.channelID,
            embeds = @[Embed(
                title: some "Error",
                description: some getCurrentExceptionMsg(),
                color: some 0x36393f
            )]
        )
        return

cmd.addChat("invite") do ():
  discard await discord.api.sendMessage(
    msg.channelID,
    embeds = @[Embed(
        title: some "Invite me!",
        description: some fmt"""[Click here]({inviteLink}) 

Or copy this link: {inviteLink}""",
        color: some 0x36393f
    )]
  )

cmd.addChat("eval") do (code: seq[string]):
  if msg.author.id == ownerID:
    try:
      var command = code.join(" ").replace(";", "\n")
      var result = execCmdEx("nim --eval:'$#' --verbosity:0" % [command])[0].strip()
      discard await discord.api.sendMessage(
        msg.channelID,
        embeds = @[Embed(
            title: some "📝 Eval result",
            description: some fmt"```{result}```",
            color: some 0x36393f
        )]
      )
    except:
      discard await discord.api.sendMessage(
        msg.channelID,
        embeds = @[Embed(
            title: some "Error",
            description: some getCurrentExceptionMsg(),
            color: some 0x36393f
        )]
      )
  else:
    discard await discord.api.sendMessage(
      msg.channelID,
      embeds = @[Embed(
          title: some "Error",
          description: some "Only the bot owner can use this command!",
          color: some 0x36393f
      )]
    )


# Start the bot
waitFor discord.startSession()
