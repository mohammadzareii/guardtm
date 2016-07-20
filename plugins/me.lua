do
local function run(msg, matches)
  if matches[1] == 'me' or 'من' then
    if is_sudo(msg) then
      return reply_msg(msg.id," You Are |—>> 😏Sudo😏 ",ok_cb,false)
    elseif is_admin1(msg) then
      return " You Are |—>> 🙃Admin🙃"
    elseif is_owner(msg) then
      return " You Are |—>> 🤑Owner🤑"
    elseif is_momod(msg) then
      return " You Are |—>> 😎Promoted😎"
    else
      return " You Are |—>> 🤓Member🤓 "
    end
  end
end

return {
  patterns = {
 "^(من)$", 
"^(me)$", 
"^[!/#](me)$"
    },
  run = run
}
end
