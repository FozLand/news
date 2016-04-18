local news = {}
news.path = minetest.get_worldpath().."news/"
news.hash_file  = news.path..'news.sum'
news.stamp_file = news.path..'news_stamps.mt'

local stamps = {}
local file = io.open(news.stamp_file, "r")
if file then
	stamps = minetest.deserialize(file:read("*all"))
	file:close()
end
news.news_stamps = stamps or {}

function news.read_hash_file()
	local file = io.open(news.hash_file, "r")
	local news_h
	if file then
		local news_hfile_content = file:read("*all")
		file:close()
		news_h = string.match(news_hfile_content, "(%w+)")
	end
	return news_h
end

function news.write_stamp_file(stamps)
	local file = io.open(news.stamp_file, 'w')
	if file then
		file:write(minetest.serialize(stamps))
		file:close()
	end
end

function news.formspec(player,article)

	local articles = {'Change Log', 'Rules', 'Privileges'}

	if ( article == "" or article == nil ) then
		article = articles[1]
	end

	local newscontent = ''
	local newsfile = io.open(news.path..article, 'r')
	if newsfile ~= nil then
		newscontent = newsfile:read("*a")
		newsfile:close()
	else
		newscontent = "Article '"..article.."' does not exist"
	end

	local index = 1
	for i,v in ipairs(articles) do
		if v == article then
			index = i
			break
		end
	end

	local formspec = "size[8,9]"..
		"textarea[0.3,0.25;8,9;news;= The Foz-Land Dispatch =;"..
			minetest.formspec_escape(newscontent)..
		"]"..
		"label[0,8;Articles]"..
		"dropdown[0,8.5;3,1;article;"..
			table.concat(articles,",")..";"..index..
		"]"..
		"button_exit[6,8.4;2,1;exit;Close]"

	return formspec
end

function news.show_formspec(player)
	local name = player:get_player_name()
	-- not showing news to guest
	if name:find('Guest') then return end
	
	minetest.show_formspec(name,"news",news.formspec(player))
	minetest.log('action','Showing news formspec to '..name)
end

minetest.register_on_joinplayer(function (player)
	local name = player:get_player_name()
	local news_hash = news.read_hash_file()
	if news.news_stamps[name] ~= news_hash then
		news.news_stamps[name] = news_hash
		minetest.after(5,news.show_formspec,player)
		news.write_stamp_file(news.news_stamps)
	end
end)

minetest.register_chatcommand("news",{
	description="Display the server news",
	func = function (name)
		local player = minetest.get_player_by_name(name)
		minetest.show_formspec(name,"news",news.formspec(player,"Change Log"))
	end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
	if formname == "news" and not fields.quit then
		local name = player:get_player_name()
		minetest.show_formspec(name,"news",news.formspec(player,fields.article))
	end
end)
