using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Runtime.Serialization;
using System.Runtime.Serialization.Json;
using System.Security.Principal;
using System.Text;
using System.Windows.Forms;

namespace Zapret2ControlCenter
{
    internal static class Program
    {
        [STAThread]
        private static void Main()
        {
            if (!IsAdministrator())
            {
                RelaunchAsAdministrator();
                return;
            }

            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
        }

        private static bool IsAdministrator()
        {
            using (WindowsIdentity identity = WindowsIdentity.GetCurrent())
            {
                WindowsPrincipal principal = new WindowsPrincipal(identity);
                return principal.IsInRole(WindowsBuiltInRole.Administrator);
            }
        }

        private static void RelaunchAsAdministrator()
        {
            ProcessStartInfo startInfo = new ProcessStartInfo
            {
                FileName = Application.ExecutablePath,
                UseShellExecute = true,
                Verb = "runas"
            };

            try
            {
                Process.Start(startInfo);
            }
            catch
            {
                MessageBox.Show(
                    "Uygulamayi kullanmak icin Yonetici izni vermen gerekiyor.",
                    "Zapret2 Roblox Kontrol Merkezi",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information);
            }
        }
    }

    internal sealed class MainForm : Form
    {
        private readonly Color Bg = Color.FromArgb(242, 238, 231);
        private readonly Color Ink = Color.FromArgb(20, 42, 42);
        private readonly Color Muted = Color.FromArgb(92, 113, 113);
        private readonly Color Card = Color.FromArgb(255, 252, 247);
        private readonly Color Accent = Color.FromArgb(36, 122, 109);
        private readonly Color Danger = Color.FromArgb(170, 69, 69);
        private readonly Color Gold = Color.FromArgb(224, 173, 31);

        private readonly Timer refreshTimer;
        private readonly Label badgeLabel;
        private readonly Label serviceStateLabel;
        private readonly Label pidLabel;
        private readonly Label adminLabel;
        private readonly Label binaryLabel;
        private readonly Label logTimeLabel;
        private readonly Label footerLabel;
        private readonly Label testSummaryLabel;
        private readonly TextBox logBox;
        private readonly DataGridView resultGrid;

        internal MainForm()
        {
            Text = "Zapret2 Roblox Kontrol Merkezi";
            StartPosition = FormStartPosition.CenterScreen;
            ClientSize = new Size(1280, 860);
            MinimumSize = new Size(1180, 780);
            BackColor = Bg;
            Font = new Font("Bahnschrift", 10f, FontStyle.Regular);

            Controls.Add(BuildHeader(out badgeLabel));
            Controls.Add(BuildLeftRail(out serviceStateLabel, out pidLabel, out adminLabel, out binaryLabel, out logTimeLabel));
            Controls.Add(BuildMainArea(out resultGrid, out testSummaryLabel, out logBox));
            Controls.Add(BuildFooter(out footerLabel));

            refreshTimer = new Timer { Interval = 3000 };
            refreshTimer.Tick += (_, __) => RefreshStatus();
            refreshTimer.Start();

            Shown += (_, __) => RefreshStatus();
            FormClosed += (_, __) => refreshTimer.Stop();
        }

