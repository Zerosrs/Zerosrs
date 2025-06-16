-- Ice Memory Library v2.0
-- A Rayfield-inspired memory manipulation library for Cheat Engine Lua
-- Documentation: https://yourdocsite.com/ice

local Ice = {
    Version = "2.0.0",
    Configuration = {
        Theme = {
            BackgroundColor = Color.fromRGB(25, 25, 25),
            PrimaryColor = Color.fromRGB(0, 170, 255),
            SecondaryColor = Color.fromRGB(50, 50, 50),
            TextColor = Color.fromRGB(255, 255, 255),
            AccentColor = Color.fromRGB(0, 204, 0),
            ErrorColor = Color.fromRGB(255, 68, 68)
        },
        Window = {
            Width = 750,
            Height = 550,
            Transparency = 0.95,
            MinimizeKey = Enum.KeyCode.RightControl
        }
    },
    Loaded = false,
    Elements = {},
    Flags = {},
    Notifications = {}
}

-- Internal functions
local function CreateSignal()
    local bindable = Instance.new("BindableEvent")
    local signal = {}
    
    function signal:Connect(func)
        return bindable.Event:Connect(func)
    end
    
    function signal:Fire(...)
        bindable:Fire(...)
    end
    
    function signal:Wait()
        return bindable.Event:Wait()
    end
    
    return signal
end

local function Tween(instance, properties, duration, ...)
    local tweenInfo = TweenInfo.new(duration, ...)
    local tween = game:GetService("TweenService"):Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

-- Core library functions
function Ice.SetConfiguration(config)
    for category, settings in pairs(config) do
        if Ice.Configuration[category] then
            for key, value in pairs(settings) do
                Ice.Configuration[category][key] = value
            end
        end
    end
end

function Ice.Init(options)
    if Ice.Loaded then return Ice end
    
    options = options or {}
    Ice.SetConfiguration(options)
    
    -- Create main window
    Ice.MainWindow = {
        Instance = createForm(),
        Tabs = {},
        CurrentTab = nil
    }
    
    Ice.MainWindow.Instance.Caption = "Ice Memory Editor"
    Ice.MainWindow.Instance.Width = Ice.Configuration.Window.Width
    Ice.MainWindow.Instance.Height = Ice.Configuration.Window.Height
    Ice.MainWindow.Instance.Position = poScreenCenter
    Ice.MainWindow.Instance.Color = Ice.Configuration.Theme.BackgroundColor
    Ice.MainWindow.Instance.AlphaBlend = true
    Ice.MainWindow.Instance.AlphaBlendValue = Ice.Configuration.Window.Transparency * 255
    
    -- Create tab container
    local tabContainer = createPanel(Ice.MainWindow.Instance)
    tabContainer.Align = "alTop"
    tabContainer.Height = 40
    tabContainer.Color = Ice.Configuration.Theme.SecondaryColor
    
    -- Create content container
    Ice.ContentContainer = createPanel(Ice.MainWindow.Instance)
    Ice.ContentContainer.Align = "alClient"
    Ice.ContentContainer.Color = Ice.Configuration.Theme.BackgroundColor
    
    Ice.Loaded = true
    
    -- Set up minimize hotkey
    local minimized = false
    local originalHeight = Ice.MainWindow.Instance.Height
    
    Ice.MainWindow.Instance.OnKeyDown = function(sender, key)
        if key == VK_CONTROL then
            minimized = not minimized
            if minimized then
                Ice.MainWindow.Instance.Height = 40
            else
                Ice.MainWindow.Instance.Height = originalHeight
            end
        end
    end
    
    return Ice
end

-- Window functions
function Ice:CreateWindow(options)
    return Ice.Init(options)
end

function Ice:CreateTab(name, icon)
    local tabButton = createButton(self.MainWindow.TabsPanel)
    tabButton.Caption = name
    tabButton.Width = 100
    tabButton.Height = 30
    tabButton.Color = Ice.Configuration.Theme.SecondaryColor
    tabButton.Font.Color = Ice.Configuration.Theme.TextColor
    
    local tabContent = createPanel(Ice.ContentContainer)
    tabContent.Visible = false
    tabContent.Align = "alClient"
    tabContent.Color = Ice.Configuration.Theme.BackgroundColor
    
    local tab = {
        Name = name,
        Button = tabButton,
        Content = tabContent,
        Sections = {}
    }
    
    table.insert(self.MainWindow.Tabs, tab)
    
    if #self.MainWindow.Tabs == 1 then
        self:SwitchTab(tab)
    end
    
    tabButton.OnClick = function()
        self:SwitchTab(tab)
    end
    
    return {
        CreateSection = function(options)
            return self:CreateSection(tab, options)
        end
    }
