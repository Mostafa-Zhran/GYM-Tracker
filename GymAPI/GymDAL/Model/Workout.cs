using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymDAL.Model
{
    public class Workout
    {
        public Guid Id { get; set; }

        public string Title { get; set; }
        public string Description { get; set; }

        public DateTime Date { get; set; }

        public string CoachId { get; set; }
        public ApplicationUser Coach { get; set; }

        public string TraineeId { get; set; }
        public ApplicationUser Trainee { get; set; }

        public ICollection<WorkoutLog> Logs { get; set; }
    }
}
