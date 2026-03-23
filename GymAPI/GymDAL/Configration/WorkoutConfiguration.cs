using GymDAL.Model;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

public class WorkoutConfiguration : IEntityTypeConfiguration<Workout>
{
    public void Configure(EntityTypeBuilder<Workout> builder)
    {
        builder.HasKey(w => w.Id);

        builder.Property(w => w.Title)
               .IsRequired()
               .HasMaxLength(100);

        builder.Property(w => w.Description)
               .HasMaxLength(1000);

        builder.Property(w => w.Date)
               .IsRequired();

        builder.HasMany(w => w.Logs)
       .WithOne(l => l.Workout)
       .HasForeignKey(l => l.WorkoutId)
       .OnDelete(DeleteBehavior.Cascade);
        // علاقة Coach
        builder.HasOne(w => w.Coach)
               .WithMany(u => u.CreatedWorkouts)
               .HasForeignKey(w => w.CoachId)
               .OnDelete(DeleteBehavior.Restrict);

        // علاقة Trainee
        builder.HasOne(w => w.Trainee)
               .WithMany(u => u.AssignedWorkouts)
               .HasForeignKey(w => w.TraineeId)
               .OnDelete(DeleteBehavior.Restrict);
    }
}