end

function Ice:SwitchTab(tab)
    if self.MainWindow.CurrentTab then
        self.MainWindow.CurrentTab.Content.Visible = false
        self.MainWindow.CurrentTab.Button.Color = Ice.Configuration.Theme.SecondaryColor
    end
    
    self.MainWindow.CurrentTab = tab
    tab.Content.Visible = true
    tab.Button.Color = Ice.Configuration.Theme.PrimaryColor
end

-- Section functions
function Ice:CreateSection(tab, options)
    options = options or {}
    
    local sectionFrame = createPanel(tab.Content)
    sectionFrame.Align = "alTop"
    sectionFrame.Height = options.Height or 100
    sectionFrame.Color = Ice.Configuration.Theme.SecondaryColor
    sectionFrame.BorderStyle = bsNone
    
    local sectionTitle = createLabel(sectionFrame)
    sectionTitle.Caption = options.Name or "Section"
    sectionTitle.Align = "alTop"
    sectionTitle.Height = 20
    sectionTitle.Font.Color = Ice.Configuration.Theme.TextColor
    sectionTitle.Font.Size = 12
    
    local sectionContent = createPanel(sectionFrame)
    sectionContent.Align = "alClient"
    sectionContent.Color = Ice.Configuration.Theme.SecondaryColor
    sectionContent.Padding = {Left = 10, Top = 5, Right = 10, Bottom = 5}
    
    local section = {
        Frame = sectionFrame,
        Title = sectionTitle,
        Content = sectionContent,
        Elements = {}
    }
    
    table.insert(tab.Sections, section)
    
    return {
        CreateLabel = function(options)
            return self:CreateLabel(section, options)
        end,
        CreateButton = function(options)
            return self:CreateButton(section, options)
        end,
        CreateToggle = function(options)
            return self:CreateToggle(section, options)
        end,
        CreateSlider = function(options)
            return self:CreateSlider(section, options)
        end,
        CreateCheat = function(options)
            return self:CreateCheat(section, options)
        end,
        CreateKeybind = function(options)
            return self:CreateKeybind(section, options)
        end,
        CreateDropdown = function(options)
            return self:CreateDropdown(section, options)
        end,
        CreateInput = function(options)
            return self:CreateInput(section, options)
        end
    }
end

-- Element creation functions
function Ice:CreateLabel(section, options)
    options = options or {}
    
    local label = createLabel(section.Content)
    label.Caption = options.Text or "Label"
    label.Font.Color = options.Color or Ice.Configuration.Theme.TextColor
    label.Font.Size = options.Size or 12
    label.Align = options.Align or "alTop"
    label.Height = options.Height or 20
    
    if options.Wrap then
        label.WordWrap = true
    end
    
    table.insert(section.Elements, label)
    
    return {
        Set = function(text)
            label.Caption = text
        end,
        Update = function(newOptions)
            if newOptions.Text then label.Caption = newOptions.Text end
            if newOptions.Color then label.Font.Color = newOptions.Color end
            if newOptions.Size then label.Font.Size = newOptions.Size end
        end
    }
end

function Ice:CreateButton(section, options)
    options = options or {}
    
    local button = createButton(section.Content)
    button.Caption = options.Text or "Button"
    button.Font.Color = Ice.Configuration.Theme.TextColor
    button.Align = options.Align or "alTop"
    button.Height = options.Height or 30
    button.Color = Ice.Configuration.Theme.SecondaryColor
    
    local hoverColor = Color.ToColor3(Ice.Configuration.Theme.PrimaryColor):Lerp(
        Color3.new(1, 1, 1), 0.2
    )
    
    button.OnMouseEnter = function()
        button.Color = hoverColor
    end
    
    button.OnMouseLeave = function()
        button.Color = Ice.Configuration.Theme.SecondaryColor
    end
    
    local callback = options.Callback or function() end
    button.OnClick = callback
    
    table.insert(section.Elements, button)
    
    return {
        Set = function(text)
            button.Caption = text
        end,
        OnClick = function(newCallback)
            button.OnClick = newCallback
        end,
        Update = function(newOptions)
            if newOptions.Text then button.Caption = newOptions.Text end
            if newOptions.Callback then button.OnClick = newOptions.Callback end
        end
    }
