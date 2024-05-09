--!Type(UI)

--!Bind
local MainContainer : VisualElement = nil
--!Bind
local ChoicePanelContainer : VisualElement = nil
--!Bind
local ChoicePanel : VisualElement = nil
--!Bind
local PanelTitle : UILabel = nil
--!Bind
local ButtonContainer : VisualElement = nil
--!Bind
local B_Parent : UIButton = nil
--!Bind
local B_Parent_Title : UILabel = nil
--!Bind
local B_Baby : UIButton = nil
--!Bind
local B_Baby_Title : UILabel = nil

local GameplayManager = require("GameplayManager")

function ParentButtonPressed()
    GameplayManager.ChangeRole(0)
    handlePanelState(ChoicePanelContainer, false)
end
function BabyButtonPressed()
    GameplayManager.ChangeRole(1)
    handlePanelState(ChoicePanelContainer, false)
end

function enableChoicePanel()
    ChoicePanelContainer.visible = true
end

function handlePanelState(panel, state)
    panel.visible = state
end

function self:ClientAwake()
    PanelTitle:SetPrelocalizedText("Choose a role :", false)
    B_Parent_Title:SetPrelocalizedText("Parent \n Adopt a Baby!", false)
    B_Baby_Title:SetPrelocalizedText("Baby \n Get Adopted!", false)
    B_Parent:RegisterPressCallback(ParentButtonPressed)
    B_Baby:RegisterPressCallback(BabyButtonPressed)
    handlePanelState(ChoicePanelContainer, false)
end