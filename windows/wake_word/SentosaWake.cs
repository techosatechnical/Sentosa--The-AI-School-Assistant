using System;
using System.Diagnostics;
using System.IO;
using System.Speech.Recognition;
using System.Threading;

namespace SentosaWake {
    class Program {
        static void Main(string[] args) {
            int parentPid = 0;
            if (args.Length > 0 && int.TryParse(args[0], out parentPid) && parentPid > 0) {
                Thread watchdog = new Thread(delegate() {
                    try {
                        Process parent = Process.GetProcessById(parentPid);
                        parent.WaitForExit();
                    } catch {
                        // Parent process not found or already exited
                    }
                    Environment.Exit(0);
                });
                watchdog.IsBackground = true;
                watchdog.Start();
            }

            try {
                using (SpeechRecognitionEngine sre = new SpeechRecognitionEngine()) {
                    Choices choices = new Choices();
                    choices.Add(new string[] {
                        "Sentosa",
                        "Hey Sentosa",
                        "Hi Sentosa",
                        "Hello Sentosa",
                        "Sentosa Stop",
                        "Stop",
                        "Cancel",
                        "Admission",
                        "Admissions",
                        "Admission procedure",
                        "Start admission",
                        "Sentosa admission"
                    });
                    GrammarBuilder gb = new GrammarBuilder(choices);
                    sre.LoadGrammar(new Grammar(gb));
                    sre.SetInputToDefaultAudioDevice();
                    sre.SpeechRecognized += delegate(object sender, SpeechRecognizedEventArgs e) {
                        if (e.Result != null && e.Result.Confidence >= 0.40f) {
                            Console.WriteLine("RECOGNIZED:" + e.Result.Text + ":" + e.Result.Confidence.ToString("F2"));
                            Console.Out.Flush();
                        }
                    };
                    sre.RecognizeAsync(RecognizeMode.Multiple);
                    Console.WriteLine("READY");
                    Console.Out.Flush();
                    
                    while (true) {
                        string line = Console.ReadLine();
                        if (line == "QUIT" || line == null) {
                            break;
                        }
                    }
                }
            } catch (Exception ex) {
                Console.WriteLine("ERROR:" + ex.Message);
                Console.Out.Flush();
            }
        }
    }
}
