<# :
@echo off
powershell -ExecutionPolicy Bypass -WindowStyle Hidden -Command "IEX (Get-Content '%~f0' | Out-String)"
exit /b
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object Windows.Forms.Form
$form.Text = "B384"
$form.Size = New-Object Drawing.Size(500, 680)
$form.StartPosition = "CenterScreen"

$panel = New-Object Windows.Forms.FlowLayoutPanel
$panel.Location = "20, 50"; $panel.Size = "440, 420"; $panel.AutoScroll = $true; $panel.BorderStyle = "FixedSingle"
$form.Controls.Add($panel)

$items = @("System Uptime", "Battery Health", "Battery Percent", "Battery Status", "CPU Name", "CPU GHz", "RAM Amount", "Ram Used", "Ram Available", "Type of RAM", "Motherboard Name", "Amount of Screens", "Screen Resolution", "Time", "Date", "Version of Windows", "CPU Temp", "GPU Temp", "Total Storage", "Type of Storage", "Free Space", "Used Space", "Fan Speed")
$checkBoxes = @{}
foreach ($item in $items) {
    $cb = New-Object Windows.Forms.CheckBox
    $cb.Text = $item; $cb.Width = 180; $cb.Checked = $true
    $panel.Controls.Add($cb); $checkBoxes[$item] = $cb
}

$exportBtn = New-Object Windows.Forms.Button
$exportBtn.Text = "FORCE EXPORT"; $exportBtn.Location = "150, 485"; $exportBtn.Size = "200, 45"; $exportBtn.BackColor = "AliceBlue"
$form.Controls.Add($exportBtn)

$exportBtn.Add_Click({
    $report = New-Object System.Collections.Generic.List[string]
    $report.Add("Z736 Summary")
    $report.Add("------------------------------------------")

    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    $cpu = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue
    $batt = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue
    $drive = Get-PSDrive C -ErrorAction SilentlyContinue
    $mem = Get-CimInstance Win32_PhysicalMemory -ErrorAction SilentlyContinue | Select-Object -First 1

    if ($checkBoxes["System Uptime"].Checked) { $report.Add("1. Uptime: $(((Get-Date) - $os.LastBootUpTime).ToString('dd\.hh\:mm'))") }
    if ($checkBoxes["CPU Name"].Checked) { $report.Add("5. CPU: $($cpu.Name)") }
    if ($checkBoxes["CPU GHz"].Checked) { $report.Add("6. Speed: $([Math]::Round($cpu.MaxClockSpeed/1000, 2)) GHz") }
    
    $total = [Math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $free = [Math]::Round($os.FreePhysicalMemory / 1MB, 2)
    if ($checkBoxes["RAM Amount"].Checked) { $report.Add("7. RAM Total: $total GB") }
    if ($checkBoxes["Ram Used"].Checked) { $report.Add("8. RAM Used: $([Math]::Round($total-$free, 2)) GB") }

    if ($checkBoxes["Total Storage"].Checked) { $report.Add("19. Storage Total: $([Math]::Round(($drive.Used + $drive.Free) / 1GB, 2)) GB") }
    if ($checkBoxes["Free Space"].Checked) { $report.Add("21. Storage Free: $([Math]::Round($drive.Free / 1GB, 2)) GB") }

    if ($checkBoxes["Time"].Checked) { $report.Add("14. Time: $(Get-Date -Format 'HH:mm:ss')") }
    if ($checkBoxes["Date"].Checked) { $report.Add("15. Date: $(Get-Date -Format 'yyyy-MM-dd')") }

    if ($report.Count -le 2) { $report.Add("ERROR: Could not fetch data. Try Running as Admin.") }

    $desktop = [Environment]::GetFolderPath("Desktop")
    $filePath = Join-Path $desktop "Z736_summary.txt"
    
    try {
        $report | Out-File -FilePath $filePath -Encoding utf8 -Force
        [System.Windows.Forms.MessageBox]::Show("Saved to Desktop!", "Success")
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to write file: $($_.Exception.Message)", "Error")
    }
})

$form.ShowDialog()