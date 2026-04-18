using ApartmanApp.Core.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ApartmanApp.Data.Configurations;

public class OylamaSecenekConfiguration : IEntityTypeConfiguration<OylamaSecenek>
{
    public void Configure(EntityTypeBuilder<OylamaSecenek> builder)
    {
        builder.HasKey(s => s.Id);
        builder.Property(s => s.Metin).IsRequired().HasMaxLength(200);

        builder.HasOne(s => s.Oylama)
            .WithMany(o => o.Secenekler)
            .HasForeignKey(s => s.OylamaId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.ToTable("OylamaSecenekler");
    }
}
