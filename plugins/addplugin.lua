local function run(msg, matches)
  local text = matches[1]
  local b = 1
  while b ~= 0 do
    text = text:trim()
    text,b = text:gsub('^!+','')
  end
    if not is_sudo(msg) then
    return '⚫️ اضافه کردن افزونه فقط توسط سودو ⚫️'
  end
  local name = matches[2]
  local file = io.open("./"..name, "w")
  file:write(text)
  file:flush()
  file:close()
  return "done😊"
 end
 return {
  description = "⚫️ یک افزونه مفید برای سودو ⚫️",
  usage = "⚫️ یک افزونه برای اضافه کردن افزونه به سرور ⚫️",
  patterns = {
    "^[/#!]plugin (.+) (.*)$"
    "^plugin (.+) (.*)$"
  },
  run = run
}
