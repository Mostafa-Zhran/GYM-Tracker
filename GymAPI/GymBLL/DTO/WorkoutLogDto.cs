using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymBLL.DTO
{
    public class WorkoutLogDto
    {
        public Guid WorkoutId { get; set; }

        public DateTime CompletedAt { get; set; }

        public string Notes { get; set; }
    }
}
