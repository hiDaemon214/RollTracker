-- 插件命名空间
RollTracker = CreateFrame("Frame")

-- 初始化
RollTracker.rollData = {}
RollTracker.isTracking = false
RollTracker.entries = {} -- 用于存储列表条目

-- 主窗口
RollTracker.frame = CreateFrame("Frame", "RollTrackerFrame", UIParent, "BasicFrameTemplateWithInset")
RollTracker.frame:SetSize(220, 320)
RollTracker.frame:SetPoint("CENTER")
RollTracker.frame:SetMovable(true)
RollTracker.frame:EnableMouse(true)
RollTracker.frame:RegisterForDrag("LeftButton")
RollTracker.frame:SetScript("OnDragStart", RollTracker.frame.StartMoving)
RollTracker.frame:SetScript("OnDragStop", RollTracker.frame.StopMovingOrSizing)
RollTracker.frame:Hide()

-- 标题
local title = RollTracker.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
title:SetPoint("CENTER", RollTracker.frame.TitleBg, "CENTER", 0, 0)
title:SetText("Roll Tracker")

-- 控制按钮
local buttonWidth = 55
local buttonSpacing = 5

-- 开始按钮
local startButton = CreateFrame("Button", nil, RollTracker.frame, "GameMenuButtonTemplate")
startButton:SetSize(buttonWidth, 30)
startButton:SetPoint("TOPLEFT", 8, -30)
startButton:SetText("开始")
startButton:SetScript("OnClick", function() RollTracker:StartTracking() end)

-- 结束按钮
local endButton = CreateFrame("Button", nil, RollTracker.frame, "GameMenuButtonTemplate")
endButton:SetSize(85, 30)
endButton:SetPoint("LEFT", startButton, "RIGHT", buttonSpacing, 0)
endButton:SetText("结束并通报")
endButton:SetScript("OnClick", function() RollTracker:StopTracking() end)

-- 清空按钮
local clearButton = CreateFrame("Button", nil, RollTracker.frame, "GameMenuButtonTemplate")
clearButton:SetSize(buttonWidth, 30)
clearButton:SetPoint("LEFT", endButton, "RIGHT", buttonSpacing, 0)
clearButton:SetText("清空")
clearButton:SetScript("OnClick", function()
    RollTracker.rollData = {}
    RollTracker:UpdateRollList()
end)

-- 滚动框
RollTracker.scrollFrame = CreateFrame("ScrollFrame", nil, RollTracker.frame, "UIPanelScrollFrameTemplate")
RollTracker.scrollFrame:SetPoint("TOPLEFT", 10, -70)
RollTracker.scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)

RollTracker.scrollChild = CreateFrame("Frame")
RollTracker.scrollChild:SetSize(200, 0)
RollTracker.scrollFrame:SetScrollChild(RollTracker.scrollChild)

-- 最高Roll显示
local highestRollText = RollTracker.frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
highestRollText:SetPoint("BOTTOM", RollTracker.frame, "BOTTOM", 0, 15)

-- 更新列表
function RollTracker:UpdateRollList()
    -- 清除旧条目
    for _, entry in ipairs(RollTracker.entries) do
        entry:Hide()
    end
    RollTracker.entries = {}

    -- 创建新条目
    local offset = 0
    local maxRoll = 0
    local maxPlayer = ""
    
    for player, roll in pairs(self.rollData) do
        local entry = self.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        entry:SetPoint("TOPLEFT", 10, -offset)
        entry:SetText(format("|cff00ff00%s|r: %d", player, roll))
        offset = offset + 18
        
        table.insert(RollTracker.entries, entry)
        
        if roll > maxRoll then
            maxRoll = roll
            maxPlayer = player
        end
    end

    -- 更新最高Roll显示
    if maxRoll > 0 then
        highestRollText:SetText(format("最高: |cff00ff00%s|r - %d", maxPlayer, maxRoll))
    else
        highestRollText:SetText("")
    end
    
    self.scrollChild:SetHeight(offset)
end

-- 排序功能
function RollTracker:SortRolls()
    local sorted = {}
    for k, v in pairs(self.rollData) do table.insert(sorted, {player = k, roll = v}) end
    table.sort(sorted, function(a, b) return a.roll > b.roll end)
    
    self.rollData = {}
    for _, v in ipairs(sorted) do self.rollData[v.player] = v.roll end
end

-- 开始记录
function RollTracker:StartTracking()
    self.rollData = {}
    self.isTracking = true
    self.frame:Show()
    self:UpdateRollList()
    SendChatMessage("------ 开始Roll点 -----", "RAID")
    SendChatMessage("------ 请勿重复Roll点 -----", "RAID")
end

-- 结束记录
function RollTracker:StopTracking()
    if self.isTracking then
        self.isTracking = false
        self:SortRolls()
        self:UpdateRollList()

        -- 查找最高 Roll 点
        local maxRoll = 0
        local maxPlayer = ""
        for player, roll in pairs(self.rollData) do
            if roll > maxRoll then
                maxRoll = roll
                maxPlayer = player
            end
        end

        -- 发送团队消息
        if maxPlayer ~= "" then
            --SendChatMessage("------ Roll点结果 -----", "PARTY")
            for player, roll in pairs(self.rollData) do
                SendChatMessage(format("--%s: %d--", player, roll), "RAID")
            end
            -- print(maxRoll)
            -- print(maxPlayer)
             --SendChatMessage("----------------------", "PARTY")
            SendChatMessage("当前最高分:"..maxPlayer.." - "..maxRoll, "RAID")
           -- SendChatMessage(format("最高 Roll 点：|cff00ff00%s|r - %d", maxPlayer, maxRoll), "PARTY")
           
        else
            SendChatMessage("本次 Roll 点没有记录到任何结果。", "RAID")
        end
    end
end

-- 事件处理
RollTracker:RegisterEvent("CHAT_MSG_SYSTEM")
RollTracker:SetScript("OnEvent", function(self, event, msg)
    if not self.isTracking then return end
    
    -- 解析中文 Roll 点消息格式
    local player, roll = string.match(msg, "^(.+)掷出(%d+)%(")
    if not roll then
        player, roll = string.match(msg, "^(.+)掷出(%d+)")
    end
    
    if player and roll then
        roll = tonumber(roll)
        -- 防止重复 Roll 点
        if not self.rollData[player] then
            self.rollData[player] = roll
            self:SortRolls()
            self:UpdateRollList()
        else
            SendChatMessage(format("%s 你已经Roll过点了！", player), "WHISPER", nil, player)
        end
    end
end)

-- 斜杠命令
SLASH_ROLLTRACKER1 = "/rolltracker"
SLASH_ROLLTRACKER2 = "/rlt"
SlashCmdList["ROLLTRACKER"] = function()
    RollTracker.frame:SetShown(not RollTracker.frame:IsShown())
end