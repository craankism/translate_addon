local ADDON_NAME = ...

local function ShowClipboardWindow(link)
    if not ClipboardFrame then
        local frame = CreateFrame("Frame", "ClipboardFrame", UIParent, "BackdropTemplate")
        frame:SetSize(420, 140)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("DIALOG")
        frame:SetBackdrop({
            bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
            edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        frame:Hide()

        frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        frame.title:SetPoint("TOP", 0, -12)
        frame.title:SetText("Copy to Clipboard")

        frame.editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
        frame.editBox:SetSize(380, 30)
        frame.editBox:SetPoint("CENTER", 0, -5)
        frame.editBox:SetAutoFocus(true)

        frame.editBox:SetScript("OnEditFocusGained", function(self)
            self:HighlightText()
        end)
        frame.editBox:SetScript("OnEscapePressed", function()
            frame:Hide()
        end)
        frame.editBox:SetScript("OnChar", function()
            frame:Hide()
        end)

        frame.exitButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        frame.exitButton:SetSize(80, 25)
        frame.exitButton:SetPoint("BOTTOM", 0, 12)
        frame.exitButton:SetText("Exit")
        frame.exitButton:SetScript("OnClick", function()
            frame:Hide()
        end)

        ClipboardFrame = frame
    end

    ClipboardFrame:Show()
    ClipboardFrame.editBox:SetText(link)
    ClipboardFrame.editBox:HighlightText()
    ClipboardFrame.editBox:SetFocus()
end

hooksecurefunc("SetItemRef", function(link, text, button, chatFrame)
    local linkType, addon, kind, rest = link:match("^([^:]+):([^:]+):([^:]+):(.+)$")
    if linkType ~= "addon" or addon ~= "LinkClipboard" then
        return
    end

    local url = rest
    local canTranslate = (kind == "translate")

    if kind == "clipboard" or kind == "discord" or kind == "softres" or kind == "translate" then
        ShowClipboardWindow(url, canTranslate)
    end
end)


local function AddCopyButtons(self, event, message, ...)
    -- Check for Cyrillic characters
    if message:find("[\128-\191\208-\209][\128-\191]") then
        local newMsg = message:gsub("[\n\r]", " ") -- Sanitize newlines for the link
        return false, string.format("%s |cffffff00|Haddon:LinkClipboard:translate:%s|h[Copy]|h|r", message, newMsg), ...
    end

    local newMsg = message:gsub("(https?://[%w-_%.%?%.:/%+=&%%#@~]+)", function(url)
        local cleanUrl = url:match("^(.-)[%]%),>*%s]*$") or url

        if cleanUrl:match("^https?://discord%.gg") or cleanUrl:match("^https?://discord%.com") then
            return string.format(
                "|cFF7289DA|Haddon:LinkClipboard:discord:%s|h[Discord]|h|r",
                cleanUrl
            )
        elseif cleanUrl:match("^https?://softres%.") then
            return string.format(
                "|cFFFFA500|Haddon:LinkClipboard:softres:%s|h[Softres]|h|r",
                cleanUrl
            )
        elseif cleanUrl:match("^https?://") or cleanUrl:match("^www%.") then
            return string.format(
                "|cffffffff%s|r |cffffff00|Haddon:LinkClipboard:clipboard:%s|h[Copy]|h|r",
                cleanUrl, cleanUrl
            )
        end

        return url
    end)

    return false, newMsg, ...
end

local allChatEvents = {
    "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE",
    "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM",
    "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER", "CHAT_MSG_PARTY",
    "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID",
    "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING",
    "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_CHANNEL", "CHAT_MSG_SYSTEM"
}

for _, event in ipairs(allChatEvents) do
    ChatFrame_AddMessageEventFilter(event, AddCopyButtons)
end
