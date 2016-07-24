local function run(msg)
local text = [[`pong` *😆*]]
 send_api_msg(msg, get_receiver_api(msg), text, true, 'md')
end
return { 
patterns = {
"^[!/#]ping$",
"^ping$"
}, 
run = run
 }
