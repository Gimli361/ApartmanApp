using ApartmanApp.Core.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace ApartmanApp.Data.Configurations;

public class ArizaConfiguration : IEntityTypeConfiguration<Ariza>
{
    public void Configure(EntityTypeBuilder<Ariza> builder)
    {
        builder.HasKey(a => a.Id);

        builder.Property(a => a.Baslik)
            .IsRequired()
            .HasMaxLength(100);

        builder.Property(a => a.Aciklama)
            .IsRequired()
            .HasMaxLength(1000);

        builder.Property(a => a.Durum)
            .IsRequired();

        builder.Property(a => a.Oncelik)
            .IsRequired();

        builder.Property(a => a.Tarih)
            .IsRequired();

        builder.ToTable("Arizalar");
    }
}
