package.path = package.path .. ';.luarocks/share/lua/5.2/?.lua'
  ..';.luarocks/share/lua/5.2/?/init.lua'
package.cpath = package.cpath .. ';.luarocks/lib/lua/5.2/?.so'

require("./bot/utils")

local f = assert(io.popen('/usr/bin/git describe --tags', 'r'))
VERSION = assert(f:read('*a'))
f:close()

-- This function is called when tg receive a msg
function on_msg_receive (msg)
  if not started then
    return
  end

  msg = backward_msg_format(msg)

  local receiver = get_receiver(msg)
  print(receiver)
  --vardump(msg)
  --vardump(msg)
  msg = pre_process_service_msg(msg)
  if msg_valid(msg) then
    msg = pre_process_msg(msg)
    if msg then
      match_plugins(msg)
      if redis:get("bot:markread") then
        if redis:get("bot:markread") == "on" then
          mark_read(receiver, ok_cb, false)
        end
      end
    end
  end
end

function ok_cb(extra, success, result)

end

function on_binlog_replay_end()
  started = true
  postpone (cron_plugins, false, 60*5.0)
  -- See plugins/isup.lua as an example for cron

  _config = load_config()

  -- load plugins
  plugins = {}
  load_plugins()
end

function msg_valid(msg)
  -- Don't process outgoing messages
  if msg.out then
    print('\27[36mNot valid: msg from us\27[39m')
    return false
  end

  -- Before bot was started
  if msg.date < os.time() - 5 then
    print('\27[36mNot valid: old msg\27[39m')
    return false
  end

  if msg.unread == 0 then
    print('\27[36mNot valid: readed\27[39m')
    return false
  end

  if not msg.to.id then
    print('\27[36mNot valid: To id not provided\27[39m')
    return false
  end

  if not msg.from.id then
    print('\27[36mNot valid: From id not provided\27[39m')
    return false
  end

  if msg.from.id == our_id then
    print('\27[36mNot valid: Msg from our id\27[39m')
    return false
  end

  if msg.to.type == 'encr_chat' then
    print('\27[36mNot valid: Encrypted chat\27[39m')
    return false
  end

  if msg.from.id == 777000 then
    --send_large_msg(*group id*, msg.text) *login code will be sent to GroupID*
    return false
  end

  return true
end

--
function pre_process_service_msg(msg)
   if msg.service then
      local action = msg.action or {type=""}
      -- Double ! to discriminate of normal actions
      msg.text = "!!tgservice " .. action.type

      -- wipe the data to allow the bot to read service messages
      if msg.out then
         msg.out = false
      end
      if msg.from.id == our_id then
         msg.from.id = 0
      end
   end
   return msg
end

-- Apply plugin.pre_process function
function pre_process_msg(msg)
  for name,plugin in pairs(plugins) do
    if plugin.pre_process and msg then
      print('Preprocess', name)
      msg = plugin.pre_process(msg)
    end
  end
  return msg
end

-- Go over enabled plugins patterns.
function match_plugins(msg)
  for name, plugin in pairs(plugins) do
    match_plugin(plugin, name, msg)
  end
end

-- Check if plugin is on _config.disabled_plugin_on_chat table
local function is_plugin_disabled_on_chat(plugin_name, receiver)
  local disabled_chats = _config.disabled_plugin_on_chat
  -- Table exists and chat has disabled plugins
  if disabled_chats and disabled_chats[receiver] then
    -- Checks if plugin is disabled on this chat
    for disabled_plugin,disabled in pairs(disabled_chats[receiver]) do
      if disabled_plugin == plugin_name and disabled then
        local warning = 'Plugin '..disabled_plugin..' is disabled on this chat'
        print(warning)
        return true
      end
    end
  end
  return false
end

