using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymDAL.Configration
{
    using GymDAL.Model;
    using Microsoft.EntityFrameworkCore;
    using Microsoft.EntityFrameworkCore.Metadata.Builders;

    public class ApplicationUserConfiguration
        : IEntityTypeConfiguration<ApplicationUser>
    {
        public void Configure(EntityTypeBuilder<ApplicationUser> builder)
        {
            // Table Name
            builder.ToTable("Users");


            // ==============================
            // Self Relationship (Coach - Trainees)
            // ==============================

            builder.HasOne(u => u.Coach)
                   .WithMany(c => c.Trainees)
                   .HasForeignKey(u => u.CoachId)
                   .OnDelete(DeleteBehavior.Restrict);

            // ==============================
            // Created Workouts (Coach)
            // ==============================

            builder.HasMany(u => u.CreatedWorkouts)
                   .WithOne(w => w.Coach)
                   .HasForeignKey(w => w.CoachId)
                   .OnDelete(DeleteBehavior.Restrict);

            // ==============================
            // Assigned Workouts (Trainee)
            // ==============================

            builder.HasMany(u => u.AssignedWorkouts)
                   .WithOne(w => w.Trainee)
                   .HasForeignKey(w => w.TraineeId)
                   .OnDelete(DeleteBehavior.Restrict);
        }
    }
}
