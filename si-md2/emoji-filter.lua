-- emoji-filter.lua
-- Filtro Lua para converter emojis Unicode em comandos \emoji{} do LaTeX
-- Compatível com LuaLaTeX + pacote 'emoji'
-- Referência de nomes: https://ctan.org/pkg/emoji

local emojis = {
  -- ✅ USADOS NO LIVRO (cap01.ipynb)
  ["🎓"] = "\\emoji{graduation-cap}",
  ["🔹"] = "\\emoji{small-blue-diamond}",
  ["🚀"] = "\\emoji{rocket}",
  ["🤖"] = "\\emoji{robot}",
  ["🧪"] = "\\emoji{test-tube}",

  -- 😀 ROSTOS E EMOÇÕES
  ["😀"] = "\\emoji{grinning}",
  ["😁"] = "\\emoji{beaming-face-with-smiling-eyes}",
  ["😂"] = "\\emoji{face-with-tears-of-joy}",
  ["😃"] = "\\emoji{grinning-face-with-big-eyes}",
  ["😄"] = "\\emoji{grinning-face-with-smiling-eyes}",
  ["😅"] = "\\emoji{grinning-face-with-sweat}",
  ["😆"] = "\\emoji{grinning-squinting-face}",
  ["😇"] = "\\emoji{smiling-face-with-halo}",
  ["😊"] = "\\emoji{smiling-face-with-smiling-eyes}",
  ["😋"] = "\\emoji{face-savoring-food}",
  ["😎"] = "\\emoji{smiling-face-with-sunglasses}",
  ["😍"] = "\\emoji{smiling-face-with-heart-eyes}",
  ["😢"] = "\\emoji{crying-face}",
  ["😭"] = "\\emoji{loudly-crying-face}",
  ["😡"] = "\\emoji{enraged-face}",
  ["😤"] = "\\emoji{face-with-steam-from-nose}",
  ["😱"] = "\\emoji{face-screaming-in-fear}",
  ["😴"] = "\\emoji{sleeping-face}",
  ["🤔"] = "\\emoji{thinking-face}",
  ["🤩"] = "\\emoji{star-struck}",
  ["🥳"] = "\\emoji{partying-face}",
  ["🥺"] = "\\emoji{pleading-face}",
  ["🤗"] = "\\emoji{smiling-face-with-open-hands}",
  ["🤯"] = "\\emoji{exploding-head}",
  ["😬"] = "\\emoji{grimacing-face}",
  ["🙄"] = "\\emoji{face-with-rolling-eyes}",

  -- 👍 GESTOS E PESSOAS
  ["👍"] = "\\emoji{thumbs-up}",
  ["👎"] = "\\emoji{thumbs-down}",
  ["👏"] = "\\emoji{clapping-hands}",
  ["🙏"] = "\\emoji{folded-hands}",
  ["👋"] = "\\emoji{waving-hand}",
  ["✋"] = "\\emoji{raised-hand}",
  ["🤝"] = "\\emoji{handshake}",
  ["💪"] = "\\emoji{flexed-biceps}",
  ["🧠"] = "\\emoji{brain}",
  ["👁"] = "\\emoji{eye}",
  ["👀"] = "\\emoji{eyes}",
  ["👤"] = "\\emoji{bust-in-silhouette}",
  ["👥"] = "\\emoji{busts-in-silhouette}",
  ["🧑"] = "\\emoji{person}",
  ["👩"] = "\\emoji{woman}",
  ["👨"] = "\\emoji{man}",
  ["🧑‍💻"] = "\\emoji{technologist}",
  ["👩‍💻"] = "\\emoji{woman-technologist}",
  ["👨‍💻"] = "\\emoji{man-technologist}",
  ["🧑‍🎓"] = "\\emoji{student}",
  ["👩‍🏫"] = "\\emoji{woman-teacher}",
  ["👨‍🏫"] = "\\emoji{man-teacher}",
  ["🧑‍🔬"] = "\\emoji{scientist}",

  -- 💡 OBJETOS E FERRAMENTAS
  ["💡"] = "\\emoji{light-bulb}",
  ["🔍"] = "\\emoji{magnifying-glass-tilted-left}",
  ["🔎"] = "\\emoji{magnifying-glass-tilted-right}",
  ["🔧"] = "\\emoji{wrench}",
  ["🔨"] = "\\emoji{hammer}",
  ["⚙️"] = "\\emoji{gear}",
  ["🛠️"] = "\\emoji{hammer-and-wrench}",
  ["📌"] = "\\emoji{pushpin}",
  ["📍"] = "\\emoji{round-pushpin}",
  ["📎"] = "\\emoji{paperclip}",
  ["🖇️"] = "\\emoji{linked-paperclips}",
  ["📏"] = "\\emoji{straight-ruler}",
  ["📐"] = "\\emoji{triangular-ruler}",
  ["✂️"] = "\\emoji{scissors}",
  ["🗑️"] = "\\emoji{wastebasket}",
  ["💾"] = "\\emoji{floppy-disk}",
  ["💿"] = "\\emoji{optical-disk}",
  ["📀"] = "\\emoji{dvd}",
  ["📱"] = "\\emoji{mobile-phone}",
  ["💻"] = "\\emoji{laptop}",
  ["🖥️"] = "\\emoji{desktop-computer}",
  ["⌨️"] = "\\emoji{keyboard}",
  ["🖱️"] = "\\emoji{computer-mouse}",
  ["🖨️"] = "\\emoji{printer}",
  ["📷"] = "\\emoji{camera}",
  ["🎙️"] = "\\emoji{studio-microphone}",
  ["📡"] = "\\emoji{satellite-antenna}",
  ["🔋"] = "\\emoji{battery}",
  ["🔌"] = "\\emoji{electric-plug}",

  -- 📚 EDUCAÇÃO E CIÊNCIA
  ["📚"] = "\\emoji{books}",
  ["📖"] = "\\emoji{open-book}",
  ["📝"] = "\\emoji{memo}",
  ["📓"] = "\\emoji{notebook}",
  ["📔"] = "\\emoji{notebook-with-decorative-cover}",
  ["📒"] = "\\emoji{ledger}",
  ["📕"] = "\\emoji{closed-book}",
  ["📗"] = "\\emoji{green-book}",
  ["📘"] = "\\emoji{blue-book}",
  ["📙"] = "\\emoji{orange-book}",
  ["📜"] = "\\emoji{scroll}",
  ["📄"] = "\\emoji{page-facing-up}",
  ["📃"] = "\\emoji{page-with-curl}",
  ["📋"] = "\\emoji{clipboard}",
  ["🗒️"] = "\\emoji{spiral-notepad}",
  ["🗓️"] = "\\emoji{spiral-calendar}",
  ["📅"] = "\\emoji{calendar}",
  ["📆"] = "\\emoji{tear-off-calendar}",
  ["🔬"] = "\\emoji{microscope}",
  ["🔭"] = "\\emoji{telescope}",
  ["🧬"] = "\\emoji{dna}",
  ["🧫"] = "\\emoji{petri-dish}",
  ["🧲"] = "\\emoji{magnet}",
  ["⚗️"] = "\\emoji{alembic}",
  ["🌡️"] = "\\emoji{thermometer}",
  ["📊"] = "\\emoji{bar-chart}",
  ["📈"] = "\\emoji{chart-increasing}",
  ["📉"] = "\\emoji{chart-decreasing}",
  ["🗃️"] = "\\emoji{card-file-box}",
  ["🗄️"] = "\\emoji{file-cabinet}",
  ["🗂️"] = "\\emoji{card-index-dividers}",
  ["🐍"] = "\\emoji{snake}",

  -- ⚠️ SÍMBOLOS E SINAIS
  ["✅"] = "\\emoji{check-mark-button}",
  ["❌"] = "\\emoji{cross-mark}",
  ["❓"] = "\\emoji{question-mark}",
  ["❗"] = "\\emoji{exclamation-mark}",
  ["⚠️"] = "\\emoji{warning}",
  ["🚫"] = "\\emoji{prohibited}",
  ["🔴"] = "\\emoji{red-circle}",
  ["🟠"] = "\\emoji{orange-circle}",
  ["🟡"] = "\\emoji{yellow-circle}",
  ["🟢"] = "\\emoji{green-circle}",
  ["🔵"] = "\\emoji{blue-circle}",
  ["🟣"] = "\\emoji{purple-circle}",
  ["⚫"] = "\\emoji{black-circle}",
  ["⚪"] = "\\emoji{white-circle}",
  ["🔶"] = "\\emoji{large-orange-diamond}",
  ["🔷"] = "\\emoji{large-blue-diamond}",
  ["🔸"] = "\\emoji{small-orange-diamond}",
  ["🔺"] = "\\emoji{red-triangle-pointed-up}",
  ["🔻"] = "\\emoji{red-triangle-pointed-down}",
  ["▶️"] = "\\emoji{play-button}",
  ["⏩"] = "\\emoji{fast-forward-button}",
  ["⏪"] = "\\emoji{fast-reverse-button}",
  ["⏫"] = "\\emoji{fast-up-button}",
  ["⏬"] = "\\emoji{fast-down-button}",
  ["⏯️"] = "\\emoji{play-or-pause-button}",
  ["🔁"] = "\\emoji{repeat-button}",
  ["🔀"] = "\\emoji{shuffle-tracks-button}",
  ["➕"] = "\\emoji{plus}",
  ["➖"] = "\\emoji{minus}",
  ["✖️"] = "\\emoji{multiply}",
  ["➗"] = "\\emoji{divide}",
  ["♾️"] = "\\emoji{infinity}",
  ["💯"] = "\\emoji{hundred-points}",
  ["🔑"] = "\\emoji{key}",
  ["🗝️"] = "\\emoji{old-key}",
  ["🔒"] = "\\emoji{locked}",
  ["🔓"] = "\\emoji{unlocked}",

  -- 🌐 NATUREZA, VIAGEM E LUGARES
  ["🌍"] = "\\emoji{earth-africa}",
  ["🌎"] = "\\emoji{earth-americas}",
  ["🌏"] = "\\emoji{earth-asia}",
  ["🌐"] = "\\emoji{globe-with-meridians}",
  ["🗺️"] = "\\emoji{world-map}",
  ["🌱"] = "\\emoji{seedling}",
  ["🌲"] = "\\emoji{evergreen-tree}",
  ["🌳"] = "\\emoji{deciduous-tree}",
  ["🌿"] = "\\emoji{herb}",
  ["☀️"] = "\\emoji{sun}",
  ["🌙"] = "\\emoji{crescent-moon}",
  ["⭐"] = "\\emoji{star}",
  ["🌟"] = "\\emoji{glowing-star}",
  ["⚡"] = "\\emoji{lightning}",
  ["🔥"] = "\\emoji{fire}",
  ["💧"] = "\\emoji{droplet}",
  ["🌊"] = "\\emoji{water-wave}",

  -- 🏆 PRÊMIOS E CONQUISTAS
  ["🏆"] = "\\emoji{trophy}",
  ["🥇"] = "\\emoji{1st-place-medal}",
  ["🥈"] = "\\emoji{2nd-place-medal}",
  ["🥉"] = "\\emoji{3rd-place-medal}",
  ["🎖️"] = "\\emoji{military-medal}",
  ["🎯"] = "\\emoji{bullseye}",
  ["🎲"] = "\\emoji{game-die}",
  ["🎮"] = "\\emoji{video-game}",
  ["🎨"] = "\\emoji{artist-palette}",
  ["🎵"] = "\\emoji{musical-note}",
  ["🎶"] = "\\emoji{musical-notes}",
  ["🎤"] = "\\emoji{microphone}",
  ["📣"] = "\\emoji{megaphone}",
  ["📢"] = "\\emoji{loudspeaker}",

  -- 🤖 IA E TECNOLOGIA
  ["🤖"] = "\\emoji{robot}",
  ["🦾"] = "\\emoji{mechanical-arm}",
  ["🦿"] = "\\emoji{mechanical-leg}",
  ["💬"] = "\\emoji{speech-balloon}",
  ["💭"] = "\\emoji{thought-balloon}",
  ["🔗"] = "\\emoji{link}",
  ["📡"] = "\\emoji{satellite-antenna}",
  ["🛰️"] = "\\emoji{satellite}",
  ["🚀"] = "\\emoji{rocket}",
  ["🛸"] = "\\emoji{flying-saucer}",
  ["🔮"] = "\\emoji{crystal-ball}",
  ["🧩"] = "\\emoji{puzzle-piece}",
  ["🧮"] = "\\emoji{abacus}",

  -- ✍️ ESCRITA E COMUNICAÇÃO
  ["✍️"] = "\\emoji{writing-hand}",
  ["🖊️"] = "\\emoji{pen}",
  ["🖋️"] = "\\emoji{fountain-pen}",
  ["✏️"] = "\\emoji{pencil}",
  ["🖍️"] = "\\emoji{crayon}",
  ["📧"] = "\\emoji{e-mail}",
  ["📨"] = "\\emoji{incoming-envelope}",
  ["📩"] = "\\emoji{envelope-with-arrow}",
  ["📤"] = "\\emoji{outbox-tray}",
  ["📥"] = "\\emoji{inbox-tray}",
  ["📦"] = "\\emoji{package}",
  ["🏷️"] = "\\emoji{label}",

  -- ➡️ SETAS
  ["➡️"] = "\\emoji{right-arrow}",
  ["⬅️"] = "\\emoji{left-arrow}",
  ["⬆️"] = "\\emoji{up-arrow}",
  ["⬇️"] = "\\emoji{down-arrow}",
  ["↗️"] = "\\emoji{up-right-arrow}",
  ["↘️"] = "\\emoji{down-right-arrow}",
  ["↙️"] = "\\emoji{down-left-arrow}",
  ["↖️"] = "\\emoji{up-left-arrow}",
  ["↩️"] = "\\emoji{right-arrow-curving-left}",
  ["↪️"] = "\\emoji{left-arrow-curving-right}",
  ["🔄"] = "\\emoji{counterclockwise-arrows-button}",
}

-- Função principal do filtro
function Str(el)
  if FORMAT ~= "latex" then return nil end

  local result = {}
  local has_emoji = false

  for _, cp in utf8.codes(el.text) do
    local char = utf8.char(cp)
    if emojis[char] then
      table.insert(result, pandoc.RawInline("latex", emojis[char]))
      has_emoji = true
    else
      -- Acumula texto normal
      if #result == 0 or result[#result].tag ~= "Str" then
        table.insert(result, pandoc.Str(char))
      else
        result[#result] = pandoc.Str(result[#result].text .. char)
      end
    end
  end

  if has_emoji then
    return result
  end
end