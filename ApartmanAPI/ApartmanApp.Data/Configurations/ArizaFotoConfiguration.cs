using ApartmanApp.Core.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ApartmanApp.Data.Configurations;

public class ArizaFotoConfiguration : IEntityTypeConfiguration<ArizaFoto>
{
    public void Configure(EntityTypeBuilder<ArizaFoto> builder)
    {
        builder.HasKey(f => f.Id);

        builder.Property(f => f.DosyaAdi)
            .IsRequired()
            .HasMaxLength(255);

        builder.Property(f => f.DosyaYolu)
            .IsRequired()
            .HasMaxLength(500);

        builder.HasOne(f => f.Ariza)
            .WithMany(a => a.Fotograflar)
            .HasForeignKey(f => f.ArizaId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
