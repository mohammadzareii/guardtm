local function run(msg, matches)
    if is_momod(msg) then
        return
    end
    local data = load_data(_config.moderation.data)
    if data[tostring(msg.to.id)] then
        if data[tostring(msg.to.id)]['settings'] then
            if data[tostring(msg.to.id)]['settings']['fosh'] then
                lock_fosh = data[tostring(msg.to.id)]['settings']['fosh']
            end
        end
    end
    local chat = get_receiver(msg)
    local user = "user#id"..msg.from.id
    if lock_fosh == "yes" then
       delete_msg(msg.id, ok_cb, true)
    end
end
 
return {
  patterns = {
        "(ک*س)$",
	"کــــــــــیر",
	"کــــــــــــــــــــــــــــــیر",
	"کـیـــــــــــــــــــــــــــــــــــــــــــــــــــر",
        "ک×یر",
	"ک÷یر",
	"ک*ص",
	"کــــــــــیرر",
	"گوساله",
	"gosale",
	"gusale",
	"[Kk]ir",
	"کص",
	"کس",
	"جنده",
	"لاشی",
	"کونی",
	"حرومزاده",
	"حرومی",
	"سگ",
	"مادر سگ",
        "ناموس",
	"[Kk]os",
	"[Jj]ende",
	"[Ll]ashi",
	"[Kk]ooni",
	"[Hh]aroom",
	"[Ff]uck",
	"[Ff]cker",
	"suck",
  },
  run = run
}



