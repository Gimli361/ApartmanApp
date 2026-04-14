using ApartmanApp.Core.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ApartmanApp.Data.Configurations;

public class ArizaTakipConfiguration : IEntityTypeConfiguration<ArizaTakip>
{
    public void Configure(EntityTypeBuilder<ArizaTakip> builder)
    {
        builder.HasKey(t => t.Id);

        builder.HasIndex(t => new { t.ArizaId, t.KullaniciId })
            .IsUnique();

        builder.HasOne(t => t.Ariza)
            .WithMany(a => a.Takipler)
            .HasForeignKey(t => t.ArizaId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(t => t.Kullanici)
            .WithMany(k => k.Takipler)
            .HasForeignKey(t => t.KullaniciId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.ToTable("ArizaTakipler");
    }
}