end

function Ice:CreateToggle(section, options)
    options = options or {}
    
    local container = createPanel(section.Content)
    container.Align = "alTop"
    container.Height = 30
    container.Color = Ice.Configuration.Theme.SecondaryColor
    
    local label = createLabel(container)
    label.Caption = options.Text or "Toggle"
    label.Font.Color = Ice.Configuration.Theme.TextColor
    label.Align = "alLeft"
    label.Width = 200
    
    local toggleFrame = createPanel(container)
    toggleFrame.Width = 50
    toggleFrame.Height = 20
    toggleFrame.Align = "alRight"
    toggleFrame.Color = options.Default and Ice.Configuration.Theme.AccentColor 
        or Ice.Configuration.Theme.SecondaryColor
    toggleFrame.BorderColor = Ice.Configuration.Theme.PrimaryColor
    toggleFrame.BorderWidth = 1
    
    local toggleKnob = createPanel(toggleFrame)
    toggleKnob.Width = 16
    toggleKnob.Height = 16
    toggleKnob.Color = Ice.Configuration.Theme.TextColor
    toggleKnob.Position = options.Default and "poRight" or "poLeft"
    
    local state = options.Default or false
    local callback = options.Callback or function() end
    
    local function UpdateToggle()
        if state then
            toggleFrame.Color = Ice.Configuration.Theme.AccentColor
            toggleKnob.Position = "poRight"
        else
            toggleFrame.Color = Ice.Configuration.Theme.SecondaryColor
            toggleKnob.Position = "poLeft"
        end
        callback(state)
    end
    
    toggleFrame.OnClick = function()
        state = not state
        UpdateToggle()
    end
    
    table.insert(section.Elements, container)
    
    return {
        GetState = function()
            return state
        end,
        SetState = function(newState)
            state = newState
            UpdateToggle()
        end,
        Toggle = function()
            state = not state
            UpdateToggle()
        end,
        OnChanged = function(newCallback)
            callback = newCallback
        end
    }
end

-- Cheat-specific functions
function Ice:CreateCheat(section, options)
    options = options or {}
    
    if not options.Name or not options.SearchPattern or not options.ReplacePattern then
        error("Cheat requires Name, SearchPattern, and ReplacePattern")
    end
    
    local container = createPanel(section.Content)
    container.Align = "alTop"
    container.Height = 40
    container.Color = Ice.Configuration.Theme.SecondaryColor
    
    local label = createLabel(container)
    label.Caption = options.Name
    label.Font.Color = Ice.Configuration.Theme.TextColor
    label.Align = "alLeft"
    label.Width = 200
    
    local statusLabel = createLabel(container)
    statusLabel.Caption = "Not scanned"
    statusLabel.Font.Color = Ice.Configuration.Theme.TextColor
    statusLabel.Align = "alRight"
    statusLabel.Width = 100
    
    local scanButton = createButton(container)
    scanButton.Caption = "Scan"
    scanButton.Align = "alRight"
    scanButton.Width = 80
    scanButton.Color = Ice.Configuration.Theme.SecondaryColor
    scanButton.Font.Color = Ice.Configuration.Theme.TextColor
    
    local toggle = self:CreateToggle({
        Text = "",
        Default = false,
        Callback = function(state)
            if state then
                if not self:MemoryScan(options.Name, options.SearchPattern) then
                    statusLabel.Caption = "Not found"
                    statusLabel.Font.Color = Ice.Configuration.Theme.ErrorColor
                    return false
                end
                
                if self:ReplaceBytes(options.Name, options.SearchPattern, options.ReplacePattern) then
                    statusLabel.Caption = "Active"
                    statusLabel.Font.Color = Ice.Configuration.Theme.AccentColor
                    return true
                else
                    statusLabel.Caption = "Error"
                    statusLabel.Font.Color = Ice.Configuration.Theme.ErrorColor
                    return false
                end
            else
                if self:ReplaceBytes(options.Name, options.ReplacePattern, options.SearchPattern) then
                    statusLabel.Caption = "Found"
                    statusLabel.Font.Color = Ice.Configuration.Theme.TextColor
                    return true
                else
                    statusLabel.Caption = "Error"
                    statusLabel.Font.Color = Ice.Configuration.Theme.ErrorColor
                    return false
                end
            end
        end
    })
    
    scanButton.OnClick = function()
        if self:MemoryScan(options.Name, options.SearchPattern) then
            statusLabel.Caption = "Found"
            statusLabel.Font.Color = Ice.Configuration.Theme.TextColor
        else
            statusLabel.Caption = "Not found"
            statusLabel.Font.Color = Ice.Configuration.Theme.ErrorColor
        end
    end
    
    table.insert(section.Elements, container)
    
    return {
        Scan = function()
            scanButton.OnClick()
        end,
        Enable = function()
            toggle.SetState(true)
        end,
        Disable = function()
            toggle.SetState(false)
        end,
        Toggle = function()
            toggle.Toggle()
        end
    }
