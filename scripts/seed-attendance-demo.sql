-- Run with sqlcmd -E -C -I -b against the local attendance database.
SET QUOTED_IDENTIFIER ON;
SET XACT_ABORT ON;
SET NOCOUNT ON;
BEGIN TRANSACTION;

DECLARE @lecturer nvarchar(450) = (SELECT UserId FROM Lecturers WHERE LecturerCode = 'GV001');
IF @lecturer IS NULL THROW 50001, 'Lecturer GV001 is required.', 1;

IF NOT EXISTS (SELECT 1 FROM Courses WHERE Code = 'LTDD-DEMO')
    INSERT INTO Courses (Code, Name, Credits) VALUES ('LTDD-DEMO', N'Lập trình di động', 3);
DECLARE @course int = (SELECT Id FROM Courses WHERE Code = 'LTDD-DEMO');

IF NOT EXISTS (SELECT 1 FROM Classes WHERE Name = 'LTDD-DEMO-01' AND CourseId = @course AND LecturerUserId = @lecturer)
    INSERT INTO Classes (Name, CourseId, LecturerUserId, Room)
    VALUES ('LTDD-DEMO-01', @course, @lecturer, 'P.A301');
DECLARE @class int = (SELECT TOP (1) Id FROM Classes WHERE Name = 'LTDD-DEMO-01' AND CourseId = @course AND LecturerUserId = @lecturer ORDER BY Id);

INSERT INTO ClassMembers (ClassGroupId, StudentId)
SELECT @class, s.Id FROM Students s
WHERE s.StudentCode IN ('SV001','SV002','SV003','SV004','SV005','SV006','SV007','SV008','SV009','SV010')
AND NOT EXISTS (SELECT 1 FROM ClassMembers m WHERE m.ClassGroupId = @class AND m.StudentId = s.Id);

-- Input times are Vietnam time (+07:00); the application stores UTC.
INSERT INTO Schedules (ClassGroupId, StartsAtUtc, EndsAtUtc, Room)
SELECT @class, CONVERT(datetime2, SWITCHOFFSET(v.StartsAt, '+00:00')),
       CONVERT(datetime2, SWITCHOFFSET(v.EndsAt, '+00:00')), 'P.A301'
FROM (VALUES
    (CAST('2026-10-22T07:00:00+07:00' AS datetimeoffset), CAST('2026-10-22T09:00:00+07:00' AS datetimeoffset)),
    (CAST('2026-10-22T13:00:00+07:00' AS datetimeoffset), CAST('2026-10-22T15:00:00+07:00' AS datetimeoffset)),
    (CAST('2026-10-23T07:00:00+07:00' AS datetimeoffset), CAST('2026-10-23T09:00:00+07:00' AS datetimeoffset))
) v(StartsAt, EndsAt)
WHERE NOT EXISTS (SELECT 1 FROM Schedules s WHERE s.ClassGroupId = @class
    AND s.StartsAtUtc = CONVERT(datetime2, SWITCHOFFSET(v.StartsAt, '+00:00')));

IF (SELECT COUNT(*) FROM ClassMembers WHERE ClassGroupId = @class) < 10
    THROW 50002, 'Expected at least ten demo students.', 1;
COMMIT;

SELECT c.Id AS ClassId, c.Name AS ClassName, co.Name AS CourseName, c.Room,
    (SELECT COUNT(*) FROM ClassMembers m WHERE m.ClassGroupId = c.Id) AS StudentCount
FROM Classes c JOIN Courses co ON co.Id = c.CourseId WHERE c.Id = @class;
SELECT Id, CONVERT(datetime2, StartsAtUtc AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time') AS StartsAtVietnam,
    CONVERT(datetime2, EndsAtUtc AT TIME ZONE 'UTC' AT TIME ZONE 'SE Asia Standard Time') AS EndsAtVietnam, Room
FROM Schedules WHERE ClassGroupId = @class ORDER BY StartsAtUtc;