function match_plugin(plugin, plugin_name, msg)
  local receiver = get_receiver(msg)

  -- Go over patterns. If one matches it's enough.
  for k, pattern in pairs(plugin.patterns) do
    local matches = match_pattern(pattern, msg.text)
    if matches then
      print("msg matches: ", pattern)

      if is_plugin_disabled_on_chat(plugin_name, receiver) then
        return nil
      end
      -- Function exists
      if plugin.run then
        -- If plugin is for privileged users only
        if not warns_user_not_allowed(plugin, msg) then
          local result = plugin.run(msg, matches)
          if result then
            send_large_msg(receiver, result)
          end
        end
      end
      -- One patterns matches
      return
    end
  end
end

-- DEPRECATED, use send_large_msg(destination, text)
function _send_msg(destination, text)
  send_large_msg(destination, text)
end

-- Save the content of _config to config.lua
function save_config( )
  serialize_to_file(_config, './data/config.lua')
  print ('saved config into ./data/config.lua')
end

-- Returns the config from config.lua file.
-- If file doesn't exist, create it.
function load_config( )
  local f = io.open('./data/config.lua', "r")
  -- If config.lua doesn't exist
  if not f then
    print ("Created new config file: data/config.lua")
    create_config()
  else
    f:close()
  end
  local config = loadfile ("./data/config.lua")()
  for v,user in pairs(config.sudo_users) do
    print("Sudo user: " .. user)
  end
  return config
end