        private Control BuildHeader(out Label statusBadge)
        {
            Panel header = CreateCard(new Rectangle(24, 22, 1232, 146), Color.FromArgb(18, 46, 45));
            header.Paint += (_, e) => DrawSoftGradient(e.Graphics, header.ClientRectangle, Color.FromArgb(18, 46, 45), Color.FromArgb(27, 65, 63));

            LogoPanel logo = new LogoPanel
            {
                Location = new Point(26, 26),
                Size = new Size(88, 88),
                BackColor = Color.Transparent
            };
            header.Controls.Add(logo);

            Label title = new Label
            {
                Text = "Zapret2 Roblox Kontrol Merkezi",
                ForeColor = Color.FromArgb(248, 244, 236),
                Font = new Font("Bahnschrift", 30f, FontStyle.Bold),
                Location = new Point(128, 28),
                AutoSize = true,
                BackColor = Color.Transparent
            };
            header.Controls.Add(title);

            Label subtitle = new Label
            {
                Text = "Modern C# arayuz ile baslat, durdur, test et ve durumu tek ekrandan izle.",
                ForeColor = Color.FromArgb(194, 216, 211),
                Font = new Font("Bahnschrift", 15f, FontStyle.Regular),
                Location = new Point(130, 78),
                Size = new Size(760, 28),
                BackColor = Color.Transparent
            };
            header.Controls.Add(subtitle);

            statusBadge = new Label
            {
                Text = "KAPALI",
                TextAlign = ContentAlignment.MiddleCenter,
                ForeColor = Color.FromArgb(255, 248, 240),
                BackColor = Color.FromArgb(191, 96, 96),
                Font = new Font("Bahnschrift", 15f, FontStyle.Bold),
                Location = new Point(1082, 42),
                Size = new Size(118, 44)
            };
            statusBadge.Paint += RoundedBadgePaint;
            header.Controls.Add(statusBadge);

            return header;
        }

        private Control BuildLeftRail(out Label state, out Label pid, out Label admin, out Label binary, out Label logTime)
        {
            Panel rail = new Panel
            {
                Location = new Point(24, 186),
                Size = new Size(358, 598),
                BackColor = Color.Transparent
            };

            Panel quick = CreateCard(new Rectangle(0, 0, 358, 292), Card);
            rail.Controls.Add(quick);

            Label quickTitle = MakeTitle("Hizli Kontroller", new Point(22, 20));
            quick.Controls.Add(quickTitle);
            quick.Controls.Add(MakeBody("En cok kullanilan islemler burada.", new Rectangle(22, 58, 290, 24)));

            Button start = MakeButton("Bypass Baslat", Accent, Color.White, new Rectangle(22, 96, 314, 48));
            start.Click += (_, __) => RunAction("Bypass baslatiliyor...", "start", RefreshStatus);
            quick.Controls.Add(start);

            Button stop = MakeButton("Bypass Durdur", Danger, Color.White, new Rectangle(22, 154, 314, 48));
            stop.Click += (_, __) => RunAction("Bypass durduruluyor...", "stop", RefreshStatus);
            quick.Controls.Add(stop);

            Button test = MakeButton("Roblox Erisim Testi", Gold, Ink, new Rectangle(22, 212, 314, 48));
            test.Click += (_, __) => RunTest();
            quick.Controls.Add(test);

            Panel live = CreateCard(new Rectangle(0, 310, 358, 154), Card);
            rail.Controls.Add(live);
            live.Controls.Add(MakeTitle("Canli Durum", new Point(22, 18)));
            state = MakeMetric("Servis: kontrol ediliyor", new Point(22, 64), true);
            pid = MakeMetric("PID: -", new Point(22, 90), false);
            admin = MakeMetric("Yonetici: -", new Point(22, 114), false);
            binary = MakeMetric("Binary: -", new Point(180, 90), false);
            logTime = MakeMetric("Son log: -", new Point(180, 114), false);
            live.Controls.Add(state);
            live.Controls.Add(pid);
            live.Controls.Add(admin);
            live.Controls.Add(binary);
            live.Controls.Add(logTime);

            Panel tools = CreateCard(new Rectangle(0, 482, 358, 116), Card);
            rail.Controls.Add(tools);
            tools.Controls.Add(MakeTitle("Araclar", new Point(22, 18)));
            Button refresh = MakeButton("Durumu Yenile", Color.FromArgb(214, 231, 225), Ink, new Rectangle(22, 58, 152, 36));
            refresh.Click += (_, __) => RefreshStatus();
            tools.Controls.Add(refresh);
            Button folder = MakeButton("Klasoru Ac", Color.FromArgb(236, 230, 221), Ink, new Rectangle(184, 58, 152, 36));
            folder.Click += (_, __) => OpenProjectFolder();
            tools.Controls.Add(folder);

            return rail;
        }

