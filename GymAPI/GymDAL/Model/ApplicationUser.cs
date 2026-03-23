using Microsoft.AspNetCore.Identity;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymDAL.Model
{
    public class ApplicationUser : IdentityUser
    {
        // Coach → Trainees
        public ICollection<ApplicationUser> Trainees { get; set; }

        // Trainee → Coach
        public string? CoachId { get; set; }
        public ApplicationUser Coach { get; set; }

        public ICollection<Workout> CreatedWorkouts { get; set; }
        public ICollection<Workout> AssignedWorkouts { get; set; }
    }
}
