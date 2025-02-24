
local noteMat = Material("echoesbeyond/note_simple.png", "smooth")
local mapMat = Material("echoesbeyond/map.png", "smooth")
local settingsMat = Material("echoesbeyond/settings.png", "smooth")
local reportMat = Material("echoesbeyond/report.png", "smooth")
local vignette = Material("echoesbeyond/vignette.png", "smooth")

-- The main menu
hook.Add("ScoreboardShow", "mainmenu_ScoreboardShow", function()
	if (IsValid(mainMenu)) then
		mainMenu:Remove()
	end

	local width, height = ScrW() / 2.5, ScrH() / 2

	mainMenu = vgui.Create("DPanel")
	mainMenu:SetSize(width, height)
	mainMenu:Center()
	mainMenu:MakePopup()
	mainMenu:SetAlpha(0)
	mainMenu:AlphaTo(255, 0.5)

	LocalPlayer():EmitSound("echoesbeyond/whoosh.wav", 75, 100, 0.75)

	mainMenu.Paint = function(self, width, height)
		surface.SetDrawColor(25, 25, 25)
		surface.DrawRect(0, 0, width, height)

		surface.SetMaterial(vignette)
		surface.DrawTexturedRect(0, 0, width, height)

		local breatheLayer = math.sin(CurTime() * 1.5)

		surface.SetDrawColor(255, 255, 255, 5)
		surface.SetMaterial(noteMat)
		surface.DrawTexturedRectRotated(width / 2, height / 2 + 5 * breatheLayer, height / 1.5, height / 1.5, 0)
	end

	mainMenu.OnKeyCodePressed = function(self, key)
		if (key != KEY_TAB) then return end

		self:Close()
	end

	mainMenu.Close = function(self)
		self:AlphaTo(0, 0.25, 0, function()
			self:Remove()
		end)

		if (IsValid(mapMenu)) then
			mapMenu:Close(true)
		end

		if (IsValid(settingsMenu)) then
			settingsMenu:Close(true)
		end

		LocalPlayer():EmitSound("echoesbeyond/whoosh.wav", 75, 90, 0.75)

		self:SetKeyboardInputEnabled(false)
		self:SetMouseInputEnabled(false)
	end

	local title = vgui.Create("DLabel", mainMenu)
	title:SetText("Echoes Beyond")
	title:SetFont("DermaLarge")
	title:SizeToContents()
	title:CenterHorizontal()
	title:SetY(20)

	local subTitle = vgui.Create("DLabel", mainMenu)
	subTitle:SetText("- A cinematic thought experiment -")
	subTitle:SizeToContents()
	subTitle:CenterHorizontal()
	subTitle:SetY(55)

	local mapOption = vgui.Create("DButton", mainMenu)
	mapOption:SetSize(48, 48)
	mapOption:SetPos(10, 10)
	mapOption:SetText("")
	mapOption.Paint = function(self, width, height)
		surface.SetDrawColor(self:IsDown() and Color(100, 100, 100) or self:IsHovered() and Color(75, 75, 75) or Color(50, 50, 50))
		surface.SetMaterial(mapMat)
		surface.DrawTexturedRect(0, 0, width, height)
	end
	mapOption.DoClick = function()
		LocalPlayer():EmitSound("echoesbeyond/button_click.wav", 75, math.random(95, 105))

		if (IsValid(mapMenu)) then
			mapMenu:Close()
		else
			vgui.Create("echoMapMenu")
		end
	end

	local settingsOption = vgui.Create("DButton", mainMenu)
	settingsOption:SetSize(48, 48)
	settingsOption:SetPos(width - 48 - 10, 10)
	settingsOption:SetText("")
	settingsOption.Paint = function(self, width, height)
		surface.SetDrawColor(self:IsDown() and Color(100, 100, 100) or self:IsHovered() and Color(75, 75, 75) or Color(50, 50, 50))
		surface.SetMaterial(settingsMat)
		surface.DrawTexturedRect(0, 0, width, height)
	end
	settingsOption.DoClick = function()
		LocalPlayer():EmitSound("echoesbeyond/button_click.wav", 75, math.random(95, 105))

		if (IsValid(reportMenu)) then reportMenu:Close() end

		if (IsValid(settingsMenu)) then
			settingsMenu:Close()
		else
			vgui.Create("echoSettingsMenu")
		end
	end

	local reportOption = vgui.Create("DButton", mainMenu)
	reportOption:SetSize(48, 48)
	reportOption:SetPos(width - 48 - 10, 48 + 20)
	reportOption:SetText("")
	reportOption.Paint = function(self, width, height)
		surface.SetDrawColor(self:IsDown() and Color(100, 100, 100) or self:IsHovered() and Color(75, 75, 75) or Color(50, 50, 50))
		surface.SetMaterial(reportMat)
		surface.DrawTexturedRect(0, 0, width, height)
	end
	reportOption.DoClick = function()
		LocalPlayer():EmitSound("echoesbeyond/button_click.wav", 75, math.random(95, 105))

		if (IsValid(settingsMenu)) then settingsMenu:Close() end

		if (IsValid(reportMenu)) then
			reportMenu:Close()
		else
			vgui.Create("echoReportMenu")
		end
	end

	local maps = {}
	local ownMapCount = 0
	local writtenNotes = file.Read("echoesbeyond/writtennotes.txt", "DATA")
	writtenNotes = util.JSONToTable(writtenNotes and writtenNotes != "" and writtenNotes or "[]")

	for i = 1, #writtenNotes do
		local map = writtenNotes[i].map
		if (maps[map]) then continue end

		maps[map] = true
	end

	ownMapCount = table.Count(maps)

	local noteCount = #notes

	local currCountLabel = vgui.Create("DLabel", mainMenu)
	currCountLabel:SetText("There " .. (noteCount == 1 and "is" or "are") .. " currently " .. noteCount .. " echo" .. (noteCount == 1 and "" or "es") .. " on this map. You have read " .. expiredNoteCount .. " of them.")
	currCountLabel:SizeToContents()
	currCountLabel:CenterHorizontal()
	currCountLabel:SetY(height - 70)

	local personalCountLabel = vgui.Create("DLabel", mainMenu)
	personalCountLabel:SetText("You have written " .. #writtenNotes .. " echo" .. (#writtenNotes == 1 and "" or "es") .. " across " .. ownMapCount .. (ownMapCount == 1 and " map." or " different maps."))
	personalCountLabel:SizeToContents()
	personalCountLabel:CenterHorizontal()
	personalCountLabel:SetY(height - 50)

	local totalCountLabel = vgui.Create("DLabel", mainMenu)
	totalCountLabel:SetText("There are currently " .. globalNoteCount .. " total echoes across " .. mapCount .. " different maps.")
	totalCountLabel:SizeToContents()
	totalCountLabel:CenterHorizontal()
	totalCountLabel:SetY(height - 30)
end)

-- Close when pressing escape
hook.Add("OnPauseMenuShow", "mainmenu_OnPauseMenuShow", function()
	if (!IsValid(mainMenu)) then return end

	mainMenu:Close()

	return false
end)

hook.Add("HUDPaint", "mainmenu_HUDPaint", function()
	if (!IsValid(mainMenu)) then return end
	local alpha = mainMenu:GetAlpha()

	surface.SetDrawColor(25, 25, 25, 200 * (alpha / 255))
	surface.DrawRect(0, 0, ScrW(), ScrH())
end)
