using System;
using System.Diagnostics;
using System.Globalization;
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
                RecognizerInfo recognizer = null;
                foreach (RecognizerInfo ri in SpeechRecognitionEngine.InstalledRecognizers()) {
                    if (ri.Culture.Name.Equals("en-US", StringComparison.OrdinalIgnoreCase)) {
                        recognizer = ri;
                        break;
                    }
                }
                if (recognizer == null && SpeechRecognitionEngine.InstalledRecognizers().Count > 0) {
                    recognizer = SpeechRecognitionEngine.InstalledRecognizers()[0];
                }

                using (SpeechRecognitionEngine sre = (recognizer != null) 
                    ? new SpeechRecognitionEngine(recognizer) 
                    : new SpeechRecognitionEngine()) {
                    
                    CultureInfo targetCulture = (recognizer != null) ? recognizer.Culture : CultureInfo.GetCultureInfo("en-US");
                    
                    Choices choices = new Choices();
                    choices.Add(new string[] {
                        "Hey Sentosa",
                        "Hey Sendosa",
                        "Hai Sendosa",
                        "Hi Sendosa",
                        "Hi Sentosa",
                        "Hello Sendosa",
                        "Ok Sendosa",
                        "Hello Sentosa",
                        "OK Sentosa",
                        "Hey Centosa",
                        "Hi Centosa",
                        "Hello Centosa",
                        "OK Centosa",
                        "Hey Santosa",
                        "Hi Santosa",
                        "Hello Santosa",
                        "OK Santosa",
                        "Hey San tosa",
                        "Hi San tosa",
                        "OK San tosa",
                        "Hey Sen tosa",
                        "Hi Sen tosa",
                        "OK Sen tosa",
                        "Hey Santhosa",
                        "Hey Sendosa",
                        "Sentosa Stop",
                        "Stop Sentosa",
                        "Cancel Sentosa",
                        "Sentosa Cancel",
                        "Sentosa Admission",
                        "Admission",
                        "Admissions",
                        "Admission procedure",
                        "Start admission"
                    });

                    GrammarBuilder gb = new GrammarBuilder(choices);
                    gb.Culture = targetCulture;
                    Grammar grammar = new Grammar(gb);
                    grammar.Name = "SentosaWakeGrammar";
                    sre.LoadGrammar(grammar);

                    sre.SetInputToDefaultAudioDevice();

                    sre.SpeechRecognized += delegate(object sender, SpeechRecognizedEventArgs e) {
                        if (e.Result != null) {
                            string text = e.Result.Text;
                            float conf = e.Result.Confidence;                        
                            bool isMultiWord = text.Contains(" ");
                            float threshold = isMultiWord ? 0.28f : 0.32f;

                            if (conf >= threshold) {
                                Console.WriteLine("RECOGNIZED:" + text + ":" + conf.ToString("F2", CultureInfo.InvariantCulture));
                                Console.Out.Flush();
                            } else {
                                Console.WriteLine("LOW_CONFIDENCE:" + text + ":" + conf.ToString("F2", CultureInfo.InvariantCulture));
                                Console.Out.Flush();
                            }
                        }
                    };

                    sre.SpeechRecognitionRejected += delegate(object sender, SpeechRecognitionRejectedEventArgs e) {
                        if (e.Result != null && e.Result.Confidence >= 0.15f) {
                            Console.WriteLine("REJECTED:" + e.Result.Text + ":" + e.Result.Confidence.ToString("F2", CultureInfo.InvariantCulture));
                            Console.Out.Flush();
                        }
                    };

                    sre.RecognizeAsync(RecognizeMode.Multiple);
                    Console.WriteLine("READY:" + targetCulture.Name);
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