        private Control BuildMainArea(out DataGridView grid, out Label summary, out TextBox logPreview)
        {
            Panel area = new Panel
            {
                Location = new Point(400, 186),
                Size = new Size(856, 598),
                BackColor = Color.Transparent
            };

            Panel testCard = CreateCard(new Rectangle(0, 0, 856, 242), Card);
            area.Controls.Add(testCard);
            testCard.Controls.Add(MakeTitle("Erisim Test Sonuclari", new Point(22, 18)));
            summary = MakeBody("Henuz test calismadi.", new Rectangle(282, 26, 320, 22));
            testCard.Controls.Add(summary);

            grid = new DataGridView
            {
                Location = new Point(22, 62),
                Size = new Size(812, 156),
                ReadOnly = true,
                AllowUserToAddRows = false,
                AllowUserToDeleteRows = false,
                AllowUserToResizeRows = false,
                BackgroundColor = Color.White,
                BorderStyle = BorderStyle.None,
                RowHeadersVisible = false,
                AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill,
                SelectionMode = DataGridViewSelectionMode.FullRowSelect
            };
            grid.DefaultCellStyle.BackColor = Color.FromArgb(255, 249, 240);
            grid.AlternatingRowsDefaultCellStyle.BackColor = Color.FromArgb(248, 248, 243);
            grid.ColumnHeadersDefaultCellStyle.BackColor = Color.FromArgb(235, 240, 237);
            grid.EnableHeadersVisualStyles = false;
            grid.Columns.Add("ResultText", "Durum");
            grid.Columns.Add("Url", "Adres");
            grid.Columns.Add("Status", "HTTP");
            grid.Columns[0].FillWeight = 18;
            grid.Columns[1].FillWeight = 54;
            grid.Columns[2].FillWeight = 28;
            testCard.Controls.Add(grid);

            Panel logCard = CreateCard(new Rectangle(0, 260, 856, 338), Card);
            area.Controls.Add(logCard);
            logCard.Controls.Add(MakeTitle("Canli Log Onizleme", new Point(22, 18)));
            logCard.Controls.Add(MakeBody("Son 30 satir gosteriliyor.", new Rectangle(268, 26, 240, 22)));

            logPreview = new TextBox
            {
                Location = new Point(22, 62),
                Size = new Size(812, 246),
                Multiline = true,
                ReadOnly = true,
                ScrollBars = ScrollBars.Both,
                WordWrap = false,
                BorderStyle = BorderStyle.None,
                BackColor = Color.FromArgb(18, 38, 38),
                ForeColor = Color.FromArgb(223, 247, 241),
                Font = new Font("Consolas", 11f, FontStyle.Regular)
            };
            logCard.Controls.Add(logPreview);

            Button openLog = MakeButton("Logu Ac", Color.FromArgb(236, 230, 221), Ink, new Rectangle(690, 18, 144, 30));
            openLog.Click += (_, __) => OpenLog();
            logCard.Controls.Add(openLog);

            return area;
        }

        private Control BuildFooter(out Label footer)
        {
            Panel footerCard = CreateCard(new Rectangle(24, 800, 1232, 44), Color.FromArgb(255, 247, 234));
            footer = new Label
            {
                Text = "Hazir. Bu pencere acikken durum otomatik yenilenir.",
                ForeColor = Muted,
                Font = new Font("Bahnschrift", 11f, FontStyle.Regular),
                Location = new Point(18, 11),
                Size = new Size(860, 22),
                BackColor = Color.Transparent
            };
            footerCard.Controls.Add(footer);
            return footerCard;
        }

