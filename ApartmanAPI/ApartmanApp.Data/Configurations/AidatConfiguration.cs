using ApartmanApp.Core.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ApartmanApp.Data.Configurations;

public class AidatConfiguration : IEntityTypeConfiguration<Aidat>
{
    public void Configure(EntityTypeBuilder<Aidat> builder)
    {
        builder.HasKey(a => a.Id);

        builder.Property(a => a.Tutar)
            .IsRequired()
            .HasPrecision(10, 2);

        builder.Property(a => a.Ay).IsRequired();
        builder.Property(a => a.Yil).IsRequired();

        builder.Property(a => a.OdemeDurumu)
            .HasConversion<string>()
            .IsRequired();

        builder.HasOne(a => a.Kullanici)
            .WithMany()
            .HasForeignKey(a => a.KullaniciId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
