using ApartmanApp.Core.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ApartmanApp.Data.Configurations;

public class KullaniciConfiguration : IEntityTypeConfiguration<Kullanici>
{
    public void Configure(EntityTypeBuilder<Kullanici> builder)
    {
        builder.HasKey(k => k.Id);

        builder.Property(k => k.Ad)
            .IsRequired()
            .HasMaxLength(50);

        builder.Property(k => k.Soyad)
            .IsRequired()
            .HasMaxLength(50);

        builder.Property(k => k.Email)
            .IsRequired()
            .HasMaxLength(100);

        builder.HasIndex(k => k.Email)
            .IsUnique();

        builder.Property(k => k.DaireNo)
            .IsRequired()
            .HasMaxLength(10);

        builder.Property(k => k.Rol)
            .IsRequired();

        builder.HasMany(k => k.Arizalar)
            .WithOne(a => a.Bildiren)
            .HasForeignKey(a => a.BildirenId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.ToTable("Kullanicilar");
    }
}
