
CreateClientConVar("echoes_personalshowall", "0")

local vignette = Material("echoesbeyond/vignette.png", "smooth")
local deleteMat = Material("echoesbeyond/trash.png", "smooth")

-- The personal echoes menu
local PANEL = {}

function PANEL:Init()
	if (IsValid(personalEchoesMenu)) then
		personalEchoesMenu:Remove()
	end

	personalEchoesMenu = self

	self.echoList = {}
	self.deleting = false

	self:SetSize(ScrW() / 4, ScrH() / 1.5)
	self:Center()
	self:SetX(mainMenu:GetX() - self:GetWide() - 10)
	self:MakePopup()
	self:SetAlpha(0)

	self:AlphaTo(255, 0.25, 0)
	EchoSound("whoosh", nil, 0.75)

	local title = vgui.Create("DLabel", self)
	title:SetText("Personal Echoes")
	title:SetFont("DermaLarge")
	title:SizeToContents()
	title:CenterHorizontal()
	title:SetY(20)

	local subTitle = vgui.Create("DLabel", self)
	subTitle:SetText("View & Delete your written Echoes here. (Press R to write an Echo)")
	subTitle:SizeToContents()
	subTitle:CenterHorizontal()
	subTitle:SetY(55)

	local subSubTitle = vgui.Create("DLabel", self)
	subSubTitle:SetText("Deleting Echoes decreases the cooldown for the map they are on.")
	subSubTitle:SizeToContents()
	subSubTitle:CenterHorizontal()
	subSubTitle:SetY(75)

	local conVar = GetConVar("echoes_personalshowall")

	self.showAll = vgui.Create("DCheckBoxLabel", self)
	self.showAll:SetText("Show all Echoes (Not just map-specific)")
	self.showAll:SetValue(conVar:GetBool())
	self.showAll:SizeToContents()
	self.showAll:SetPos(15, 100)
	self.showAll.OnChange = function(this, value)
		self:ListEchoes(self.searchBar:GetValue())

		conVar:SetBool(value)
	end

	self.searchBar = vgui.Create("DTextEntry", self)
	self.searchBar:SetSize(self:GetWide() - 20, 20)
	self.searchBar:SetPos(10, 125)
	self.searchBar:SetPlaceholderText("Search for an Echo...")
	self.searchBar.OnChange = function(this)
		local search = this:GetValue():lower()

		self:ListEchoes(search)
	end
	self.searchBar.Paint = function(this, width, height)
		surface.SetDrawColor(50, 50, 50)
		surface.DrawRect(0, 0, width, height)

		this:DrawTextEntryText(color_white, color_white, color_white)
	end

	self.searchBar:RequestFocus()

	self.echoContainer = vgui.Create("DScrollPanel", self)
	self.echoContainer:SetPos(10, 155)
	self.echoContainer:SetSize(self:GetWide() - 20, self:GetTall() - 165)
	self.echoContainer.Paint = function(this, width, height)
		surface.SetDrawColor(0, 0, 0, 100)
		surface.DrawRect(0, 0, this:GetWide(), this:GetTall())
	end
	self.echoContainer.VBar.Paint = function(this, width, height)
		surface.SetDrawColor(35, 35, 35)
		surface.DrawRect(0, 0, this:GetWide(), this:GetTall())
	end
	self.echoContainer.VBar.btnGrip.Paint = function(this, width, height)
		surface.SetDrawColor(45, 45, 45)
		surface.DrawRect(0, 0, self.echoContainer.VBar.btnGrip:GetWide(), self.echoContainer.VBar.btnGrip:GetTall())
	end
	self.echoContainer.VBar.btnUp.Paint = function() end
	self.echoContainer.VBar.btnDown.Paint = function() end

	self:ListEchoes()
end