end

-- Memory manipulation functions
function Ice:MemoryScan(key, pattern)
    if not pattern or type(pattern) ~= "string" or #pattern == 0 then return false end
    
    local aob = AOBScan(pattern)
    if aob and aob.Count > 0 then
        self.CachedAddresses = self.CachedAddresses or {}
        self.CachedAddresses[key] = {}
        
        for i = 0, aob.Count - 1 do
            table.insert(self.CachedAddresses[key], aob[i])
        end
        
        aob.Destroy()
        return true
    else
        self.CachedAddresses[key] = nil
        if aob then aob.Destroy() end
        return false
    end
end

function Ice:ReplaceBytes(key, from, to)
    if not from or not to then return false end
    
    local addresses = self.CachedAddresses and self.CachedAddresses[key]
    if not addresses or #addresses == 0 then return false end

    local success = true
    for _, addr in ipairs(addresses) do
        local addressNum = type(addr) == "string" and tonumber(addr, 16) or addr
        if not autoAssemble(string.format("%X:\ndb %s\n", addressNum, to)) then
            success = false
        end
    end
    
    return success
end

function Ice:MemoryMatches(key, pattern)
    if not pattern then return false end
    
    local addresses = self.CachedAddresses and self.CachedAddresses[key]
    if not addresses or #addresses == 0 then return false end

    local expected = {}
    for byte in string.gmatch(pattern, "[^%s]+") do
        table.insert(expected, byte)
    end
    
    if #expected == 0 then return false end

    for _, addr in ipairs(addresses) do
        local current = readBytes(addr, #expected, true)
        if not current then return false end

        for i = 1, #expected do
            if expected[i] ~= "??" and string.format("%02X", current[i]) ~= expected[i]:upper() then
                return false
            end
        end
    end
    
    return true
end

-- Utility functions
function Ice:CreateNotification(options)
    options = options or {}
    
    local notification = createPanel(self.MainWindow.Instance)
    notification.Width = 300
    notification.Height = 60
    notification.Color = options.Type == "error" and Ice.Configuration.Theme.ErrorColor
        or Ice.Configuration.Theme.PrimaryColor
    notification.Position = "poScreenCenter"
    notification.AlphaBlend = true
    notification.AlphaBlendValue = 220
    
    local title = createLabel(notification)
    title.Caption = options.Title or "Notification"
    title.Font.Color = Ice.Configuration.Theme.TextColor
    title.Align = "alTop"
    title.Height = 20
    
    local message = createLabel(notification)
    message.Caption = options.Message or ""
    message.Font.Color = Ice.Configuration.Theme.TextColor
    message.Align = "alClient"
    message.WordWrap = true
    
    table.insert(self.Notifications, notification)
    
    delay(options.Duration or 5, function()
        notification.Visible = false
        notification.Destroy()
    end)
    
    return {
        Extend = function(additionalTime)
            options.Duration = (options.Duration or 5) + additionalTime
        end,
        Dismiss = function()
            notification.Visible = false
            notification.Destroy()
        end
    }
end

function Ice:Destroy()
    if self.MainWindow and self.MainWindow.Instance then
        self.MainWindow.Instance.Destroy()
    end
    self.Loaded = false
end

return Ice