-- Create a basic config.json file and saves it.
function create_config( )
  -- A simple config with basic plugins and ourselves as privileged user
  config = {
    enabled_plugins = {
    "admin",
    "onservice",
    "inrealm",
    "ingroup",
    "inpm",
    "banhammer",
    "stats",
    "anti_spam",
    "owners",
    "arabic_lock",
    "set",
    "get",
    "broadcast",
    "invite",
    "all",
    "leave_ban",
    "supergroup",
    "whitelist",
    "msg_checks",
    "plugins",
    "addplugin",
    "filter",
    "linkpv",
    "lock_emoji",
    "lock_english",
    "lock_fosh",
    "lock_fwd",
    "lock_join",
    "lock_media",
    "lock_operator",
    "lock_username",
    "lock_tag",
    "lock_reply",
    "dlpm",
    "send",
    "set_type",
    "welcome",
    "sh",
    "serverinfo",
    "writer2",
    "txtvoice",
    "time",
    "webshot",
    "stickers",
    "stick",
    "shortlink",
    "redisoner",
    "music",
    "me",
    "info",
    "imagepro",
    "help2",
    "getcaption",
    "begu",
    "fal",
    "weather",
    "id"
    },
    sudo_users = {237948368},--Sudo users
    moderation = {data = 'data/moderation.json'},
    about_text = [[MeGa shield v2.9
An advanced administration bot based on TG-CLI written in Lua

Github:
https://github.com/mohammadzareii/guard

Admins:
@Mmdzri [Developer]
@DavidZzz [Developer]
@sheypoorak_Suport [Manager]
@SweetherTM [suport]

Special thanks to
SEEDTEAM
graphic2014
sheypoorak team
Avira team

Our channels
@SweetherTM [persian]
]],
    help_text_realm = [[
Realm Commands:

!creategroup [Name]
»ايجاد يک گروه

!createrealm [Name]
»ايجاد يک قلمرو

!setname [Name]
»ثبت اسم قلمرو

!setabout [group|sgroup] [GroupID] [Text]
»ثبت مشخصات گروه

!setrules [GroupID] [Text]
»ثبت قوانين گروه ها

!lock [GroupID] [setting]
»قفل تنظيمات گروه ها

!unlock [GroupID] [setting]
»غيرفعال کردن قفل تنظيمات گروه ها

!settings [group|sgroup] [GroupID]
»ثبت تنظيمات براي گروه توسط آيدي

!wholist
»نمايش ليست کاربران گروه/قلمرو

!who
»فرستادن يک فايل از ليست کاربران در گروه/قلمرو

!type
»مطلع شدن از نوع گروه

!kill chat [GroupID]
»اخراج دسته جمعي همه کاربران و حذف گروه

!kill realm [RealmID]
»اخراج دسته جمعي همه کاربران و حذف قلمرو

!addadmin [id|username]
»ترفيع به مقام مديريت توسط آيدي يا نام کاربري*فقط سودو*

!removeadmin [id|username]
»عزل مقام مديريت توسط آيدي يا نمام کاربري*فقط سودو*

!list groups
»نمايش ليست تمام گروه ها

!list realms
»نمايش ليست تمام قلمروها

!support
»ترفيع کاربر به کاربر پشتيبان

!-support
»عزل مقام پشتيباني 

!log
Get a logfile of current group or realm

!broadcast [text]
!broadcast Hello !
»ارسال متن به همه گروه ها*فقط سودو*

!bc [group_id] [text]
!bc 123456789 Hello !
»اين دستور براي ارسال متن به يک گروه توسط آيدي ميباشد


**You شما ميتوانيد از "#" و "!" يا "/"براي اجراي دستور استفاده کنيد


»»فقط ادمين ها و سودو ميتوانند ربات به گروه اضافه کنند««


»»فقط سودو و ادمين ها ميتوانند از دستورات kick,ban,unban,newlink,setphoto,setname,lock,unlock,set rules,set about and settings استفاده کنند««

»» فقط سودو و ادمينها مجاز با استفاده از res, setowner, commands هستند ««
]],
    help_text = [[
Commands list :

»kick [username|id]
»شما ميتوانيد با ريپلي کردن فرد مورد نظر او را اخراج کنيد

»ban [ username|id]
»شما ميتوانيد با ريپلي کردن فرد مورد نظر او را اخراج کنيد
*بدون قابليت بازگشت*

»unban [id]
»آزاد کردن کاربران از ليست کاربران مسدود

»who
»ليست کاربران گروه

»modlist
»ليست مديران گروه

»promote [username]
»ترفيع دادن کاربران

»demote [username]
»عزل مقام مديريت از مديران

»kickme
»دستور براي اخراج شدن از گروه به ميل خودتان

»about
»درباره گروه

»setphoto
»ثبت عکس گروه

»setname [name]
»ثبت اسم گروه

»rules
»قوانين گروه

»id
»نمايش آيدي گروه/خودتان/يا کاربران ديگر

»help
»نمايش متن راهنماي گروه

»lock [links|flood|spam|Arabic|member|rtl|sticker|contacts|strict]
»تنظيم قفل هاي گروه
*rtl: حذف پيام هايي که از راست به چپ نوشته ميشوند*

»unlock [links|flood|spam|Arabic|member|rtl|sticker|contacts|strict]
»تنظيمات غيرفعال سازي قفل هاي گروه
*rtl: غير فعال کردن قفل پيام هايي که از راست به چپ نوشته ميشوند*

»mute [all|audio|gifs|photo|video]
»فيلتر پيام هاي گروه با توجه به نوعشان
*هر نوع پيامي که فيلتر باشد پس از ارسال پاک ميشود*

»unmute [all|audio|gifs|photo|video]
»غير فعال کردن فيلتر پيام ها
*هر نوع پيامي که فيلتر باشد پس از ارسال پاک ميشود*

»set rules <text>
»ثبت  <text> براي قوانين گروه

»set about <text>
»ثبت  <text> براي مشخصات گروه

»settings
»نمايش تنظيمات گروه

»muteslist
»نمايش ليست فيلتر براي گروه

»muteuser [username]
»فيلتر کردن يک کاربر در گفتگو
*کاربر فيلتر شده اگر صحبت کند اخراج ميشود*
*فقظ صاحب گروه ميتواند کربران را فيلتر کند / مديران و صاحب ميتوانند فيلتر را لغو کنند*

»mutelist
»نمايش ليست کاربران فيلتر شده

»newlink
»ايجاد/يا تغيير لينک

»link
»نمايش لينک گروه

»owner
»نمايش آيدي صاحب گروه

»setowner [id]
»ثبت صاحب گروه توسظ آي دي

»setflood [value]
»ثبت عدد براي حساسيت فلود

»stats
»آمار پيام ساده

»save [value] <text>
»ذخيره متن

»get [value]
»نمايش متن

»clean [modlist|rules|about]
» پاکسازي [modlist|rules|about] و تبديل کردن به صفر

»res [username]
»نمايش آي دي توسط نام کاربري
"!res @username"

»log
»نمايش سياهه هاي گروه

»BANLIST
»نمايش ليست کاربران مسدود

**You شما ميتوانيد از "#" و "!" يا "/"براي اجراي دستور استفاده کنيد


*تنها مالک و مديرها مي توانيد ربات در گروه اضافه کنند


*فقط مديران و صاحب گروه ميتوانند از دستورات block, ban, unban, newlink, link, setphoto, setname, lock, unlock, setrules, setabout, settings استفاده کنند

*فقط صاحب گروه ميتواند از دستورات res, setowner, promote, demote, log استفاده کند

]],
	help_text_super =[[
«S.GP COMMANDS»

»INFO
»نمايش اطلاعاتي  از شما

»ADMINS
»نمايش ليست ادمين سوپرگروه

»OWNER
»نمايش نام و مشخصات صاحب گروه

»MODLIST
»نمايش ليست مديران سوپرگروه

»BOTS
»ليست ربات هاي سوپرگروه

»WHO
«ليست تمام کاربران سوپرگروه

»BLOCK
»اخراج کاربر از سوپر گروه
*اضافه کردن کاربر به ليست کاربران مسدود*

»KICK
»اخراج کردن کاربر از سوپرگروه
*بدون اضافه شدن به ليست کاربران مسدود*

»BAN
»اخراج کاربر از سوپرگروه
*بدون قابليت بازگشت*

»UNBAN
»آزاد کردن کاربر مسدود

»ID
»نمايش آيدي شما
*For userID's: !id @username or reply !id*

»ID FROM
»مشاهده آيدي کاربري که پيام فرستاده

»KICKME
»خروج از گروه با ميل خود کاربر
*با قابليت بازگشت*

»SETOWNER
»ثبت صاحب سوپرگروه

»PROMOTE [username|id]
»ترفيع دادن مديران سوپرگروه

»DEMOTE[username|id]
«عزل مقام مديريت

»SETNAME
»ثبت نام جديد براي سوپرگروه

»SETPHOTO
»ثبت تصوير جديد براي سوپرگروه

»SETRULES
»ثبت قوانين براي سوپرگروه

»SETABOUT
»ثبت مشخصات گروه

»SAVE [value] <text>
»ثبت مشخصات اضافي

»GET [value]
»بازيابي اطلاعات اضافي براي چت 

»NEWLINK
»ساخت يک لينک جديد

»LINK
»نمايش لينک سوپرگروه

»RULES
»نمايش قوانين سوپرگروه

»LOCK [links|flood|spam|Arabic|member|rtl|sticker|contacts|strict|tag|username|fwd|reply|fosh|tgservice|leave|join|emoji|english|media|operator]
»تنظيمات قفل هاي سوپرگروه
*rtl: حذف پيام هايي که از راست به چپ نوشته ميشوند*
*strict: فعال کردن تنظيمات سختگيرانه*
*fosh: حذف فحاشي*
*fwd: حذف پيامهاي فوروارد شده*

»UNLOCK [links|flood|spam|Arabic|member|rtl|sticker|contacts|strict|tag|username|fwd|reply|fosh|tgservice|leave|join|emoji|english|media|operator]
»تنظيمات غيرفعال کردن قفل هاي سوپرگروه
*rtl: غير فعال کردن قفل پيام هايي که از راست به چپ نوشته ميشوند*
*strict: غير فعال کردن تنظيمات سختگيرانه*

»MUTE [all|audio|gifs|photo|video|service]
»فيلتر پيام هاي گروه با توجه به نوعشان
*هر نوع پيامي که فيلتر باشد پس از ارسال پاک ميشود*

»UNMUTE [all|audio|gifs|photo|video|service]
»غير فعال کردن فيلتر پيام ها
*هر نوع پيامي که فيلتر باشد پس از ارسال پاک ميشود*

»SETFLOOD [value]
»ثبت تعداد پيام هاي پشت هم

»TYPE [name]
»ثبت نوع گروه /خصوصي|عمومي

»SETTINGS
»نمايش تنظيمات سوپرگروه

»MUTELIST
»نمايش ليست بي صدا

»SILENT [username]
»فيلتر کردن يک کاربر در گفتگو
*پيام هاي کاربران فيلتر شده خودکار پاک ميشوند*
*فقط صاحب گروه ميتواند کاربر را فيلتر کند*

»SILENTLIST
»نمايش ليست کاربران فيلتر شده

»BANLIST
»نمايش ليست کاربران مسدود

»CLEAN [rules|about|modlist|silentlist|filterlist]
»پاکسازي قوانين|درباره|مدبران|ليست بيصدا|ليست فيلتر*

»DEL
»حذف پيام توسظ ريپلي

»FILTER [word]
»ربات پيامهاي حاوي کلمات فيلتر را پاک ميکند

»UNFILTER [word]
»حذف کلمه از ليست فيلتر

»FILTERLIST
»نمايش ليست فيلتر

»CLEAN MSG [value]
»حذف آخرين پيام هاي سوپر گروه به تعداد دلخواه تا 

»PUBLIC [yes|no]
»سوپر گروه عمومي

»RES [username]
»مشاهده نام و آي دي کاربران توسط نام کاربري

»LOG
»مشاهده الگريتم گروه
*جستجو براي دلايل اخراج [#RTL|#spam|#lockmember]

**شما ميتوانيد از "#" و "!" يا "/"براي اجراي دستور استفاده کنيد
*بعضي از دستورات مختص صاحب گروه ميباشد

*فقط مديران و صاحب گروه ميتوانند از دستورات block, ban, unban, newlink, link, setphoto, setname, lock, unlock, setrules, setabout, settings استفاده کنند
*فقط صاحب گروه ميتواند از دستورات res, setowner, promote, demote, log استفاده کند
]],
  }
  serialize_to_file(config, './data/config.lua')
  print('saved config into ./data/config.lua')
end

function on_our_id (id)
  our_id = id
end

function on_user_update (user, what)
  --vardump (user)
end

function on_chat_update (chat, what)
  --vardump (chat)
end

function on_secret_chat_update (schat, what)
  --vardump (schat)
end

function on_get_difference_end ()
end

-- Enable plugins in config.json
function load_plugins()
  for k, v in pairs(_config.enabled_plugins) do
    print("Loading plugin", v)

    local ok, err =  pcall(function()
      local t = loadfile("plugins/"..v..'.lua')()
      plugins[v] = t
    end)

    if not ok then
      print('\27[31mError loading plugin '..v..'\27[39m')
	  print(tostring(io.popen("lua plugins/"..v..".lua"):read('*all')))
      print('\27[31m'..err..'\27[39m')
    end

  end
end

-- custom add
function load_data(filename)

	local f = io.open(filename)
	if not f then
		return {}
	end
	local s = f:read('*all')
	f:close()
	local data = JSON.decode(s)

	return data

end

function save_data(filename, data)

	local s = JSON.encode(data)
	local f = io.open(filename, 'w')
	f:write(s)
	f:close()

end


-- Call and postpone execution for cron plugins
function cron_plugins()

  for name, plugin in pairs(plugins) do
    -- Only plugins with cron function
    if plugin.cron ~= nil then
      plugin.cron()
    end
  end

  -- Called again in 2 mins
  postpone (cron_plugins, false, 120)
end

-- Start and load values
our_id = 0
now = os.time()
math.randomseed(now)
started = false
