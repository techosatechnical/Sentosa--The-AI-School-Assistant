param(
    [int]$ParentPid = 0
)

Add-Type -AssemblyName System.Speech
try {
    $recognizer = [System.Speech.Recognition.SpeechRecognitionEngine]::InstalledRecognizers() | Where-Object { $_.Culture.Name -like "en-*" } | Select-Object -First 1
    if ($recognizer) {
        $sre = New-Object System.Speech.Recognition.SpeechRecognitionEngine($recognizer)
        $targetCulture = $recognizer.Culture
    }
    else {
        $sre = New-Object System.Speech.Recognition.SpeechRecognitionEngine
        $targetCulture = [System.Globalization.CultureInfo]::GetCultureInfo("en-US")
    }

    $choices = New-Object System.Speech.Recognition.Choices
    $choices.Add([string[]]@(
            "Nira", "Hey Nira", "Hi Nira", "Hello Nira", "OK Nira", "Hey Nire",
            "Hi Nire", "Hello Nire", "OK Nire",
            "Hey Neera", "Hi Neera", "Hello Neera", "OK Neera",
            "Hey Meera", "Hi Meera", "Hello Meera",
            "Hey Mira", "Hi Mira", "Hello Mira",
            "Nira Stop", "Stop Nira", "Cancel Nira", "Nira Cancel",
            "Nira Admission", "Admission", "Admissions", "Admission procedure", "Start admission"
        ))
    $gb = New-Object System.Speech.Recognition.GrammarBuilder($choices)
    $gb.Culture = $targetCulture
    $g = New-Object System.Speech.Recognition.Grammar($gb)
    $sre.LoadGrammar($g)
    $sre.SetInputToDefaultAudioDevice()
    Unregister-Event -SourceIdentifier "SpeechRec" -ErrorAction SilentlyContinue
    Register-ObjectEvent -InputObject $sre -EventName "SpeechRecognized" -SourceIdentifier "SpeechRec" | Out-Null
    $sre.RecognizeAsync([System.Speech.Recognition.RecognizeMode]::Multiple)
    Write-Output "READY:$($targetCulture.Name)"
    [Console]::Out.Flush()

    while ($true) {
        if ($ParentPid -gt 0) {
            $parentProcess = Get-Process -Id $ParentPid -ErrorAction SilentlyContinue
            if (-not $parentProcess) {
                break
            }
        }

        $speechEvent = Wait-Event -SourceIdentifier "SpeechRec" -Timeout 1
        if ($speechEvent) {
            $text = $speechEvent.SourceEventArgs.Result.Text
            $confidence = $speechEvent.SourceEventArgs.Result.Confidence
            $isMulti = $text.Contains(" ")
            $threshold = if ($isMulti) { 0.28 } else { 0.32 }
            if ($confidence -ge $threshold) {
                Write-Output "RECOGNIZED:$($text):$($confidence)"
                [Console]::Out.Flush()
            }
            Remove-Event -EventIdentifier $speechEvent.EventIdentifier
        }
    }
}
catch {
    Write-Output "ERROR: $($_.Exception.Message)"
}
finally {
    if ($sre) {
        $sre.Dispose()
    }
}
