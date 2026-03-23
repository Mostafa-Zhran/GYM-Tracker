using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymDAL.Model
{
    public class WorkoutLog
    {
        public Guid Id { get; set; }

        public Guid WorkoutId { get; set; }
        public Workout Workout { get; set; }

        public DateTime CompletedAt { get; set; }

        public string Notes { get; set; }

        public int? Rating { get; set; } // من 1 لـ 5 مثلاً
    }
}
