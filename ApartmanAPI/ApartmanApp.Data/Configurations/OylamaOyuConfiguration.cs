using ApartmanApp.Core.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ApartmanApp.Data.Configurations;

public class OylamaOyuConfiguration : IEntityTypeConfiguration<OylamaOyu>
{
    public void Configure(EntityTypeBuilder<OylamaOyu> builder)
    {
        builder.HasKey(o => o.Id);

        // Bir kullanıcı bir oylamaya sadece bir kez oy verebilir
        builder.HasIndex(o => new { o.OylamaId, o.KullaniciId })
            .IsUnique();

        builder.HasOne(o => o.Oylama)
            .WithMany(oy => oy.Oylar)
            .HasForeignKey(o => o.OylamaId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(o => o.Secenek)
            .WithMany(s => s.Oylar)
            .HasForeignKey(o => o.SecenekId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(o => o.Kullanici)
            .WithMany()
            .HasForeignKey(o => o.KullaniciId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.ToTable("OylamaOylari");
    }
}