function PANEL:ListEchoes(filter)
	for _, entry in pairs(self.echoList) do
		entry:Remove()
	end

	self.echoList = {}

	if (filter) then
		filter = filter:Trim()
		filter = filter != "" and filter
	end

	local currMap = game.GetMap()
	local echoNum = 1

	for i = #writtenEchoes, 1, -1 do -- Loop through the echoes in reverse order
		local echo = writtenEchoes[i]

		if (filter and !echo.comment:lower():find(filter:lower())) then continue end
		if (echo.map != currMap and !self.showAll:GetChecked()) then continue end

		local basePanel = vgui.Create("DPanel", self.echoContainer)
		basePanel:Dock(TOP)
		basePanel:SetTall(80)
		basePanel:DockMargin(0, 0, 10, 10)
		basePanel.Paint = function(this, width, height)
			surface.SetDrawColor(30, 30, 30)
			surface.DrawRect(0, 0, width, height)
		end

		local mapLabel = vgui.Create("DLabel", basePanel)
		mapLabel:SetPos(5, 3)
		mapLabel:SetText(echo.map)
		mapLabel:SetFont("TargetID")
		mapLabel:SetTextColor(Color(200, 200, 200))
		mapLabel:SizeToContents()
		mapLabel:SetContentAlignment(4)

		local echoText = vgui.Create("DTextEntry", basePanel)
		echoText:SetSize(self.echoContainer:GetWide() - 30, basePanel:GetTall())
		echoText:SetPos(3, 30)
		echoText:SetText(echo.comment)
		echoText:SetMultiline(true)
		echoText:SetEditable(false)
		echoText:SetDrawBackground(false)
		echoText:SetTextColor(Color(200, 200, 200))
		echoText:SetPaintBackground(false)

		-- Don't ask
		local barEnabled = self.echoContainer.VBar.Enabled

		if (self.deleting) then
			barEnabled = !barEnabled
		end

		local deleteButton = vgui.Create("DButton", basePanel)
		deleteButton:SetSize(20, 20)
		deleteButton:SetPos(self.echoContainer:GetWide() - (barEnabled and 35 or 50), 5)
		deleteButton:SetText("")
		deleteButton.Paint = function(this, width, height)
			surface.SetDrawColor(this:IsDown() and Color(125, 125, 125) or this:IsHovered() and Color(100, 100, 100) or Color(75, 75, 75))
			surface.SetMaterial(deleteMat)
			surface.DrawTexturedRect(0, 0, width, height)
		end
		deleteButton.DoClick = function(this)
			EchoSound("button_click")

			EchoesConfirm("Delete Echo", "Are you sure you want to delete this Echo? This action is irreversible.", function()
				http.Fetch("https://resonance.flatgrass.net/note/delete?id=" .. echo.id, function(body, _, _, code)
					if (code != 200) then
						EchoNotify("RESONANCE ERROR: " .. string.sub(body, 1, -2))

						return
					end

					table.remove(writtenEchoes, i) -- Remove the echo from the written echoes table

					-- Remove the echo from the world
					for k = 1, #echoes do
						if (echoes[k].id != echo.id) then continue end

						table.remove(echoes, k)

						break
					end

					self.deleting = true
					self:ListEchoes(self.searchBar:GetValue())

					EchoNotify("Echo deleted successfully.")
				end, function(error)
					EchoNotify(error)
				end, {authorization = authToken})
			end)
		end

		basePanel:SetAlpha(0)
		basePanel:AlphaTo(255, 0.25, 0.05 * echoNum)
		self.echoList[#self.echoList + 1] = basePanel

		echoNum = echoNum + 1
	end

	self.deleting = false
end

function PANEL:Paint(width, height)
	surface.SetDrawColor(25, 25, 25)
	surface.DrawRect(0, 0, width, height)

	surface.SetMaterial(vignette)
	surface.DrawTexturedRect(0, 0, width, height)
end

function PANEL:OnKeyCodePressed(key)
	if (key != KEY_TAB) then return end

	self:Close()
end

function PANEL:Close(bNoSound)
	self:AlphaTo(0, 0.25, 0, function()
		self:Remove()
	end)

	if (bNoSound) then return end
	EchoSound("whoosh", 90, 0.75)
end

vgui.Register("echoPersonalEchoesMenu", PANEL, "EditablePanel")

-- Close when pressing escape
hook.Add("OnPauseMenuShow", "personalechoes_OnPauseMenuShow", function()
	if (!IsValid(personalEchoesMenu)) then return end

	personalEchoesMenu:Close()

	return false
end)
