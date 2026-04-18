using ApartmanApp.Core.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ApartmanApp.Data.Configurations;

public class OylamaConfiguration : IEntityTypeConfiguration<Oylama>
{
    public void Configure(EntityTypeBuilder<Oylama> builder)
    {
        builder.HasKey(o => o.Id);
        builder.Property(o => o.Baslik).IsRequired().HasMaxLength(200);
        builder.Property(o => o.Aciklama).HasMaxLength(1000);

        builder.HasOne(o => o.Olusturan)
            .WithMany()
            .HasForeignKey(o => o.OlusturanId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.ToTable("Oylamalar");
    }
}
