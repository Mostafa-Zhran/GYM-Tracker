using GymBLL.DTO;
using GymBLL.DTO.AuthintcationDto;
using GymDAL.DB;
using GymDAL.Model;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace GymAPI.Controllers
{
    public class CoachController : ControllerBase
    {
        private readonly AppDbContext _context;

        public CoachController(AppDbContext context)
        {
            _context = context;
        }

        [Authorize(Roles = "Trainee")]
        [HttpPost("assign-coach")]
        public async Task<IActionResult> AssignCoach([FromBody] AssignCoachDto dto)
        {
            var traineeId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (traineeId == null)
                return Unauthorized();

            var coach = await _context.Users
                .FirstOrDefaultAsync(u => u.Id == dto.CoachId);

            if (coach == null)
                return NotFound("Coach not found");

            var trainee = await _context.Users
                .FirstOrDefaultAsync(u => u.Id == traineeId);

            if (trainee == null)
                return NotFound("Trainee not found");

            trainee.CoachId = coach.Id;

            await _context.SaveChangesAsync();

            return Ok("Coach assigned successfully");
        }

        [Authorize(Roles = "Coach")]
        [HttpPost("assign")]
        public async Task<IActionResult> AssignWorkout([FromBody] AssignWorkoutDto dto)
        {
            var coachId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            // تأكد إن الترايني تابع للمدرب
            var trainee = await _context.Users
                .FirstOrDefaultAsync(u => u.Id == dto.TraineeId && u.CoachId == coachId);

            if (trainee == null)
                return Forbid("This trainee is not assigned to you.");

            var workout = new Workout
            {
                Id = Guid.NewGuid(),
                Title = dto.Title,
                Description = dto.Description,
                Date = dto.Date,
                CoachId = coachId,
                TraineeId = dto.TraineeId
            };

            _context.Workouts.Add(workout);
            await _context.SaveChangesAsync();

            return Ok("Added Seccufully");
        }

        [HttpGet("trainees")]
        public async Task<IActionResult> GetMyTrainees()
        {
            var coachId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (coachId == null)
                return Unauthorized();

            var trainees = await _context.Users
                .Where(u => u.CoachId == coachId)
                .Select(u => new TraineeResponseDto
                {
                    Id = u.Id,
                    Name= u.UserName,
                    Email = u.Email
                })
                .ToListAsync();

            return Ok(trainees);
        }

        [Authorize(Roles = "Trainee")]
        [HttpGet("today")]
        public async Task<ActionResult<WorkoutResponseDto?>> GetTodayWorkout()
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            var today = DateTime.UtcNow.Date;
            var tomorrow = today.AddDays(2);

            var workout = await _context.Workouts
                .Include(w => w.Coach)
                .Include(w => w.Trainee)
                .Include(w => w.Logs)
                .Where(w =>
                    w.TraineeId == userId &&
                    w.Date >= today &&
                    w.Date < tomorrow)
                .FirstOrDefaultAsync();

            if (workout == null)
                return Ok(null);

            var log = workout.Logs
                .OrderByDescending(l => l.CompletedAt)
                .FirstOrDefault();

            var dto = new WorkoutResponseDto
            {
                Title = workout.Title,
                Description = workout.Description,
                ScheduledDate = workout.Date,
                CoachName = workout.Coach.UserName,
                TraineeName = workout.Trainee.UserName,

                Log = log == null ? null : new WorkoutLogDto
                {
                    CompletedAt = log.CompletedAt,
                    Notes = log.Notes
                }
            };

            return Ok(dto);
        }

        // ─────────────────────────────────────────
        // LOG TODAY WORKOUT
        // ─────────────────────────────────────────

        [Authorize(Roles = "Trainee")]
        [HttpPost("log")]
        public async Task<IActionResult> LogWorkout([FromBody] WorkoutLogDto dto)
        {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);

            var today = DateTime.UtcNow.Date;
            var tomorrow = today.AddDays(2);

            var workout = await _context.Workouts
                .FirstOrDefaultAsync(w =>
                    w.TraineeId == userId &&
                    w.Date >= today &&
                    w.Date < tomorrow);

            if (workout == null)
                return BadRequest("No workout scheduled for today");

            var alreadyLogged = await _context.WorkoutLogs
                .AnyAsync(l => l.WorkoutId == workout.Id);

            if (alreadyLogged)
                return BadRequest("Workout already logged");

            var log = new WorkoutLog
            {
                Id = Guid.NewGuid(),
                WorkoutId = workout.Id,
                CompletedAt = DateTime.UtcNow, // السيرفر يحدد الوقت
                Notes = dto.Notes
            };

            _context.WorkoutLogs.Add(log);

            await _context.SaveChangesAsync();

            return Ok(new
            {
                message = "Workout logged successfully"
            });
        }

        [Authorize]
        [HttpGet("history")]
        public async Task<IActionResult> GetChatHistory(
            string otherUserId,
            int pageNumber = 1,
            int pageSize = 20)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            if (string.IsNullOrEmpty(userId))
                return Unauthorized();

            if (string.IsNullOrEmpty(otherUserId))
                return BadRequest("otherUserId is required");

            if (pageNumber < 1) pageNumber = 1;
            if (pageSize < 1 || pageSize > 50) pageSize = 20;

            var query = _context.Messages
                .Where(m =>
                    (m.SenderId == userId && m.ReceiverId == otherUserId) ||
                    (m.SenderId == otherUserId && m.ReceiverId == userId))
                .OrderByDescending(m => m.Timestamp);

            var total = await query.CountAsync();

            var messages = await query
                .Skip((pageNumber - 1) * pageSize)
                .Take(pageSize)
                .Select(m => new ChatMessageDto
                {
                    Id = m.Id,
                    SenderId = m.SenderId,
                    ReceiverId = m.ReceiverId,
                    Content = m.Content,
                    Timestamp = m.Timestamp,
                    IsSeen = m.IsSeen
                })
                .ToListAsync();

            return Ok(new
            {
                pageNumber,
                pageSize,
                total,
                data = messages
            });
        }


        [Authorize]
        [HttpPost("seen")]
        public async Task<IActionResult> MarkAsSeen(string otherUserId)
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;

            var messages = await _context.Messages
                .Where(m => m.SenderId == otherUserId &&
                            m.ReceiverId == userId &&
                            !m.IsSeen)
                .ToListAsync();

            foreach (var msg in messages)
                msg.IsSeen = true;

            await _context.SaveChangesAsync();

            return Ok();
        }
    }
}

