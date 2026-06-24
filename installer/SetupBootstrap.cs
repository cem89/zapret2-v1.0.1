using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Security.Principal;
using System.Windows.Forms;

namespace Zapret2Installer
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
            Application.Run(new InstallerForm());
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
                    "Kuruluma devam etmek icin Yonetici izni vermen gerekiyor.",
                    "Zapret2 Roblox Kurulum",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Information);
            }
        }
    }

    internal sealed class InstallerForm : Form
    {
        private readonly Panel card;
        private readonly Label titleLabel;
        private readonly Label subtitleLabel;
        private readonly Label statusLabel;
        private readonly ProgressBar progressBar;
        private readonly Button installButton;
        private readonly Button cancelButton;

        internal InstallerForm()
        {
            Text = "Zapret2 Roblox Kurulum";
            StartPosition = FormStartPosition.CenterScreen;
            ClientSize = new Size(680, 420);
            MinimumSize = new Size(680, 420);
            BackColor = Color.FromArgb(241, 236, 228);
            Font = new Font("Bahnschrift", 10f, FontStyle.Regular);
            FormBorderStyle = FormBorderStyle.FixedSingle;
            MaximizeBox = false;

            card = new Panel
            {
                BackColor = Color.White,
                Location = new Point(24, 24),
                Size = new Size(632, 372)
            };

            titleLabel = new Label
            {
                Text = "Zapret2 Roblox Kontrol Merkezi",
                Font = new Font("Bahnschrift", 22f, FontStyle.Bold),
                ForeColor = Color.FromArgb(22, 45, 45),
                Location = new Point(28, 26),
                AutoSize = true
            };

            subtitleLabel = new Label
            {
                Text = "Tek tikla kurulum yapar, masaustu kisayolu olusturur ve uygulamayi kullanima hazirlar.",
                Font = new Font("Bahnschrift", 11f, FontStyle.Regular),
                ForeColor = Color.FromArgb(95, 110, 110),
                Location = new Point(30, 72),
                Size = new Size(560, 46)
            };

            statusLabel = new Label
            {
                Text = "Hazir. Kurulumu baslatmak icin butona basin.",
                Font = new Font("Bahnschrift", 11f, FontStyle.Regular),
                ForeColor = Color.FromArgb(22, 45, 45),
                Location = new Point(30, 182),
                Size = new Size(560, 26)
            };

            progressBar = new ProgressBar
            {
                Location = new Point(30, 224),
                Size = new Size(570, 24),
                Style = ProgressBarStyle.Continuous,
                Minimum = 0,
                Maximum = 100
            };

            installButton = new Button
            {
                Text = "Kurulumu Baslat",
                BackColor = Color.FromArgb(31, 122, 109),
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat,
                Font = new Font("Bahnschrift", 12f, FontStyle.Bold),
                Location = new Point(30, 286),
                Size = new Size(240, 46)
            };
            installButton.FlatAppearance.BorderSize = 0;
            installButton.Click += InstallButton_Click;

            cancelButton = new Button
            {
                Text = "Kapat",
                BackColor = Color.FromArgb(233, 226, 214),
                ForeColor = Color.FromArgb(22, 45, 45),
                FlatStyle = FlatStyle.Flat,
                Font = new Font("Bahnschrift", 12f, FontStyle.Bold),
                Location = new Point(286, 286),
                Size = new Size(160, 46)
            };
            cancelButton.FlatAppearance.BorderSize = 0;
            cancelButton.Click += (_, __) => Close();

            card.Controls.Add(titleLabel);
            card.Controls.Add(subtitleLabel);
            card.Controls.Add(statusLabel);
            card.Controls.Add(progressBar);
            card.Controls.Add(installButton);
            card.Controls.Add(cancelButton);
            Controls.Add(card);
        }

        private void InstallButton_Click(object sender, EventArgs e)
        {
            installButton.Enabled = false;
            cancelButton.Enabled = false;

            try
            {
                RunInstall();
                statusLabel.Text = "Kurulum tamamlandi. Masaustundeki kisayol ile uygulamayi acabilirsin.";
                progressBar.Value = 100;

                DialogResult result = MessageBox.Show(
                    "Kurulum tamamlandi.\n\nUygulamayi simdi acmak ister misin?",
                    "Zapret2 Roblox Kurulum",
                    MessageBoxButtons.YesNo,
                    MessageBoxIcon.Information);

                if (result == DialogResult.Yes)
                {
                    string launcher = Path.Combine(GetInstallDirectory(), "zapret2_kontrol_merkezi.cmd");
                    if (File.Exists(launcher))
                    {
                        Process.Start(new ProcessStartInfo
                        {
                            FileName = launcher,
                            WorkingDirectory = GetInstallDirectory(),
                            UseShellExecute = true
                        });
                    }
                }

                cancelButton.Text = "Kapat";
                cancelButton.Enabled = true;
            }
            catch (Exception ex)
            {
                statusLabel.Text = "Kurulum sirasinda hata olustu.";
                cancelButton.Enabled = true;
                MessageBox.Show(
                    ex.Message,
                    "Zapret2 Roblox Kurulum",
                    MessageBoxButtons.OK,
                    MessageBoxIcon.Error);
                installButton.Enabled = true;
            }
        }

        private void RunInstall()
        {
            string installDir = GetInstallDirectory();
            string tempRoot = Path.Combine(Path.GetTempPath(), "zapret2-install-" + Guid.NewGuid().ToString("N"));
            string zipPath = Path.Combine(tempRoot, "payload.zip");
            string extractRoot = Path.Combine(tempRoot, "extract");

            Directory.CreateDirectory(tempRoot);
            Directory.CreateDirectory(extractRoot);

            try
            {
                UpdateStep("Kurulum paketi hazirlaniyor...", 12);
                ExtractEmbeddedZip(zipPath);

                UpdateStep("Dosyalar aciliyor...", 34);
                ZipFile.ExtractToDirectory(zipPath, extractRoot);

                string payloadRoot = Path.Combine(extractRoot, "zapret2-v1.0.1");
                if (!Directory.Exists(payloadRoot))
                {
                    throw new InvalidOperationException("Kurulum icerigi beklenen klasor yapisinda degil.");
                }

                UpdateStep("Program dosyalari kopyalaniyor...", 64);
                CopyDirectory(payloadRoot, installDir);

                UpdateStep("Kisayollar olusturuluyor...", 86);
                CreateShortcut(
                    Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory), "Zapret2 Roblox Kontrol Merkezi.lnk"),
                    Path.Combine(installDir, "zapret2_kontrol_merkezi.cmd"),
                    installDir,
                    Path.Combine(installDir, @"nfq2\windows\res\winws.ico"));

                string startMenuDir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Programs), "Zapret2 Roblox Kontrol Merkezi");
                Directory.CreateDirectory(startMenuDir);
                CreateShortcut(
                    Path.Combine(startMenuDir, "Zapret2 Roblox Kontrol Merkezi.lnk"),
                    Path.Combine(installDir, "zapret2_kontrol_merkezi.cmd"),
                    installDir,
                    Path.Combine(installDir, @"nfq2\windows\res\winws.ico"));

                UpdateStep("Kurulum tamamlandi.", 100);
            }
            finally
            {
                try
                {
                    if (Directory.Exists(tempRoot))
                    {
                        Directory.Delete(tempRoot, true);
                    }
                }
                catch
                {
                }
            }
        }

        private void ExtractEmbeddedZip(string destinationPath)
        {
            Assembly assembly = Assembly.GetExecutingAssembly();
            using (Stream stream = assembly.GetManifestResourceStream("payload.zip"))
            {
                if (stream == null)
                {
                    throw new InvalidOperationException("Gomulu kurulum paketi bulunamadi.");
                }

                using (FileStream file = new FileStream(destinationPath, FileMode.Create, FileAccess.Write))
                {
                    stream.CopyTo(file);
                }
            }
        }

        private static string GetInstallDirectory()
        {
            return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles), "Zapret2 Roblox Kontrol Merkezi");
        }

        private void UpdateStep(string text, int value)
        {
            statusLabel.Text = text;
            progressBar.Value = Math.Max(progressBar.Minimum, Math.Min(progressBar.Maximum, value));
            Application.DoEvents();
        }

        private static void CopyDirectory(string sourceDir, string destinationDir)
        {
            Directory.CreateDirectory(destinationDir);

            foreach (string directory in Directory.GetDirectories(sourceDir, "*", SearchOption.AllDirectories))
            {
                string relative = directory.Substring(sourceDir.Length).TrimStart(Path.DirectorySeparatorChar);
                Directory.CreateDirectory(Path.Combine(destinationDir, relative));
            }

            foreach (string file in Directory.GetFiles(sourceDir, "*", SearchOption.AllDirectories))
            {
                string relative = file.Substring(sourceDir.Length).TrimStart(Path.DirectorySeparatorChar);
                string destination = Path.Combine(destinationDir, relative);
                Directory.CreateDirectory(Path.GetDirectoryName(destination));
                File.Copy(file, destination, true);
            }
        }

        private static void CreateShortcut(string shortcutPath, string targetPath, string workingDirectory, string iconPath)
        {
            Type shellType = Type.GetTypeFromProgID("WScript.Shell");
            dynamic shell = Activator.CreateInstance(shellType);
            dynamic shortcut = shell.CreateShortcut(shortcutPath);
            shortcut.TargetPath = targetPath;
            shortcut.WorkingDirectory = workingDirectory;
            if (File.Exists(iconPath))
            {
                shortcut.IconLocation = iconPath;
            }
            shortcut.Save();
        }
    }
}
