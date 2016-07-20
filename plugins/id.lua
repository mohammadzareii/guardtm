do
function run(msg, matches)
  return "#⚫️ آی دی گروه : "..msg.from.id.."\n#⚫️ نام گروه : "..msg.to.title.."\n#⚫️ نام شما : "..(msg.from.first_name or '').."\n#⚫️ اسم کوچک : "..(msg.from.first_name or '').."\n#⚫️ شهرت : "..(msg.from.last_name or '').."\n#⚫️ آی دی ( ID) : "..msg.from.id.."\n#⚫️ نام کاربری : @"..(msg.from.username or '').."\n#⚫️ شماره تلفن : +"..(msg.from.phone or '')
end
return {
  description = "", 
  usage = "",
  patterns = {
    "^[!/#]id$",
  },
  run = run
}
end
