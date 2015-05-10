local NAME, config = ...
local options = {}

-- Up values
local _G = _G
local tostring = _G.tostring
local UIParent, CreateFrame = _G.UIParent, _G.CreateFrame
local F, C = _G.Aurora[1], _G.Aurora[2]
local r, g, b = C.r, C.g, C.b

-- RealUI
local nibRealUI = LibStub("AceAddon-3.0"):GetAddon("nibRealUI")
local L = LibStub("AceLocale-3.0"):GetLocale("nibRealUI")
local ndb = nibRealUI.db.profile
local hudSize = ndb.settings.hudSize
local round = nibRealUI.Round

-- Ace
local ACR = LibStub("AceConfigRegistry-3.0")
local ACD = LibStub("AceConfigDialog-3.0")
local GUI = LibStub("AceGUI-3.0")

local uiWidth, uiHeight = UIParent:GetSize()
local initialized = false
local isHuDShown = false

local function debug(...)
    nibRealUI.Debug("Config", ...)
end

local hudConfig, hudToggle
local function InitializeOptions()
    debug("Init")

    nibRealUI:SetUpOptions() -- Old
    ACR:RegisterOptionsTable("HuD", options.HuD)
    ACD:SetDefaultSize("HuD", 600, 480)
    ACR:RegisterOptionsTable("RealUI", options.RealUI)
    initialized = true

    -- The HuD Config bar
    local height = round(uiHeight * 0.05)
    local width = round(height * 1.3)
    hudConfig = CreateFrame("Frame", "RealUIHuDConfig", UIParent)
    hudConfig:SetPoint("BOTTOM", UIParent, "TOP", -500, 0)
    F.CreateBD(hudConfig)

    local slideAnim = hudConfig:CreateAnimationGroup()
    slideAnim:SetScript("OnFinished", function(self)
        local x, y = self.slide:GetOffset()
        hudConfig:ClearAllPoints()
        if y < 0 then
            hudConfig:SetPoint("TOP", UIParent, "TOP", -500, 0)
        else
            hudConfig:SetPoint("BOTTOM", UIParent, "TOP", -500, 1)
        end
    end)
    local slide = slideAnim:CreateAnimation("Translation")
    slide:SetDuration(1)
    slide:SetSmoothing("OUT")
    slideAnim.slide = slide

    -- Highlight frame
    local highlight = CreateFrame("Frame", "RealUIHuDConfig", hudConfig)
    F.CreateBD(highlight, 0.0)
    highlight:SetBackdropColor(r, g, b, 0.3)
    highlight:SetBackdropBorderColor(r, g, b)
    highlight:Hide()

    local hlAnim = highlight:CreateAnimationGroup()
    local hl = hlAnim:CreateAnimation("Translation")
    hl:SetDuration(0.2)
    hl:SetSmoothing("OUT")
    hlAnim.hl = hl

    -- Buttons
    local tabs
    tabs = {
        {
            slug = "toggle",
            icon = [[Interface\AddOns\nibRealUI\Media\Config\Grid]],
        },
        {
            slug = "unitframes",
            icon = [[Interface\AddOns\nibRealUI\Media\Config\Grid]],
        },
        {
            slug = "auratracker",
            icon = [[Interface\AddOns\nibRealUI\Media\Config\Auras]],
        },
        {
            slug = "castbars",
            icon = [[Interface\AddOns\nibRealUI\Media\Config\Auras]],
        },
        {
            slug = "close",
            icon = [[Interface\AddOns\nibRealUI\Media\Config\Close]],
            onclick = function(self, ...)
                debug("OnClick", self.slug, ...)
                highlight:Hide()
                hudToggle()
            end,
        }
    }
    local function tabOnClick(self, ...)
        debug("OnClick", self.slug, ...)
        if highlight.clicked and tabs[highlight.clicked].frame then
            tabs[highlight.clicked].frame:Hide()
        end
        local widget = ACD.OpenFrames["HuD"]
        if widget and highlight.clicked == self.ID then
            highlight.clicked = nil
            widget.titlebg:SetPoint("TOP", 0, 12)
            ACD:Close("HuD")
        else
            highlight.clicked = self.ID
            ACD:Open("HuD", self.slug)
            widget = ACD.OpenFrames["HuD"]
            widget:ClearAllPoints()
            widget:SetPoint("TOP", hudConfig, "BOTTOM")
            widget:SetTitle(self.text:GetText())
            widget.titlebg:SetPoint("TOP", 0, 0)
            -- the position will get reset via SetStatusTable, so we need to set our new positions there too.
            local status = widget.status or widget.localstatus
            status.top = widget.frame:GetTop()
            status.left = widget.frame:GetLeft()
        end
    end
    local prevFrame, container
    debug("size", width, height)
    for i = 1, #tabs do
        local tab = tabs[i]
        debug("iter tabs", i, tab.slug)
        local btn = CreateFrame("Button", "$parentBtn"..i, hudConfig)
        btn.ID = i
        btn.slug = tab.slug
        btn:SetSize(width, height)
        btn:SetScript("OnEnter", function(self, ...)
            if slideAnim:IsPlaying() then return end
            debug("OnEnter", tab.slug)
            if highlight:IsShown() then
                debug(highlight.hover, highlight.clicked)
                if highlight.hover ~= self.ID then
                    hl:SetOffset(width * (self.ID - highlight.hover), 0)
                    hlAnim:SetScript("OnFinished", function(hlAnim)
                        highlight.hover = i
                        highlight:SetAllPoints(self)
                    end)
                    hlAnim:Play()
                elseif hlAnim:IsPlaying() then
                    debug("Stop Playing")
                    hlAnim:Stop()
                end
            else
                highlight.hover = i
                highlight:SetAllPoints(self)
                highlight:Show()
            end
        end)
        btn:SetScript("OnLeave", function(self, ...)
            if hudConfig:IsMouseOver() then return end
            debug("OnLeave hudConfig", ...)
            if highlight.clicked then
                debug(highlight.hover, highlight.clicked)
                if highlight.hover ~= highlight.clicked then
                    hl:SetOffset(width * (highlight.clicked - highlight.hover), 0)
                    hlAnim:SetScript("OnFinished", function(hlAnim)
                        highlight.hover = highlight.clicked
                        highlight:SetAllPoints(hudConfig[highlight.clicked])
                    end)
                    hlAnim:Play()
                elseif hlAnim:IsPlaying() then
                    debug("Stop Playing")
                    hlAnim:Stop()
                end
            else
                highlight:Hide()
            end
        end)

        if i == 1 then
            btn:SetPoint("TOPLEFT")
            local check = CreateFrame("CheckButton", nil, btn, "SecureActionButtonTemplate, UICheckButtonTemplate")
            check:SetHitRectInsets(-10, -10, -1, -21)
            check:SetPoint("CENTER", 0, 10)
            check:SetAttribute("type1", "macro")
            _G.SecureHandlerWrapScript(check, "OnClick", check, [[
                if self:GetID() == 1 then
                    self:SetAttribute("macrotext", format("/cleartarget\n/focus\n/run RealUIHuDTestMode(false)"))
                    self:SetID(0)
                else
                    self:SetAttribute("macrotext", format("/target player\n/focus\n/run RealUIHuDTestMode(true)"))
                    self:SetID(1)
                end
            ]])
        else
            btn:SetPoint("TOPLEFT", prevFrame, "TOPRIGHT")
            btn:SetScript("OnClick", tab.onclick or tabOnClick)

            local icon = btn:CreateTexture(nil, "ARTWORK")
            icon:SetTexture(tab.icon)
            icon:SetSize(height * 0.5, height * 0.5)
            icon:SetPoint("TOP", 0, -(height * 0.15))
        end

        local text = btn:CreateFontString()
        text:SetFontObject(_G.GameFontHighlightSmall)
        text:SetWidth(width * 0.9)
        text:SetPoint("BOTTOM", 0, width * 0.08)
        text:SetText(options.HuD.args[tab.slug].name)
        btn.text = text

        hudConfig[i] = btn
        prevFrame = btn
    end
    hudConfig:SetSize(#tabs * width, height)

    hudToggle = function( ... )
        if isHuDShown then
            ACD:Close("HuD")
            -- slide out
            slide:SetOffset(0, height)
            slideAnim:Play()
            isHuDShown = false
        else
            -- slide in
            slide:SetOffset(0, -height)
            slideAnim:Play()
            isHuDShown = true
        end
    end
end

function nibRealUI:ToggleConfig(mode, ...)
    debug("Toggle", mode, ...)
    if not initialized then InitializeOptions() end
    if mode == "HuD" and not ... then
        nibRealUI:ShowConfigBar() -- Old
        return hudToggle()
    end
    --if not mode:match("RealUI") then mode = "RealUI" end
    if ACD.OpenFrames[mode] then
        ACD:Close(mode)
    else
        ACD:Open(mode, ...)
    end
end

local unitframes do
    local CombatFader = nibRealUI:GetModule("CombatFader")
    local UnitFrames = nibRealUI:GetModule("UnitFrames")
    local db = UnitFrames.db.profile
    unitframes = {
        name = UNITFRAME_LABEL,
        type = "group",
        childGroups = "tab",
        args = {
            enable = {
                name = L["General_Enabled"],
                desc = L["General_EnabledDesc"]:format("RealUI "..UNITFRAME_LABEL),
                type = "toggle",
                get = function(info) return nibRealUI:GetModuleEnabled("UnitFrames") end,
                set = function(info, value)
                    nibRealUI:SetModuleEnabled("UnitFrames", value)
                    nibRealUI:ReloadUIDialog()
                end,
            },
            general = {
                name = GENERAL,
                type = "group",
                order = 10,
                args = {
                    classColor = {
                        name = L["Appearance_ClassColorHealth"],
                        type = "toggle",
                        get = function() return db.overlay.classColor end,
                        set = function(info, value)
                            db.overlay.classColor = value
                        end,
                        order = 10,
                    },
                    classColorNames = {
                        name = L["Appearance_ClassColorNames"],
                        type = "toggle",
                        get = function() return db.overlay.classColorNames end,
                        set = function(info, value)
                            db.overlay.classColorNames = value
                        end,
                        order = 20,
                    },
                    statusText = {
                        name = STATUS_TEXT,
                        desc = OPTION_TOOLTIP_STATUS_TEXT_DISPLAY,
                        type = "select",
                        values = function()
                            return {
                                both = _G.STATUS_TEXT_BOTH,
                                perc = _G.STATUS_TEXT_PERCENT,
                                value = _G.STATUS_TEXT_VALUE,
                            }
                        end,
                        get = function(info)
                            return db.misc.statusText
                        end,
                        set = function(info, value)
                            db.misc.statusText = value
                            UnitFrames:RefreshUnits("StatusText")
                        end,
                        order = 30,
                    },
                    focusClick = {
                        name = L["UnitFrames_SetFocus"],
                        desc = L["UnitFrames_SetFocusDesc"],
                        type = "toggle",
                        get = function() return db.misc.focusclick end,
                        set = function(info, value)
                            db.misc.focusclick = value
                        end,
                        order = 40,
                    },
                    focusKey = {
                        name = L["UnitFrames_ModifierKey"],
                        type = "select",
                        values = function()
                            return {
                                shift = _G.SHIFT_KEY_TEXT,
                                ctrl = _G.CTRL_KEY_TEXT,
                                alt = _G.ALT_KEY_TEXT,
                            }
                        end,
                        disabled = function() return not db.misc.focusclick end,
                        get = function(info)
                            return db.misc.focuskey
                        end,
                        set = function(info, value)
                            db.misc.focuskey = value
                        end,
                        order = 41,
                    },
                    combatFade = {
                        name = L["CombatFade"],
                        type = "group",
                        inline = true,
                        disabled = function() return not db.misc.combatfade.enabled end,
                        order = 50,
                        args = {
                            incombat = {
                                name = L["CombatFade_InCombat"],
                                type = "range",
                                isPercent = true,
                                min = 0, max = 1, step = 0.05,
                                get = function(info) return db.misc.combatfade.opacity.incombat end,
                                set = function(info, value)
                                    db.misc.combatfade.opacity.incombat = value
                                    CombatFader:RefreshMod()
                                end,
                                order = 10,
                            },
                            harmtarget = {
                                name = L["CombatFade_HarmTarget"],
                                type = "range",
                                isPercent = true,
                                min = 0, max = 1, step = 0.05,
                                get = function(info) return db.misc.combatfade.opacity.harmtarget end,
                                set = function(info, value)
                                    db.misc.combatfade.opacity.harmtarget = value
                                    CombatFader:RefreshMod()
                                end,
                                order = 20,
                            },
                            target = {
                                name = L["CombatFade_Target"],
                                type = "range",
                                isPercent = true,
                                min = 0, max = 1, step = 0.05,
                                get = function(info) return db.misc.combatfade.opacity.target end,
                                set = function(info, value)
                                    db.misc.combatfade.opacity.target = value
                                    CombatFader:RefreshMod()
                                end,
                                order = 30,
                            },
                            hurt = {
                                name = L["CombatFade_Hurt"],
                                type = "range",
                                isPercent = true,
                                min = 0, max = 1, step = 0.05,
                                get = function(info) return db.misc.combatfade.opacity.hurt end,
                                set = function(info, value)
                                    db.misc.combatfade.opacity.hurt = value
                                    CombatFader:RefreshMod()
                                end,
                                order = 40,
                            },
                            outofcombat = {
                                name = L["CombatFade_NoCombat"],
                                type = "range",
                                isPercent = true,
                                min = 0, max = 1, step = 0.05,
                                get = function(info) return db.misc.combatfade.opacity.outofcombat end,
                                set = function(info, value)
                                    db.misc.combatfade.opacity.outofcombat = value
                                    CombatFader:RefreshMod()
                                end,
                                order = 50,
                            },
                        }
                    }
                }
            },
            units = {
                name = L["UnitFrames_Units"],
                type = "group",
                childGroups = "select",
                order = 20,
                args = {
                    player = {
                        name = PLAYER,
                        type = "group",
                        order = 10,
                        args = {}
                    },
                    pet = {
                        name = PET,
                        type = "group",
                        order = 20,
                        args = {}
                    },
                    target = {
                        name = TARGET,
                        type = "group",
                        order = 30,
                        args = {}
                    },
                    targettarget = {
                        name = SHOW_TARGET_OF_TARGET_TEXT,
                        type = "group",
                        order = 40,
                        args = {}
                    },
                    focus = {
                        name = FOCUS,
                        type = "group",
                        order = 50,
                        args = {}
                    },
                    focustarget = {
                        name = BINDING_NAME_FOCUSTARGET,
                        type = "group",
                        order = 60,
                        args = {}
                    },
                }
            },
            groups = {
                name = GROUPS,
                type = "group",
                childGroups = "select",
                order = 30,
                args = {
                    gap = {
                        name = L["UnitFrames_Gap"],
                        desc = L["UnitFrames_GapDesc"],
                        type = "range",
                        min = 0, max = 10, step = 1,
                        get = function(info) return db.boss.gap end,
                        set = function(info, value) db.boss.gap = value end,
                        order = 10,
                    },
                    x = {
                        name = L["UnitFrames_XOffset"],
                        type = "input",
                        order = 20,
                        get = function(info) return tostring(db.positions[hudSize].boss.x) end,
                        set = function(info, value)
                            db.positions[hudSize].boss.x = nibRealUI:ValidateOffset(value)
                        end,
                    },
                    y = {
                        name = L["UnitFrames_YOffset"],
                        type = "input",
                        order = 30,
                        get = function(info) return tostring(db.positions[hudSize].boss.y) end,
                        set = function(info, value)
                            db.positions[hudSize].boss.y = nibRealUI:ValidateOffset(value)
                        end,
                    },
                    boss = {
                        name = BOSS,
                        type = "group",
                        order = 40,
                        args = {
                            showPlayerAuras = {
                                name = L["UnitFrames_PlayerAuras"],
                                desc = L["UnitFrames_PlayerAurasDesc"],
                                type = "toggle",
                                get = function() return db.boss.showPlayerAuras end,
                                set = function(info, value)
                                    db.boss.showPlayerAuras = value
                                end,
                                order = 10,
                            },
                            showNPCAuras = {
                                name = L["UnitFrames_NPCAuras"],
                                desc = L["UnitFrames_NPCAurasDesc"],
                                type = "toggle",
                                get = function() return db.boss.showNPCAuras end,
                                set = function(info, value)
                                    db.boss.showNPCAuras = value
                                end,
                                order = 20,
                            },
                            buffCount = {
                                name = L["UnitFrames_BuffCount"],
                                type = "range",
                                min = 1, max = 8, step = 1,
                                get = function(info) return db.boss.buffCount end,
                                set = function(info, value) db.boss.buffCount = value end,
                                order = 30,
                            },
                            debuffCount = {
                                name = L["UnitFrames_DebuffCount"],
                                type = "range",
                                min = 1, max = 8, step = 1,
                                get = function(info) return db.boss.debuffCount end,
                                set = function(info, value) db.boss.debuffCount = value end,
                                order = 40,
                            },

                        }
                    },
                    arena = {
                        name = ARENA,
                        type = "group",
                        order = 50,
                        args = {
                            enabled = {
                                name = L["General_Enabled"],
                                desc = L["General_EnabledDesc"]:format("RealUI"..SHOW_ARENA_ENEMY_FRAMES_TEXT),
                                type = "toggle",
                                get = function() return db.arena.enabled end,
                                set = function(info, value)
                                    db.arena.enabled = value
                                end,
                                order = 10,
                            },
                            options = {
                                name = "",
                                type = "group",
                                inline = true,
                                disabled = function() return not db.arena.enabled end,
                                order = 20,
                                args = {
                                    announceUse = {
                                        name = L["UnitFrames_AnnounceTrink"],
                                        desc = L["UnitFrames_AnnounceTrinkDesc"],
                                        type = "toggle",
                                        get = function() return db.arena.announceUse end,
                                        set = function(info, value)
                                            db.arena.announceUse = value
                                        end,
                                        order = 10,
                                    },
                                    announceChat = {
                                        name = CHAT,
                                        desc = L["UnitFrames_AnnounceChatDesc"],
                                        type = "select",
                                        values = function()
                                            return {
                                                group = _G.INSTANCE_CHAT,
                                                say = _G.CHAT_MSG_SAY,
                                            }
                                        end,
                                        disabled = function() return not db.arena.announceUse end,
                                        get = function(info)
                                            return _G.strlower(db.arena.announceChat)
                                        end,
                                        set = function(info, value)
                                            db.arena.announceChat = value
                                        end,
                                        order = 20,
                                    },
                                    --[[showPets = {
                                        name = SHOW_ARENA_ENEMY_PETS_TEXT,
                                        desc = OPTION_TOOLTIP_SHOW_ARENA_ENEMY_PETS,
                                        type = "toggle",
                                        get = function() return db.arena.showPets end,
                                        set = function(info, value)
                                            db.arena.showPets = value
                                        end,
                                        order = 30,
                                    },
                                    showCast = {
                                        name = SHOW_ARENA_ENEMY_CASTBAR_TEXT,
                                        desc = OPTION_TOOLTIP_SHOW_ARENA_ENEMY_CASTBAR,
                                        type = "toggle",
                                        get = function() return db.arena.showCast end,
                                        set = function(info, value)
                                            db.arena.showCast = value
                                        end,
                                        order = 40,
                                    },]]
                                },
                            },
                        }
                    },
                }
            },
        },
    }
    local units = unitframes.args.units.args
    for unitSlug, unit in next, units do
        local position = db.positions[hudSize][unitSlug]
        if unitSlug == "player" or unitSlug == "target" then
            unit.args.anchorWidth = {
                name = L["UnitFrames_AnchorWidth"],
                desc = L["UnitFrames_AnchorWidthDesc"],
                type = "range",
                width = "double",
                min = round(uiWidth * 0.1),
                max = round(uiWidth * 0.5),
                step = 2,
                order = 5,
                get = function(info) return ndb.positions[nibRealUI.cLayout]["UFHorizontal"] end,
                set = function(info, value)
                    ndb.positions[nibRealUI.cLayout]["UFHorizontal"] = value
                    nibRealUI:UpdatePositioners()
                end,
            }
        end
        unit.args.x = {
            name = L["UnitFrames_XOffset"],
            type = "input",
            order = 10,
            get = function(info) return tostring(position.x) end,
            set = function(info, value)
                value = nibRealUI:ValidateOffset(value)
                position.x = value
            end,
        }
        unit.args.y = {
            name = L["UnitFrames_YOffset"],
            type = "input",
            order = 20,
            get = function(info) return tostring(position.y) end,
            set = function(info, value)
                value = nibRealUI:ValidateOffset(value)
                position.y = value
            end,
        }
        --[[ future times
        local unitInfo = db.units[unitSlug]
        unit.args = {
            width = {
                name = L["HuD_Width"],
                type = "input",
                --width = "half",
                order = 10,
                get = function(info) return tostring(unitInfo.height.x) end,
                set = function(info, value)
                    unitInfo.height.x = value
                end,
                pattern = "^(%d+)$",
                usage = "You can only use whole numbers."
            },
            height = {
                name = L["HuD_Height"],
                type = "input",
                --width = "half",
                order = 20,
                get = function(info) return tostring(unitInfo.height.y) end,
                set = function(info, value)
                    unitInfo.height.y = value
                end,
                pattern = "^(%d+)$",
                usage = "You can only use whole numbers."
            },
            healthHeight = {
                name = "Health bar height",
                desc = "The height of the health bar as a percentage of the total unit height",
                type = "range",
                width = "double",
                min = 0,
                max = 1,
                step = .01,
                isPercent = true,
                order = 50,
                get = function(info) return unitInfo.healthHeight end,
                set = function(info, value)
                    unitInfo.healthHeight = value
                end,
            },
            x = {
                name = L["UnitFrames_XOffset"],
                type = "range",
                min = -100,
                max = 50,
                step = 1,
                order = 30,
                get = function(info) return unitInfo.position.x end,
                set = function(info, value)
                    unitInfo.position.x = value
                end,
            },
            y = {
                name = "L["UnitFrames_YOffset"],
                type = "range",
                min = -100,
                max = 100,
                step = 1,
                order = 40,
                get = function(info) return unitInfo.position.y end,
                set = function(info, value)
                    unitInfo.position.y = value
                end,
            },
        --]]
    end
end
local auratracker do
    local AuraTracking = nibRealUI:GetModule("AuraTracking")
    local db = AuraTracking.db.profile
    local trackingData = db.tracking[nibRealUI.class]
    local function getNameOrder(spellData)
        local order, pos, name = 70, "", _G.GetSpellInfo(spellData.spell) or L["AuraTrack_SpellNameID"]

        if spellData.order and spellData.order > 0 then
            order = spellData.order * 10
            pos = spellData.order.." "
        end
        if spellData.auraType == "debuff" then
            order = order + 1
            name = (pos.."|cff%s%s|r"):format("ff0000", name)
        else
            name = (pos.."|cff%s%s|r"):format("00ff00", name)
        end
        return name, order
    end
    local function createTraker(id)
        local spellData = trackingData[id]
        local spellOptions = auratracker.args.options
        local name, order = getNameOrder(spellData)

        return {
            name = name,
            type = "group",
            order = order,
            args = {
                name = {
                    name = L["AuraTrack_SpellNameID"],
                    desc = L["AuraTrack_NoteSpellID"],
                    type = "input",
                    validate = function(info, value)
                        debug("Validate Spellname", info[#info-1], spellOptions.args[info[#info-1]].name)
                        return _G.GetSpellInfo(value) and true or L["AuraTrack_InvalidName"]
                    end,
                    get = function(info) return tostring(spellData.spell) end,
                    set = function(info, value)
                        debug("Set Spellname", info[#info-1], spellOptions.args[info[#info-1]].name)
                        spellData.spell = value
                        spellOptions.args[info[#info-1]].name = value
                    end,
                    order = 10,
                },
                enable = {
                    name = L["General_Enabled"],
                    desc = L["General_EnabledDesc"]:format(L["AuraTrack_Selected"]),
                    type = "toggle",
                    get = function(info)
                        return not spellData.isDisabled
                    end,
                    set = function(info, value)
                        if spellData.isDisabled then
                            AuraTracking:EnableTracker(id)
                        else
                            AuraTracking:DisableTracker(id)
                        end
                    end,
                    order = 20,
                },
                type = {
                    name = L["AuraTrack_Type"],
                    desc = L["AuraTrack_TypeDesc"],
                    type = "select",
                    style = "radio",
                    values = function()
                        return {
                            buff = L["AuraTrack_Buff"],
                            debuff = L["AuraTrack_Debuff"],
                        }
                    end,
                    get = function(info)
                        return spellData.auraType or "buff"
                    end,
                    set = function(info, value)
                        spellData.auraType = value
                        
                        local spellOptions = spellOptions.args[info[#info-1]]
                        spellOptions.name, spellOptions.order = getNameOrder(spellData)
                    end,
                    order = 30,
                },
                position = {
                    name = L["General_Position"],
                    desc = L["AuraTrack_StaticDesc"],
                    type = "range",
                    min = 0, max = 6, step = 1,
                    get = function(info) return spellData.order or 0 end,
                    set = function(info, value)
                        spellData.order = value

                        local spellOptions = spellOptions.args[info[#info-1]]
                        spellOptions.name, spellOptions.order = getNameOrder(spellData)
                    end,
                    order = 40,
                },
                unit = {
                    name = L["AuraTrack_Unit"],
                    type = "select",
                    values = function()
                        return {
                            player = _G.PLAYER,
                            target = _G.TARGET,
                            pet = _G.PET,
                        }
                    end,
                    get = function(info)
                        return spellData.unit
                    end,
                    set = function(info, value)
                        spellData.unit = value
                    end,
                    order = 50,
                },
                useSpec = {
                    name = _G.SPECIALIZATION,
                    desc = L["General_Tristate"..tostring(spellData.useSpec)].."\n"..
                        L["AuraTrack_TristateSpec"..tostring(spellData.useSpec)],
                    type = "toggle",
                    tristate = true,
                    get = function(info)
                        return spellData.useSpec
                    end,
                    set = function(info, value)
                        local spellOptions = spellOptions.args[info[#info-1]].args
                        if value == false then
                            spellOptions.spec.type = "select"
                            spellOptions.spec.disabled = true
                        elseif value == true then
                            spellOptions.spec.disabled = false
                        else
                            spellOptions.spec.type = "multiselect"
                        end
                        spellOptions.useSpec.desc = L["General_Tristate"..tostring(value)].."\n"..
                            L["AuraTrack_TristateSpec"..tostring(value)]
                        spellData.useSpec = value
                    end,
                    order = 30,
                },
                spec = {
                    name = _G.SPECIALIZATION,
                    type = (spellData.useSpec == nil) and "multiselect" or "select",
                    disabled = function() return spellData.useSpec == false end,
                    values = function()
                        local table = {}
                        for i = 1, _G.GetNumSpecializations() do
                            local _, name = _G.GetSpecializationInfo(i)
                            table[i] = name
                        end
                        return table
                    end,
                    get = function(info, key, ...)
                        debug("Spec get", key, ...)
                        if key then
                            return spellData.specs[key]
                        else
                            for i = 1, #spellData.specs do
                                if spellData.specs[i] then
                                    return i
                                end
                            end
                        end
                    end,
                    set = function(info, key, value, ...)
                        debug("Spec set", key, value, ...)
                        spellData.specs[key] = value == nil and true or value
                    end,
                    order = 30,
                },
                remove = {
                    name = L["AuraTrack_Remove"],
                    type = "execute",
                    confirm = true,
                    confirmText = L["AuraTrack_RemoveConfirm"],
                    func = function(info, ...)
                        debug("Remove", info[#info], info[#info-1], ...)
                        debug("Removed ID", id, trackingData[id].spell)
                        tremove(trackingData, id)
                        nibRealUI:ReloadUIDialog()
                    end,
                    order = -1,
                },
            }
        }
    end
    auratracker = {
        name = L["AuraTrack"],
        type = "group",
        args = {
            new = {
                name = L["AuraTrack_Create"],
                type = "execute",
                func = function(info, ...)
                    debug("Create New", info[#info], info[#info-1], ...)
                    local id = AuraTracking:CreateNewTracker()
                    debug("New id:", id)
                    auratracker.args.options.args["spell"..id] = createTraker(id)
                end,
                order = 10,
            },
            enable = {
                name = L["General_Enabled"],
                desc = L["General_EnabledDesc"]:format(L["AuraTrack"]),
                type = "toggle",
                get = function(info) return nibRealUI:GetModuleEnabled("AuraTracking") end,
                set = function(info, value)
                    nibRealUI:SetModuleEnabled("AuraTracking", value)
                    nibRealUI:ReloadUIDialog()
                end,
                order = 20,
            },
            options = {
                name = L["AuraTrack_TrackerOptions"],
                type = "group",
                args = {
                    size = {
                        name = L["AuraTrack_Size"],
                        type = "range",
                        min = 24, max = 64, step = 1,
                        get = function(info) return db.style.slotSize end,
                        set = function(info, value)
                            db.style.slotSize = value
                        end,
                        order = 10,
                    },
                    padding = {
                        name = L["AuraTrack_Padding"],
                        type = "range",
                        min = 0, max = 32, step = 1,
                        get = function(info) return db.style.padding end,
                        set = function(info, value)
                            db.style.padding = value
                        end,
                        order = 20,
                    },
                    inactiveOpacity = {
                        name = L["AuraTrack_InactiveOpacity"],
                        type = "range",
                        isPercent = true,
                        min = 0, max = 1, step = 0.05,
                        get = function(info) return db.indicators.fadeOpacity end,
                        set = function(info, value)
                            db.indicators.fadeOpacity = value
                        end,
                        order = 30,
                    },
                    verticalCD = {
                        name = L["AuraTrack_VerticalCD"],
                        desc = L["AuraTrack_VerticalCDDesc"],
                        type = "toggle",
                        get = function(info) return db.indicators.useCustomCD end,
                        set = function(info, value)
                            db.indicators.useCustomCD = value
                        end,
                        order = 40,
                    },
                    visibility = {
                        name = L["AuraTrack_Visibility"],
                        type = "group",
                        inline = true,
                        args = {
                            showCombat = {
                                name = L["AuraTrack_ShowInCombat"],
                                desc = L["AuraTrack_ShowInCombatDesc"],
                                type = "toggle",
                                get = function(info) return db.visibility.showCombat end,
                                set = function(info, value)
                                    db.visibility.showCombat = value
                                end,
                                order = 10,
                            },
                            showHostile = {
                                name = L["AuraTrack_ShowHostile"],
                                desc = L["AuraTrack_ShowHostileDesc"],
                                type = "toggle",
                                get = function(info) return db.visibility.showHostile end,
                                set = function(info, value)
                                    db.visibility.showHostile = value
                                end,
                                order = 20,
                            },
                            showPvE = {
                                name = L["AuraTrack_ShowInPvE"],
                                desc = L["AuraTrack_ShowInPvEDesc"],
                                type = "toggle",
                                get = function(info) return db.visibility.showPvE end,
                                set = function(info, value)
                                    db.visibility.showPvE = value
                                end,
                                order = 30,
                            },
                            showPvP = {
                                name = L["AuraTrack_ShowInPvP"],
                                desc = L["AuraTrack_ShowInPvPDesc"],
                                type = "toggle",
                                get = function(info) return db.visibility.showPvP end,
                                set = function(info, value)
                                    db.visibility.showPvP = value
                                end,
                                order = 40,
                            },
                        }
                    }
                }
            }
        }
    }
    for id = 1, #trackingData do
        auratracker.args.options.args["spell"..id] = createTraker(id)
        --[[local type
        if spell.auraType == "debuff" then
            type = string.format("|cffff3030%s|r", L["AuraTrack_Debuff"])
        else
            type = string.format("|cff30ff30%s|r", L["AuraTrack_Buff"])
        end
        local spec
        if spell.forms then
            --
        elseif spell.specs then
            for i = 1, #spell.specs do
                if spell.specs[i] then
                    local _, name = _G.GetSpecializationInfo(i)
                    spec = spec and spec..", "..name or name
                end
            end
        else
            spec = _G.ACHIEVEMENTFRAME_FILTER_ALL
        end
        local row = table:AddRow(nil, spell.order or "~", type, GetSpellInfo(spell.spell), spec)
        row:SetHighlightTexture(C.media.backdrop)
        row:GetHighlightTexture():SetVertexColor(r, g, b, 0.5)]]
    end
end
options.HuD = {
    type = "group",
    args = {
        toggle = { -- This is for button creation
            name = L["HuD_ShowElements"],
            type = "group",
            args = {
            },
        },
        unitframes = unitframes,
        auratracker = auratracker,
        castbars = {
            name = L["HuD_CastBars"],
            type = "group",
            args = {
                enable = {
                    name = L["General_Enabled"],
                    desc = L["General_EnabledDesc"]:format(L["HuD_CastBars"]),
                    type = "toggle",
                    set = function(info,val) end,
                    get = function(info) return end
                },
            },
        },
        close = { -- This is for button creation
            name = CLOSE,
            type = "group",
            args = {
            },
        },
    }
}

options.RealUI = {
    type = "group",
    args = {
        enable = {
            name = "Enable",
            desc = "Enables / disables the addon",
            type = "toggle",
            set = function(info,val) end,
            get = function(info) end
        },
        moreoptions = {
            name = "More Options",
            type = "group",
            args = {
                -- more options go here
            }
        }
    }
}
