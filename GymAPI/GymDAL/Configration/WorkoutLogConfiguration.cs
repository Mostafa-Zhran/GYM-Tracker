using GymDAL.Model;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace GymDAL.Configration
{
    public class WorkoutLogConfiguration : IEntityTypeConfiguration<WorkoutLog>
    {
        public void Configure(EntityTypeBuilder<WorkoutLog> builder)
        {
            builder.HasKey(l => l.Id);

            builder.Property(l => l.CompletedAt)
                   .IsRequired();

            builder.Property(l => l.Notes)
                   .HasMaxLength(1000);

            builder.Property(l => l.Rating)
                   .HasDefaultValue(0);
        }
    }
}
