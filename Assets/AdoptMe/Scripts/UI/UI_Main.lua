--!Type(UI)

--!Bind
local MainContainer : VisualElement = nil
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

--!Bind
local CreateFamily : UIButton = nil
--!Bind
local Invite : UIButton = nil
--!Bind
local AcceptInvite : UIButton = nil
--!Bind
local LeaveFamily : UIButton = nil
--!Bind
local Button1Text : UILabel = nil
--!Bind
local Button2Text : UILabel = nil
--!Bind
local Button3Text : UILabel = nil
--!Bind
local Button4Text : UILabel = nil

local GameplayManager = require("GameplayManager")

function ParentButtonPressed()
    GameplayManager.ChangeRole(0)
    handlePanelState(ChoicePanel, false)
end
function BabyButtonPressed()
    GameplayManager.ChangeRole(1)
    handlePanelState(ChoicePanel, false)
end

function AddInvitePopup(player)
    print("clicked player", player.name)
end

function enableChoicePanel()
    --ChoicePanel.visible = true
end

function handlePanelState(panel, state)
    panel.visible = state
end

function CreateFamilyClicked()
    print("CreateFamilyClicked")
    GameplayManager.CreateFamilyFromClient("MyNewFamily")
    CreateFamily.visible = false
end

function InviteFamilyClicked()
    print("InviteFamilyClicked")
    GameplayManager.InviteFamilyFromClient("MyNewFamily")
    Invite.visible = false
end

function AcceptInviteClicked()
    print("AcceptInviteClicked")
    GameplayManager.AcceptInviteFromClient()
    AcceptInvite.visible = false
end

function LeaveFamilyClicked()
    print("LeaveFamilyClicked")
    GameplayManager.LeaveFamilyFromClient()
    LeaveFamily.visible = false
end

function SetInviteStateOpen(inviteTo)
    Button2Text:SetPrelocalizedText("Invite To Family : " .. inviteTo, false)
    Invite.visible = true
end

function SetAcceptInviteStateOpen(invitedBy, invitedToFamily)
    Button3Text:SetPrelocalizedText("Accept Invite from " .. invitedBy .. "To" .. invitedToFamily , false)
    AcceptInvite.visible = true
end

function SetLeaveStateOpen(familyName)
    Button4Text:SetPrelocalizedText("Leave " .. familyName, false)
    CreateFamily.visible = false
    LeaveFamily.visible = true
end

function SetCreateFamilyStateOpen()
    CreateFamily.visible = true
end

function self:ClientAwake()
    PanelTitle:SetPrelocalizedText("Choose a role :", false)
    B_Parent_Title:SetPrelocalizedText("Parent \n Adopt a Baby!", false)
    B_Baby_Title:SetPrelocalizedText("Baby \n Get Adopted!", false)
    B_Parent:RegisterPressCallback(ParentButtonPressed)
    B_Baby:RegisterPressCallback(BabyButtonPressed)
    handlePanelState(ChoicePanel, false)
    Button1Text:SetPrelocalizedText("CreateFamily", false)
    Button2Text:SetPrelocalizedText("Invite To Family", false)
    Button3Text:SetPrelocalizedText("AcceptInvite", false)
    Button4Text:SetPrelocalizedText("LeaveFamily", false)
    CreateFamily:RegisterPressCallback(CreateFamilyClicked)
    Invite:RegisterPressCallback(InviteFamilyClicked)
    AcceptInvite:RegisterPressCallback(AcceptInviteClicked)
    LeaveFamily:RegisterPressCallback(LeaveFamilyClicked)
    Invite.visible = false
    AcceptInvite.visible = false
    LeaveFamily.visible = false
end