using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymBLL.DTO
{
    public class AssignWorkoutDto
    {
        public string TraineeId { get; set; }

        public string Title { get; set; }
        public string Description { get; set; }

        public DateTime Date { get; set; }
    }
}
