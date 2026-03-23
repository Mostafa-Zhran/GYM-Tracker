using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymBLL.DTO
{
    public class WorkoutResponseDto
    {
        public string Title { get; set; }

        public string Description { get; set; }

        public DateTime ScheduledDate { get; set; }

        public string CoachName { get; set; }

        public string TraineeName { get; set; }
        public WorkoutLogDto? Log { get; set; }

    }
}
