using System.Diagnostics;
using System.Net;
using System.Net.Sockets;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Threading.Channels;
using Microsoft.Data.SqlClient;

// Real HTTP + real isolated SQL Server DB + local SMTP sink, no Gmail credentials.
var root = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, "../../../../../"));
var api = Path.Combine(root, "BackEnd/NguyenXuanPhu_KTGK_LTDD/NguyenXuanPhu_KTGK_LTDD");
var settings = JsonDocument.Parse(File.ReadAllText(Path.Combine(api, "appsettings.json")));
var connection = new SqlConnectionStringBuilder(settings.RootElement.GetProperty("ConnectionStrings").GetProperty("DefaultConnection").GetString());
var database = "Attendance_Verification_" + Guid.NewGuid().ToString("N");
connection.InitialCatalog = database;
var smtp = new TcpListener(IPAddress.Loopback, 0);
smtp.Start();
var smtpPort = ((IPEndPoint)smtp.LocalEndpoint).Port;
var mailbox = Channel.CreateUnbounded<string>();
using var cancellation = new CancellationTokenSource();
var smtpTask = Task.Run(async () => {
    try {
        while (!cancellation.IsCancellationRequested) {
            var client = await smtp.AcceptTcpClientAsync(cancellation.Token);
            _ = Task.Run(async () => {
                using (client) {
                    using var stream = client.GetStream();
                    using var reader = new StreamReader(stream, Encoding.ASCII);
                    using var writer = new StreamWriter(stream, Encoding.ASCII) { AutoFlush = true, NewLine = "\r\n" };
                    await writer.WriteLineAsync("220 localhost SMTP verification");
                    while (await reader.ReadLineAsync() is { } command) {
                        if (command.StartsWith("EHLO") || command.StartsWith("HELO")) await writer.WriteLineAsync("250 localhost");
                        else if (command == "DATA") {
                            await writer.WriteLineAsync("354 End with dot");
                            var body = new StringBuilder();
                            while (await reader.ReadLineAsync() is { } line && line != ".") body.AppendLine(line);
                            await mailbox.Writer.WriteAsync(body.ToString());
                            await writer.WriteLineAsync("250 Accepted");
                        } else if (command == "QUIT") { await writer.WriteLineAsync("221 Bye"); break; }
                        else await writer.WriteLineAsync("250 OK");
                    }
                }
            });
        }
    } catch (OperationCanceledException) { }
});
var socket = new TcpListener(IPAddress.Loopback, 0); socket.Start();
var port = ((IPEndPoint)socket.LocalEndpoint).Port; socket.Stop();
var start = new ProcessStartInfo("dotnet", $"\"{Environment.GetEnvironmentVariable("API_VERIFICATION_DLL") ?? Path.Combine(api, "bin/Debug/net10.0/NguyenXuanPhu_KTGK_LTDD.dll")}\"") { WorkingDirectory = api, UseShellExecute = false, CreateNoWindow = true, RedirectStandardOutput = true, RedirectStandardError = true };
var password = "Verify_" + Guid.NewGuid().ToString("N") + "!Aa1";
foreach (var item in new Dictionary<string, string> {
    ["ASPNETCORE_URLS"] = $"http://127.0.0.1:{port}", ["ASPNETCORE_ENVIRONMENT"] = "Development",
    ["ConnectionStrings__DefaultConnection"] = connection.ConnectionString,
    ["Jwt__Secret"] = Guid.NewGuid().ToString("N") + Guid.NewGuid().ToString("N"),
    ["SeedAdmin__Email"] = "admin@verification.test", ["SeedAdmin__Password"] = password,
    ["Smtp__Host"] = "127.0.0.1", ["Smtp__Port"] = smtpPort.ToString(), ["Smtp__EnableSsl"] = "false",
    ["RateLimits__OtpPerMinute"] = "100", ["Smtp__User"] = "test", ["Smtp__Password"] = "test", ["Smtp__From"] = "sender@verification.test"
}) start.Environment[item.Key] = item.Value;
var output = new StringBuilder();
using var process = new Process { StartInfo = start };
process.OutputDataReceived += (_, e) => { lock (output) output.AppendLine(e.Data); };
process.ErrorDataReceived += (_, e) => { lock (output) output.AppendLine(e.Data); };
process.Start(); process.BeginOutputReadLine(); process.BeginErrorReadLine();
using var http = new HttpClient { BaseAddress = new Uri($"http://127.0.0.1:{port}"), Timeout = TimeSpan.FromSeconds(20) };
var checks = 0;
async Task<JsonElement> Request(string method, string path, object? body = null, string? token = null, int expected = 200) {
    using var request = new HttpRequestMessage(new HttpMethod(method), path);
    if (token != null) request.Headers.Authorization = new("Bearer", token);
    if (body != null) request.Content = JsonContent.Create(body);
    using var response = await http.SendAsync(request);
    var text = await response.Content.ReadAsStringAsync();
    if ((int)response.StatusCode != expected) throw new Exception($"{method} {path}: expected {expected}, got {(int)response.StatusCode}: {text}");
    checks++;
    if (string.IsNullOrEmpty(text)) return default;
    try { return JsonDocument.Parse(text).RootElement.Clone(); } catch { return default; }
}
async Task<string> Code() {
    using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(10));
    var raw = (await mailbox.Reader.ReadAsync(timeout.Token)).Replace("\r\n", "\n");
    var separator = raw.IndexOf("\n\n", StringComparison.Ordinal);
    var body = separator >= 0 ? raw[(separator + 2)..] : raw;
    if (raw.Contains("Content-Transfer-Encoding: base64", StringComparison.OrdinalIgnoreCase)) body = Encoding.UTF8.GetString(Convert.FromBase64String(body));
    var match = Regex.Match(body, @"\b\d{6}\b");
    if (!match.Success) throw new Exception("SMTP message does not contain a six digit OTP.");
    return match.Value;
}
async Task<string> Login(string email) {
    var pending = await Request("POST", "/api/auth/login", new { email, password });
    if (pending.TryGetProperty("token", out _)) throw new Exception("Login must not issue token before OTP.");
    var otp = await Code();
    var result = await Request("POST", "/api/auth/verify-login", new { email, otp });
    await Request("POST", "/api/auth/verify-login", new { email, otp }, expected: 401);
    return result.GetProperty("token").GetString()!;
}
async Task VerifyEmail(string email) {
    await Request("POST", "/api/auth/resend-email", new { email, otp = "" });
    var otp = await Code();
    await Request("POST", "/api/auth/verify-email", new { email, otp });
}
try {
    bool ready = false;
    for (var i = 0; i < 90; i++) {
        if (process.HasExited) throw new Exception("Backend exited: " + output);
        try { using var response = await http.GetAsync("/api/health"); if (response.IsSuccessStatusCode) { ready = true; break; } } catch (HttpRequestException) { }
        await Task.Delay(500);
    }
    if (!ready) throw new Exception("Backend did not start: " + output);
    await Request("GET", "/api/students", expected: 401);
    var admin = await Login("admin@verification.test");
    var lecturerAccount = await Request("POST", "/api/accounts", new { email = "lecturer@verification.test", fullName = "Giảng viên kiểm thử", role = "Lecturer", password }, admin);
    var lecturerId = lecturerAccount.GetProperty("id").GetString();
    string lecturerCode;
    await using (var lookup = new SqlConnection(connection.ConnectionString)) {
        await lookup.OpenAsync();
        await using var command = lookup.CreateCommand();
        command.CommandText = "SELECT LecturerCode FROM Lecturers WHERE UserId = @id";
        command.Parameters.AddWithValue("@id", lecturerId!);
        lecturerCode = (string)(await command.ExecuteScalarAsync())!;
        // Code login must select Lecturer even when the identity also has Admin.
        command.CommandText = "INSERT INTO AspNetUserRoles (UserId, RoleId) SELECT @id, Id FROM AspNetRoles WHERE Name = 'Admin'";
        await command.ExecuteNonQueryAsync();
    }
    await VerifyEmail("  " + lecturerCode.ToLowerInvariant() + "  ");
    var lecturer = await Login(lecturerCode.ToLowerInvariant());
    await Request("POST", "/api/accounts", new { email = "illegal@verification.test", fullName = "Forbidden", role = "Lecturer", password }, lecturer, 403);
    var assistant = await Request("POST", "/api/accounts", new { email = "assistant@verification.test", fullName = "CTV", role = "Collaborator", password }, lecturer);
    await Request("PUT", "/api/accounts/" + assistant.GetProperty("id").GetString(), new { fullName = "CTV đã sửa", email = "assistant@verification.test" }, lecturer);
    var student = await Request("POST", "/api/students", new { studentCode = "SV001", fullName = "Sinh viên", email = "student@verification.test", faculty = "CNTT" }, lecturer);
    var sid = student.GetProperty("id").GetInt32();
    await Request("POST", "/api/auth/register", new { email = "wrong@verification.test", password, fullName = "", studentCode = "SV001" }, expected: 400);
    await Request("POST", "/api/auth/register", new { email = "student@verification.test", password, fullName = "", studentCode = "SV001" });
    await Request("POST", "/api/auth/verify-email", new { email = "student@verification.test", otp = await Code() });
    await Request("POST", "/api/auth/login", new { email = "SV999", password }, expected: 401);
    await Request("POST", "/api/auth/login", new { email = "SV001", password = "WrongPassword!1" }, expected: 401);
    var studentToken = await Login("  sv001  ");
    await Request("GET", "/api/accounts", token: studentToken, expected: 403);
    await Request("POST", "/api/students", new { studentCode = "SV002", fullName = "Forbidden", email = "forbidden@verification.test" }, studentToken, 403);
    await VerifyEmail("assistant@verification.test");
    var collaborator = await Login("assistant@verification.test");
    await Request("POST", "/api/students", new { studentCode = "SVCTV", fullName = "CTV thêm", email = "ctvstudent@verification.test", faculty = "CNTT" }, collaborator);
    await Request("PUT", "/api/students/" + sid, new { studentCode = "SV001", fullName = "Không được sửa", email = "student@verification.test", faculty = "CNTT" }, collaborator, 403);
    await Request("POST", "/api/accounts", new { email = "illegal2@verification.test", fullName = "Forbidden", role = "Collaborator", password }, collaborator, 403);
    var course = await Request("POST", "/api/courses", new { code = "MOB101", name = "Lập trình di động", credits = 3 }, lecturer);
    var cid = course.GetProperty("id").GetInt32();
    var cls = await Request("POST", "/api/classes", new { name = "Lớp kiểm thử", courseId = cid, room = "A101" }, lecturer);
    var classId = cls.GetProperty("id").GetInt32();
    var schedule = await Request("POST", "/api/schedules", new { classGroupId = classId, startsAtUtc = DateTime.UtcNow, endsAtUtc = DateTime.UtcNow.AddHours(2), room = "A101" }, lecturer);
    await Request("PUT", "/api/schedules/" + schedule.GetProperty("id").GetInt32(), new { classGroupId = classId, startsAtUtc = DateTime.UtcNow, endsAtUtc = DateTime.UtcNow.AddHours(3), room = "A102" }, lecturer);
    var vector = Enumerable.Repeat(1.0, 192).ToArray();
    await Request("PUT", "/api/face", new { embedding = new[] { 1.0 } }, studentToken, 400);
    await Request("PUT", "/api/face", new { embedding = vector }, studentToken);
    var session = await Request("POST", "/api/attendance/sessions", new { classGroupId = classId, latitude = 10.8, longitude = 106.6, durationMinutes = 10 }, lecturer);
    var qr = session.GetProperty("qrToken").GetString();
    var sessionId = session.GetProperty("id").GetInt32();
    await Request("POST", "/api/attendance/begin", new { qrToken = qr, latitude = 10.8, longitude = 106.6 }, studentToken, 403);
    await Request("POST", $"/api/classes/{classId}/students/{sid}", token: lecturer);
    await Request("POST", "/api/attendance/begin", new { qrToken = qr, latitude = 11.8, longitude = 106.6 }, studentToken, 400);
    var challenge = await Request("POST", "/api/attendance/begin", new { qrToken = qr, latitude = 10.8, longitude = 106.6 }, studentToken);
    var challengeId = challenge.GetProperty("challengeId").GetString();
    await Request("POST", "/api/attendance/mark", new { challengeId, embedding = Enumerable.Repeat(-1.0, 192).ToArray() }, studentToken, 400);
    await Request("POST", "/api/attendance/mark", new { challengeId, embedding = vector }, studentToken);
    await Request("POST", "/api/attendance/mark", new { challengeId, embedding = vector }, studentToken, 400);
    await Request("POST", "/api/attendance/begin", new { qrToken = qr, latitude = 10.8, longitude = 106.6 }, studentToken, 409);
    var records = await Request("GET", $"/api/attendance/sessions/{sessionId}/records", token: lecturer);
    if (records.GetArrayLength() != 1) throw new Exception("Expected one attendance record.");
    await Request("PUT", $"/api/attendance/sessions/{sessionId}/records/{sid}", new { present = false, reason = "Kiểm thử điều chỉnh" }, lecturer);
    var history = await Request("GET", "/api/attendance/mine", token: studentToken);
    if (history[0].GetProperty("method").GetString() != "Manual:Absent") throw new Exception("Correction was not saved.");
    var session2 = await Request("POST", "/api/attendance/sessions", new { classGroupId = classId, latitude = 10.8, longitude = 106.6, durationMinutes = 10 }, lecturer);
    qr = session2.GetProperty("qrToken").GetString();
    challenge = await Request("POST", "/api/attendance/begin", new { qrToken = qr, latitude = 10.8, longitude = 106.6 }, studentToken);
    await Task.Delay(TimeSpan.FromSeconds(11));
    await Request("POST", "/api/attendance/mark", new { challengeId = challenge.GetProperty("challengeId").GetString(), embedding = vector }, studentToken, 400);
    await Request("PUT", $"/api/attendance/sessions/{session2.GetProperty("id").GetInt32()}/close", token: lecturer);
    await Request("POST", "/api/attendance/begin", new { qrToken = qr, latitude = 10.8, longitude = 106.6 }, studentToken, 400);
    await Request("DELETE", "/api/courses/" + cid, token: lecturer, expected: 409);
    await Request("DELETE", "/api/schedules/" + schedule.GetProperty("id").GetInt32(), token: lecturer, expected: 204);
    await Request("DELETE", "/api/accounts/" + assistant.GetProperty("id").GetString(), token: lecturer, expected: 204);
    Console.WriteLine($"PASS: {checks} HTTP checks, real SQL Server migrations, SMTP OTP, role permissions, MSSV linking, face comparison, GPS, replay, timeout, session closure and attendance correction.");
} finally {
    if (!process.HasExited) { process.Kill(entireProcessTree: true); await process.WaitForExitAsync(); }
    cancellation.Cancel(); smtp.Stop(); await smtpTask;
    SqlConnection.ClearAllPools();
    // Drop only the isolated database generated by this test run.
    if (!Regex.IsMatch(database, "^Attendance_Verification_[a-f0-9]{32}$")) throw new Exception("Invalid test database name.");
    connection.InitialCatalog = "master";
    await using var sql = new SqlConnection(connection.ConnectionString);
    await sql.OpenAsync();
    await using var command = sql.CreateCommand();
    command.CommandText = $"IF DB_ID('{database}') IS NOT NULL BEGIN ALTER DATABASE [{database}] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [{database}]; END";
    await command.ExecuteNonQueryAsync();
}