        private void RefreshStatus()
        {
            try
            {
                StatusDto status = RunJsonCommand<StatusDto>("status");
                serviceStateLabel.Text = "Servis: " + (status.IsRunning ? "aktif" : "kapali");
                pidLabel.Text = "PID: " + (status.ProcessId.HasValue ? status.ProcessId.Value.ToString() : "-");
                adminLabel.Text = "Yonetici: " + (status.IsAdmin ? "Evet" : "Hayir");
                binaryLabel.Text = "Binary: " + (status.WinwsExists ? "Bulundu" : "Eksik");
                logTimeLabel.Text = "Son log: " + (string.IsNullOrWhiteSpace(status.LastLogUpdate) ? "-" : ParsePowerShellDate(status.LastLogUpdate).ToString("dd.MM HH:mm"));
                badgeLabel.Text = status.IsRunning ? "AKTIF" : "KAPALI";
                badgeLabel.BackColor = status.IsRunning ? Color.FromArgb(43, 132, 95) : Color.FromArgb(191, 96, 96);
                logBox.Text = RunTextCommand("log");
                footerLabel.Text = status.IsRunning ? "Bypass su anda aktif." : "Bypass kapali. Baslat dugmesi ile acabilirsin.";
            }
            catch (Exception ex)
            {
                footerLabel.Text = "Durum okunamadi: " + ex.Message;
            }
        }

        private void RunTest()
        {
            footerLabel.Text = "Roblox erisim testi calisiyor...";
            try
            {
                List<TestDto> results = RunJsonCommand<List<TestDto>>("test");
                resultGrid.Rows.Clear();
                int ok = 0;
                foreach (TestDto item in results)
                {
                    string result = item.Success ? "OK" : "FAIL";
                    if (item.Success) ok++;
                    resultGrid.Rows.Add(result, item.Url, string.IsNullOrWhiteSpace(item.Status) ? "curl_exit=" + item.ExitCode : item.Status);
                }
                testSummaryLabel.Text = ok + " / " + results.Count + " basarili";
                footerLabel.Text = "Erisim testi tamamlandi.";
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, Text, MessageBoxButtons.OK, MessageBoxIcon.Error);
                footerLabel.Text = "Test sirasinda hata olustu.";
            }
        }

