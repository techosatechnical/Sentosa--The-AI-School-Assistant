param(
    [int]$ParentPid = 0
)

Add-Type -AssemblyName System.Speech
try {
    $sre = New-Object System.Speech.Recognition.SpeechRecognitionEngine
    $choices = New-Object System.Speech.Recognition.Choices
    $choices.Add([string[]]@(
        "Sentosa",
        "Hey Sentosa",
        "Hi Sentosa",
        "Hello Sentosa",
        "Sentosa Stop",
        "Start",
        "Admission",
        "Stop",
        "Cancel"
    ))
    $gb = New-Object System.Speech.Recognition.GrammarBuilder $choices
    $g = New-Object System.Speech.Recognition.Grammar $gb
    $sre.LoadGrammar($g)
    $sre.SetInputToDefaultAudioDevice()
    Unregister-Event -SourceIdentifier "SpeechRec" -ErrorAction SilentlyContinue
    Register-ObjectEvent -InputObject $sre -EventName "SpeechRecognized" -SourceIdentifier "SpeechRec" | Out-Null
    $sre.RecognizeAsync([System.Speech.Recognition.RecognizeMode]::Multiple)
    Write-Output "READY"
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
            if ($confidence -ge 0.40) {
                Write-Output "RECOGNIZED:$($text):$($confidence)"
                [Console]::Out.Flush()
            }
            Remove-Event -EventIdentifier $speechEvent.EventIdentifier
        }
    }
} catch {
    Write-Output "ERROR: $($_.Exception.Message)"
} finally {
    if ($sre) {
        $sre.Dispose()
    }
}