        private void RunAction(string busyMessage, string action, Action after)
        {
            footerLabel.Text = busyMessage;
            try
            {
                ActionDto dto = RunJsonCommand<ActionDto>(action);
                footerLabel.Text = dto.Message;
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message, Text, MessageBoxButtons.OK, MessageBoxIcon.Error);
                footerLabel.Text = "Hata: " + ex.Message;
            }
            finally
            {
                after();
            }
        }

        private void OpenProjectFolder()
        {
            Process.Start(new ProcessStartInfo
            {
                FileName = AppDomain.CurrentDomain.BaseDirectory,
                UseShellExecute = true
            });
        }

        private void OpenLog()
        {
            string logPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "winws-roblox.log");
            if (File.Exists(logPath))
            {
                Process.Start(new ProcessStartInfo
                {
                    FileName = "notepad.exe",
                    Arguments = "\"" + logPath + "\"",
                    UseShellExecute = true
                });
            }
            else
            {
                MessageBox.Show("Henuz acilabilecek bir log dosyasi yok.", Text, MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
        }

        private static DateTime ParsePowerShellDate(string raw)
        {
            if (string.IsNullOrWhiteSpace(raw))
            {
                return DateTime.MinValue;
            }

            int start = raw.IndexOf('(');
            int end = raw.IndexOf(')');
            if (start >= 0 && end > start)
            {
                string number = raw.Substring(start + 1, end - start - 1);
                long ms;
                if (long.TryParse(number, out ms))
                {
                    return new DateTime(1970, 1, 1).AddMilliseconds(ms).ToLocalTime();
                }
            }

            DateTime parsed;
            if (DateTime.TryParse(raw, out parsed))
            {
                return parsed;
            }

            return DateTime.MinValue;
        }

        private T RunJsonCommand<T>(string action)
        {
            string output = RunPowerShell("-File \"" + ApiScriptPath + "\" " + action);
            return Deserialize<T>(output);
        }

        private string RunTextCommand(string action)
        {
            return RunPowerShell("-File \"" + ApiScriptPath + "\" " + action);
        }

        private string RunPowerShell(string arguments)
        {
            ProcessStartInfo psi = new ProcessStartInfo
            {
                FileName = "powershell.exe",
                Arguments = "-NoProfile -ExecutionPolicy Bypass " + arguments,
                UseShellExecute = false,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                CreateNoWindow = true,
                WorkingDirectory = AppDomain.CurrentDomain.BaseDirectory,
                StandardOutputEncoding = Encoding.UTF8,
                StandardErrorEncoding = Encoding.UTF8
            };

            using (Process process = Process.Start(psi))
            {
                string stdout = process.StandardOutput.ReadToEnd();
                string stderr = process.StandardError.ReadToEnd();
                process.WaitForExit();

                if (process.ExitCode != 0)
                {
                    throw new InvalidOperationException(string.IsNullOrWhiteSpace(stderr) ? "PowerShell komutu basarisiz oldu." : stderr.Trim());
                }

                return stdout.Trim();
            }
        }

        private static T Deserialize<T>(string json)
        {
            using (MemoryStream ms = new MemoryStream(Encoding.UTF8.GetBytes(json)))
            {
                DataContractJsonSerializer serializer = new DataContractJsonSerializer(typeof(T));
                return (T)serializer.ReadObject(ms);
            }
        }

        private string ApiScriptPath
        {
            get { return Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "zapret2-roblox-api.ps1"); }
        }

        private Panel CreateCard(Rectangle bounds, Color color)
        {
            Panel panel = new Panel
            {
                Location = bounds.Location,
                Size = bounds.Size,
                BackColor = color
            };
            panel.Paint += RoundedCardPaint;
            return panel;
        }

        private Label MakeTitle(string text, Point location)
        {
            return new Label
            {
                Text = text,
                Font = new Font("Bahnschrift", 21f, FontStyle.Bold),
                ForeColor = Ink,
                Location = location,
                AutoSize = true,
                BackColor = Color.Transparent
            };
        }

        private Label MakeBody(string text, Rectangle bounds)
        {
            return new Label
            {
                Text = text,
                Font = new Font("Bahnschrift", 11f, FontStyle.Regular),
                ForeColor = Muted,
                Location = bounds.Location,
                Size = bounds.Size,
                BackColor = Color.Transparent
            };
        }

        private Label MakeMetric(string text, Point location, bool emphasized)
        {
            return new Label
            {
                Text = text,
                Font = new Font("Bahnschrift", emphasized ? 15f : 11f, emphasized ? FontStyle.Bold : FontStyle.Regular),
                ForeColor = emphasized ? Ink : Muted,
                Location = location,
                Size = new Size(150, 24),
                BackColor = Color.Transparent
            };
        }

        private Button MakeButton(string text, Color backColor, Color foreColor, Rectangle bounds)
        {
            Button button = new Button
            {
                Text = text,
                BackColor = backColor,
                ForeColor = foreColor,
                FlatStyle = FlatStyle.Flat,
                Font = new Font("Bahnschrift", 13f, FontStyle.Bold),
                Location = bounds.Location,
                Size = bounds.Size,
                TabStop = false
            };
            button.FlatAppearance.BorderSize = 0;
            button.Paint += RoundedButtonPaint;
            return button;
        }

        private void RoundedCardPaint(object sender, PaintEventArgs e)
        {
            Panel panel = (Panel)sender;
            e.Graphics.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
            using (var path = RoundRect(new Rectangle(0, 0, panel.Width - 1, panel.Height - 1), 26))
            using (var brush = new SolidBrush(panel.BackColor))
            {
                e.Graphics.FillPath(brush, path);
            }
        }

        private void RoundedBadgePaint(object sender, PaintEventArgs e)
        {
            Label label = (Label)sender;
            e.Graphics.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
            using (var path = RoundRect(new Rectangle(0, 0, label.Width - 1, label.Height - 1), 22))
            using (var brush = new SolidBrush(label.BackColor))
            {
                e.Graphics.FillPath(brush, path);
            }
            TextRenderer.DrawText(e.Graphics, label.Text, label.Font, new Rectangle(0, 0, label.Width, label.Height), label.ForeColor, TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter);
        }

        private void RoundedButtonPaint(object sender, PaintEventArgs e)
        {
            Button button = (Button)sender;
            e.Graphics.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
            using (var path = RoundRect(new Rectangle(0, 0, button.Width - 1, button.Height - 1), 18))
            using (var brush = new SolidBrush(button.BackColor))
            {
                e.Graphics.FillPath(brush, path);
            }
            TextRenderer.DrawText(e.Graphics, button.Text, button.Font, new Rectangle(0, 0, button.Width, button.Height), button.ForeColor, TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter);
        }

        private void DrawSoftGradient(Graphics graphics, Rectangle rect, Color from, Color to)
        {
            using (var brush = new System.Drawing.Drawing2D.LinearGradientBrush(rect, from, to, 25f))
            using (var path = RoundRect(new Rectangle(0, 0, rect.Width - 1, rect.Height - 1), 30))
            {
                graphics.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
                graphics.FillPath(brush, path);
            }
        }

        private static System.Drawing.Drawing2D.GraphicsPath RoundRect(Rectangle bounds, int radius)
        {
            int diameter = radius * 2;
            var path = new System.Drawing.Drawing2D.GraphicsPath();
            path.AddArc(bounds.X, bounds.Y, diameter, diameter, 180, 90);
            path.AddArc(bounds.Right - diameter, bounds.Y, diameter, diameter, 270, 90);
            path.AddArc(bounds.Right - diameter, bounds.Bottom - diameter, diameter, diameter, 0, 90);
            path.AddArc(bounds.X, bounds.Bottom - diameter, diameter, diameter, 90, 90);
            path.CloseFigure();
            return path;
        }
    }

    internal sealed class LogoPanel : Panel
    {
        protected override void OnPaint(PaintEventArgs e)
        {
            base.OnPaint(e);
            e.Graphics.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;

            Rectangle orb = new Rectangle(4, 4, 80, 80);
            using (var grad = new System.Drawing.Drawing2D.LinearGradientBrush(orb, Color.FromArgb(37, 183, 152), Color.FromArgb(21, 64, 69), 45f))
            {
                e.Graphics.FillEllipse(grad, orb);
            }

            using (var ringPen = new Pen(Color.FromArgb(241, 236, 228), 3.4f))
            {
                e.Graphics.DrawEllipse(ringPen, 8, 8, 72, 72);
            }

            Point[] bolt =
            {
                new Point(42, 14),
                new Point(27, 43),
                new Point(42, 43),
                new Point(31, 71),
                new Point(58, 36),
                new Point(44, 36)
            };
            using (var boltBrush = new SolidBrush(Color.FromArgb(255, 206, 87)))
            {
                e.Graphics.FillPolygon(boltBrush, bolt);
            }

            using (var dotBrush = new SolidBrush(Color.FromArgb(255, 247, 236)))
            {
                e.Graphics.FillEllipse(dotBrush, 16, 18, 8, 8);
                e.Graphics.FillEllipse(dotBrush, 61, 56, 7, 7);
            }
        }
    }

    [DataContract]
    internal sealed class StatusDto
    {
        [DataMember] public bool IsAdmin { get; set; }
        [DataMember] public bool IsRunning { get; set; }
        [DataMember] public int? ProcessId { get; set; }
        [DataMember] public bool WinwsExists { get; set; }
        [DataMember] public string LastLogUpdate { get; set; }
    }

    [DataContract]
    internal sealed class TestDto
    {
        [DataMember] public string Url { get; set; }
        [DataMember] public bool Success { get; set; }
        [DataMember] public int ExitCode { get; set; }
        [DataMember] public string Status { get; set; }
        [DataMember] public string Details { get; set; }
    }

    [DataContract]
    internal sealed class ActionDto
    {
        [DataMember(Name = "success")] public bool Success { get; set; }
        [DataMember(Name = "message")] public string Message { get; set; }
    }
}
